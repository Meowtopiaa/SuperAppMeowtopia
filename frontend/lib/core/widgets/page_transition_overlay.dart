import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import 'walking_cat_loader.dart';

/// Observer ringan untuk mendeteksi perpindahan halaman (PageRoute)
/// di seluruh Super App — termasuk push, pop, dan replace.
class PageTransitionTracker extends NavigatorObserver {
  final VoidCallback _onTransition;

  PageTransitionTracker({required VoidCallback onTransition})
    : _onTransition = onTransition;

  void _notifyIfPageRoute(Route<dynamic>? route) {
    if (route is PageRoute<dynamic>) {
      _onTransition();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      _notifyIfPageRoute(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notifyIfPageRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notifyIfPageRoute(newRoute);
  }
}

/// Overlay antisipasi blank-screen berbasis animasi kucing 2.5D ("Memuat...").
///
/// - Jika perpindahan halaman cepat (tidak ngelag, selesai render sebelum [showDelay]),
///   overlay TIDAK muncul sama sekali sehingga navigasi langsung instan.
/// - Jika halaman tujuan sedang lambat/ngelag melewati [showDelay], animasi kucing
///   2.5D + tulisan "Memuat..." muncul langsung tanpa background kotak/layar penuh
///   hingga frame halaman tujuan selesai dirender.
/// - Saat idle, overlay sepenuhnya di-unmount (0% CPU/GPU).
class PageTransitionLoaderHost extends StatefulWidget {
  const PageTransitionLoaderHost({
    super.key,
    required this.router,
    required this.child,
    this.transitionListenable,
    this.showDelay = const Duration(milliseconds: 120),
    this.minVisibleDuration = const Duration(milliseconds: 280),
    this.fadeOutDuration = const Duration(milliseconds: 180),
    this.showOnInitialLoad = true,
  });

  final GoRouter router;
  final Widget child;
  final Listenable? transitionListenable;

  /// Batas waktu tunggu sebelum menganggap perpindahan halaman sedang lambat/ngelag.
  final Duration showDelay;

  /// Durasi tampil minimum (hanya bila overlay sempat muncul) agar tidak berkedip 1 frame.
  final Duration minVisibleDuration;

  final Duration fadeOutDuration;
  final bool showOnInitialLoad;

  @override
  State<PageTransitionLoaderHost> createState() =>
      _PageTransitionLoaderHostState();
}

class _PageTransitionLoaderHostState extends State<PageTransitionLoaderHost> {
  late String _lastLocation;
  bool _mountedOverlay = false;
  bool _visible = false;
  int _epoch = 0;
  Timer? _delayTimer;
  Timer? _minTimer;
  Timer? _unmountTimer;

  String get _providerLocation =>
      widget.router.routeInformationProvider.value.uri.toString();

  String get _delegateLocation =>
      widget.router.routerDelegate.currentConfiguration.uri.toString();

  @override
  void initState() {
    super.initState();
    _lastLocation = _providerLocation.isNotEmpty
        ? _providerLocation
        : _delegateLocation;

    widget.router.routeInformationProvider.addListener(_onRouteInfoChanged);
    widget.router.routerDelegate.addListener(_onRouterDelegateChanged);
    widget.transitionListenable?.addListener(_onExternalTransition);

    if (widget.showOnInitialLoad) {
      _beginTransitionWatch();
    }
  }

  @override
  void didUpdateWidget(covariant PageTransitionLoaderHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routeInformationProvider.removeListener(
        _onRouteInfoChanged,
      );
      oldWidget.router.routerDelegate.removeListener(_onRouterDelegateChanged);
      widget.router.routeInformationProvider.addListener(_onRouteInfoChanged);
      widget.router.routerDelegate.addListener(_onRouterDelegateChanged);
      _lastLocation = _providerLocation.isNotEmpty
          ? _providerLocation
          : _delegateLocation;
    }
    if (oldWidget.transitionListenable != widget.transitionListenable) {
      oldWidget.transitionListenable?.removeListener(_onExternalTransition);
      widget.transitionListenable?.addListener(_onExternalTransition);
    }
  }

  @override
  void dispose() {
    widget.router.routeInformationProvider.removeListener(_onRouteInfoChanged);
    widget.router.routerDelegate.removeListener(_onRouterDelegateChanged);
    widget.transitionListenable?.removeListener(_onExternalTransition);
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _delayTimer?.cancel();
    _minTimer?.cancel();
    _unmountTimer?.cancel();
  }

  void _onRouteInfoChanged() {
    _handleLocationChange(_providerLocation);
  }

  void _onRouterDelegateChanged() {
    _handleLocationChange(_delegateLocation);
  }

  void _handleLocationChange(String nextLocation) {
    if (nextLocation.isEmpty || nextLocation == _lastLocation) return;
    _lastLocation = nextLocation;
    _triggerTransition();
  }

  void _onExternalTransition() {
    _triggerTransition();
  }

  void _triggerTransition() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      scheduleMicrotask(_beginTransitionWatch);
    } else {
      _beginTransitionWatch();
    }
  }

  void _beginTransitionWatch() {
    if (!mounted) return;
    _cancelTimers();
    final epoch = ++_epoch;
    var frameCompleted = false;
    var minDurationDone = false;

    void tryHide() {
      if (!mounted || epoch != _epoch) return;
      if (!_mountedOverlay) return;
      if (!frameCompleted || !minDurationDone) return;
      _startFadeOut(epoch);
    }

    // Jika halaman belum selesai dirender setelah [showDelay], baru tampilkan kucing berjalan.
    _delayTimer = Timer(widget.showDelay, () {
      if (!mounted || epoch != _epoch || frameCompleted) return;
      setState(() {
        _mountedOverlay = true;
        _visible = true;
      });

      _minTimer = Timer(widget.minVisibleDuration, () {
        if (!mounted || epoch != _epoch) return;
        minDurationDone = true;
        tryHide();
      });
    });

    // Pantau kapan frame halaman tujuan benar-benar selesai dirender.
    SchedulerBinding.instance.scheduleFrame();
    SchedulerBinding.instance.endOfFrame.then((_) {
      if (!mounted || epoch != _epoch) return;
      frameCompleted = true;
      _delayTimer?.cancel();
      if (_mountedOverlay) {
        tryHide();
      }
    });
  }

  void _startFadeOut(int epoch) {
    if (!mounted || epoch != _epoch) return;
    setState(() => _visible = false);

    _unmountTimer?.cancel();
    _unmountTimer = Timer(widget.fadeOutDuration, () {
      if (!mounted || epoch != _epoch) return;
      setState(() => _mountedOverlay = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_mountedOverlay)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _visible ? 1.0 : 0.0,
                duration: widget.fadeOutDuration,
                curve: Curves.easeOutCubic,
                child: const Material(
                  type: MaterialType.transparency,
                  child: Center(child: WalkingCatLoader(size: 164)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
