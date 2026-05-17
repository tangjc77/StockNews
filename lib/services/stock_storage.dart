import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/stock_item.dart';

enum MarketType { sse, szse }

class StockStorage {
  static const _sseKey = 'sse_stocks';
  static const _szseKey = 'szse_stocks';

  Future<List<StockItem>> loadStocks(MarketType market) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(market));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveStocks(MarketType market, List<StockItem> stocks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(stocks.map((e) => e.toJson()).toList());
    await prefs.setString(_key(market), encoded);
  }

  String _key(MarketType market) =>
      market == MarketType.sse ? _sseKey : _szseKey;
}
