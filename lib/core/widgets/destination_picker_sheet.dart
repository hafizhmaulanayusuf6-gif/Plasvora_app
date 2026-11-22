import 'dart:async';

import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../models/shipping_destination.dart';
import '../../repositories/shipping_repository.dart';

/// Bottom sheet pencarian destinasi domestik yang dipakai ulang untuk:
/// 1. Lokasi asal penjual (Create/Edit Listing)
/// 2. Wilayah tujuan pembeli (Buku Alamat)
class DestinationPickerSheet extends StatefulWidget {
  final ShippingRepository shippingRepository;
  final String title;
  final String? initialQuery;

  const DestinationPickerSheet({
    super.key,
    required this.shippingRepository,
    this.title = 'Pilih Lokasi',
    this.initialQuery,
  });

  static Future<ShippingDestination?> show(
    BuildContext context, {
    required ShippingRepository shippingRepository,
    String title = 'Pilih Lokasi',
    String? initialQuery,
  }) {
    return showModalBottomSheet<ShippingDestination>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DestinationPickerSheet(
        shippingRepository: shippingRepository,
        title: title,
        initialQuery: initialQuery,
      ),
    );
  }

  @override
  State<DestinationPickerSheet> createState() => _DestinationPickerSheetState();
}

class _DestinationPickerSheetState extends State<DestinationPickerSheet> {
  static const int _minQueryLength = 2;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  int _searchVersion = 0;

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;
  List<ShippingDestination> _results = const [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    final initialTrimmed = _searchController.text.trim();
    if (initialTrimmed.length >= _minQueryLength) {
      final version = ++_searchVersion;
      _debounceTimer = Timer(_debounceDuration, () {
        _performSearch(initialTrimmed, version);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    final version = ++_searchVersion;
    final trimmed = value.trim();

    if (trimmed.length < _minQueryLength) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = false;
          _errorMessage = null;
          _results = const [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }

    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(trimmed, version);
    });
  }

  void _clearQuery() {
    _searchController.clear();
    _onQueryChanged('');
  }

  void _retrySearch() {
    final trimmed = _searchController.text.trim();
    if (trimmed.length < _minQueryLength) return;
    _debounceTimer?.cancel();
    final version = ++_searchVersion;
    _performSearch(trimmed, version);
  }

  Future<void> _performSearch(String query, int version) async {
    if (!mounted || version != _searchVersion) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final destinations = await widget.shippingRepository.searchDestinations(
        query: query,
      );
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _isLoading = false;
        _hasSearched = true;
        _results = destinations;
      });
    } on ApiException catch (e) {
      if (!mounted || version != _searchVersion) return;
      final friendly = e.message.trim().isNotEmpty
          ? e.message.trim()
          : 'Gagal memuat lokasi. Silakan coba lagi.';
      setState(() {
        _isLoading = false;
        _hasSearched = true;
        _errorMessage = friendly;
        _results = const [];
      });
    } catch (_) {
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _isLoading = false;
        _hasSearched = true;
        _errorMessage = 'Gagal memuat lokasi. Periksa koneksi internet lalu coba lagi.';
        _results = const [];
      });
    }
  }

  String _buildLocationHierarchy(ShippingDestination item) {
    final parts = <String>[];
    for (final raw in [
      item.subdistrictName,
      item.districtName,
      item.cityName,
      item.provinceName,
    ]) {
      final trimmed = raw?.trim() ?? '';
      if (trimmed.isNotEmpty &&
          !parts.any((existing) => existing.toLowerCase() == trimmed.toLowerCase())) {
        parts.add(trimmed);
      }
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - bottomInset;
    final sheetHeight = (availableHeight * 0.82).clamp(280.0, 620.0);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTypography.headlineSm(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Tutup',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.length >= _minQueryLength) {
                      _debounceTimer?.cancel();
                      final version = ++_searchVersion;
                      _performSearch(trimmed, version);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Ketik kelurahan, kecamatan, atau kota...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.onSurfaceVariant,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: _clearQuery,
                            tooltip: 'Hapus pencarian',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: const Icon(
                              Icons.cancel,
                              size: 20,
                              color: AppColors.outline,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryContainer,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // Body states
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primaryContainer,
              ),
              const SizedBox(height: 12),
              Text(
                'Mencari lokasi...',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(color: AppColors.onSurface),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _retrySearch,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_searching,
                size: 40,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Ketik minimal 2 karakter untuk mencari kelurahan, kecamatan, atau kota.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_outlined,
                size: 40,
                color: AppColors.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Lokasi tidak ditemukan.',
                textAlign: TextAlign.center,
                style: AppTypography.labelLg(color: AppColors.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Coba gunakan nama kecamatan, kota, atau kode pos lain.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
      itemBuilder: (context, index) {
        final item = _results[index];
        final hierarchy = _buildLocationHierarchy(item);
        final postalCode = item.postalCode?.trim();
        final hasPostalCode = postalCode != null && postalCode.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(item),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: AppTypography.labelLg(
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (hierarchy.isNotEmpty &&
                              hierarchy.toLowerCase() !=
                                  item.label.toLowerCase()) ...[
                            const SizedBox(height: 2),
                            Text(
                              hierarchy,
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (hasPostalCode) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Kode Pos $postalCode',
                              style: AppTypography.labelSm(
                                color: AppColors.secondary,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
