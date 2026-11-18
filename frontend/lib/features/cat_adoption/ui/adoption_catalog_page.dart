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
        title: const Text('Adopsi', style: AdoptionTheme.titleStyle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 22),
            tooltip: 'Riwayat pengajuan',
            onPressed: () => _showApplicationsSheet(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.pets_outlined, size: 22),
            tooltip: 'Kucing saya',
            onPressed: () => context.push('/adoption/my-cats'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator(message: 'Memuat kucing...')
          : provider.errorMessage != null
              ? AdoptionErrorState(
                  message: provider.errorMessage!,
                  onRetry: () => provider.fetchInitialData(),
                )
              : RefreshIndicator(
                  color: AdoptionTheme.accent,
                  onRefresh: () => provider.fetchInitialData(),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                        children: [
                          _buildIntro(context),
                          const SizedBox(height: 20),
                          _buildFilterRow(),
                          const SizedBox(height: 16),
                          if (filteredCats.isEmpty)
                            const AdoptionEmptyState(
                              message: 'Belum ada kucing yang siap diadopsi',
                              submessage:
                                  'Coba ubah filter, atau cek lagi beberapa hari ke depan.',
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const gap = 16.0;
                                final width = constraints.maxWidth;
                                final columns = width >= 900
                                    ? 3
                                    : width >= 560
                                        ? 2
                                        : 1;
                                final itemWidth =
                                    (width - gap * (columns - 1)) / columns;
                                return Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: filteredCats
                                      .map((cat) => SizedBox(
                                            width: itemWidth,
                                            child: _CatCard(cat: cat),
                                          ))
                                      .toList(),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kucing kampus yang mencari rumah',
          style: AdoptionTheme.headlineStyle,
        ),
        const SizedBox(height: 6),
        const Text(
          'Semua kucing di sini sudah diperiksa pengurus adopsi. '
          'Sebelum mengambil kucing, isi dulu form kelayakan.',
          style: AdoptionTheme.bodyStyle,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.push('/adoption/apply'),
          style: TextButton.styleFrom(
            foregroundColor: AdoptionTheme.accent,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            textStyle: AdoptionTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          child: const Text('Isi form kelayakan'),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Semua',
          selected: _filterGender == 'semua' && _filterAge == 'semua',
          onTap: () => setState(() {
            _filterGender = 'semua';
            _filterAge = 'semua';
          }),
        ),
        _FilterChip(
          label: 'Jantan',
          selected: _filterGender == 'male',
          onTap: () => setState(
            () => _filterGender = _filterGender == 'male' ? 'semua' : 'male',
          ),
        ),
        _FilterChip(
          label: 'Betina',
          selected: _filterGender == 'female',
          onTap: () => setState(
            () => _filterGender = _filterGender == 'female' ? 'semua' : 'female',
          ),
        ),
        _FilterChip(
          label: 'Anak',
          selected: _filterAge == 'kitten',
          onTap: () => setState(
            () => _filterAge = _filterAge == 'kitten' ? 'semua' : 'kitten',
          ),
        ),
        _FilterChip(
          label: 'Dewasa',
          selected: _filterAge == 'adult',
          onTap: () => setState(
            () => _filterAge = _filterAge == 'adult' ? 'semua' : 'adult',
          ),
        ),
      ],
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: AdoptionTheme.bodyStyle.copyWith(
        color: selected ? Colors.white : AdoptionTheme.textMain,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: AdoptionTheme.cardBg,
      selectedColor: AdoptionTheme.accent,
      side: BorderSide(
        color: selected ? AdoptionTheme.accent : AdoptionTheme.inputBorder,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderSm),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KARTU KUCING (seluruh kartu bisa diketuk)
// ─────────────────────────────────────────────────────────────────────────────

class _CatCard extends StatelessWidget {
  final CatModel cat;

  const _CatCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final genderLabel = cat.gender == 'male' ? 'Jantan' : 'Betina';
    final traits = <String>[
      if (cat.primaryColor != null && cat.primaryColor!.isNotEmpty) cat.primaryColor!,
      if (cat.pattern != null && cat.pattern!.isNotEmpty) cat.pattern!,
      if (cat.sterilizationStatus) 'Sudah steril',
    ];

    void open() => context.push(
          '/adoption/apply?cat_id=${cat.id}&name=${Uri.encodeComponent(cat.name)}',
        );

    return Material(
      color: AdoptionTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: AdoptionTheme.borderLg,
        side: BorderSide(color: AdoptionTheme.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CatPhotoBox(
              photoUrl: cat.primaryPhotoUrl,
              borderRadius: BorderRadius.zero,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: AdoptionTheme.titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$genderLabel, ${cat.breed}',
                    style: AdoptionTheme.bodyStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cat.description != null && cat.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      cat.description!,
                      style: AdoptionTheme.bodyStyle.copyWith(
                        color: AdoptionTheme.textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (traits.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: traits.map((t) => _TagChip(label: t)).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cat.lastSeenLocationName ?? 'Area kampus',
                          style: AdoptionTheme.captionStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Lihat detail',
                        style: AdoptionTheme.bodyStyle.copyWith(
                          color: AdoptionTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        color: AdoptionTheme.chipBg,
        borderRadius: AdoptionTheme.borderSm,
      ),
      child: Text(
        label,
        style: AdoptionTheme.captionStyle.copyWith(color: AdoptionTheme.textSub),
      ),
    );
  }
}
