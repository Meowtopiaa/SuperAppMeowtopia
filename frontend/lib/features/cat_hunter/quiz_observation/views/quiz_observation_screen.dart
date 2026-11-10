import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/primary_button.dart';
import '../../cat_dex/data/models/cat_model.dart';
import '../models/observation_answer.dart';
import '../../approach_session/views/approach_arena_screen.dart';
import 'widgets/quiz_option_card.dart';

class QuizObservationScreen extends StatefulWidget {
  final CatModel scannedCat;

  const QuizObservationScreen({
    super.key,
    required this.scannedCat,
  });

  @override
  State<QuizObservationScreen> createState() => _QuizObservationScreenState();
}

class _QuizObservationScreenState extends State<QuizObservationScreen> {
  int _currentQuestionIndex = 0; // 0, 1, 2

  final Map<int, String> _selectedOptionIds = {};

  final List<QuizQuestion> _questions = const [
    QuizQuestion(
      step: 1,
      title: 'Kondisi Mata & Wajah',
      description: 'Bagaimana kondisi kebersihan mata, hidung, dan wajah kucing saat ini?',
      options: [
        QuizOption(
          id: 'eye_clean',
          label: 'Bersih & Cerah',
          sublabel: 'Mata jernih, hidung bersih, dan responsif',
          iconEmoji: '✨',
        ),
        QuizOption(
          id: 'eye_watery',
          label: 'Berair atau Belekan',
          sublabel: 'Terdapat kotoran mata atau air mata berlebih',
          iconEmoji: '💧',
        ),
        QuizOption(
          id: 'eye_injured',
          label: 'Terluka atau Kotor',
          sublabel: 'Ada bekas goresan atau bengkak pada wajah',
          iconEmoji: '🩹',
        ),
      ],
    ),
    QuizQuestion(
      step: 2,
      title: 'Kondisi Tubuh & Bulu',
      description: 'Perhatikan kondisi fisik tubuh, bobot, dan kebersihan bulu kucing.',
      options: [
        QuizOption(
          id: 'body_healthy',
          label: 'Sehat & Terawat',
          sublabel: 'Bulu halus rapi, berat badan proporsional',
          iconEmoji: '🐱',
        ),
        QuizOption(
          id: 'body_thin',
          label: 'Tampak Kurus',
          sublabel: 'Tubuh ramping, membutuhkan asupan nutrisi',
          iconEmoji: '🍲',
        ),
        QuizOption(
          id: 'body_fungus_wound',
          label: 'Ada Jamur atau Luka',
          sublabel: 'Bulu tampak pitak atau ada luka terbuka',
          iconEmoji: '⚠️',
        ),
      ],
    ),
    QuizQuestion(
      step: 3,
      title: 'Perilaku Saat Ini',
      description: 'Bagaimana respons dan bahasa tubuh kucing saat Anda mendekat?',
      options: [
        QuizOption(
          id: 'behavior_friendly',
          label: 'Tenang & Bersahabat',
          sublabel: 'Ekor melengkung ramah, mendengkur lembut',
          iconEmoji: '💖',
        ),
        QuizOption(
          id: 'behavior_sleeping',
          label: 'Sedang Tidur Pulas',
          sublabel: 'Berbaring rileks beristirahat di tempat teduh',
          iconEmoji: '💤',
        ),
        QuizOption(
          id: 'behavior_alert_weak',
          label: 'Waspada atau Lemas',
          sublabel: 'Meringkuk tegang atau tampak kurang bertenaga',
          iconEmoji: '👀',
        ),
      ],
    ),
  ];

  int get _calculatedTrust {
    // 25% for each question answered up to 75% initial modal
    return _selectedOptionIds.length * 25;
  }

  void _onOptionSelected(String optionId) {
    setState(() {
      _selectedOptionIds[_currentQuestionIndex] = optionId;
    });
  }

  void _nextStep() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Completed all 3 questions, proceed to Approach Arena
      final answers = ObservationSubmission(
        catId: widget.scannedCat.id,
        eyeFaceCondition: _selectedOptionIds[0] ?? 'eye_clean',
        bodyCoatCondition: _selectedOptionIds[1] ?? 'body_healthy',
        behaviorCondition: _selectedOptionIds[2] ?? 'behavior_friendly',
        timestamp: DateTime.now().toIso8601String(),
        earnedTrustModal: _calculatedTrust,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ApproachArenaScreen(
            cat: widget.scannedCat,
            observationSubmission: answers,
            initialTrust: _calculatedTrust,
          ),
        ),
      );
    }
  }

  void _prevStep() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentQuestionIndex];
    final isOptionSelected = _selectedOptionIds.containsKey(_currentQuestionIndex);
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(
        title: 'Kuis Observasi Fisik',
        subtitle: '${widget.scannedCat.name} • ${widget.scannedCat.zone}',
        statusText: 'Sains Warga',
        showBackButton: true,
        onBack: _prevStep,
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
                    // Step Progress Header: "Pertanyaan X dari 3"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pertanyaan ${_currentQuestionIndex + 1} dari 3',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPeach,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Modal Luluh: $_calculatedTrust%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryPeachDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Progress Segment Bar (thin)
                    Row(
                      children: List.generate(3, (index) {
                        final isFilled = index <= _currentQuestionIndex;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: isFilled ? AppColors.primary : AppColors.borderInteractive,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: AppDimensions.spaceLg),

                    // Cat Profile Badge Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.borderCard),
                        boxShadow: AppDimensions.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryPeach,
                              border: Border.all(color: AppColors.primary, width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              widget.scannedCat.avatarAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.pets,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.scannedCat.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.scannedCat.locationDetail,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sweetSpotGreenBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.scannedCat.healthStatus,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sweetSpotGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceLg),

                    // Question Card
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceLg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.borderCard),
                        boxShadow: AppDimensions.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQ.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentQ.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppDimensions.spaceLg),

                          // Options
                          ...currentQ.options.map((opt) {
                            final isSelected =
                                _selectedOptionIds[_currentQuestionIndex] == opt.id;
                            return QuizOptionCard(
                              option: opt,
                              isSelected: isSelected,
                              onTap: () => _onOptionSelected(opt.id),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceMd),

                    // Citizen Science note callout
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCallout),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.volunteer_activism_rounded,
                            size: 18,
                            color: AppColors.primaryPeachDark,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data observasi ini otomatis tercatat di agregat kesehatan pengelola kampus Telkom University.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation CTA
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.marginHorizontal,
                vertical: AppDimensions.spaceMd,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: PrimaryButton(
                label: isLastQuestion
                    ? 'Lanjut ke Sesi Pendekatan (+75% Trust)'
                    : 'Pertanyaan Selanjutnya',
                icon: isLastQuestion
                    ? Icons.favorite_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: isOptionSelected ? _nextStep : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
