/// Konstanta untuk modul Cat Adoption (E-Nigma)
/// Berdasarkan PRD v1.1 dan Keputusan Tiket EN-8
library adoption_constants;

/// Q4: Pengembalian fisik ke kampus nonaktif (adoption.return_enabled=false)
/// Disimpan sebagai SATU konstanta agar mudah diubah untuk uji tampilan aktif
const bool kAdoptionReturnEnabled = false;

/// Q3: Versi lembar komitmen adopter
const String kCommitmentVersion = 'v1.0';

/// Batas waktu penahanan kucing saat pengambilan (ADP-07)
const Duration kPickupLockDuration = Duration(hours: 48);

/// Siklus follow-up berkala (ADP-09)
const int kFollowupCycleDays = 14;
const int kTotalFollowupCycles = 6; // 3 bulan kalender pertama

/// Teks komitmen adopter Meowtopia
const String kAdopterCommitmentText = '''
Komitmen Adopter Meowtopia (v1.0):
1. Menjamin tempat tinggal yang aman, bebas dari bahaya, dan diizinkan oleh pemilik tempat/keluarga.
2. Menyediakan pakan bernutrisi, air bersih, pasir higienis, dan perawatan medis/vaksin yang memadai.
3. Melaporkan kondisi kucing setiap 14 hari selama 3 bulan pertama melalui fitur Follow-up aplikasi.
4. Tidak menelantarkan, memindahtangankan tanpa persetujuan, atau mengeksploitasi kucing.
5. Menjaga kalung identitas QR Meowtopia tetap terpasang dengan baik.
6. Segera melaporkan apabila terjadi kondisi darurat, sakit parah, atau kehilangan.
''';
