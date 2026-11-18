// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

// Palet status modul adopsi: lima arti saja. Status selalu tampil dengan
// teks, bukan hanya warna (NFR-09).
const Color _neutral = Color(0xFF5F5650);
const Color _neutralBg = Color(0xFFF1ECE7);
const Color _waiting = Color(0xFF9A6200);
const Color _waitingBg = Color(0xFFFBF1DE);
const Color _info = Color(0xFF35618F);
const Color _infoBg = Color(0xFFE8EFF6);
const Color _ok = Color(0xFF2F7D4F);
const Color _okBg = Color(0xFFE6F2EA);
const Color _bad = Color(0xFFB3261E);
const Color _badBg = Color(0xFFFBEAE8);

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
        return 'Disetujui';
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
        return _neutral;
      case ApplicationStatus.SUBMITTED:
        return _info;
      case ApplicationStatus.REVISION_REQUESTED:
        return _waiting;
      case ApplicationStatus.APPROVED:
        return _ok;
      case ApplicationStatus.REJECTED:
        return _bad;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ApplicationStatus.DRAFT:
        return _neutralBg;
      case ApplicationStatus.SUBMITTED:
        return _infoBg;
      case ApplicationStatus.REVISION_REQUESTED:
        return _waitingBg;
      case ApplicationStatus.APPROVED:
        return _okBg;
      case ApplicationStatus.REJECTED:
        return _badBg;
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
        return 'Pengembalian Diajukan';
      case ActiveAdoptionStatus.RETURN_APPROVED:
        return 'Pengembalian Disetujui';
      case ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING:
        return 'Menunggu Verifikasi Bukti';
      case ActiveAdoptionStatus.CLOSED_RETURNED:
        return 'Sudah Dikembalikan';
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
        return _ok;
      case ActiveAdoptionStatus.RETURN_REQUESTED:
        return _waiting;
      case ActiveAdoptionStatus.RETURN_APPROVED:
        return _info;
      case ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING:
        return _waiting;
      case ActiveAdoptionStatus.CLOSED_RETURNED:
        return _neutral;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ActiveAdoptionStatus.ACTIVE:
        return _okBg;
      case ActiveAdoptionStatus.RETURN_REQUESTED:
        return _waitingBg;
      case ActiveAdoptionStatus.RETURN_APPROVED:
        return _infoBg;
      case ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING:
        return _waitingBg;
      case ActiveAdoptionStatus.CLOSED_RETURNED:
        return _neutralBg;
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
        return 'Terlambat';
      case FollowupStatus.REVIEWED:
        return 'Sudah Diperiksa';
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
        return _neutral;
      case FollowupStatus.SUBMITTED:
        return _info;
      case FollowupStatus.LATE:
        return _bad;
      case FollowupStatus.REVIEWED:
        return _ok;
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
        return 'Kalung atau QR Rusak';
      case AdoptionIssueCategory.CARE:
        return 'Butuh Perawatan';
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
        return 'Pengembalian biasa';
      case ReturnReasonType.EMERGENCY:
        return 'Pengembalian darurat';
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
        return 'Ditahan untukmu';
      case PickupLockStatus.RELEASED:
        return 'Penahanan berakhir';
      case PickupLockStatus.USED:
        return 'Berhasil Diambil';
    }
  }
}
