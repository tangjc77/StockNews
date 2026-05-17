import 'package:flutter/material.dart';

import '../models/stock_item.dart';
import '../services/stock_storage.dart';
import '../widgets/market_segment.dart';
import 'market_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _marketPageController = PageController();
  final _storage = StockStorage();

  int _marketIndex = 0;
  List<StockItem> _sseStocks = [];
  List<StockItem> _szseStocks = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  @override
  void dispose() {
    _marketPageController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    final sse = await _storage.loadStocks(MarketType.sse);
    final szse = await _storage.loadStocks(MarketType.szse);
    if (!mounted) return;
    setState(() {
      _sseStocks = sse;
      _szseStocks = szse;
      _loaded = true;
    });
  }

  void _updateSseStocks(List<StockItem> stocks) {
    setState(() => _sseStocks = stocks);
  }

  void _updateSzseStocks(List<StockItem> stocks) {
    setState(() => _szseStocks = stocks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                MarketSegment(
                  labels: const ['沪股通', '深股通'],
                  selectedIndex: _marketIndex,
                  onChanged: (index) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _marketIndex = index);
                    _marketPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                Expanded(
                  child: PageView(
                    controller: _marketPageController,
                    onPageChanged: (index) =>
                        setState(() => _marketIndex = index),
                    children: [
                      MarketPage(
                        market: MarketType.sse,
                        stocks: _sseStocks,
                        onStocksChanged: _updateSseStocks,
                        isMarketActive: _marketIndex == 0,
                      ),
                      MarketPage(
                        market: MarketType.szse,
                        stocks: _szseStocks,
                        onStocksChanged: _updateSzseStocks,
                        isMarketActive: _marketIndex == 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
