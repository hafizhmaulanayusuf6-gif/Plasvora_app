import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/payment_launcher.dart';
import '../../core/utils/phone_utils.dart';
import '../../models/material_listing.dart';
import '../../models/shipping_destination.dart';
import '../../models/user_address.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/address_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/matching_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../address/address_form_screen.dart';
import '../address/address_list_screen.dart';
import '../auth/login_screen.dart';
import '../checkout/checkout_screen.dart';
import '../matching/matching_results_screen.dart';
import 'create_material_listing_screen.dart';

class MaterialDetailScreen extends StatefulWidget {
  final int materialId;
  final MaterialListing? initialMaterial;
  final MarketplaceViewModel viewModel;
  final AuthViewModel? authViewModel;
  final MatchingViewModel? matchingViewModel;
  final AddressViewModel? addressViewModel;
  final ShippingRepository? shippingRepository;
  final OrderViewModel? orderViewModel;
  final PaymentLauncher? paymentLauncher;

  const MaterialDetailScreen({
    super.key,
    required this.materialId,
    this.initialMaterial,
    required this.viewModel,
    this.authViewModel,
    this.matchingViewModel,
    this.addressViewModel,
    this.shippingRepository,
    this.orderViewModel,
    this.paymentLauncher,
  });

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  late MaterialListing? _material;
  bool _isLoading = false;
  bool _isLaunchingWhatsApp = false;
  String? _errorMessage;

  bool _isEstimating = false;
  ShippingEstimateResult? _estimateResult;
  String? _estimateError;
  int? _lastObservedAddressId;
  bool _hasTriggeredAddressLoad = false;
  int _estimateRequestVersion = 0;

  @override
  void initState() {
    super.initState();
    _material = widget.initialMaterial;
    _lastObservedAddressId = widget.addressViewModel?.selectedAddress?.id;
    widget.addressViewModel?.addListener(_handleAddressStateChanged);
    widget.authViewModel?.addListener(_handleAuthStateChanged);
    _fetchDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureBuyerAddressesLoaded();
      }
    });
  }

  @override
  void dispose() {
    widget.addressViewModel?.removeListener(_handleAddressStateChanged);
    widget.authViewModel?.removeListener(_handleAuthStateChanged);
    super.dispose();
  }

  bool _isOwnListing(MaterialListing item) {
    final isAuthenticated = widget.authViewModel?.isAuthenticated ?? false;
    final currentUserId = widget.authViewModel?.currentUser?.id;
    return isAuthenticated &&
        currentUserId != null &&
        currentUserId == item.ownerId;
  }

  void _handleAddressStateChanged() {
    if (!mounted) return;
    final nextId = widget.addressViewModel?.selectedAddress?.id;
    if (nextId != _lastObservedAddressId) {
      _lastObservedAddressId = nextId;
      _estimateRequestVersion++;
      setState(() {
        _estimateResult = null;
        _estimateError = null;
        _isEstimating = false;
      });
    } else {
      setState(() {});
    }
  }

  void _handleAuthStateChanged() {
    if (!mounted) return;
    _ensureBuyerAddressesLoaded();
    setState(() {});
  }

  void _ensureBuyerAddressesLoaded() {
    final auth = widget.authViewModel;
    final addressVm = widget.addressViewModel;
    final item = _material;
    if (auth == null || !auth.isAuthenticated) return;
    if (addressVm == null || item == null) return;
    if (_isOwnListing(item)) return;
    if (item.originDestinationId == null) return;
    if (_hasTriggeredAddressLoad) return;

    _hasTriggeredAddressLoad = true;
    if (addressVm.addresses.isEmpty && !addressVm.isLoading) {
      addressVm.loadAddresses();
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = _material == null;
      _errorMessage = null;
    });

    try {
      final detail = await widget.viewModel.getMaterialDetail(widget.materialId);
      if (mounted) {
        setState(() {
          _material = detail;
          _isLoading = false;
        });
        _ensureBuyerAddressesLoaded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  bool _isEligibleForPaidCheckout(MaterialListing item) {
    final hasValidOrigin =
        item.originDestinationId != null &&
        item.originDestinationId! > 0 &&
        item.originLabel != null &&
        item.originLabel!.trim().isNotEmpty;
    return item.status == 'available' &&
        !item.isFree &&
        item.price > 0 &&
        item.weightKg > 0 &&
        hasValidOrigin;
  }

  Future<void> _openCheckout(MaterialListing item) async {
    final addressVm = widget.addressViewModel;
    final shippingRepo = widget.shippingRepository;
    final orderVm = widget.orderViewModel;
    if (addressVm == null || shippingRepo == null || orderVm == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          listing: item,
          addressViewModel: addressVm,
          shippingRepository: shippingRepo,
          orderViewModel: orderVm,
          authViewModel: widget.authViewModel,
          marketplaceViewModel: widget.viewModel,
          paymentLauncher: widget.paymentLauncher,
          initialEstimate: _estimateResult,
        ),
      ),
    );
  }

  Future<void> _openEditListing(MaterialListing item) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => CreateMaterialListingScreen(
          viewModel: widget.viewModel,
          existingListing: item,
          shippingRepository: widget.shippingRepository,
        ),
      ),
    );
    if (!mounted) return;
    if (result is MaterialListing) {
      setState(() {
        _material = result;
        _estimateResult = null;
        _estimateError = null;
      });
    }
  }

  Future<void> _openAddressSelection() async {
    final addressVm = widget.addressViewModel;
    final shippingRepo = widget.shippingRepository;
    if (addressVm == null || shippingRepo == null) return;

    await Navigator.of(context).push<UserAddress?>(
      MaterialPageRoute(
        builder: (_) => AddressListScreen(
          addressViewModel: addressVm,
          shippingRepository: shippingRepo,
          selectionMode: true,
        ),
      ),
    );
  }

  Future<void> _openAddAddress() async {
    final addressVm = widget.addressViewModel;
    final shippingRepo = widget.shippingRepository;
    if (addressVm == null || shippingRepo == null) return;

    await Navigator.of(context).push<UserAddress?>(
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
          addressViewModel: addressVm,
          shippingRepository: shippingRepo,
        ),
      ),
    );
  }

  Future<void> _estimateShipping(
    MaterialListing item,
    UserAddress selectedAddress,
  ) async {
    if (_isEstimating) return;
    final shippingRepo = widget.shippingRepository;
    if (shippingRepo == null) return;

    final requestVersion = ++_estimateRequestVersion;
    setState(() {
      _isEstimating = true;
      _estimateError = null;
    });

    try {
      final result = await shippingRepo.estimateShipping(
        listingId: item.id,
        addressId: selectedAddress.id,
      );
      if (!mounted || requestVersion != _estimateRequestVersion) return;
      setState(() {
        _estimateResult = result;
        _estimateError = null;
        _isEstimating = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestVersion != _estimateRequestVersion) return;
      final friendly = e.message.trim().isNotEmpty
          ? e.message.trim()
          : 'Gagal menghitung estimasi ongkos kirim. Silakan coba lagi.';
      setState(() {
        _estimateError = friendly;
        _estimateResult = null;
        _isEstimating = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _estimateRequestVersion) return;
      setState(() {
        _estimateError =
            'Gagal menghitung estimasi ongkos kirim. Periksa koneksi lalu coba lagi.';
        _estimateResult = null;
        _isEstimating = false;
      });
    }
  }

  Future<void> _openSellerWhatsApp(Uri uri) async {
    if (_isLaunchingWhatsApp) return;
    setState(() => _isLaunchingWhatsApp = true);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak dapat membuka WhatsApp. Pastikan aplikasi WhatsApp atau browser terpasang.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal membuka WhatsApp. Silakan coba lagi beberapa saat.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunchingWhatsApp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Detail Material',
          style: AppTypography.headlineSm(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_material != null)
            IconButton(
              icon: Icon(
                _material!.isFavorited ? Icons.bookmark : Icons.bookmark_border,
                color: _material!.isFavorited
                    ? AppColors.primaryContainer
                    : AppColors.secondary,
              ),
              onPressed: () async {
                await widget.viewModel.toggleFavorite(_material!.id);
                setState(() {
                  _material = _material!.copyWith(
                    isFavorited: !_material!.isFavorited,
                  );
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _material == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Gagal Memuat Detail Material',
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTypography.bodySm(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchDetail,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _material!;
    final isAuthenticated = widget.authViewModel?.isAuthenticated ?? false;
    final isOwnListing = _isOwnListing(item);

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. Gambar Material
          _buildImageBanner(item),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Kategori Badge & Jarak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.categoryLabel,
                        style: AppTypography.labelSm(
                          color: AppColors.primaryContainer,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (item.distanceKm != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.distanceKm!.toStringAsFixed(1)} km',
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Nama Material
                Text(
                  item.name,
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),

                // 4. Harga Total (Satu Lot) / Gratis Badge + Estimasi per kg (display-only)
                if (item.isFree || item.price == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Gratis',
                      style: AppTypography.labelMd(
                        color: AppColors.onSecondaryContainer,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.formattedPrice,
                            style: AppTypography.headlineMd(
                              color: AppColors.primaryContainer,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Harga total (satu lot)',
                              style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (item.formattedEstimatedPricePerKg != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Estimasi ~${item.formattedEstimatedPricePerKg} (perkiraan saja)',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 16),

                // 5. Spesifikasi Grid
                Text(
                  'Spesifikasi Material',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.scale,
                        label: 'Berat Material',
                        value: '${item.weightKg.toStringAsFixed(1)} kg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.clean_hands,
                        label: 'Kondisi',
                        value: item.conditionLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.location_on,
                        label: 'Lokasi Umum',
                        value: item.generalLocation.isNotEmpty
                            ? item.generalLocation
                            : '-',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.person,
                        label: 'Pemilik',
                        value: item.ownerName ?? 'Pengguna #${item.ownerId}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 16),

                // 6. Deskripsi
                Text(
                  'Deskripsi Material',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.isNotEmpty
                      ? item.description
                      : 'Tidak ada deskripsi tambahan dari pemilik.',
                  style: AppTypography.bodyMd(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Kontrol Pemilik (Edit Listing) atau Panel Estimasi Ongkir Pembeli/Tamu
                if (isOwnListing) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _openEditListing(item),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: Text(
                        'Edit Listing',
                        style: AppTypography.labelLg(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  if (_isEligibleForPaidCheckout(item) &&
                      widget.orderViewModel != null) ...[
                    if (isAuthenticated &&
                        widget.addressViewModel != null &&
                        widget.shippingRepository != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _openCheckout(item),
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 20,
                          ),
                          label: Text(
                            'Beli Sekarang',
                            style: AppTypography.labelLg(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (!isAuthenticated &&
                        widget.authViewModel != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                  authViewModel: widget.authViewModel!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.login, size: 20),
                          label: Text(
                            'Masuk untuk Membeli Material',
                            style: AppTypography.labelLg(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  _buildShippingEstimatorPanel(
                    item,
                    isAuthenticated: isAuthenticated,
                  ),
                  const SizedBox(height: 16),
                ],

                // 8. Tombol Hubungi Penjual via WhatsApp (hanya jika bukan pemilik & nomor valid)
                Builder(
                  builder: (context) {
                    final whatsappUri = isOwnListing
                        ? null
                        : PhoneUtils.buildSellerWhatsAppUri(
                            sellerPhone: item.ownerPhone,
                            materialName: item.name,
                          );
                    if (whatsappUri == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLaunchingWhatsApp
                                ? null
                                : () => _openSellerWhatsApp(whatsappUri),
                            icon: _isLaunchingWhatsApp
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF146C3A),
                                    ),
                                  )
                                : const Icon(
                                    Icons.chat_outlined,
                                    size: 20,
                                    color: Color(0xFF146C3A),
                                  ),
                            label: Text(
                              'Hubungi Penjual via WhatsApp',
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: AppTypography.labelMd(
                                color: const Color(0xFF146C3A),
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE7F6EC),
                              foregroundColor: const Color(0xFF146C3A),
                              minimumSize: const Size(double.infinity, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              side: const BorderSide(
                                color: Color(0xFF25D366),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),

                // 9. Tombol Smart Matching untuk mencari kebutuhan yang cocok
                if (widget.matchingViewModel != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MatchingResultsScreen(
                              matchingViewModel: widget.matchingViewModel!,
                              marketplaceViewModel: widget.viewModel,
                              authViewModel: widget.authViewModel,
                              addressViewModel: widget.addressViewModel,
                              shippingRepository: widget.shippingRepository,
                              listingId: item.id,
                              title:
                                  'Kebutuhan Cocok untuk ${item.categoryLabel}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.bolt,
                        color: AppColors.primaryContainer,
                      ),
                      label: Text(
                        'Cari Kebutuhan Cocok (Smart Matching)',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: AppTypography.labelMd(
                          color: AppColors.primaryContainer,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        side: const BorderSide(
                          color: AppColors.primaryContainer,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingEstimatorPanel(
    MaterialListing item, {
    required bool isAuthenticated,
  }) {
    final hasOrigin = item.originDestinationId != null &&
        item.originDestinationId! > 0;
    final originDisplay =
        (item.originLabel != null && item.originLabel!.trim().isNotEmpty)
            ? item.originLabel!.trim()
            : 'Belum diatur';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
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
                  'Estimasi Ongkos Kirim',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ringkasan asal & berat lot
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asal Pengiriman',
                  style: AppTypography.labelSm(color: AppColors.outline),
                ),
                const SizedBox(height: 2),
                Text(
                  originDisplay,
                  style: AppTypography.bodyMd(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Berat Satu Lot: ${item.weightKg.toStringAsFixed(1)} kg',
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (!hasOrigin) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Penjual belum mengatur lokasi asal pengiriman.',
                      style: AppTypography.bodySm(color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!isAuthenticated) ...[
            Text(
              'Masuk ke akun Anda untuk memilih alamat tujuan dan menghitung estimasi ongkos kirim.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            if (widget.authViewModel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(
                          authViewModel: widget.authViewModel!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Masuk untuk Cek Ongkir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    side: const BorderSide(color: AppColors.primaryContainer),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ] else if (widget.addressViewModel != null &&
              widget.shippingRepository != null) ...[
            _buildAuthenticatedBuyerEstimatorContent(
              item,
              widget.addressViewModel!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthenticatedBuyerEstimatorContent(
    MaterialListing item,
    AddressViewModel addressVm,
  ) {
    if (addressVm.isLoading && addressVm.addresses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Memuat alamat tujuan...',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    if (addressVm.errorMessage != null && addressVm.addresses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            addressVm.errorMessage!,
            style: AppTypography.bodySm(color: AppColors.error),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: addressVm.loadAddresses,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.primaryContainer),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final selectedAddress = addressVm.selectedAddress;
    if (selectedAddress == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda belum memiliki alamat tujuan tersimpan.',
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
                'Tambah Alamat Tujuan',
                style: AppTypography.labelMd(
                  color: Colors.white,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alamat tujuan terpilih
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Tujuan: ${selectedAddress.label}',
                    style: AppTypography.labelMd(
                      color: AppColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (selectedAddress.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Utama',
                        style: AppTypography.labelSm(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
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
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Aksi Ganti / Tambah Alamat
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: _isEstimating ? null : _openAddressSelection,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: AppColors.primaryContainer,
              ),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Ganti Alamat'),
            ),
            TextButton.icon(
              onPressed: _isEstimating ? null : _openAddAddress,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: AppColors.secondary,
              ),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('Tambah Alamat'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Tombol eksplisit Cek Ongkir
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isEstimating
                ? null
                : () => _estimateShipping(item, selectedAddress),
            icon: _isEstimating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.calculate_outlined, size: 18),
            label: Text(
              _isEstimating ? 'Menghitung Ongkir...' : 'Cek Ongkir',
              style: AppTypography.labelMd(
                color: Colors.white,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
        ),

        // Hasil / Error / Kosong
        if (_estimateError != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _estimateError!,
                  style: AppTypography.bodySm(
                    color: AppColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isEstimating
                        ? null
                        : () => _estimateShipping(item, selectedAddress),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Coba Lagi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onErrorContainer,
                      side: const BorderSide(
                        color: AppColors.onErrorContainer,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_estimateResult != null) ...[
          const SizedBox(height: 14),
          if (_estimateResult!.options.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Layanan pengiriman tidak tersedia untuk rute ini saat ini.',
                    style: AppTypography.bodySm(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isEstimating
                          ? null
                          : () => _estimateShipping(item, selectedAddress),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Coba Lagi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryContainer,
                        side: const BorderSide(
                          color: AppColors.primaryContainer,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilihan Layanan Kurir',
                  style: AppTypography.labelMd(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._estimateResult!.options.map(_buildShippingOptionCard),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildShippingOptionCard(ShippingCostOption option) {
    final etdText = (option.etd != null && option.etd!.trim().isNotEmpty)
        ? 'Estimasi: ${option.etd!.trim()}'
        : 'Estimasi belum tersedia';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      option.courierName,
                      style: AppTypography.labelMd(
                        color: AppColors.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        option.service,
                        style: AppTypography.labelSm(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                if (option.description != null &&
                    option.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    option.description!.trim(),
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  etdText,
                  style: AppTypography.labelSm(color: AppColors.outline),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            MaterialListing.formatRupiah(option.cost),
            style: AppTypography.labelLg(
              color: AppColors.primaryContainer,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBanner(MaterialListing item) {
    return Container(
      width: double.infinity,
      height: 240,
      color: AppColors.surfaceContainer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.imageUrl != null && item.imageUrl!.startsWith('http'))
            Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackAsset(item),
            )
          else
            _buildFallbackAsset(item),
        ],
      ),
    );
  }

  Widget _buildFallbackAsset(MaterialListing item) {
    if (item.localAsset != null) {
      return Image.asset(
        item.localAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildDefaultPlaceholder(),
      );
    }
    return _buildDefaultPlaceholder();
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Center(
        child: Icon(
          Icons.recycling,
          size: 64,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryContainer),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSm(color: AppColors.outline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.labelLg(color: AppColors.onSurface).copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
