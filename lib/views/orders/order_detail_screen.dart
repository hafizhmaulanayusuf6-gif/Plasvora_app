import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/display_formatters.dart';
import '../../core/utils/payment_launcher.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../models/order_item.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final OrderItem? initialOrder;
  final OrderViewModel orderViewModel;
  final AuthViewModel? authViewModel;
  final PaymentLauncher? paymentLauncher;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    required this.orderViewModel,
    this.authViewModel,
    this.paymentLauncher,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with WidgetsBindingObserver {
  late final PaymentLauncher _paymentLauncher;
  final GlobalKey<FormState> _shipFormKey = GlobalKey<FormState>();
  final TextEditingController _trackingController = TextEditingController();
  final TextEditingController _shipmentNotesController =
      TextEditingController();

  bool _isLaunchingPayment = false;
  bool _isAutoRefreshingOnResume = false;
  bool _isHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _paymentLauncher = widget.paymentLauncher ?? UrlPaymentLauncher();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialOrder != null) {
      widget.orderViewModel.setCurrentOrderPreview(
        widget.initialOrder!,
        notify: false,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.orderViewModel.loadOrderDetail(widget.orderId);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingController.dispose();
    _shipmentNotesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumedAfterPayment();
    }
  }

  Future<void> _handleAppResumedAfterPayment() async {
    if (!mounted) return;
    if (_isAutoRefreshingOnResume) return;
    if (widget.orderViewModel.pendingPaymentOrderId != widget.orderId) return;
    if (widget.orderViewModel.isRefreshingPayment) return;

    _isAutoRefreshingOnResume = true;
    try {
      final result = await widget.orderViewModel.refreshPaymentStatus(
        widget.orderId,
      );
      if (!mounted) return;
      if (result != null) {
        await widget.orderViewModel.loadBuyerOrders();
        if (!mounted) return;
        _showSnackBar(result.message);
      }
    } finally {
      _isAutoRefreshingOnResume = false;
    }
  }

  OrderItem? get _resolvedOrder {
    final current = widget.orderViewModel.currentOrder;
    if (current != null && current.id == widget.orderId) {
      return current;
    }
    return widget.initialOrder;
  }

  Future<void> _handleContinuePayment(OrderItem order) async {
    if (_isLaunchingPayment || widget.orderViewModel.isRetryingPayment) return;

    setState(() => _isLaunchingPayment = true);
    try {
      String? redirectUrl = order.midtransRedirectUrl;

      if (redirectUrl == null || redirectUrl.trim().isEmpty) {
        final refreshed = await widget.orderViewModel.retryPayment(order.id);
        if (!mounted) return;
        if (refreshed == null) {
          _showSnackBar(
            widget.orderViewModel.errorMessage ??
                'Gagal menyiapkan sesi pembayaran. Silakan periksa status pembayaran.',
            isError: true,
          );
          return;
        }
        redirectUrl = refreshed.midtransRedirectUrl;
      }

      final launchResult = await _paymentLauncher.launchPaymentUrl(redirectUrl);
      if (!mounted) return;

      if (launchResult.launched) {
        widget.orderViewModel.markPendingPaymentReturn(order.id);
      } else {
        _showSnackBar(
          launchResult.errorMessage ?? 'Gagal membuka halaman pembayaran.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunchingPayment = false);
      }
    }
  }

  Future<void> _handleRefreshPayment(OrderItem order) async {
    if (widget.orderViewModel.isRefreshingPayment) return;
    final result = await widget.orderViewModel.refreshPaymentStatus(order.id);
    if (!mounted) return;
    if (result != null) {
      _showSnackBar(result.message);
    } else {
      _showSnackBar(
        widget.orderViewModel.errorMessage ??
            'Gagal memeriksa status pembayaran.',
        isError: true,
      );
    }
  }

  Future<void> _handleCancelOrder(OrderItem order) async {
    if (widget.orderViewModel.isCancellingOrder) return;

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan ${order.orderNumber} akan dibatalkan setelah diverifikasi dengan Midtrans.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLength: 255,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alasan pembatalan (opsional)',
                hintText: 'Contoh: Salah pilih alamat pengiriman',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true || !mounted) return;

    final updated = await widget.orderViewModel.cancelOrder(
      order.id,
      reason: reason.isNotEmpty ? reason : null,
    );
    if (!mounted) return;

    if (updated != null) {
      _showSnackBar('Pesanan berhasil dibatalkan.');
    } else {
      _showSnackBar(
        widget.orderViewModel.errorMessage ?? 'Pesanan belum dapat dibatalkan.',
        isError: true,
      );
    }
  }

  Future<void> _handleConfirmDelivery(OrderItem order) async {
    if (widget.orderViewModel.isConfirmingDelivery) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Konfirmasi Pesanan Diterima?'),
        content: Text(
          'Pastikan material "${order.listing.name}" sudah Anda terima sesuai pesanan. Setelah dikonfirmasi, transaksi dianggap selesai.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Belum'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Ya, Sudah Diterima'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final updated = await widget.orderViewModel.confirmDelivery(order.id);
    if (!mounted) return;

    if (updated != null) {
      _showSnackBar(
        'Pesanan selesai. Terima kasih telah bertransaksi di Plasvora.',
      );
    } else {
      _showSnackBar(
        widget.orderViewModel.errorMessage ??
            'Gagal mengonfirmasi penerimaan pesanan.',
        isError: true,
      );
    }
  }

  Future<void> _handleSubmitShipment(OrderItem order) async {
    if (widget.orderViewModel.isSubmittingShipment) return;
    if (!_shipFormKey.currentState!.validate()) return;

    final tracking = _trackingController.text.trim();
    final notes = _shipmentNotesController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Konfirmasi Pengiriman Pesanan?'),
        content: Text(
          'Nomor resi "$tracking" akan dikirimkan ke pembeli dan status pesanan berubah menjadi Sedang Dikirim.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Periksa Lagi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Kirim Pesanan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final updated = await widget.orderViewModel.shipOrder(
      orderId: order.id,
      trackingNumber: tracking,
      shipmentNotes: notes.isNotEmpty ? notes : null,
    );
    if (!mounted) return;

    if (updated != null) {
      _trackingController.clear();
      _shipmentNotesController.clear();
      _showSnackBar('Nomor resi tersimpan. Pesanan ditandai sedang dikirim.');
    } else {
      _showSnackBar(
        widget.orderViewModel.errorMessage ?? 'Gagal menyimpan resi pengiriman.',
        isError: true,
      );
    }
  }

  Future<void> _copyOrderNumber(String orderNumber) async {
    await Clipboard.setData(ClipboardData(text: orderNumber));
    if (!mounted) return;
    _showSnackBar('Nomor pesanan disalin.');
  }

  Future<void> _copyTrackingNumber(String trackingNumber) async {
    await Clipboard.setData(ClipboardData(text: trackingNumber));
    if (!mounted) return;
    _showSnackBar('Nomor resi disalin: $trackingNumber');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimplePageAppBar(title: 'Detail Pesanan'),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.orderViewModel,
          builder: (context, _) {
            final vm = widget.orderViewModel;
            final order = _resolvedOrder;

            if (vm.isLoadingDetail && order == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryContainer,
                ),
              );
            }

            if (order == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        vm.detailError ?? 'Detail pesanan tidak ditemukan.',
                        style: AppTypography.bodyMd(color: AppColors.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => vm.loadOrderDetail(widget.orderId),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(140, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final currentUserId = widget.authViewModel?.currentUser?.id;
            final isBuyer = order.isBuyerForUser(currentUserId);
            final isSeller = !isBuyer && order.isSellerForUser(currentUserId);

            return RefreshIndicator(
              onRefresh: () => vm.loadOrderDetail(widget.orderId),
              color: AppColors.primaryContainer,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (vm.isLoadingDetail)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  _buildHeaderCard(order),
                  const SizedBox(height: 14),
                  if (isBuyer)
                    _buildBuyerNextStepSection(order, vm)
                  else if (isSeller)
                    _buildSellerNextStepSection(order, vm),
                  if (isBuyer || isSeller) const SizedBox(height: 14),
                  _buildMaterialSummaryCard(order, isBuyer: isBuyer),
                  const SizedBox(height: 14),
                  _buildShippingAndAddressCard(order, isSeller: isSeller),
                  const SizedBox(height: 14),
                  _buildPaymentSummaryCard(order),
                  if (order.statusHistories.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildCollapsibleTimelineCard(order),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(OrderItem order) {
    final statusStyle = _statusBadgeStyle(order.status);
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLg(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Salin nomor pesanan',
                onPressed: () => _copyOrderNumber(order.orderNumber),
                icon: const Icon(
                  Icons.copy_outlined,
                  size: 18,
                  color: AppColors.primaryContainer,
                ),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 4),
              _statusBadge(order.statusLabel, statusStyle.$1, statusStyle.$2),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Pembayaran: ${order.paymentStatusLabel}',
                style: AppTypography.bodySm(
                  color: AppColors.onSurfaceVariant,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              if (order.createdAt != null)
                Text(
                  '· ${DisplayFormatters.formatDateTime(order.createdAt!)}',
                  style: AppTypography.bodySm(color: AppColors.outline),
                ),
            ],
          ),
          if (order.isPendingPayment && order.paymentExpiresAt != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: Color(0xFFE65100),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Batas pembayaran: ${DisplayFormatters.formatDateTime(order.paymentExpiresAt!)}',
                      style: AppTypography.bodySm(
                        color: const Color(0xFFE65100),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuyerNextStepSection(OrderItem order, OrderViewModel vm) {
    if (order.isPendingPayment) {
      return _highlightedActionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menunggu Pembayaran',
                    style: AppTypography.labelLg(
                      color: AppColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Selesaikan pembayaran untuk melanjutkan pesanan.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_isLaunchingPayment || vm.isRetryingPayment)
                    ? null
                    : () => _handleContinuePayment(order),
                icon: (_isLaunchingPayment || vm.isRetryingPayment)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payments_outlined, size: 20),
                label: Text(
                  (_isLaunchingPayment || vm.isRetryingPayment)
                      ? 'Membuka Midtrans...'
                      : 'Bayar Sekarang',
                  style: AppTypography.labelLg(
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
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: vm.isRefreshingPayment
                    ? null
                    : () => _handleRefreshPayment(order),
                icon: vm.isRefreshingPayment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryContainer,
                        ),
                      )
                    : const Icon(Icons.sync_outlined, size: 18),
                label: Text(
                  vm.isRefreshingPayment
                      ? 'Memeriksa Status...'
                      : 'Periksa Status Pembayaran',
                  style: AppTypography.labelMd(
                    color: AppColors.primaryContainer,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryContainer),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: vm.isCancellingOrder
                    ? null
                    : () => _handleCancelOrder(order),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  foregroundColor: AppColors.error,
                ),
                icon: vm.isCancellingOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: Text(
                  vm.isCancellingOrder ? 'Membatalkan...' : 'Batalkan Pesanan',
                  style: AppTypography.labelMd(
                    color: AppColors.error,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (order.isPaid) {
      return _statusNoticeCard(
        icon: Icons.inventory_2_outlined,
        title: 'Menunggu Penjual Mengirim',
        subtitle:
            'Pembayaran telah terverifikasi. Penjual sedang menyiapkan pengiriman.',
      );
    }

    if (order.isShipped) {
      return _highlightedActionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'Pesanan Sedang Dikirim',
                    style: AppTypography.labelLg(
                      color: AppColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Konfirmasi setelah material Anda terima dengan baik.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            if (order.trackingNumber != null &&
                order.trackingNumber!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildTrackingSummaryPill(order),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: vm.isConfirmingDelivery
                    ? null
                    : () => _handleConfirmDelivery(order),
                icon: vm.isConfirmingDelivery
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  vm.isConfirmingDelivery
                      ? 'Mengonfirmasi...'
                      : 'Konfirmasi Pesanan Diterima',
                  style: AppTypography.labelLg(
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
          ],
        ),
      );
    }

    if (order.isCompleted) {
      return _statusNoticeCard(
        icon: Icons.verified_outlined,
        title: 'Pesanan Selesai',
        subtitle: order.completedAt != null
            ? 'Dikonfirmasi selesai pada ${DisplayFormatters.formatDateTime(order.completedAt!)}.'
            : 'Transaksi telah selesai.',
      );
    }

    if (order.isCancelled || order.isExpired) {
      return _statusNoticeCard(
        icon: Icons.cancel_outlined,
        title: order.statusLabel,
        subtitle: order.cancellationReason != null &&
                order.cancellationReason!.isNotEmpty
            ? 'Alasan: ${order.cancellationReason!}'
            : (order.isExpired
                  ? 'Batas waktu pembayaran telah berakhir.'
                  : 'Pesanan ini telah dibatalkan.'),
        isError: true,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSellerNextStepSection(OrderItem order, OrderViewModel vm) {
    if (order.isPendingPayment) {
      return _statusNoticeCard(
        icon: Icons.hourglass_bottom_outlined,
        title: 'Menunggu Pembayaran Pembeli',
        subtitle:
            'Pesanan akan tersedia untuk diproses setelah pembayaran terverifikasi.',
      );
    }

    if (order.isPaid) {
      return _highlightedActionCard(
        child: Form(
          key: _shipFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      'Pesanan Siap Dikirim',
                      style: AppTypography.labelLg(
                        color: AppColors.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pembayaran sudah terverifikasi. Silakan siapkan pengiriman.',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kurir dipilih: ${order.courierSummary}',
                        style: AppTypography.labelMd(
                          color: AppColors.onSurface,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trackingController,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nomor Resi *',
                  hintText: 'Contoh: JNE0011223344',
                  errorText: vm.fieldErrors['tracking_number'],
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Nomor resi pengiriman wajib diisi.';
                  }
                  if (trimmed.length < 5) {
                    return 'Nomor resi minimal 5 karakter.';
                  }
                  if (trimmed.length > 100) {
                    return 'Nomor resi maksimal 100 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _shipmentNotesController,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan Pengiriman (Opsional)',
                  hintText: 'Contoh: Dikemas dengan karung rapat',
                  errorText: vm.fieldErrors['shipment_notes'],
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: vm.isSubmittingShipment
                      ? null
                      : () => _handleSubmitShipment(order),
                  icon: vm.isSubmittingShipment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.local_shipping_outlined, size: 20),
                  label: Text(
                    vm.isSubmittingShipment
                        ? 'Menyimpan Resi...'
                        : 'Input Resi & Kirim Pesanan',
                    style: AppTypography.labelLg(
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
            ],
          ),
        ),
      );
    }

    if (order.isShipped) {
      return _statusNoticeCard(
        icon: Icons.local_shipping_outlined,
        title: 'Pesanan Sedang Dikirim',
        subtitle: order.trackingNumber != null &&
                order.trackingNumber!.isNotEmpty
            ? 'Resi ${order.trackingNumber!} (${order.courierSummary}). Menunggu pembeli mengonfirmasi penerimaan paket.'
            : 'Menunggu pembeli mengonfirmasi penerimaan paket.',
      );
    }

    if (order.isCompleted) {
      return _statusNoticeCard(
        icon: Icons.verified_outlined,
        title: 'Pesanan Selesai',
        subtitle: 'Pembeli telah mengonfirmasi penerimaan material.',
      );
    }

    if (order.isCancelled || order.isExpired) {
      return _statusNoticeCard(
        icon: Icons.cancel_outlined,
        title: order.statusLabel,
        subtitle: order.cancellationReason != null &&
                order.cancellationReason!.isNotEmpty
            ? 'Alasan: ${order.cancellationReason!}'
            : (order.isExpired
                  ? 'Pesanan kedaluwarsa karena belum dibayar.'
                  : 'Pesanan ini telah dibatalkan.'),
        isError: true,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTrackingSummaryPill(OrderItem order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.courierSummary,
                  style: AppTypography.labelSm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.trackingNumber!,
                  style: AppTypography.labelLg(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _copyTrackingNumber(order.trackingNumber!),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 44),
              foregroundColor: AppColors.primaryContainer,
            ),
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Salin'),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSummaryCard(OrderItem order, {required bool isBuyer}) {
    final counterpartyLabel = isBuyer ? 'Penjual' : 'Pembeli';
    final counterpartyName = isBuyer
        ? (order.sellerName ?? 'Penjual #${order.sellerId}')
        : (order.buyerName ?? 'Pembeli #${order.buyerId}');

    return _sectionCard(
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
              _buildOrderThumbnail(order.listing.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.listing.name,
                      style: AppTypography.labelLg(
                        color: AppColors.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _chipTag(order.listing.categoryLabel),
                        _chipTag(
                          '${order.listing.weightKg.toStringAsFixed(1)} kg',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$counterpartyLabel: $counterpartyName',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.buyerNote != null && order.buyerNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              'Catatan Pembeli',
              style: AppTypography.labelSm(
                color: AppColors.onSurfaceVariant,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              order.buyerNote!,
              style: AppTypography.bodySm(color: AppColors.onSurface),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShippingAndAddressCard(
    OrderItem order, {
    required bool isSeller,
  }) {
    final addr = order.shippingAddress;
    final hasTracking =
        order.trackingNumber != null && order.trackingNumber!.isNotEmpty;
    final hasShipmentNotes =
        order.shipmentNotes != null && order.shipmentNotes!.isNotEmpty;

    return _sectionCard(
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
                  'Pengiriman & Alamat Tujuan',
                  style: AppTypography.labelLg(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Kurir', order.courierSummary),
          _infoRow(
            'Estimasi Tiba',
            DisplayFormatters.formatIndonesianEtd(order.estimatedEtd),
          ),
          if (order.listing.originLabel != null &&
              order.listing.originLabel!.trim().isNotEmpty)
            _infoRow(
              'Asal Pengiriman',
              DisplayFormatters.deduplicateLocationLabel(
                order.listing.originLabel!,
              ),
            ),
          if (order.shippedAt != null)
            _infoRow(
              'Dikirim Pada',
              DisplayFormatters.formatDateTime(order.shippedAt!),
            ),
          if (hasTracking) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nomor Resi',
                          style: AppTypography.labelSm(color: AppColors.outline),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.trackingNumber!,
                          style: AppTypography.labelLg(
                            color: AppColors.primary,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _copyTrackingNumber(order.trackingNumber!),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: AppColors.primaryContainer,
                    ),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Salin'),
                  ),
                ],
              ),
            ),
          ],
          if (hasShipmentNotes) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan Pengiriman',
              style: AppTypography.labelSm(
                color: AppColors.onSurfaceVariant,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              order.shipmentNotes!,
              style: AppTypography.bodySm(color: AppColors.onSurface),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'Alamat Tujuan',
                style: AppTypography.labelMd(
                  color: AppColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (addr == null)
            Text(
              'Informasi alamat tidak tersedia.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            )
          else if (addr.hasFullShippingDetails) ...[
            if (addr.recipientName != null)
              Text(
                addr.recipientName!,
                style: AppTypography.labelMd(
                  color: AppColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            if (addr.recipientPhone != null) ...[
              const SizedBox(height: 2),
              Text(
                PhoneUtils.formatForDisplay(addr.recipientPhone),
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ],
            if (addr.destinationLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                DisplayFormatters.deduplicateLocationLabel(
                  addr.destinationLabel!,
                ),
                style: AppTypography.bodySm(
                  color: AppColors.secondary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            if (addr.addressDetail != null) ...[
              const SizedBox(height: 2),
              Text(
                addr.addressDetail!,
                style: AppTypography.bodySm(color: AppColors.onSurface),
              ),
            ],
            if (addr.postalCode != null &&
                addr.postalCode!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Kode Pos: ${addr.postalCode!}',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ],
            if (addr.deliveryNote != null &&
                addr.deliveryNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Catatan Alamat',
                style: AppTypography.labelSm(
                  color: AppColors.onSurfaceVariant,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                addr.deliveryNote!,
                style: AppTypography.bodySm(color: AppColors.onSurface),
              ),
            ],
          ] else ...[
            if (addr.destinationLabel != null)
              Text(
                DisplayFormatters.deduplicateLocationLabel(
                  addr.destinationLabel!,
                ),
                style: AppTypography.bodyMd(
                  color: AppColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isSeller
                    ? 'Detail alamat lengkap dan nomor telepon pembeli disembunyikan hingga pembayaran terverifikasi.'
                    : 'Detail alamat tujuan diringkas untuk status pesanan ini.',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(OrderItem order) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Pembayaran',
            style: AppTypography.labelLg(
              color: AppColors.onSurface,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _priceRow('Harga Material', order.formattedItemPrice),
          const SizedBox(height: 8),
          _priceRow('Ongkos Kirim', order.formattedShippingCost),
          if (order.platformFee > 0) ...[
            const SizedBox(height: 8),
            _priceRow('Biaya Platform', order.formattedPlatformFee),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Pembayaran (${order.currency})',
                  style: AppTypography.labelLg(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.formattedTotalAmount,
                style: AppTypography.headlineSm(
                  color: AppColors.primaryContainer,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (order.paidAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Terverifikasi lunas pada ${DisplayFormatters.formatDateTime(order.paidAt!)}',
              style: AppTypography.bodySm(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsibleTimelineCard(OrderItem order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() => _isHistoryExpanded = !_isHistoryExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_outlined,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Riwayat Status Pesanan',
                      style: AppTypography.labelLg(
                        color: AppColors.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${order.statusHistories.length}',
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_isHistoryExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: order.statusHistories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final h = entry.value;
                  final isLast = idx == order.statusHistories.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: isLast
                                ? AppColors.primaryContainer
                                : AppColors.outlineVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.toStatusLabel,
                                style: AppTypography.labelMd(
                                  color: AppColors.onSurface,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (h.reason != null && h.reason!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  h.reason!,
                                  style: AppTypography.bodySm(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (h.createdAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  DisplayFormatters.formatDateTime(
                                    h.createdAt!,
                                  ),
                                  style: AppTypography.labelSm(
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
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

  Widget _highlightedActionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  Widget _statusNoticeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    final fg = isError ? AppColors.error : AppColors.primary;
    final bg = isError
        ? AppColors.errorContainer.withValues(alpha: 0.55)
        : AppColors.secondaryContainer.withValues(alpha: 0.42);
    final border = isError
        ? AppColors.error.withValues(alpha: 0.3)
        : AppColors.primaryContainer.withValues(alpha: 0.3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLg(
                    color: fg,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderThumbnail(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: (imageUrl != null && imageUrl.isNotEmpty)
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholderThumb(),
              )
            : _placeholderThumb(),
      ),
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

  Widget _chipTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySm(
                color: AppColors.onSurface,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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

  Widget _statusBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm(
          color: fg,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  (Color, Color) _statusBadgeStyle(String status) {
    switch (status) {
      case OrderItem.statusPendingPayment:
        return (const Color(0xFFE65100), const Color(0xFFFFF3E0));
      case OrderItem.statusPaid:
      case OrderItem.statusCompleted:
        return (AppColors.primary, const Color(0xFFE8F5E9));
      case OrderItem.statusShipped:
        return (AppColors.secondary, AppColors.surfaceContainer);
      case OrderItem.statusCancelled:
      case OrderItem.statusExpired:
        return (const Color(0xFFC62828), const Color(0xFFFFEBEE));
      default:
        return (AppColors.onSurfaceVariant, AppColors.surfaceContainer);
    }
  }
}
