import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';

enum TimingHitZone {
  miss,
  good,
  sweetSpot,
}

class HorizontalTimingBar extends StatefulWidget {
  final bool isPlaying;
  final ValueChanged<TimingHitZone> onHit;

  const HorizontalTimingBar({
    super.key,
    required this.isPlaying,
    required this.onHit,
  });

  @override
  State<HorizontalTimingBar> createState() => HorizontalTimingBarState();
}

class HorizontalTimingBarState extends State<HorizontalTimingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _needleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _needleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Called when user taps the trigger button
  TimingHitZone triggerTap() {
    final needlePos = _needleAnimation.value; // 0.0 to 1.0

    // Zones definition:
    // Center is 0.50.
    // Sweet spot: 0.41 to 0.59 (width 0.18)
    // Good zone: 0.28 to 0.41 and 0.59 to 0.72
    // Miss zone: < 0.28 or > 0.72
    TimingHitZone result;
    if (needlePos >= 0.41 && needlePos <= 0.59) {
      result = TimingHitZone.sweetSpot;
    } else if (needlePos >= 0.25 && needlePos <= 0.75) {
      result = TimingHitZone.good;
    } else {
      result = TimingHitZone.miss;
    }

    widget.onHit(result);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zone labels indicator
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LESET',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.missRed,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'SWEET SPOT 🎯',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sweetSpotGreen,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'LESET',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.missRed,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Timing Track Container
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;

            return SizedBox(
              width: trackWidth,
              height: AppDimensions.timingBarNeedleHeight + 8,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Background Track Bar
                  Container(
                    width: trackWidth,
                    height: AppDimensions.timingBarHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.missRedBg, // Miss zone default
                      border: Border.all(color: AppColors.borderInteractive, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Good Zone (Yellow, middle 50%)
                        Center(
                          child: Container(
                            width: trackWidth * 0.50,
                            height: double.infinity,
                            color: AppColors.goodYellowBg,
                          ),
                        ),

                        // Sweet Spot Zone (Green, middle 18%)
                        Center(
                          child: Container(
                            width: trackWidth * 0.18,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.sweetSpotGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sweetSpotGreen.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated Oscillating Needle / Knob
                  AnimatedBuilder(
                    animation: _needleAnimation,
                    builder: (context, child) {
                      // Map 0.0..1.0 to pixel offset
                      final offset = _needleAnimation.value *
                          (trackWidth - AppDimensions.timingBarNeedleWidth);

                      return Positioned(
                        left: offset,
                        child: Container(
                          width: AppDimensions.timingBarNeedleWidth,
                          height: AppDimensions.timingBarNeedleHeight,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppColors.textPrimary,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.35),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
