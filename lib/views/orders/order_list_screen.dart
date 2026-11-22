import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/payment_launcher.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/order_item.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  final OrderViewModel orderViewModel;
  final AuthViewModel? authViewModel;
  final PaymentLauncher? paymentLauncher;
  final int initialTabIndex;

  const OrderListScreen({
    super.key,
    required this.orderViewModel,
    this.authViewModel,
    this.paymentLauncher,
    this.initialTabIndex = 0,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  static const List<(String?, String)> _statusFilters = [
    (null, 'Semua'),
    (OrderItem.statusPendingPayment, 'Menunggu Bayar'),
    (OrderItem.statusPaid, 'Dibayar'),
    (OrderItem.statusShipped, 'Dikirim'),
    (OrderItem.statusCompleted, 'Selesai'),
    (OrderItem.statusCancelled, 'Dibatalkan'),
    (OrderItem.statusExpired, 'Kedaluwarsa'),
  ];

  late int _selectedTabIndex; // 0 = Pembelian (buyer), 1 = Penjualan (seller)
  bool _hasLoadedBuyer = false;
  bool _hasLoadedSeller = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialForActiveTab();
      }
    });
  }

  void _loadInitialForActiveTab() {
    if (_selectedTabIndex == 0 && !_hasLoadedBuyer) {
      _hasLoadedBuyer = true;
      widget.orderViewModel.loadBuyerOrders(
        status: widget.orderViewModel.buyerStatusFilter,
      );
    } else if (_selectedTabIndex == 1 && !_hasLoadedSeller) {
      _hasLoadedSeller = true;
      widget.orderViewModel.loadSellerOrders(
        status: widget.orderViewModel.sellerStatusFilter,
      );
    }
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
    _loadInitialForActiveTab();
  }

  Future<void> _refreshCurrentTab() {
    if (_selectedTabIndex == 0) {
      return widget.orderViewModel.loadBuyerOrders(
        status: widget.orderViewModel.buyerStatusFilter,
      );
    }
    return widget.orderViewModel.loadSellerOrders(
      status: widget.orderViewModel.sellerStatusFilter,
    );
  }

  void _applyStatusFilter(String? status) {
    if (_selectedTabIndex == 0) {
      widget.orderViewModel.loadBuyerOrders(status: status);
    } else {
      widget.orderViewModel.loadSellerOrders(status: status);
    }
  }

  void _openOrderDetail(OrderItem order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.id,
          initialOrder: order,
          orderViewModel: widget.orderViewModel,
          authViewModel: widget.authViewModel,
          paymentLauncher: widget.paymentLauncher,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const PlasvoraHeader(
        customTitle: 'Pesanan Saya',
        showBack: true,
      ),
      body: ListenableBuilder(
        listenable: widget.orderViewModel,
        builder: (context, _) {
          final vm = widget.orderViewModel;
          final isBuyerTab = _selectedTabIndex == 0;
          final orders = isBuyerTab ? vm.buyerOrders : vm.sellerOrders;
          final isLoading =
              isBuyerTab ? vm.isLoadingBuyerList : vm.isLoadingSellerList;
          final errorMessage =
              isBuyerTab ? vm.buyerListError : vm.sellerListError;
          final activeStatus =
              isBuyerTab ? vm.buyerStatusFilter : vm.sellerStatusFilter;
          final hasMore = isBuyerTab ? vm.buyerHasMore : vm.sellerHasMore;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: _buildRoleSwitcher(),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusFilters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _statusFilters[index];
                    final selected = activeStatus == filter.$1;
                    return ChoiceChip(
                      label: Text(filter.$2),
                      selected: selected,
                      onSelected: (_) => _applyStatusFilter(filter.$1),
                      selectedColor: AppColors.primaryContainer,
                      backgroundColor: AppColors.surfaceContainerLowest,
                      labelStyle: AppTypography.labelSm(
                        color: selected
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ).copyWith(fontWeight: FontWeight.w600),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primaryContainer
                            : AppColors.outlineVariant,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  color: AppColors.primaryContainer,
                  child: _buildOrderListBody(
                    orders: orders,
                    isBuyerTab: isBuyerTab,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    hasMore: hasMore,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildSegmentButton(
            label: 'Pembelian',
            icon: Icons.shopping_bag_outlined,
            selected: _selectedTabIndex == 0,
            onTap: () => _selectTab(0),
          ),
          _buildSegmentButton(
            label: 'Penjualan',
            icon: Icons.storefront_outlined,
            selected: _selectedTabIndex == 1,
            onTap: () => _selectTab(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1220312A),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: selected
                    ? AppTypography.labelMd(
                        color: AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w700)
                    : AppTypography.labelMd(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderListBody({
    required List<OrderItem> orders,
    required bool isBuyerTab,
    required bool isLoading,
    required String? errorMessage,
    required bool hasMore,
  }) {
    if (isLoading && orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryContainer),
      );
    }

    if (errorMessage != null && orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: AppTypography.bodyMd(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _refreshCurrentTab,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ),
        ],
      );
    }

    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 56),
          Icon(
            isBuyerTab
                ? Icons.shopping_bag_outlined
                : Icons.storefront_outlined,
            size: 52,
            color: AppColors.outline,
          ),
          const SizedBox(height: 12),
          Text(
            isBuyerTab ? 'Belum Ada Pembelian' : 'Belum Ada Pesanan Masuk',
            style: AppTypography.headlineSm(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isBuyerTab
                ? 'Pesanan material plastik yang Anda beli melalui Marketplace akan tampil di sini.'
                : 'Pesanan masuk dari pembeli untuk listing material Anda akan tampil di sini.',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: orders.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return Center(
            child: OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (isBuyerTab) {
                        widget.orderViewModel.loadBuyerOrders(loadMore: true);
                      } else {
                        widget.orderViewModel.loadSellerOrders(loadMore: true);
                      }
                    },
              child: Text(isLoading ? 'Memuat...' : 'Muat Lebih Banyak'),
            ),
          );
        }

        final order = orders[index];
        return _buildOrderCard(order, isBuyerTab: isBuyerTab);
      },
    );
  }

  Widget _buildOrderCard(OrderItem order, {required bool isBuyerTab}) {
    final badge = _badgeStyle(order.status);
    final counterparty = isBuyerTab
        ? (order.sellerName != null ? 'Penjual: ${order.sellerName!}' : null)
        : (order.buyerName != null ? 'Pembeli: ${order.buyerName!}' : null);

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openOrderDetail(order),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: AppTypography.labelMd(
                        color: AppColors.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badge.$2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: AppTypography.labelSm(
                        color: badge.$1,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: (order.listing.imageUrl != null &&
                              order.listing.imageUrl!.isNotEmpty)
                          ? Image.network(
                              order.listing.imageUrl!,
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
                          order.listing.name,
                          style: AppTypography.labelLg(
                            color: AppColors.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (counterparty != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            counterparty,
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          isBuyerTab
                              ? 'Pembayaran: ${order.paymentStatusLabel}'
                              : order.sellerCardHint,
                          style: AppTypography.labelSm(
                            color: isBuyerTab
                                ? AppColors.onSurfaceVariant
                                : AppColors.primary,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: AppTypography.labelSm(
                            color: AppColors.outline,
                          ),
                        ),
                        Text(
                          order.formattedTotalAmount,
                          style: AppTypography.labelLg(
                            color: AppColors.primaryContainer,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openOrderDetail(order),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: AppColors.primaryContainer,
                    ),
                    child: Text(
                      _cardActionLabel(order, isBuyerTab: isBuyerTab),
                      style: AppTypography.labelMd(
                        color: AppColors.primaryContainer,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cardActionLabel(OrderItem order, {required bool isBuyerTab}) {
    if (isBuyerTab) {
      if (order.isPendingPayment) return 'Lanjutkan Pembayaran';
      if (order.isShipped) return 'Lacak Pengiriman';
      return 'Lihat Detail';
    }
    if (order.isPaid) return 'Input Resi';
    return 'Lihat Detail';
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

  (Color, Color) _badgeStyle(String status) {
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
