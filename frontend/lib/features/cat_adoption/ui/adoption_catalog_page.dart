import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../data/adoption_catalog_model.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 1: katalog kucing READY tanpa data pribadi (EN-12, ADP-05, CAT-09).
class AdoptionCatalogPage extends StatefulWidget {
  const AdoptionCatalogPage({super.key});

  @override
  State<AdoptionCatalogPage> createState() => _AdoptionCatalogPageState();
}

class _AdoptionCatalogPageState extends State<AdoptionCatalogPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdoptionProvider>();
      provider.fetchCatalog();
      provider.fetchMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();
    final cats = provider.catalogCats;

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
      body: AdoptionBackground(
        child: RefreshIndicator(
          color: AdoptionTheme.accent,
          onRefresh: () => provider.fetchCatalog(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: ListView(
                padding: adoptionScrollPadding(context),
                children: [
                  _buildIntro(context),
                  const SizedBox(height: 4),
                  _buildFilterRow(provider),
                  const SizedBox(height: 16),
                  if (provider.isCatalogLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: LoadingIndicator(message: 'Memuat kucing...'),
                    )
                  else if (provider.catalogError != null)
                    AdoptionErrorState(
                      message: provider.catalogError!,
                      onRetry: () => provider.fetchCatalog(),
                    )
                  else if (cats.isEmpty)
                    AdoptionEmptyState(
                      message: provider.catalogFilter.isEmpty
                          ? 'Belum ada kucing yang siap diadopsi'
                          : 'Tidak ada kucing yang cocok dengan filter ini',
                      submessage: provider.catalogFilter.isEmpty
                          ? 'Cek lagi beberapa hari ke depan.'
                          : 'Coba hapus filter untuk melihat semua kucing.',
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
                          children: cats
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
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return AdoptionHeader(
      overline: 'Adopsi kucing kampus',
      title: 'Kucing yang mencari rumah',
      subtitle: 'Semua kucing di sini sudah diperiksa pengurus adopsi. '
          'Sebelum mengambil kucing, isi dulu form kelayakan.',
      icon: Icons.favorite_rounded,
      footer: SizedBox(
        height: 40,
        child: FilledButton(
          style: AdoptionTheme.primaryButtonStyle.copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 18),
            ),
          ),
          onPressed: () => context.push('/adoption/apply'),
          child: const Text('Isi form kelayakan'),
        ),
      ),
    );
  }

  /// Filter di aplikasi. Mengetuk filter yang aktif akan mematikannya.
  Widget _buildFilterRow(AdoptionProvider provider) {
    final current = provider.catalogFilter;

    void apply({String? gender, String? ageGroup}) {
      provider.setCatalogFilter(
        AdoptionCatalogFilter(gender: gender, ageGroup: ageGroup),
      );
    }

    Widget genderChip(String label, String value) => _FilterChip(
          label: label,
          selected: current.gender == value,
          onTap: () => apply(
            gender: current.gender == value ? null : value,
            ageGroup: current.ageGroup,
          ),
        );

    Widget ageChip(String label, String value) => _FilterChip(
          label: label,
          selected: current.ageGroup == value,
          onTap: () => apply(
            gender: current.gender,
            ageGroup: current.ageGroup == value ? null : value,
          ),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Semua',
          selected: current.isEmpty,
          onTap: () => apply(),
        ),
        genderChip('Jantan', 'MALE'),
        genderChip('Betina', 'FEMALE'),
        ageChip('Anak', 'KITTEN'),
        ageChip('Dewasa', 'ADULT'),
        ageChip('Lansia', 'SENIOR'),
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
      backgroundColor: AdoptionTheme.glassBg,
      selectedColor: AdoptionTheme.accent,
      side: BorderSide(
        color: selected ? AdoptionTheme.accent : Colors.white,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KARTU KUCING (seluruh kartu bisa diketuk)
// ─────────────────────────────────────────────────────────────────────────────

class _CatCard extends StatelessWidget {
  final AdoptionCatalogCat cat;

  const _CatCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final meta =
        [cat.genderLabel, if (cat.ageLabel != null) cat.ageLabel!].join(', ');
    final traits = <String>[
      if (cat.colorPattern != null) cat.colorPattern!,
      if (cat.isSterilized == true) 'Sudah steril',
    ];

    // Kartu membuka form kelayakan dengan nama kucing sebagai konteks.
    // Kelayakan tidak mengikat kucing (ADP-02); kucing dipilih saat pindai QR pengambilan.
    void open() => context.push(
          '/adoption/apply?cat_id=${Uri.encodeComponent(cat.id)}&name=${Uri.encodeComponent(cat.name)}',
        );

    return Container(
      decoration: AdoptionTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: open,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CatPhotoBox(
                photoUrl: cat.photoUrl,
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
                      meta,
                      style: AdoptionTheme.bodyStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cat.description != null) ...[
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
                        children:
                            traits.map((t) => _TagChip(label: t)).toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Ajukan adopsi',
                        style: AdoptionTheme.bodyStyle.copyWith(
                          color: AdoptionTheme.accentDark,
                          fontWeight: FontWeight.w600,
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
        borderRadius: AdoptionTheme.borderPill,
      ),
      child: Text(
        label,
        style:
            AdoptionTheme.captionStyle.copyWith(color: AdoptionTheme.textSub),
      ),
    );
  }
}
