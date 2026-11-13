// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/meow_style.dart';

/// Status Kelayakan Adopter (PRD §4.1, ADP-01..04)
enum ApplicationStatus {
  DRAFT,
  SUBMITTED,
  REVISION_REQUESTED,
  APPROVED,
  REJECTED;

  String get labelId {
    switch (this) {
      case ApplicationStatus.DRAFT:
        return 'Draf';
      case ApplicationStatus.SUBMITTED:
        return 'Menunggu Review';
      case ApplicationStatus.REVISION_REQUESTED:
        return 'Perlu Revisi';
      case ApplicationStatus.APPROVED:
        return 'Disetujui (Siap Ambil)';
      case ApplicationStatus.REJECTED:
        return 'Ditolak';
    }
  }

  IconData get icon {
    switch (this) {
      case ApplicationStatus.DRAFT:
        return Icons.edit_note_rounded;
      case ApplicationStatus.SUBMITTED:
        return Icons.hourglass_top_rounded;
      case ApplicationStatus.REVISION_REQUESTED:
        return Icons.warning_amber_rounded;
      case ApplicationStatus.APPROVED:
        return Icons.check_circle_outline_rounded;
      case ApplicationStatus.REJECTED:
        return Icons.cancel_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.DRAFT:
        return MeowStyle.slate;
      case ApplicationStatus.SUBMITTED:
        return MeowStyle.orange;
      case ApplicationStatus.REVISION_REQUESTED:
        return const Color(0xFFD97706); // Amber
      case ApplicationStatus.APPROVED:
        return AppConstants.successColor;
      case ApplicationStatus.REJECTED:
        return AppConstants.dangerColor;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ApplicationStatus.DRAFT:
        return MeowStyle.lavender;
      case ApplicationStatus.SUBMITTED:
        return AppConstants.primaryLight;
      case ApplicationStatus.REVISION_REQUESTED:
        return const Color(0xFFFEF3C7);
      case ApplicationStatus.APPROVED:
        return const Color(0xFFD1FAE5);
      case ApplicationStatus.REJECTED:
        return const Color(0xFFFEE2E2);
    }
  }
}

/// Status Adopsi Aktif Pasca Pengambilan (PRD §4.2, ADP-06..12)
enum ActiveAdoptionStatus {
  ACTIVE,
  RETURN_REQUESTED,
  RETURN_APPROVED,
  RETURN_EVIDENCE_PENDING,
  CLOSED_RETURNED;

  String get labelId {
    switch (this) {
      case ActiveAdoptionStatus.ACTIVE:
        return 'Adopsi Aktif';
      case ActiveAdoptionStatus.RETURN_REQUESTED:
        return 'Pengajuan Pengembalian';
      case ActiveAdoptionStatus.RETURN_APPROVED:
        return 'Pengembalian Disetujui';
      case ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING:
        return 'Bukti Dikumpulkan (Menunggu Verifikasi)';
      case ActiveAdoptionStatus.CLOSED_RETURNED:
        return 'Selesai (Kucing Dikembalikan)';
    }
  }

  IconData get icon {
    switch (this) {
      case ActiveAdoptionStatus.ACTIVE:
        return Icons.favorite_rounded;
      case ActiveAdoptionStatus.RETURN_REQUESTED:
        return Icons.history_edu_rounded;
      case ActiveAdoptionStatus.RETURN_APPROVED:
        return Icons.assignment_turned_in_rounded;
      case ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING:
        return Icons.pending_actions_rounded;
      case ActiveAdoptionStatus.CLOSED_RETURNED:
        return Icons.archive_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ActiveAdoptionStatus.ACTIVE:
        return AppConstants.successColor;
      case ActiveAdoptionStatus.RETURN_REQUESTED:
        return const Color(0xFFD97706);
      case ActiveAdoptionStatus.RETURN_APPROVED:
        return MeowStyle.blue;
      case ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING:
        return MeowStyle.violet;
      case ActiveAdoptionStatus.CLOSED_RETURNED:
        return MeowStyle.slate;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ActiveAdoptionStatus.ACTIVE:
        return const Color(0xFFD1FAE5);
      case ActiveAdoptionStatus.RETURN_REQUESTED:
        return const Color(0xFFFEF3C7);
      case ActiveAdoptionStatus.RETURN_APPROVED:
        return const Color(0xFFDBEAFE);
      case ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING:
        return const Color(0xFFEDE9FE);
      case ActiveAdoptionStatus.CLOSED_RETURNED:
        return MeowStyle.lavender;
    }
  }
}

/// Status Periode Follow-up 2-Mingguan (PRD ADP-09..10)
enum FollowupStatus {
  PENDING,
  SUBMITTED,
  LATE,
  REVIEWED;

  String get labelId {
    switch (this) {
      case FollowupStatus.PENDING:
        return 'Menunggu Jadwal';
      case FollowupStatus.SUBMITTED:
        return 'Laporan Terkirim';
      case FollowupStatus.LATE:
        return 'Terlambat (Tetap Bisa Kirim)';
      case FollowupStatus.REVIEWED:
        return 'Terverifikasi Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case FollowupStatus.PENDING:
        return Icons.schedule_rounded;
      case FollowupStatus.SUBMITTED:
        return Icons.send_rounded;
      case FollowupStatus.LATE:
        return Icons.alarm_off_rounded;
      case FollowupStatus.REVIEWED:
        return Icons.verified_rounded;
    }
  }

  Color get color {
    switch (this) {
      case FollowupStatus.PENDING:
        return MeowStyle.brown;
      case FollowupStatus.SUBMITTED:
        return MeowStyle.blue;
      case FollowupStatus.LATE:
        return AppConstants.dangerColor;
      case FollowupStatus.REVIEWED:
        return AppConstants.successColor;
    }
  }
}

/// Kategori Laporan Kendala (PRD ADP-13)
enum AdoptionIssueCategory {
  SICK,
  MISSING,
  DECEASED,
  DAMAGED_QR,
  CARE;

  String get labelId {
    switch (this) {
      case AdoptionIssueCategory.SICK:
        return 'Kucing Sakit';
      case AdoptionIssueCategory.MISSING:
        return 'Kucing Hilang';
      case AdoptionIssueCategory.DECEASED:
        return 'Kucing Meninggal';
      case AdoptionIssueCategory.DAMAGED_QR:
        return 'Kalung / QR Rusak';
      case AdoptionIssueCategory.CARE:
        return 'Perawatan / Kebutuhan Medis';
    }
  }

  IconData get icon {
    switch (this) {
      case AdoptionIssueCategory.SICK:
        return Icons.medical_services_outlined;
      case AdoptionIssueCategory.MISSING:
        return Icons.search_off_rounded;
      case AdoptionIssueCategory.DECEASED:
        return Icons.heart_broken_outlined;
      case AdoptionIssueCategory.DAMAGED_QR:
        return Icons.qr_code_scanner_rounded;
      case AdoptionIssueCategory.CARE:
        return Icons.healing_rounded;
    }
  }
}

/// Jalur Alasan Pengembalian (PRD ADP-11)
enum ReturnReasonType {
  NORMAL,
  EMERGENCY;

  String get labelId {
    switch (this) {
      case ReturnReasonType.NORMAL:
        return 'Jalur Biasa (Setelah 3 Bulan)';
      case ReturnReasonType.EMERGENCY:
        return 'Jalur Darurat (Dalam 3 Bulan, Wajib Alasan Khusus)';
    }
  }
}

/// Status Penguncian Kucing saat Pickup (PRD ADP-07)
enum PickupLockStatus {
  HELD,
  RELEASED,
  USED;

  String get labelId {
    switch (this) {
      case PickupLockStatus.HELD:
        return 'Ditahan (48 Jam)';
      case PickupLockStatus.RELEASED:
        return 'Kedaluwarsa / Dilepas';
      case PickupLockStatus.USED:
        return 'Berhasil Diambil';
    }
  }
}
