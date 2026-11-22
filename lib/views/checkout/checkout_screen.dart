import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/display_formatters.dart';
import '../../core/utils/payment_launcher.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../models/material_listing.dart';
import '../../models/shipping_destination.dart';
import '../../models/user_address.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/address_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../address/address_form_screen.dart';
import '../address/address_list_screen.dart';
import '../orders/order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final MaterialListing listing;
  final AddressViewModel addressViewModel;
  final ShippingRepository shippingRepository;
  final OrderViewModel orderViewModel;
  final AuthViewModel? authViewModel;
  final MarketplaceViewModel? marketplaceViewModel;
  final PaymentLauncher? paymentLauncher;
  final ShippingEstimateResult? initialEstimate;

  const CheckoutScreen({
    super.key,
    required this.listing,
    required this.addressViewModel,
    required this.shippingRepository,
    required this.orderViewModel,
    this.authViewModel,
    this.marketplaceViewModel,
    this.paymentLauncher,
    this.initialEstimate,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _RankedCourierOption {
  final ShippingCostOption option;
  final String? badgeLabel;

  const _RankedCourierOption({
    required this.option,
    this.badgeLabel,
  });
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _buyerNoteController = TextEditingController();

  ShippingEstimateResult? _estimateResult;
  ShippingCostOption? _selectedOption;
  bool _isEstimating = false;
  bool _showAllCouriers = false;
  String? _estimateError;
  int? _lastAddressId;
  int _estimateVersion = 0;

  /// Idempotency key disimpan per kombinasi logis checkout agar retry pasca timeout
  /// memakai key yang sama dan tidak pernah membuat pesanan ganda.
  String? _activeIdempotencyKey;
  String? _activeIdempotencyFingerprint;

  @override
  void initState() {
    super.initState();
    _lastAddressId = widget.addressViewModel.selectedAddress?.id;
    widget.addressViewModel.addListener(_onAddressChanged);

    final initial = widget.initialEstimate;
    if (initial != null &&
        _lastAddressId != null &&
        initial.destination.addressId == _lastAddressId) {
      _estimateResult = initial;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.orderViewModel.clearErrors();
      _bootstrapAddressAndShipping();
    });
  }

  @override
  void dispose() {
    widget.addressViewModel.removeListener(_onAddressChanged);
    _buyerNoteController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapAddressAndShipping() async {
    final addrVm = widget.addressViewModel;
    if (addrVm.addresses.isEmpty && !addrVm.isLoading) {
      await addrVm.loadAddresses();
    }
    if (!mounted) return;
    final selected = addrVm.selectedAddress;
    _lastAddressId = selected?.id;
    if (selected != null && _estimateResult == null && !_isEstimating) {
      await _fetchShippingEstimate(selected);
    }
  }

  void _onAddressChanged() {
    if (!mounted) return;
    final nextAddress = widget.addressViewModel.selectedAddress;
    final nextId = nextAddress?.id;

    if (nextId != _lastAddressId) {
      _lastAddressId = nextId;
      _estimateVersion++;
      _activeIdempotencyKey = null;
      _activeIdempotencyFingerprint = null;
      setState(() {
        _estimateResult = null;
        _selectedOption = null;
        _estimateError = null;
        _isEstimating = false;
        _showAllCouriers = false;
      });
      if (nextAddress != null) {
        _fetchShippingEstimate(nextAddress);
      }
    } else {
      setState(() {});
    }
  }

  Future<void> _fetchShippingEstimate(UserAddress address) async {
    if (_isEstimating) return;
    final version = ++_estimateVersion;
    setState(() {
      _isEstimating = true;
      _estimateError = null;
      _selectedOption = null;
      _showAllCouriers = false;
    });

    try {
      final result = await widget.shippingRepository.estimateShipping(
        listingId: widget.listing.id,
        addressId: address.id,
      );
      if (!mounted || version != _estimateVersion) return;
      setState(() {
        _estimateResult = result;
        _estimateError = null;
        _isEstimating = false;
      });
    } on ApiException catch (e) {
      if (!mounted || version != _estimateVersion) return;
      setState(() {
        _estimateResult = null;
        _estimateError = e.message.trim().isNotEmpty
            ? e.message.trim()
            : 'Gagal memuat opsi pengiriman.';
        _isEstimating = false;
      });
    } catch (_) {
      if (!mounted || version != _estimateVersion) return;
      setState(() {
        _estimateResult = null;
        _estimateError =
            'Gagal memuat opsi pengiriman. Periksa koneksi lalu coba lagi.';
        _isEstimating = false;
      });
    }
  }

  Future<void> _openAddressSelection() async {
    await Navigator.of(context).push<UserAddress?>(
      MaterialPageRoute(
        builder: (_) => AddressListScreen(
          addressViewModel: widget.addressViewModel,
          shippingRepository: widget.shippingRepository,
          selectionMode: true,
        ),
      ),
    );
  }

  Future<void> _openAddAddress() async {
    await Navigator.of(context).push<UserAddress?>(
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
          addressViewModel: widget.addressViewModel,
          shippingRepository: widget.shippingRepository,
        ),
      ),
    );
  }

  bool _isSameOption(ShippingCostOption a, ShippingCostOption b) {
    return a.courierCode.toLowerCase() == b.courierCode.toLowerCase() &&
        a.service.toUpperCase() == b.service.toUpperCase() &&
        a.cost == b.cost;
  }

  /// Mengurutkan opsi kurir secara transparan dari data aktual backend:
  /// 1) Opsi termurah ("Termurah" jika ada >= 2 opsi)
  /// 2) Opsi dengan estimasi ETD aktual yang benar-benar lebih cepat ("Estimasi Lebih Cepat")
  /// 3) Opsi lainnya diurutkan dari biaya terendah
  List<_RankedCourierOption> _rankCourierOptions(
    List<ShippingCostOption> rawOptions,
  ) {
    if (rawOptions.isEmpty) return const [];

    final byCost = List<ShippingCostOption>.from(rawOptions)
      ..sort((a, b) {
        final costCmp = a.cost.compareTo(b.cost);
        if (costCmp != 0) return costCmp;
        final daysA = DisplayFormatters.parseMinEtdDays(a.etd) ?? 9999;
        final daysB = DisplayFormatters.parseMinEtdDays(b.etd) ?? 9999;
        return daysA.compareTo(daysB);
      });

    final cheapest = byCost.first;
    final cheapestDays = DisplayFormatters.parseMinEtdDays(cheapest.etd);

    ShippingCostOption? faster;
    int? fasterDays;
    if (cheapestDays != null) {
      for (final opt in byCost.skip(1)) {
        final optDays = DisplayFormatters.parseMinEtdDays(opt.etd);
        if (optDays != null && optDays < cheapestDays) {
          if (faster == null ||
              optDays < fasterDays! ||
              (optDays == fasterDays && opt.cost < faster.cost)) {
            faster = opt;
            fasterDays = optDays;
          }
        }
      }
    }

    final ranked = <_RankedCourierOption>[
      _RankedCourierOption(
        option: cheapest,
        badgeLabel: byCost.length >= 2 ? 'Termurah' : null,
      ),
    ];

    if (faster != null) {
      ranked.add(
        _RankedCourierOption(
          option: faster,
          badgeLabel: 'Estimasi Lebih Cepat',
        ),
      );
    }

    for (final opt in byCost) {
      if (_isSameOption(opt, cheapest)) continue;
      if (faster != null && _isSameOption(opt, faster)) continue;
      ranked.add(_RankedCourierOption(option: opt));
    }

    return ranked;
  }

  String _resolveIdempotencyKey({
    required int addressId,
    required ShippingCostOption option,
    required String? buyerNote,
  }) {
    final fingerprint =
        '${widget.listing.id}|$addressId|${option.courierCode.toLowerCase()}|${option.service.toUpperCase()}|${buyerNote ?? ''}';
    if (_activeIdempotencyKey != null &&
        _activeIdempotencyFingerprint == fingerprint) {
      return _activeIdempotencyKey!;
    }
    final userId = widget.authViewModel?.currentUser?.id ?? 0;
    final micros = DateTime.now().microsecondsSinceEpoch;
    _activeIdempotencyFingerprint = fingerprint;
    _activeIdempotencyKey = 'chk-$userId-${widget.listing.id}-$micros';
    return _activeIdempotencyKey!;
  }

  Future<void> _handleSubmitCheckout() async {
    final vm = widget.orderViewModel;
    if (vm.isCreatingOrder) return;

    final selectedAddress = widget.addressViewModel.selectedAddress;
    final selectedOption = _selectedOption;
    if (selectedAddress == null || selectedOption == null) return;

    final rawNote = _buyerNoteController.text.trim();
    final buyerNote = rawNote.isNotEmpty ? rawNote : null;
    final idempotencyKey = _resolveIdempotencyKey(
      addressId: selectedAddress.id,
      option: selectedOption,
      buyerNote: buyerNote,
    );

    final created = await vm.createOrder(
      listingId: widget.listing.id,
      addressId: selectedAddress.id,
      courierCode: selectedOption.courierCode,
      courierService: selectedOption.service,
      buyerNote: buyerNote,
      idempotencyKey: idempotencyKey,
    );

    if (!mounted) return;

    if (created != null) {
      widget.marketplaceViewModel?.loadListings();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: created.id,
            initialOrder: created,
            orderViewModel: widget.orderViewModel,
            authViewModel: widget.authViewModel,
            paymentLauncher: widget.paymentLauncher,
          ),
        ),
      );
    }
  }

  void _openReconciliationOrder(int orderId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: orderId,
          orderViewModel: widget.orderViewModel,
          authViewModel: widget.authViewModel,
          paymentLauncher: widget.paymentLauncher,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.addressViewModel,
        widget.orderViewModel,
      ]),
      builder: (context, _) {
        final addrVm = widget.addressViewModel;
        final orderVm = widget.orderViewModel;
        final selectedAddress = addrVm.selectedAddress;
        final shippingCost = _selectedOption?.cost ?? 0;
        final previewTotal = widget.listing.price + shippingCost;
        final displayedTotal = _selectedOption != null
            ? previewTotal
            : widget.listing.price;
        final canSubmit =
            selectedAddress != null &&
            _selectedOption != null &&
            !_isEstimating &&
            !orderVm.isCreatingOrder;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: const SimplePageAppBar(title: 'Checkout Pesanan'),
          body: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildMaterialSummaryCard(),
                const SizedBox(height: 16),
                _buildAddressCard(addrVm, selectedAddress),
                const SizedBox(height: 16),
                _buildCourierSelectionCard(selectedAddress),
                const SizedBox(height: 16),
                _buildBuyerNoteCard(orderVm),
                const SizedBox(height: 16),
                _buildPricingSummaryCard(shippingCost, previewTotal),
                if (orderVm.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildCheckoutErrorBanner(orderVm),
                ],
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedOption != null
                              ? 'Total Estimasi'
                              : 'Harga Material',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MaterialListing.formatRupiah(displayedTotal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineSm(
                            color: AppColors.primaryContainer,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 5,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canSubmit ? _handleSubmitCheckout : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          // Override AppTheme.lightTheme's Size.fromHeight(50) (infinite width)
                          // so this Row child never triggers unbounded-width layout failure.
                          minimumSize: const Size(140, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const StadiumBorder(),
                        ),
                        child: orderVm.isCreatingOrder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Bayar ${MaterialListing.formatRupiah(displayedTotal)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMd(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialSummaryCard() {
    final item = widget.listing;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Material',
            style: AppTypography.labelLg(
              color: AppColors.onSurface,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholderThumb(),
                        )
                      : _placeholderThumb(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.labelLg(
                        color: AppColors.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.categoryLabel} · ${item.weightKg.toStringAsFixed(1)} kg · ${item.ownerName ?? 'Penjual #${item.ownerId}'}',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.formattedPrice,
                      style: AppTypography.labelLg(
                        color: AppColors.primaryContainer,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    AddressViewModel addrVm,
    UserAddress? selectedAddress,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alamat Pengiriman',
                  style: AppTypography.labelLg(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (selectedAddress != null)
                TextButton(
                  onPressed: _openAddressSelection,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.primaryContainer,
                  ),
                  child: const Text('Ganti Alamat'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (addrVm.isLoading && addrVm.addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Text('Memuat alamat tersimpan...')),
                ],
              ),
            )
          else if (addrVm.errorMessage != null && addrVm.addresses.isEmpty) ...[
            Text(
              addrVm.errorMessage!,
              style: AppTypography.bodySm(color: AppColors.error),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: addrVm.loadAddresses,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.primaryContainer),
              ),
            ),
          ] else if (selectedAddress == null) ...[
            Text(
              'Belum ada alamat pengiriman tersimpan. Tambahkan alamat untuk melihat opsi kurir.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openAddAddress,
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(
                  'Tambah Alamat',
                  style: AppTypography.labelMd(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ] else ...[
            Text(
              '${selectedAddress.label} · ${selectedAddress.recipientName}',
              style: AppTypography.labelMd(
                color: AppColors.onSurface,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              PhoneUtils.formatForDisplay(selectedAddress.recipientPhone),
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              DisplayFormatters.deduplicateLocationLabel(
                selectedAddress.destinationLabel,
              ),
              style: AppTypography.bodySm(
                color: AppColors.secondary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              selectedAddress.addressDetail,
              style: AppTypography.bodySm(color: AppColors.onSurface),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourierSelectionCard(UserAddress? selectedAddress) {
    final ranked = _estimateResult != null
        ? _rankCourierOptions(_estimateResult!.options)
        : const <_RankedCourierOption>[];

    List<_RankedCourierOption> visibleOptions = ranked;
    if (!_showAllCouriers && ranked.length > 3) {
      visibleOptions = ranked.take(3).toList();
      if (_selectedOption != null) {
        final selectedAlreadyVisible = visibleOptions.any(
          (item) => _isSameOption(item.option, _selectedOption!),
        );
        if (!selectedAlreadyVisible) {
          final matchingRanked = ranked.where(
            (item) => _isSameOption(item.option, _selectedOption!),
          );
          if (matchingRanked.isNotEmpty) {
            visibleOptions.add(matchingRanked.first);
          }
        }
      }
    }

    final hiddenCount = ranked.length - visibleOptions.length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pilih Kurir',
                  style: AppTypography.labelLg(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (selectedAddress != null && !_isEstimating)
                TextButton(
                  onPressed: () => _fetchShippingEstimate(selectedAddress),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.primaryContainer,
                  ),
                  child: const Text('Muat Ulang'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedAddress == null)
            Text(
              'Pilih atau tambahkan alamat pengiriman terlebih dahulu.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            )
          else if (_isEstimating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Text('Mengambil tarif kurir...')),
                ],
              ),
            )
          else if (_estimateError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _estimateError!,
                  style: AppTypography.bodySm(color: AppColors.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _fetchShippingEstimate(selectedAddress),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Hitung Lagi'),
                ),
              ],
            )
          else if (ranked.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Layanan pengiriman belum tersedia untuk rute ini.',
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _fetchShippingEstimate(selectedAddress),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Coba Hitung Lagi'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openAddressSelection,
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: const Text('Ganti Alamat'),
                    ),
                  ],
                ),
              ],
            )
          else ...[
            Column(
              children: visibleOptions.map((rankedOpt) {
                final opt = rankedOpt.option;
                final isSelected =
                    _selectedOption != null &&
                    _isSameOption(_selectedOption!, opt);
                final shortTitle = DisplayFormatters.formatShortCourierTitle(
                  courierName: opt.courierName,
                  courierCode: opt.courierCode,
                  service: opt.service,
                );
                final etdText = DisplayFormatters.formatIndonesianEtd(opt.etd);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedOption = opt),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondaryContainer.withValues(
                                alpha: 0.45,
                              )
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryContainer
                              : AppColors.outlineVariant.withValues(alpha: 0.7),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.primaryContainer
                                : AppColors.outline,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      shortTitle,
                                      style: AppTypography.labelMd(
                                        color: AppColors.onSurface,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    if (rankedOpt.badgeLabel != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          rankedOpt.badgeLabel!,
                                          style: AppTypography.labelSm(
                                            color:
                                                AppColors.onSecondaryContainer,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  etdText,
                                  style: AppTypography.labelSm(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            MaterialListing.formatRupiah(opt.cost),
                            style: AppTypography.labelMd(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (ranked.length > 3) ...[
              const SizedBox(height: 2),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _showAllCouriers = !_showAllCouriers);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    foregroundColor: AppColors.primaryContainer,
                  ),
                  icon: Icon(
                    _showAllCouriers ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _showAllCouriers
                        ? 'Tampilkan Lebih Sedikit'
                        : 'Lihat Opsi Lain ($hiddenCount)',
                    style: AppTypography.labelMd(
                      color: AppColors.primaryContainer,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBuyerNoteCard(OrderViewModel orderVm) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan Pembeli (Opsional)',
            style: AppTypography.labelMd(
              color: AppColors.onSurfaceVariant,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _buyerNoteController,
            maxLength: 500,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Contoh: Mohon dikemas rapi agar tidak basah',
              errorText: orderVm.fieldErrors['buyer_note'],
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.outlineVariant,
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.outlineVariant,
                  width: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummaryCard(int shippingCost, int previewTotal) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pembayaran',
            style: AppTypography.labelLg(
              color: AppColors.onSurface,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _priceRow(
            'Harga Material',
            MaterialListing.formatRupiah(widget.listing.price),
          ),
          const SizedBox(height: 8),
          _priceRow(
            'Ongkos Kirim',
            _selectedOption != null
                ? MaterialListing.formatRupiah(shippingCost)
                : 'Belum dipilih',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Estimasi Pembayaran',
                  style: AppTypography.labelLg(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedOption != null
                    ? MaterialListing.formatRupiah(previewTotal)
                    : '-',
                style: AppTypography.headlineSm(
                  color: AppColors.primaryContainer,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total akhir diverifikasi ulang oleh server saat pesanan dibuat.',
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutErrorBanner(OrderViewModel orderVm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            orderVm.errorMessage!,
            style: AppTypography.bodySm(color: AppColors.onErrorContainer),
          ),
          if (orderVm.reconciliationOrderId != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _openReconciliationOrder(orderVm.reconciliationOrderId!),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Buka Pesanan Tersimpan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onErrorContainer,
                  side: const BorderSide(color: AppColors.onErrorContainer),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: child,
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.bodyMd(
            color: AppColors.onSurface,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _placeholderThumb() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
