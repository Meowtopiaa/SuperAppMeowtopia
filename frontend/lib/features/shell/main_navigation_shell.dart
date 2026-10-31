import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/meow_style.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (label: 'Beranda', icon: Icons.home_outlined),
    (label: 'Jelajah', icon: Icons.grid_view_rounded),
    (label: 'Pindai', icon: Icons.qr_code_scanner_rounded),
    (label: 'Aktivitas', icon: Icons.history_rounded),
    (label: 'Profil', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final branch = navigationShell.currentIndex;
    final selected = branch < _destinations.length ? branch : 1;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 520);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: MeowStyle.ink.withValues(alpha: .12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: .78),
                                MeowStyle.glassTint.withValues(alpha: .68),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .86),
                              width: 1.2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final slot =
                                    constraints.maxWidth / _destinations.length;
                                final bubbleWidth = (slot - 12).clamp(
                                  44.0,
                                  72.0,
                                );
                                final itemHeight =
                                    48 +
                                    (MediaQuery.textScalerOf(
                                                  context,
                                                ).scale(10) -
                                                10)
                                            .clamp(0.0, 20.0) *
                                        1.4;
                                final barHeight = itemHeight + 13;
                                return SizedBox(
                                  height: barHeight,
                                  child: Stack(
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: selected.toDouble(),
                                          end: selected.toDouble(),
                                        ),
                                        duration: duration,
                                        curve: Curves.easeOutBack,
                                        builder: (context, position, _) {
                                          final stretch = (selected - position)
                                              .abs()
                                              .clamp(0.0, 1.0);
                                          final width =
                                              bubbleWidth + stretch * 16;
                                          final height =
                                              itemHeight - stretch * 6;
                                          return Positioned(
                                            left:
                                                position.clamp(0.0, 4.0) *
                                                    slot +
                                                (slot - width) / 2,
                                            top: (barHeight - height) / 2,
                                            width: width,
                                            height: height,
                                            child: IgnorePointer(
                                              child: DecoratedBox(
                                                key: const ValueKey(
                                                  'nav-bubble',
                                                ),
                                                decoration: BoxDecoration(
                                                  color: MeowStyle.peach
                                                      .withValues(alpha: .82),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: .4),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Row(
                                        children: [
                                          for (
                                            var index = 0;
                                            index < _destinations.length;
                                            index++
                                          )
                                            Expanded(
                                              child: _destination(
                                                index,
                                                branch,
                                                selected,
                                                bubbleWidth,
                                                itemHeight,
                                                duration,
                                              ),
                                            ),
                                        ],
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
                  ),
                ),
              ),
            ),
    );
  }

  Widget _destination(
    int index,
    int branch,
    int selected,
    double width,
    double height,
    Duration duration,
  ) {
    final active = selected == index;
    final color = index == 2
        ? Colors.white
        : active
        ? MeowStyle.orangeDark
        : MeowStyle.brown;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        key: ValueKey('nav-${_destinations[index].label}'),
        borderRadius: BorderRadius.circular(23),
        onTap: () =>
            navigationShell.goBranch(index, initialLocation: index == branch),
        child: SizedBox(
          height: height + 13,
          child: Center(
            child: Container(
              width: width,
              height: height,
              decoration: index == 2
                  ? BoxDecoration(
                      color: MeowStyle.orange,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: [
                        BoxShadow(
                          color: MeowStyle.orange.withValues(alpha: .16),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    )
                  : null,
              child: AnimatedScale(
                scale: active ? 1.04 : 1,
                duration: duration,
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_destinations[index].icon, size: 21, color: color),
                    const SizedBox(height: 4),
                    Text(
                      _destinations[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active || index == 2
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
