import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_feature.dart';
import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/cinematic_card.dart';
import '../../../core/widgets/meow_widgets.dart';

class FeatureCarousel extends StatefulWidget {
  const FeatureCarousel({super.key});

  @override
  State<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends State<FeatureCarousel>
    with WidgetsBindingObserver {
  static const _stories = [
    (
      feature: AppFeature.feeding,
      eyebrow: 'ADOPT FEEDING SPOT',
      title: 'Isi mangkuknya.\nHangatkan harinya.',
      action: 'Temukan spot makan',
      image: 'assets/images/figma/ginger-cat-hero.png',
    ),
    (
      feature: AppFeature.identification,
      eyebrow: 'KENALI KUCING',
      title: 'Satu sapaan.\nKenali teman barumu.',
      action: 'Mulai kenali kucing',
      image: 'assets/images/figma/ginger-cat-hero.png',
    ),
    (
      feature: AppFeature.hunter,
      eyebrow: 'CAT HUNTER',
      title: 'Jelajahi kampus.\nTemukan ceritanya.',
      action: 'Mulai penjelajahan',
      image: 'assets/images/figma/feeding-shelter.png',
    ),
    (
      feature: AppFeature.adoption,
      eyebrow: 'ADOPSI KUCING',
      title: 'Rumah yang hangat.\nAwal cerita baru.',
      action: 'Temukan teman pulang',
      image: 'assets/images/figma/ginger-cat-hero.png',
    ),
    (
      feature: AppFeature.incident,
      eyebrow: 'LAPOR INSIDEN',
      title: 'Lihat yang butuh bantuan?\nMulai dari kepedulian.',
      action: 'Laporkan kondisi kucing',
      image: 'assets/images/figma/spot-scan-background.png',
    ),
  ];

  // Start away from zero so swiping in either direction wraps naturally.
  final PageController _controller = PageController(initialPage: 500);
  Timer? _timer;
  int _page = 500;
  bool _touching = false;
  bool _reduceMotion = false;
  bool _visible = true;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _resumed = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _scheduleAdvance();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _scheduleAdvance();
  }

  void _scheduleAdvance() {
    _timer?.cancel();
    if (!_resumed || !_visible || _touching) return;
    _timer = Timer(const Duration(seconds: 6), () => _showPage(_page + 1));
  }

  void _showPage(int page) {
    if (!_controller.hasClients) return;
    if (_reduceMotion) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _setTouching(bool touching) {
    _touching = touching;
    _scheduleAdvance();
  }

  double _bannerHeight(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final contentWidth = math.max(1.0, width - 40);
    double measure(
      String text,
      double size,
      double available, {
      FontWeight weight = FontWeight.w600,
      double height = 1.4,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size,
            fontWeight: weight,
            height: height,
          ),
        ),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: math.max(1.0, available));
      final measured = painter.height;
      painter.dispose();
      return measured;
    }

    return _stories.fold(226.0, (height, story) {
      final eyebrow =
          math.max(14.0, measure(story.eyebrow, 11, contentWidth - 39)) + 12;
      final title = measure(
        story.title,
        23,
        contentWidth,
        weight: FontWeight.w700,
        height: 1.2,
      );
      final button = math.max(
        48.0,
        measure(story.action, 12, contentWidth - 57) + 16,
      );
      return math.max(height, 40 + eyebrow + 14 + title + 16 + button);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Semantics(
      label:
          'Sorotan fitur ${_page % _stories.length + 1} dari ${_stories.length}',
      child: Listener(
        onPointerDown: (_) => _setTouching(true),
        onPointerUp: (_) => _setTouching(false),
        onPointerCancel: (_) => _setTouching(false),
        child: SizedBox(
          height: _bannerHeight(context, constraints.maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PageView.builder(
              key: const ValueKey('feature-carousel'),
              controller: _controller,
              onPageChanged: (page) {
                setState(() => _page = page);
                _scheduleAdvance();
              },
              itemBuilder: (context, page) {
                final story = _stories[page % _stories.length];
                return CinematicCard(
                  image: AssetImage(story.image),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MeowPill(
                        story.eyebrow,
                        color: const Color(0x29FFDBCA),
                        foreground: const Color(0xFFFFE4D6),
                        icon: story.feature.icon,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        story.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -.6,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: MeowStyle.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          visualDensity: VisualDensity.standard,
                          tapTargetSize: MaterialTapTargetSize.padded,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () => context.go(story.feature.route),
                        icon: Icon(story.feature.icon, size: 17),
                        label: Text(
                          story.action,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
