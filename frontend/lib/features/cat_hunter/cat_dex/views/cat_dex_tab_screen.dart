import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../widgets/app_header_bar.dart';
import '../data/repositories/mock_cat_repository.dart';
import 'widgets/cafe_sanctuary_view.dart';
import 'widgets/catalog_grid_view.dart';

class CatDexTabScreen extends StatefulWidget {
  final int initialTabIndex;

  const CatDexTabScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CatDexTabScreen> createState() => _CatDexTabScreenState();
}

class _CatDexTabScreenState extends State<CatDexTabScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockCatRepository(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppHeaderBar(
            title: 'Kucing Kampus',
            subtitle: _selectedTab == 0
                ? 'TelCat World • Kafe Kucing'
                : 'TelCat World • Katalog Cat-Dex',
            statusText: 'Koleksi',
          ),
          body: Column(
            children: [
              // Segmented Tab Switcher
              Container(
                margin: const EdgeInsets.fromLTRB(
                  AppDimensions.marginHorizontal,
                  12,
                  AppDimensions.marginHorizontal,
                  4,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    // Tab 1: Kafe Kucing
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = 0;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 0
                                ? const [
                                    BoxShadow(
                                      color: Color.fromRGBO(242, 106, 27, 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '☕',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Kafe Kucing',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab 2: Katalog Cat-Dex
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 1
                                ? const [
                                    BoxShadow(
                                      color: Color.fromRGBO(242, 106, 27, 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '📋',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Katalog Cat-Dex',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Active Tab Content
              Expanded(
                child: _selectedTab == 0
                    ? CafeSanctuaryView(
                        onSwitchToCatalog: () {
                          setState(() {
                            _selectedTab = 1;
                          });
                        },
                      )
                    : CatalogGridView(
                        onVisitInCafe: () {
                          setState(() {
                            _selectedTab = 0;
                          });
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
