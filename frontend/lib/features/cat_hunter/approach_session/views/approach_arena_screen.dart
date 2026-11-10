import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/primary_button.dart';
import '../../cat_dex/data/models/cat_model.dart';
import '../../cat_dex/data/repositories/mock_cat_repository.dart';
import '../../quiz_observation/models/observation_answer.dart';
import '../../encounter_result/views/result_modal_dialog.dart';
import 'widgets/horizontal_timing_bar.dart';

enum CatMood {
  waspada,
  tenang,
  nyaman,
}

class ApproachArenaScreen extends StatefulWidget {
  final CatModel cat;
  final ObservationSubmission observationSubmission;
  final int initialTrust;

  const ApproachArenaScreen({
    super.key,
    required this.cat,
    required this.observationSubmission,
    this.initialTrust = 75,
  });

  @override
  State<ApproachArenaScreen> createState() => _ApproachArenaScreenState();
}

class _ApproachArenaScreenState extends State<ApproachArenaScreen> {
  final GlobalKey<HorizontalTimingBarState> _timingBarKey = GlobalKey();

  late int _trustPercentage;
  int _currentTurn = 1; // 1, 2, 3
  final int _maxTurns = 3;
  CatMood _mood = CatMood.tenang;
  bool _isTimingModeActive = false;
  String _statusFeedback = 'Pilih taktik pendekatan yang tepat dengan memperhatikan suasana hati kucing.';

  @override
  void initState() {
    super.initState();
    _trustPercentage = widget.initialTrust;
    if (_trustPercentage >= 70) {
      _mood = CatMood.nyaman;
    }
  }

  void _onPetChin() {
    if (_currentTurn > _maxTurns) return;

    setState(() {
      if (_mood == CatMood.waspada) {
        _trustPercentage = (_trustPercentage + 5).clamp(0, 100);
        _statusFeedback = '${widget.cat.name} masih waspada, elusanmu terasa mengejutkannya (+5% Trust).';
      } else {
        _trustPercentage = (_trustPercentage + 20).clamp(0, 100);
        _mood = CatMood.nyaman;
        _statusFeedback = 'Purrr! ${widget.cat.name} menikmati elusan lembut di dagunya (+20% Trust).';
      }
      _checkTurnAdvance();
    });
  }

  void _onGiveSpace() {
    if (_currentTurn > _maxTurns) return;

    setState(() {
      _trustPercentage = (_trustPercentage + 10).clamp(0, 100);
      _mood = CatMood.tenang;
      _statusFeedback = 'Kamu menjaga jarak aman. ${widget.cat.name} merasa dihormati dan emosinya tenang (+10% Trust).';
      _checkTurnAdvance();
    });
  }

  void _onActivateTimingMode() {
    setState(() {
      _isTimingModeActive = true;
      _statusFeedback = 'Kunci ketepatan waktu! Ketuk tombol saat jarum berada di Sweet Spot Hijau!';
    });
  }

  void _onCancelTimingMode() {
    setState(() {
      _isTimingModeActive = false;
      _statusFeedback = 'Mode Luluhkan dibatalkan. Pilih taktik untuk membangun trust.';
    });
  }

  void _onTriggerTimingHit() {
    final barState = _timingBarKey.currentState;
    if (barState == null) return;

    final hitZone = barState.triggerTap();
    _handleHitResult(hitZone);
  }

  void _handleHitResult(TimingHitZone hitZone) {
    if (hitZone == TimingHitZone.sweetSpot) {
      // Perfect Sweet Spot!
      setState(() {
        _trustPercentage = 100;
        _isTimingModeActive = false;
        _statusFeedback = 'Luar Biasa! Tepat di Sweet Spot! Hati ${widget.cat.name} luluh sepenuhnya!';
      });
      _finishEncounterSuccess(earnedPoints: 50);
    } else if (hitZone == TimingHitZone.good) {
      // Good Zone
      setState(() {
        _trustPercentage = 100;
        _isTimingModeActive = false;
        _statusFeedback = 'Bagus! Jarum di Zona Kuning. ${widget.cat.name} merasa nyaman dan luluh!';
      });
      _finishEncounterSuccess(earnedPoints: 35);
    } else {
      // Miss Zone
      setState(() {
        _trustPercentage = (_trustPercentage - 15).clamp(0, 100);
        _mood = CatMood.waspada;
        _isTimingModeActive = false;
        _statusFeedback = 'Aduh meleset! Gerakanmu terlalu tiba-tiba, ${widget.cat.name} menjadi waspada (-15% Trust).';
        _checkTurnAdvance();
      });
    }
  }

  void _checkTurnAdvance() {
    if (_currentTurn < _maxTurns) {
      _currentTurn++;
    } else {
      // Out of turns
      if (_trustPercentage >= 80) {
        // High enough trust to succeed on last turn
        _finishEncounterSuccess(earnedPoints: 35);
      } else {
        _showRunAwayDialog();
      }
    }
  }

  void _finishEncounterSuccess({required int earnedPoints}) {
    MockCatRepository().completeEncounter(
      catId: widget.cat.id,
      earnedPoints: earnedPoints,
      lastObservationDate: 'Hari ini, Baru saja',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => ResultModalDialog(
        cat: widget.cat,
        observation: widget.observationSubmission,
        earnedPoints: earnedPoints,
        onOpenCatDex: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onBackToHome: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  void _showRunAwayDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusModal),
        ),
        title: const Text(
          'Kucing Beranjak Santai 🐾',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'Giliran interaksi telah selesai. ${widget.cat.name} memutuskan untuk tidur siang di tempat teduh. Jangan khawatir, kamu bisa mendekatinya lagi nanti!',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          PrimaryButton(
            label: 'Kembali ke Beranda',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Color get _moodColor {
    switch (_mood) {
      case CatMood.waspada:
        return AppColors.missRed;
      case CatMood.tenang:
        return AppColors.goodYellow;
      case CatMood.nyaman:
        return AppColors.sweetSpotGreen;
    }
  }

  String get _moodText {
    switch (_mood) {
      case CatMood.waspada:
        return 'Waspada 👀';
      case CatMood.tenang:
        return 'Tenang 😌';
      case CatMood.nyaman:
        return 'Nyaman & Siap Luluh 💖';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isTimingModeActive ? const Color(0xFF141416) : AppColors.background,
      appBar: AppHeaderBar(
        title: 'Arena Pendekatan',
        subtitle: '${widget.cat.name} • Giliran $_currentTurn dari $_maxTurns',
        statusText: 'Interaktif',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.marginHorizontal,
                  vertical: AppDimensions.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Turn & Mood Header Badge Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Turn Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isTimingModeActive ? Colors.white12 : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            border: Border.all(
                              color: _isTimingModeActive ? Colors.white24 : AppColors.borderInteractive,
                            ),
                          ),
                          child: Text(
                            'Giliran $_currentTurn/$_maxTurns',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isTimingModeActive ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // Mood Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _moodColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            border: Border.all(color: _moodColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _moodColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _moodText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isTimingModeActive ? Colors.white : _moodColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spaceMd),

                    // Trust Bar Card
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceMd),
                      decoration: BoxDecoration(
                        color: _isTimingModeActive ? const Color(0xFF222228) : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(
                          color: _isTimingModeActive ? Colors.white12 : AppColors.borderCard,
                        ),
                        boxShadow: AppDimensions.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tingkat Luluh (Trust Bar)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _isTimingModeActive ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$_trustPercentage%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Trust Linear Indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _trustPercentage / 100.0,
                              minHeight: 10,
                              backgroundColor: _isTimingModeActive ? Colors.white10 : AppColors.surfaceSubtle,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _trustPercentage >= 80
                                    ? AppColors.sweetSpotGreen
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceLg),

                    // 2D Cat Avatar Stage Container
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isTimingModeActive
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.primaryPeach,
                          border: Border.all(
                            color: _isTimingModeActive
                                ? AppColors.primary
                                : AppColors.borderSubtle,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(_isTimingModeActive ? 0.35 : 0.1),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: ClipOval(
                          child: Image.asset(
                            widget.cat.avatarAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.pets_rounded,
                              size: 72,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceMd),

                    // Status / Narrative Feedback Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isTimingModeActive ? const Color(0xFF282830) : AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCallout),
                        border: Border.all(
                          color: _isTimingModeActive ? Colors.white24 : AppColors.borderInteractive,
                        ),
                      ),
                      child: Text(
                        _statusFeedback,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isTimingModeActive ? Colors.white : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceLg),

                    // Horizontal Timing Bar Component (Shown when Timing Mode is active)
                    if (_isTimingModeActive) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E26),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '🎯 UJI KETEPATAN WAKTU (TIMING BAR)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            HorizontalTimingBar(
                              key: _timingBarKey,
                              isPlaying: true,
                              onHit: _handleHitResult,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextButton(
                                    onPressed: _onCancelTimingMode,
                                    child: const Text(
                                      'Batal',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: PrimaryButton(
                                    label: 'Ketuk Sekarang! (Luluhkan)',
                                    icon: Icons.touch_app_rounded,
                                    onPressed: _onTriggerTimingHit,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Tactical Action Bar (When Timing Mode is inactive)
            if (!_isTimingModeActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.marginHorizontal,
                  vertical: AppDimensions.spaceMd,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row with 2 tactique options: Elus Dagu & Beri Ruang
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onPetChin,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.borderInteractive),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                              ),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👋 Elus Dagu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                SizedBox(height: 2),
                                Text('+20% Trust', style: TextStyle(fontSize: 11, color: AppColors.sweetSpotGreen, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onGiveSpace,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.borderInteractive),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                              ),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🐾 Beri Ruang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                SizedBox(height: 2),
                                Text('+10% & Tenang', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Primary Decision Action: Luluhkan (Triggers timing bar)
                    PrimaryButton(
                      label: '💖 Luluhkan (Uji Timing)',
                      icon: Icons.bolt_rounded,
                      onPressed: _onActivateTimingMode,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
