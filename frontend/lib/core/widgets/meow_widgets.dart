import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/meow_style.dart';

class MeowPage extends StatelessWidget {
  const MeowPage({
    super.key,
    required this.child,
    this.title,
    this.bottom,
    this.back = true,
  });
  final Widget child;
  final String? title;
  final Widget? bottom;
  final bool back;

  static EdgeInsets scrollPadding(
    BuildContext context, {
    double top = 20,
    double bottom = 20,
  }) => EdgeInsets.fromLTRB(
    20,
    top,
    20,
    bottom + MediaQuery.paddingOf(context).bottom,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MeowStyle.background,
    appBar: title == null
        ? null
        : AppBar(
            backgroundColor: MeowStyle.background.withValues(alpha: .95),
            leading: back
                ? IconButton(
                    tooltip: 'Kembali',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/feeding'),
                  )
                : null,
            title: Text(title!),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: 'Akun saya',
                onPressed: () => context.go('/profile'),
                icon: const CircleAvatar(
                  radius: 17,
                  backgroundColor: MeowStyle.orangeDark,
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE7D9),
            MeowStyle.background,
            Color(0xFFE5F8F0),
            MeowStyle.background,
          ],
          stops: [0, .35, .7, 1],
        ),
      ),
      child: SafeArea(
        top: title == null,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ),
    ),
    bottomNavigationBar: bottom == null
        ? null
        : SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: bottom,
                ),
              ),
            ),
          ),
  );
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color ?? Colors.white.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F9D4300),
          blurRadius: 28,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class MeowButton extends StatelessWidget {
  const MeowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.busy = false,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;
  final bool secondary;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? MeowStyle.lilac : MeowStyle.orange,
        foregroundColor: secondary ? MeowStyle.ink : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: busy ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 20),
          const SizedBox(width: 9),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}

class MeowPill extends StatelessWidget {
  const MeowPill(
    this.label, {
    super.key,
    this.color = MeowStyle.lilac,
    this.foreground = MeowStyle.brown,
    this.icon,
  });
  final String label;
  final Color color;
  final Color foreground;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

class IconBubble extends StatelessWidget {
  const IconBubble(
    this.icon, {
    super.key,
    this.color = MeowStyle.peach,
    this.foreground = MeowStyle.orangeDark,
    this.size = 42,
  });
  final IconData icon;
  final Color color;
  final Color foreground;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Icon(icon, color: foreground, size: size * .48),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.icon, this.trailing});
  final String title;
  final IconData? icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, size: 19, color: MeowStyle.orangeDark),
        const SizedBox(width: 7),
      ],
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

class FigmaIcon extends StatelessWidget {
  const FigmaIcon(this.asset, {super.key, this.size = 20});
  final String asset;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: SvgPicture.asset(
      'assets/icons/figma/$asset.svg',
      fit: BoxFit.contain,
    ),
  );
}
