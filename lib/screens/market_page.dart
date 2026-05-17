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
        NavigationBar(
          selectedIndex: _bottomIndex,
          onDestinationSelected: (index) {
            setState(() => _bottomIndex = index);
            _onBottomTap(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article),
              label: '披露信息',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: '代码配置',
            ),
          ],
        ),
      ],
    );
  }
}
