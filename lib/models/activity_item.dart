import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ActivityItem {
  final String type;
  final String action;
  final String description;
  final String status;
  final int? referenceId;
  final DateTime? timestamp;
  final String rawTimestamp;

  const ActivityItem({
    required this.type,
    required this.action,
    required this.description,
    required this.status,
    this.referenceId,
    this.timestamp,
    required this.rawTimestamp,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    final rawTs = json['timestamp']?.toString() ?? '';
    if (rawTs.isNotEmpty) {
      parsedTime = DateTime.tryParse(rawTs);
    }

    int? refId;
    if (json['reference_id'] != null) {
      if (json['reference_id'] is int) {
        refId = json['reference_id'] as int;
      } else {
        refId = int.tryParse(json['reference_id'].toString());
      }
    }

    return ActivityItem(
      type: json['type']?.toString() ?? 'general',
      action: json['action']?.toString() ?? 'Aktivitas Tercatat',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      referenceId: refId,
      timestamp: parsedTime,
      rawTimestamp: rawTs,
    );
  }

  /// Icon representatif berdasarkan jenis dan status aktivitas
  IconData get icon {
    switch (type) {
      case 'material_listing':
        return Icons.storefront_outlined;
      case 'material_request':
        return Icons.assignment_outlined;
      case 'plastic_analysis':
        return Icons.document_scanner_outlined;
      case 'handover_request':
        if (status == 'utilization_confirmed' || status == 'completed') {
          return Icons.check_circle_outline;
        } else if (status == 'handed_over') {
          return Icons.local_shipping_outlined;
        } else if (status == 'rejected' || status == 'cancelled') {
          return Icons.cancel_outlined;
        }
        return Icons.swap_horiz_outlined;
      default:
        return Icons.history;
    }
  }

  /// Label status yang ramah pengguna
  String get statusLabel {
    switch (status) {
      case 'available':
        return 'Tersedia';
      case 'reserved':
        return 'Direservasi';
      case 'completed':
        return 'Selesai';
      case 'inactive':
        return 'Nonaktif';
      case 'active':
        return 'Aktif';
      case 'fulfilled':
        return 'Terpenuhi';
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'approved':
        return 'Disetujui';
      case 'handed_over':
        return 'Telah Diserahkan';
      case 'utilization_confirmed':
        return 'Dikonfirmasi Dimanfaatkan';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status.isNotEmpty
            ? '${status[0].toUpperCase()}${status.substring(1)}'
            : 'Tercatat';
    }
  }

  /// Warna teks label status
  Color get statusColor {
    switch (status) {
      case 'available':
      case 'active':
      case 'approved':
      case 'completed':
        return AppColors.primary;
      case 'utilization_confirmed':
        return const Color(0xFF1B5E20);
      case 'handed_over':
      case 'reserved':
        return AppColors.secondary;
      case 'pending':
        return const Color(0xFFE65100);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  /// Warna latar belakang label status
  Color get statusBg {
    switch (status) {
      case 'available':
      case 'active':
      case 'approved':
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'utilization_confirmed':
        return AppColors.secondaryContainer;
      case 'handed_over':
      case 'reserved':
        return AppColors.surfaceContainer;
      case 'pending':
        return const Color(0xFFFFF3E0);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return AppColors.surfaceContainer;
    }
  }

  /// Format waktu ramah pengguna (contoh: "Hari ini · 11:20", "Kemarin · 14:45", "08 Nov 2026 · 14:12")
  String get formattedDate {
    if (timestamp == null) return rawTimestamp;

    final local = timestamp!.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(local.year, local.month, local.day);

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute WIB';

    final diffDays = today.difference(itemDate).inDays;
    if (diffDays == 0) {
      return 'Hari ini · $timeStr';
    } else if (diffDays == 1) {
      return 'Kemarin · $timeStr';
    } else {
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final month = monthNames[local.month - 1];
      return '${local.day} $month ${local.year} · $timeStr';
    }
  }
}

