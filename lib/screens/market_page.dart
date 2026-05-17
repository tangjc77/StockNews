import 'package:flutter/material.dart';

import '../models/stock_item.dart';
import '../services/stock_storage.dart';
import 'code_config_page.dart';
import 'disclosure_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({
    super.key,
    required this.market,
    required this.stocks,
    required this.onStocksChanged,
    this.isMarketActive = true,
  });

  final MarketType market;
  final List<StockItem> stocks;
  final ValueChanged<List<StockItem>> onStocksChanged;
  final bool isMarketActive;

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final _pageController = PageController();
  int _bottomIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _bottomIndex = index),
            children: [
              DisclosurePage(
                key: ValueKey('disclosure_${widget.market.name}'),
                market: widget.market,
                stocks: widget.stocks,
                autoRefresh:
                    widget.isMarketActive && _bottomIndex == 0,
              ),
              CodeConfigPage(
                market: widget.market,
                stocks: widget.stocks,
                onStocksChanged: widget.onStocksChanged,
              ),
            ],
          ),
        ),
        if (!keyboardVisible)
          _MarketBottomBar(
            height: 60,
            selectedIndex: _bottomIndex,
            onSelected: (index) {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _bottomIndex = index);
              _onBottomTap(index);
            },
            items: const [
              _BottomNavItem(
                icon: Icons.article_outlined,
                selectedIcon: Icons.article,
                label: '披露信息',
              ),
              _BottomNavItem(
                icon: Icons.tune_outlined,
                selectedIcon: Icons.tune,
                label: '代码配置',
              ),
            ],
          ),
      ],
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _MarketBottomBar extends StatelessWidget {
  const _MarketBottomBar({
    required this.height,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final double height;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_BottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navTheme = theme.navigationBarTheme;

    return Material(
      color: navTheme.backgroundColor ?? scheme.surface,
      elevation: navTheme.elevation ?? 3,
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == selectedIndex;
            final color = selected ? scheme.primary : scheme.onSurfaceVariant;
            final labelStyle = navTheme.labelTextStyle?.resolve({
                  if (selected) WidgetState.selected,
                }) ??
                TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                );

            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: 20,
                      color: color,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: labelStyle.copyWith(fontSize: 11, color: color),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
