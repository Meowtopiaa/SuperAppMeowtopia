import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/cinematic_card.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../data/feeding_spot_model.dart';

class SpotPhoto extends StatelessWidget {
  const SpotPhoto(
    this.spot, {
    super.key,
    required this.isDemo,
    this.height = 190,
  });
  final FeedingSpotModel spot;
  final bool isDemo;
  final double height;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      color: MeowStyle.lilac,
      alignment: Alignment.center,
      child: const Icon(
        Icons.cottage_outlined,
        size: 48,
        color: MeowStyle.orangeDark,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: isDemo
          ? Image.asset(
              spot.imageAsset,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : spot.imageUrl == null
          ? fallback
          : Image.network(
              spot.imageUrl!,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

class FeedingSpotPreviewCard extends StatelessWidget {
  const FeedingSpotPreviewCard({
    super.key,
    required this.spot,
    required this.isDemo,
  });

  final FeedingSpotModel spot;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? cardImage;
    if (isDemo) {
      cardImage = AssetImage(spot.imageAsset);
    } else if (spot.imageUrl != null) {
      cardImage = NetworkImage(spot.imageUrl!);
    }

    return CinematicCard(
      image: cardImage,
      imageOnLeft: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      onTap: () => context.push('/feeding/spot/${spot.id}'),
      child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          SizedBox(width: constraints.maxWidth * .25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spot.lastFedSentence,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCFD3DD),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  spot.distanceLabel != null
                      ? '${spot.activityLabel} · ${spot.distanceLabel}'
                      : spot.activityLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MeowStyle.peach,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ],
      ),
    ),
  );
  }
}

class CampusSpotMap extends StatefulWidget {
  const CampusSpotMap({
    super.key,
    required this.spots,
    this.selectedId,
    required this.isDemo,
    this.isFullScreen = false,
  });

  final List<FeedingSpotModel> spots;
  final String? selectedId;
  final bool isDemo;
  final bool isFullScreen;

  @override
  State<CampusSpotMap> createState() => _CampusSpotMapState();
}

class _CampusSpotMapState extends State<CampusSpotMap> {
  final MapController _mapController = MapController();
  static LatLng? _cachedUserLocation;
  LatLng? _userLocation;
  bool _isOutOfCampus = false;
  bool _locating = false;

  // Telkom University Center (Gedung Bangkit / Danau Galau)
  static const LatLng campusCenter = LatLng(-6.9732, 107.6304);

  // Polygon Perimeter Resmi Wilayah Telkom University Bandung (76 titik presisi OSM Way 557649490 + Kantin Teknik)
  static const List<LatLng> telkomBoundary = [
    LatLng(-6.9697046, 107.6307312),
    LatLng(-6.9702850, 107.6309752),
    LatLng(-6.9703549, 107.6310401),
    LatLng(-6.9704453, 107.6311774),
    LatLng(-6.9709586, 107.6319851),
    LatLng(-6.9714512, 107.6326704),
    LatLng(-6.9720409, 107.6335066),
    LatLng(-6.9721221, 107.6334442),
    LatLng(-6.9721713, 107.6335354),
    LatLng(-6.9730965, 107.6334992),
    LatLng(-6.9731498, 107.6334415),
    LatLng(-6.9732669, 107.6333047),
    LatLng(-6.9739019, 107.6326382),
    LatLng(-6.9739511, 107.6326248),
    LatLng(-6.9740250, 107.6326088),
    LatLng(-6.9740603, 107.6325980),
    LatLng(-6.9744437, 107.6325403),
    LatLng(-6.9747597, 107.6324340),
    LatLng(-6.9748191, 107.6324698),
    LatLng(-6.9750573, 107.6325926),
    LatLng(-6.9752184, 107.6326986),
    LatLng(-6.9754460, 107.6329333),
    LatLng(-6.9755306, 107.6329688),
    LatLng(-6.9756371, 107.6329654),
    LatLng(-6.9760504, 107.6329319),
    LatLng(-6.9761877, 107.6328865),
    LatLng(-6.9762394, 107.6327978),
    LatLng(-6.9774654, 107.6315466),
    LatLng(-6.9776200, 107.6313900),
    LatLng(-6.9779500, 107.6317500),
    LatLng(-6.9786500, 107.6310800),
    LatLng(-6.9778500, 107.6306200),
    LatLng(-6.9777357, 107.6305917),
    LatLng(-6.9776897, 107.6301411),
    LatLng(-6.9776505, 107.6299500),
    LatLng(-6.9776405, 107.6298387),
    LatLng(-6.9776425, 107.6297320),
    LatLng(-6.9776837, 107.6294491),
    LatLng(-6.9777157, 107.6292425),
    LatLng(-6.9777250, 107.6290642),
    LatLng(-6.9771872, 107.6290481),
    LatLng(-6.9756444, 107.6290561),
    LatLng(-6.9753076, 107.6290521),
    LatLng(-6.9752314, 107.6290444),
    LatLng(-6.9752204, 107.6290434),
    LatLng(-6.9751658, 107.6289844),
    LatLng(-6.9748710, 107.6287074),
    LatLng(-6.9743039, 107.6282313),
    LatLng(-6.9738060, 107.6277861),
    LatLng(-6.9732909, 107.6282461),
    LatLng(-6.9731484, 107.6283976),
    LatLng(-6.9719577, 107.6283936),
    LatLng(-6.9719437, 107.6284074),
    LatLng(-6.9719344, 107.6284312),
    LatLng(-6.9719360, 107.6284644),
    LatLng(-6.9719360, 107.6284781),
    LatLng(-6.9713819, 107.6284996),
    LatLng(-6.9713727, 107.6281416),
    LatLng(-6.9713512, 107.6280972),
    LatLng(-6.9712548, 107.6268379),
    LatLng(-6.9712235, 107.6267521),
    LatLng(-6.9707124, 107.6267702),
    LatLng(-6.9702045, 107.6267943),
    LatLng(-6.9696254, 107.6275329),
    LatLng(-6.9696164, 107.6275597),
    LatLng(-6.9694956, 107.6277231),
    LatLng(-6.9685079, 107.6275742),
    LatLng(-6.9684786, 107.6280342),
    LatLng(-6.9684853, 107.6284620),
    LatLng(-6.9692014, 107.6286001),
    LatLng(-6.9696267, 107.6303470),
    LatLng(-6.9697046, 107.6307312),
  ];

  /// Ray-casting algorithm untuk mengecek apakah titik koordinat berada di dalam poligon Telkom University
  static bool isPointInsideCampus(LatLng point) {
    bool inside = false;
    for (int i = 0, j = telkomBoundary.length - 1; i < telkomBoundary.length; j = i++) {
      final xi = telkomBoundary[i].latitude;
      final yi = telkomBoundary[i].longitude;
      final xj = telkomBoundary[j].latitude;
      final yj = telkomBoundary[j].longitude;

      final intersect = ((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  @override
  void initState() {
    super.initState();
    if (_cachedUserLocation != null) {
      _userLocation = _cachedUserLocation;
      _isOutOfCampus = !isPointInsideCampus(_cachedUserLocation!);
    }
    _checkUserLocation(moveToLocation: false);
  }

  Future<void> _checkUserLocation({bool moveToLocation = true}) async {
    // 1. Gerakkan kamera secara INSTAN (0ms) jika posisi sudah ada di memori
    final immediatePos = _userLocation ?? _cachedUserLocation;
    if (moveToLocation && immediatePos != null) {
      _mapController.move(immediatePos, 17.0);
    }

    if (immediatePos == null) {
      setState(() => _locating = true);
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }

      // 2. Cek lastKnownPosition terlebih dahulu bila belum ada cache
      if (immediatePos == null) {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null && mounted) {
          final cached = LatLng(lastPos.latitude, lastPos.longitude);
          _cachedUserLocation = cached;
          setState(() {
            _userLocation = cached;
            _isOutOfCampus = !isPointInsideCampus(cached);
            _locating = false;
          });
          if (moveToLocation) {
            _mapController.move(cached, 17.0);
          }
        }
      }

      // 3. Sinkronisasi posisi satelit terbaru di background
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );

      final userPos = LatLng(position.latitude, position.longitude);
      _cachedUserLocation = userPos;

      if (mounted) {
        setState(() {
          _userLocation = userPos;
          _isOutOfCampus = !isPointInsideCampus(userPos);
          _locating = false;
        });

        if (moveToLocation && immediatePos == null) {
          _mapController.move(userPos, 17.0);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validSpots = widget.spots.where((s) => s.latitude != 0.0 && s.longitude != 0.0).toList();
    final center = widget.selectedId != null && validSpots.any((s) => s.id == widget.selectedId)
        ? LatLng(
            validSpots.firstWhere((s) => s.id == widget.selectedId).latitude,
            validSpots.firstWhere((s) => s.id == widget.selectedId).longitude,
          )
        : campusCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.isFullScreen ? 0 : 18),
      child: Container(
        height: widget.isFullScreen ? null : 240,
        decoration: BoxDecoration(
          color: MeowStyle.lavender,
          border: widget.isFullScreen ? null : Border.all(color: MeowStyle.lilac),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: widget.isFullScreen ? 16.5 : 15.8,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'id.meowtopia.meowtopia',
                ),
                // Area Luar Jangkauan Kampus (Diagonal Orange Hatch Lines + Grid Boundary sesuai acuan)
                const _CampusBoundaryOverlay(boundary: telkomBoundary),
                MarkerLayer(
                  markers: [
                    // Marker Spot Pakan
                    for (final spot in validSpots)
                      Marker(
                        point: LatLng(spot.latitude, spot.longitude),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.isFullScreen) {
                              Navigator.pop(context);
                            }
                            context.push('/feeding/spot/${spot.id}');
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.selectedId == spot.id
                                  ? MeowStyle.orange
                                  : spot.isActive
                                      ? MeowStyle.green
                                      : MeowStyle.slate,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Marker Posisi User Saat Ini
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 6),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Header Tag Kampus
            const Positioned(
              top: 10,
              left: 10,
              child: MeowPill(
                'Area Telkom University',
                color: Colors.white,
                icon: Icons.school_outlined,
              ),
            ),
            // Tombol Kontrol Kanan Atas: Center ke Kampus & Focus ke Lokasi Saya
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  // Tombol Fokus ke Lokasi Saya (GPS Auto-Focus)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Fokus ke lokasi saya',
                      onPressed: _locating ? null : () => _checkUserLocation(moveToLocation: true),
                      icon: _locating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              size: 20,
                              color: Color(0xFF2563EB),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tombol Reset ke Pusat Kampus Telkom
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Pusat Kampus Telkom',
                      onPressed: () => _mapController.move(campusCenter, 16.0),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Banner Peringatan Luar Jangkauan
            if (_isOutOfCampus)
              Positioned(
                top: 52,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFA39E)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFCF1322), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anda berada di luar jangkauan wilayah Telkom University!',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCF1322),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Label Bawah
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Arsiran oranye: Luar wilayah Telkom University',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: MeowStyle.brown),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampusBoundaryOverlay extends StatelessWidget {
  const _CampusBoundaryOverlay({required this.boundary});
  final List<LatLng> boundary;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final offsets = <Offset>[
      for (final pt in boundary)
        () {
          final p = camera.latLngToScreenPoint(pt);
          return Offset(p.x, p.y);
        }(),
    ];

    // Titik-titik garis grid vertikal berdasarkan bujur (longitude) seperti di gambar acuan
    const gridLongitudes = <double>[
      107.6240,
      107.6285,
      107.6330,
      107.6375,
    ];
    final gridXs = <double>[
      for (final lon in gridLongitudes)
        camera.latLngToScreenPoint(LatLng(-6.9732, lon)).x,
    ];

    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _CampusBoundaryPainter(
            campusOffsets: offsets,
            gridXs: gridXs,
          ),
        ),
      ),
    );
  }
}

class _CampusBoundaryPainter extends CustomPainter {
  const _CampusBoundaryPainter({
    required this.campusOffsets,
    required this.gridXs,
  });

  final List<Offset> campusOffsets;
  final List<double> gridXs;

  @override
  void paint(Canvas canvas, Size size) {
    if (campusOffsets.length < 3) return;

    final screenRect = Offset.zero & size;
    final screenPath = Path()..addRect(screenRect);

    final campusPath = Path()..moveTo(campusOffsets.first.dx, campusOffsets.first.dy);
    for (int i = 1; i < campusOffsets.length; i++) {
      campusPath.lineTo(campusOffsets[i].dx, campusOffsets[i].dy);
    }
    campusPath.close();

    // 1. Area Luar Kampus (No-Go Zone): Tint Oranye + Garis-Garis Diagonal Oranye + Grid Vertikal
    final outsidePath = Path.combine(PathOperation.difference, screenPath, campusPath);

    canvas.save();
    canvas.clipPath(outsidePath);

    // Latar belakang oranye lembut di luar jangkauan
    final outsideFill = Paint()
      ..color = const Color(0x28FF8C00)
      ..style = PaintingStyle.fill;
    canvas.drawRect(screenRect, outsideFill);

    // Garis-garis miring (diagonal hatch lines) berwarna oranye di luar batas kampus
    final hatchPaint = Paint()
      ..color = const Color(0x88FF6D00)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double step = 16.0;
    final double maxExtent = size.width + size.height;
    for (double d = -size.height; d < maxExtent; d += step) {
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        hatchPaint,
      );
    }

    // Garis grid vertikal putih seperti pada contoh gambar referensi
    final gridPaint = Paint()
      ..color = const Color(0xBBFFFFFF)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final x in gridXs) {
      if (x >= 0 && x <= size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }

    canvas.restore();

    // 2. Area Dalam Kampus: Sedikit tint ungu/biru bersih seperti gambar acuan
    final insideFill = Paint()
      ..color = const Color(0x186366F1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(campusPath, insideFill);

    // 3. Garis Batas Perimeter Telkom University (Double Stroke: Putih di dalam + Hitam/Slate tegas di luar)
    final innerWhiteStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(campusPath, innerWhiteStroke);

    final outerDarkStroke = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(campusPath, outerDarkStroke);
  }

  @override
  bool shouldRepaint(covariant _CampusBoundaryPainter oldDelegate) => true;
}

class FeedingMessage extends StatelessWidget {
  const FeedingMessage(this.message, {super.key, this.action, this.onAction});
  final String message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      children: [
        const IconBubble(Icons.info_outline_rounded),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: MeowStyle.brown, height: 1.5),
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          MeowButton(label: action!, onPressed: onAction),
        ],
      ],
    ),
  );
}
