import 'package:flutter/material.dart';

import '../theme/meow_style.dart';

/// A quiet image backdrop that fades into a solid, readable surface.
class CinematicCard extends StatelessWidget {
  const CinematicCard({
    super.key,
    required this.child,
    this.image,
    this.imageOnLeft = false,
    this.color = MeowStyle.ink,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final ImageProvider? image;
  final bool imageOnLeft;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: onTap != null,
    button: onTap != null,
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: color,
        child: Stack(
          children: [
            if (image != null)
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Image(
                    image: image!,
                    fit: BoxFit.cover,
                    alignment: imageOnLeft
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    errorBuilder: (_, __, ___) => const SizedBox.expand(),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: imageOnLeft
                        ? [
                            color.withValues(alpha: .32),
                            color.withValues(alpha: .74),
                            color,
                            color,
                          ]
                        : [
                            color,
                            color.withValues(alpha: .94),
                            color.withValues(alpha: .56),
                            color.withValues(alpha: .20),
                          ],
                    stops: imageOnLeft
                        ? const [0, .28, .56, 1]
                        : const [0, .28, .66, 1],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap, excludeFromSemantics: true),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
