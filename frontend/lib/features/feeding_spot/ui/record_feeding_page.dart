import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../data/feeding_session.dart';
import '../logic/feeding_spot_provider.dart';
import 'feeding_widgets.dart';
import 'scan_spot_page.dart';

class RecordFeedingPage extends StatefulWidget {
  const RecordFeedingPage({super.key});
  @override
  State<RecordFeedingPage> createState() => _RecordFeedingPageState();
}

class _RecordFeedingPageState extends State<RecordFeedingPage> {
  Timer? _timer;
  bool _busy = false;
  String? _error;
  bool _notesOpen = false;
  late final TextEditingController _notes;
  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(
      text: context.read<FeedingSpotProvider>().session?.notes ?? '',
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addPhoto({int? replaceIndex}) async {
    final provider = context.read<FeedingSpotProvider>();
    try {
      var example = false;
      if (provider.isDemo) {
        final choice = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Tambahkan bukti foto',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Ambil langsung dari kamera'),
                  onTap: () => Navigator.pop(sheet, 'camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Gunakan foto contoh'),
                  subtitle: const Text('Hanya untuk pratinjau lokal'),
                  onTap: () => Navigator.pop(sheet, 'example'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
        if (choice == null || !mounted) return;
        example = choice == 'example';
      }
      if (example) {
        await provider.addExampleEvidence(replaceIndex: replaceIndex);
      } else {
        if (!mounted) return;
        final photo = await context.push<FeedingEvidence>('/feeding/camera');
        if (photo != null) {
          provider.addEvidence(photo, replaceIndex: replaceIndex);
        }
      }
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final provider = context.read<FeedingSpotProvider>();
      provider.session?.notes = _notes.text;
      final result = await provider.submitSession();
      if (mounted) context.pushReplacement('/feeding/submission/${result.id}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('Bad state: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedingSpotProvider>();
    final session = provider.session;
    if (session == null) {
      return MeowPage(
        title: 'Refill Check In',
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FeedingMessage(
            'Mulai dengan memindai QR resmi di spot pemberian makan.',
            action: 'Pindai QR Spot',
            onAction: () => context.pushReplacement('/feeding/scan'),
          ),
        ),
      );
    }
    final intentLeft = session.remainingIntentTime;
    final finalizeLeft = session.remainingFinalizeTime;
    final intentSec = intentLeft.inSeconds;
    final finalizeSec = finalizeLeft.inSeconds;
    final intentCountdown =
        '${(intentSec ~/ 60).toString().padLeft(2, '0')}:${(intentSec % 60).toString().padLeft(2, '0')}';
    final finalizeCountdown =
        '${(finalizeSec ~/ 60).toString().padLeft(2, '0')}:${(finalizeSec % 60).toString().padLeft(2, '0')}';

    return MeowPage(
      title: 'Refill Check In',
      bottom: MeowButton(
        label: session.isExpired
            ? 'Sesi berakhir'
            : provider.isDemo
            ? 'Kirim Bukti · Pratinjau'
            : 'Kirim Bukti',
        busy: _busy,
        icon: Icons.arrow_forward_rounded,
        onPressed: session.canSubmit && !_busy ? _submit : null,
      ),
      child: ListView(
        padding: MeowPage.scrollPadding(context, top: 0, bottom: 24),
        children: [
          GlassCard(
            child: Row(
              children: [
                const IconBubble(Icons.location_on_rounded),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOKASI PEMBERIAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: MeowStyle.brown,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.spot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MeowPill(
                      finalizeCountdown,
                      color: MeowStyle.peach,
                      foreground: MeowStyle.orangeDark,
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Intent: $intentCountdown',
                      style: const TextStyle(
                        fontSize: 10,
                        color: MeowStyle.brown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            FeedingError(_error!),
          ],
          if (session.isExpired) ...[
            const SizedBox(height: 12),
            const FeedingError(
              'Sesi berakhir. Pindai ulang QR untuk melanjutkan.',
            ),
            TextButton(
              onPressed: () => context.pushReplacement(
                '/feeding/scan?spot_id=${session.spot.id}',
              ),
              child: const Text('Pindai ulang QR'),
            ),
          ],
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FigmaIcon('camera'),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Bukti Foto Lapangan',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    MeowPill(
                      '${session.evidence.length}/3 Siap',
                      color: MeowStyle.mint,
                      foreground: MeowStyle.green,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                const Text(
                  'Foto tempat makan yang sudah terisi makanan.',
                  style: TextStyle(
                    fontSize: 13,
                    color: MeowStyle.brown,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MeowStyle.lilac,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      FigmaIcon('photo-policy', size: 17),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Foto langsung dari kamera, tanpa galeri.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (session.evidence.isEmpty)
                  InkWell(
                    onTap: session.isExpired ? null : () => _addPhoto(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 186,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: MeowStyle.lavender,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0C0B1)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconBubble(
                            Icons.add_a_photo_outlined,
                            color: Colors.white,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Ambil foto utama',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Wajib · mangkuk dan pakan terlihat jelas',
                            style: TextStyle(
                              fontSize: 11,
                              color: MeowStyle.brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 186,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.memory(
                              session.evidence.first.bytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x33000000),
                                    Colors.transparent,
                                    Color(0xBB283044),
                                  ],
                                  stops: [0, .5, 1],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: MeowPill(
                              session.evidence.first.isExample
                                  ? 'Foto contoh'
                                  : 'Foto utama · wajib',
                              color: MeowStyle.slate,
                              foreground: Colors.white,
                            ),
                          ),
                          const Positioned(
                            top: 10,
                            right: 10,
                            child: MeowPill(
                              'Siap diperiksa',
                              color: MeowStyle.green,
                              foreground: Colors.white,
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                          const Positioned(
                            bottom: 15,
                            left: 10,
                            child: Text(
                              'Mangkuk pakan terisi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: MeowStyle.orangeDark,
                              ),
                              onPressed: session.isExpired
                                  ? null
                                  : () => _addPhoto(replaceIndex: 0),
                              icon: const FigmaIcon('retake-photo', size: 14),
                              label: const Text(
                                'Ambil ulang',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 1; index < 3; index++) ...[
                      if (index == 2) const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: session.isExpired
                              ? null
                              : () => _addPhoto(
                                  replaceIndex: index < session.evidence.length
                                      ? index
                                      : null,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: MeowStyle.lavender,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE0C0B1),
                              ),
                            ),
                            child: index < session.evidence.length
                                ? Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.memory(
                                            session.evidence[index].bytes,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: IconButton(
                                          tooltip: 'Hapus foto tambahan',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white,
                                          ),
                                          onPressed: () =>
                                              provider.removeEvidence(index),
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconBubble(
                                        index == 1
                                            ? Icons.add_a_photo_outlined
                                            : Icons.pets_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        index == 1
                                            ? '+ Sudut lain'
                                            : '+ Kucing makan',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Opsional',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: MeowStyle.brown,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Foto diperiksa setelah pengajuan dikirim.',
                  style: TextStyle(fontSize: 10, color: MeowStyle.brown),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Rincian Pakan',
                  icon: Icons.restaurant_rounded,
                  trailing: Text(
                    '* Wajib diisi',
                    style: TextStyle(fontSize: 10, color: MeowStyle.orangeDark),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Jenis pakan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: session.foodType,
                  decoration: const InputDecoration(
                    fillColor: MeowStyle.lavender,
                    prefixIcon: Icon(
                      Icons.grain_rounded,
                      color: MeowStyle.orangeDark,
                    ),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'dry_food',
                      child: Text(
                        'Dry Food (Pakan Kering)',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'wet_food',
                      child: Text(
                        'Wet Food (Pakan Basah)',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'water',
                      child: Text(
                        'Air Minum Bersih',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  onChanged: session.isExpired
                      ? null
                      : (value) => setState(() => session.foodType = value!),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Jumlah pakan · perkiraan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MeowStyle.lavender,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const FigmaIcon('food-quantity', size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          session.quantity,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final quantity in [
                      '1 genggam (perkiraan 60 g)',
                      '2 genggam (perkiraan 120 g)',
                      '1 mangkuk',
                    ])
                      ChoiceChip(
                        label: Text(
                          quantity.replaceAll(' (perkiraan ', '\n(~'),
                          textAlign: TextAlign.center,
                        ),
                        selected: session.quantity == quantity,
                        selectedColor: MeowStyle.peach,
                        backgroundColor: MeowStyle.lilac,
                        labelStyle: const TextStyle(fontSize: 10, height: 1.5),
                        showCheckmark: false,
                        side: BorderSide.none,
                        onSelected: session.isExpired
                            ? null
                            : (_) =>
                                  setState(() => session.quantity = quantity),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Takaran bukan penilaian kecukupan nutrisi kucing.',
                  style: TextStyle(fontSize: 10, color: MeowStyle.brown),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setState(() => _notesOpen = !_notesOpen),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MeowStyle.lavender,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const FigmaIcon('notes', size: 17),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Catatan kondisi (opsional)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _notesOpen
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: MeowStyle.brown,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_notesOpen) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    maxLength: 500,
                    onChanged: (value) => session.notes = value,
                    decoration: const InputDecoration(
                      labelText: 'Catatan lapangan',
                      hintText: 'Contoh: mangkuk sudah dibersihkan.',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Kucing yang Diberi Makan (Opsional - AFS-10)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MeowStyle.brown,
                  ),
                ),
                const SizedBox(height: 8),
                if (session.catCode != null && session.catCode!.isNotEmpty)
                  Row(
                    children: [
                      MeowPill(
                        'Kucing: ${session.catCode}',
                        color: MeowStyle.mint,
                        foreground: MeowStyle.green,
                        icon: Icons.pets_rounded,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Hapus asosiasi kucing',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() {
                          session.catCode = null;
                          session.catId = null;
                        }),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                    label: const Text('Pindai QR / Kode Kalung Kucing (AFS-10)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MeowStyle.orangeDark,
                      side: const BorderSide(color: MeowStyle.peach),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final code = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final ctrl = TextEditingController();
                          return AlertDialog(
                            title: const Text('Identitas Kucing (Opsional)'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Masukkan kode alfanumerik kalung atau token QR kucing yang ada di spot:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: ctrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Contoh: CAT001 atau MTP1.C.token',
                                    border: OutlineInputBorder(),
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                                child: const Text('Simpan'),
                              ),
                            ],
                          );
                        },
                      );
                      if (code != null && code.isNotEmpty) {
                        setState(() {
                          session.catCode = code;
                          session.catId = code;
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const GlassCard(
            color: Color(0xDDEAEDFF),
            child: Row(
              children: [
                IconBubble(
                  Icons.workspace_premium_outlined,
                  color: MeowStyle.orange,
                  foreground: Colors.white,
                  size: 36,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kebaikanmu tercatat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Reward mengikuti hasil verifikasi dan aturan poin.',
                        style: TextStyle(
                          fontSize: 11,
                          color: MeowStyle.brown,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            FeedingError(_error!),
          ],
          if (session.evidence.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Tambahkan minimal satu foto untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: MeowStyle.brown),
              ),
            ),
        ],
      ),
    );
  }
}
