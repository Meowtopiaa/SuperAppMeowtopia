import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../../cat/data/cat_model.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 1 — Katalog Kucing Siap Adopsi
class AdoptionCatalogPage extends StatefulWidget {
  const AdoptionCatalogPage({super.key});

  @override
  State<AdoptionCatalogPage> createState() => _AdoptionCatalogPageState();
}

class _AdoptionCatalogPageState extends State<AdoptionCatalogPage> {
  String _filterGender = 'semua'; // 'semua' | 'male' | 'female'
  String _filterAge = 'semua'; // 'semua' | 'kitten' | 'adult'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionProvider>().fetchInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();

    final filteredCats = provider.readyCats.where((cat) {
      final genderOk = _filterGender == 'semua' || cat.gender == _filterGender;
      return genderOk;
    }).toList();

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Adopsi',
          style: AdoptionTheme.titleStyle,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 22),
            tooltip: 'Riwayat Pengajuan',
            onPressed: () => _showApplicationsSheet(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, size: 22),
            tooltip: 'Kucing Saya',
            onPressed: () => context.push('/adoption/my-cats'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator(message: 'Memuat...')
          : provider.errorMessage != null
              ? AdoptionErrorState(
                  message: provider.errorMessage!,
                  onRetry: () => provider.fetchInitialData(),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: RefreshIndicator(
                      color: AdoptionTheme.accent,
                      onRefresh: () => provider.fetchInitialData(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                        children: [
                          // ── Banner Pengantar Ramah Web & Mobile ────────────
                          _buildHeroBanner(context),
                          const SizedBox(height: 16),

                          // ── Header ringkas ─────────────────────────────────
                          _buildHeader(context),
                          const SizedBox(height: 16),

                          // ── Chip Filter ───────────────────────────────────
                          _buildFilterRow(),
                          const SizedBox(height: 20),

                          // ── Daftar kucing responsif (Web & Mobile) ─────────
                          if (filteredCats.isEmpty)
                            const AdoptionEmptyState(
                              icon: Icons.pets_rounded,
                              message: 'Belum ada kucing tersedia',
                              submessage:
                                  'Coba ubah filter, atau kunjungi lagi nanti.',
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                if (width >= 960) {
                                  // Web desktop lebar: 3 kolom lega
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                      mainAxisExtent: 425,
                                    ),
                                    itemCount: filteredCats.length,
                                    itemBuilder: (context, index) =>
                                        _CatCard(cat: filteredCats[index]),
                                  );
                                } else if (width >= 640) {
                                  // Tablet / medium web: 2 kolom seragam
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      mainAxisExtent: 425,
                                    ),
                                    itemCount: filteredCats.length,
                                    itemBuilder: (context, index) =>
                                        _CatCard(cat: filteredCats[index]),
                                  );
                                } else {
                                  // Layar mobile: kartu seragam rapi
                                  return Column(
                                    children: filteredCats
                                        .map((cat) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 16),
                                              child: SizedBox(
                                                height: 425,
                                                child: _CatCard(cat: cat),
                                              ),
                                            ))
                                        .toList(),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AdoptionTheme.accentSurface,
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(
          color: AdoptionTheme.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdoptionTheme.accentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Program Sahabat Kampus',
                    style: AdoptionTheme.captionStyle.copyWith(
                      color: AdoptionTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temukan Sahabat Kucing di Kampus',
                  style: AdoptionTheme.titleStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kucing-kucing kampus yang siap mendapatkan keluarga baru dan hunian yang aman.',
                  style: AdoptionTheme.captionStyle.copyWith(
                    color: AdoptionTheme.textSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AdoptionTheme.accent,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Temukan kucing kampus yang cocok untukmu.',
            style: AdoptionTheme.bodyStyle.copyWith(
              color: AdoptionTheme.textSub,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.push('/adoption/apply'),
          child: Text(
            'Isi form kelayakan',
            style: AdoptionTheme.captionStyle.copyWith(
              color: AdoptionTheme.accent,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AdoptionTheme.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            selected: _filterGender == 'semua' && _filterAge == 'semua',
            onTap: () => setState(() {
              _filterGender = 'semua';
              _filterAge = 'semua';
            }),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Jantan',
            selected: _filterGender == 'male',
            onTap: () => setState(
              () => _filterGender = _filterGender == 'male' ? 'semua' : 'male',
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Betina',
            selected: _filterGender == 'female',
            onTap: () => setState(
              () => _filterGender =
                  _filterGender == 'female' ? 'semua' : 'female',
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Anak',
            selected: _filterAge == 'kitten',
            onTap: () => setState(
              () => _filterAge = _filterAge == 'kitten' ? 'semua' : 'kitten',
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Dewasa',
            selected: _filterAge == 'adult',
            onTap: () => setState(
              () => _filterAge = _filterAge == 'adult' ? 'semua' : 'adult',
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicationsSheet(BuildContext context, AdoptionProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final apps = provider.myApplications;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Pengajuan',
                    style: AdoptionTheme.titleStyle,
                  ),
                  CloseButton(),
                ],
              ),
              const SizedBox(height: 10),
              if (apps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Belum ada pengajuan.',
                      style: AdoptionTheme.bodyStyle,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: apps.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 12, color: AdoptionTheme.divider),
                    itemBuilder: (_, index) {
                      final item = apps[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: item.status.backgroundColor,
                          child: Icon(
                            item.status.icon,
                            color: item.status.color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.catName ?? 'Draf Pengajuan',
                          style: AdoptionTheme.subtitleStyle,
                        ),
                        subtitle: Text(
                          item.status.labelId,
                          style: AdoptionTheme.captionStyle
                              .copyWith(color: item.status.color),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AdoptionTheme.textHint,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          context.push('/adoption/detail/${item.id}');
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AdoptionTheme.accent : Colors.white,
          borderRadius: AdoptionTheme.borderSm,
          border: Border.all(
            color: selected ? AdoptionTheme.accent : AdoptionTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AdoptionTheme.captionStyle.copyWith(
            color: selected ? Colors.white : AdoptionTheme.textSub,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KARTU KUCING SERAGAM (Web Grid & Mobile List)
// ─────────────────────────────────────────────────────────────────────────────

class _CatCard extends StatelessWidget {
  final CatModel cat;

  const _CatCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final location = cat.lastSeenLocationName ?? 'Area Kampus';

    return Container(
      decoration: AdoptionTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto Proporsional dengan Gender Badge ──────────────────────
          Stack(
            children: [
              _CatPhoto(
                photoUrl: cat.primaryPhotoUrl,
                height: 170,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AdoptionTheme.radiusLg),
                  topRight: Radius.circular(AdoptionTheme.radiusLg),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _GenderBadge(gender: cat.gender),
              ),
            ],
          ),

          // ── Konten Informasi Kucing ───────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: AdoptionTheme.subtitleStyle.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cat.breed,
                    style: AdoptionTheme.captionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (cat.description != null && cat.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      cat.description!,
                      style: AdoptionTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: AdoptionTheme.textSub,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),
                  // Chip sifat & status steril
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (cat.sterilizationStatus)
                        const _TagChip(
                          label: 'Steril',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      if (cat.pattern != null && cat.pattern!.isNotEmpty)
                        _TagChip(label: cat.pattern!),
                      if (cat.primaryColor != null && cat.primaryColor!.isNotEmpty)
                        _TagChip(label: cat.primaryColor!),
                    ],
                  ),

                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AdoptionTheme.textHint,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          style: AdoptionTheme.captionStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdoptionTheme.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AdoptionTheme.borderMd,
                          ),
                          textStyle: AdoptionTheme.captionStyle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          context.push(
                            '/adoption/apply?cat_id=${cat.id}&name=${Uri.encodeComponent(cat.name)}',
                          );
                        },
                        child: const Text('Lihat Detail'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS PRIVAT
// ─────────────────────────────────────────────────────────────────────────────

class _CatPhoto extends StatelessWidget {
  final String? photoUrl;
  final double? height;
  final BorderRadius? borderRadius;

  const _CatPhoto({
    this.photoUrl,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.zero;
    final hasUrl = photoUrl != null && photoUrl!.isNotEmpty;

    Widget placeholder = ClipRRect(
      borderRadius: br,
      child: Container(
        height: height,
        color: AdoptionTheme.accentSurface,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 36,
            color: AdoptionTheme.accent.withValues(alpha: 0.3),
          ),
        ),
      ),
    );

    if (!hasUrl) return placeholder;

    return ClipRRect(
      borderRadius: br,
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: height,
          color: AdoptionTheme.accentSurface,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AdoptionTheme.accent.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          height: height,
          color: AdoptionTheme.accentSurface,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 28,
              color: AdoptionTheme.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderBadge extends StatelessWidget {
  final String gender;

  const _GenderBadge({required this.gender});

  @override
  Widget build(BuildContext context) {
    final isMale = gender == 'male';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isMale ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
        borderRadius: AdoptionTheme.borderSm,
        border: Border.all(
          color: isMale ? const Color(0xFFBFDBFE) : const Color(0xFFFBCFE8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMale ? Icons.male_rounded : Icons.female_rounded,
            size: 13,
            color: isMale ? const Color(0xFF3B82F6) : const Color(0xFFEC4899),
          ),
          const SizedBox(width: 3),
          Text(
            isMale ? 'Jantan' : 'Betina',
            style: AdoptionTheme.captionStyle.copyWith(
              fontSize: 11,
              color: isMale ? const Color(0xFF1D4ED8) : const Color(0xFFBE185D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _TagChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: const BoxDecoration(
        color: AdoptionTheme.chipBg,
        borderRadius: AdoptionTheme.borderSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: AdoptionTheme.accent,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AdoptionTheme.captionStyle.copyWith(
              fontSize: 11,
              color: AdoptionTheme.textSub,
            ),
          ),
        ],
      ),
    );
  }
}
