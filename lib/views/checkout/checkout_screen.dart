import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/payment_launcher.dart';
import '../../core/widgets/plasvora_header.dart';
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

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _buyerNoteController = TextEditingController();

  ShippingEstimateResult? _estimateResult;
  ShippingCostOption? _selectedOption;
  bool _isEstimating = false;
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
        final canSubmit =
            selectedAddress != null &&
            _selectedOption != null &&
            !_isEstimating &&
            !orderVm.isCreatingOrder;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: const PlasvoraHeader(
            customTitle: 'Checkout Pesanan',
            showBack: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _buildMaterialSummaryCard(),
              const SizedBox(height: 14),
              _buildAddressCard(addrVm, selectedAddress),
              const SizedBox(height: 14),
              _buildCourierSelectionCard(selectedAddress),
              const SizedBox(height: 14),
              _buildBuyerNoteCard(orderVm),
              const SizedBox(height: 14),
              _buildPricingSummaryCard(shippingCost, previewTotal),
              if (orderVm.errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildCheckoutErrorBanner(orderVm),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: AppTypography.labelSm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _selectedOption != null
                              ? MaterialListing.formatRupiah(previewTotal)
                              : MaterialListing.formatRupiah(
                                  widget.listing.price,
                                ),
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
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: canSubmit ? _handleSubmitCheckout : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        // Override AppTheme.lightTheme's Size.fromHeight(50) (infinite width)
                        // so this Row child never triggers unbounded-width layout failure.
                        minimumSize: const Size(140, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              'Buat Pesanan & Bayar',
                              style: AppTypography.labelMd(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w700),
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
            'Ringkasan Material (Satu Lot)',
            style: AppTypography.labelLg(color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
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
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.categoryLabel} • ${item.weightKg.toStringAsFixed(1)} kg • Penjual: ${item.ownerName ?? 'Pengguna #${item.ownerId}'}',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
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
                  style: AppTypography.labelLg(color: AppColors.onSurface),
                ),
              ),
              if (selectedAddress != null)
                TextButton(
                  onPressed: _openAddressSelection,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
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
                  Text('Memuat alamat tersimpan...'),
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
              'Anda belum memiliki alamat pengiriman tersimpan. Tambahkan alamat untuk memilih layanan pengiriman.',
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
                  'Tambah Alamat Pengiriman',
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
              '${selectedAddress.label} • ${selectedAddress.recipientName}',
              style: AppTypography.labelMd(
                color: AppColors.onSurface,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              selectedAddress.recipientPhone,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              selectedAddress.destinationLabel,
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
                  'Pilih Layanan Pengiriman',
                  style: AppTypography.labelLg(color: AppColors.onSurface),
                ),
              ),
              if (selectedAddress != null && !_isEstimating)
                TextButton(
                  onPressed: () => _fetchShippingEstimate(selectedAddress),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
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
                  Text('Mengambil tarif kurir...'),
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
          else if (_estimateResult == null || _estimateResult!.options.isEmpty)
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
          else
            Column(
              children: _estimateResult!.options.map((opt) {
                final isSelected =
                    _selectedOption != null &&
                    _selectedOption!.courierCode == opt.courierCode &&
                    _selectedOption!.service == opt.service;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedOption = opt),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondaryContainer.withValues(alpha: 0.4)
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
                                Text(
                                  '${opt.courierName} (${opt.service})',
                                  style: AppTypography.labelMd(
                                    color: AppColors.onSurface,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (opt.etd != null)
                                  Text(
                                    'Estimasi ${opt.etd!}',
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
            style: AppTypography.labelLg(color: AppColors.onSurface),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
            style: AppTypography.labelLg(color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          _priceRow(
            'Harga Material',
            MaterialListing.formatRupiah(widget.listing.price),
          ),
          const SizedBox(height: 6),
          _priceRow(
            'Ongkir',
            _selectedOption != null
                ? MaterialListing.formatRupiah(shippingCost)
                : 'Belum dipilih',
          ),
          const SizedBox(height: 6),
          _priceRow('Biaya Platform', MaterialListing.formatRupiah(0)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: AppTypography.labelLg(color: AppColors.onSurface),
              ),
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
            'Tarif pengiriman dan total pembayaran akhir akan diverifikasi ulang secara otoritatif oleh server saat pesanan dibuat.',
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
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: child,
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
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
