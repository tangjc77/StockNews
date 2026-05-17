import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stock_item.dart';
import '../services/stock_storage.dart';

class CodeConfigPage extends StatefulWidget {
  const CodeConfigPage({
    super.key,
    required this.market,
    required this.stocks,
    required this.onStocksChanged,
  });

  final MarketType market;
  final List<StockItem> stocks;
  final ValueChanged<List<StockItem>> onStocksChanged;

  @override
  State<CodeConfigPage> createState() => _CodeConfigPageState();
}

class _CodeConfigPageState extends State<CodeConfigPage> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _storage = StockStorage();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(List<StockItem> stocks) async {
    await _storage.saveStocks(widget.market, stocks);
    widget.onStocksChanged(stocks);
  }

  void _addStock() {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();

    if (code.isEmpty || name.isEmpty) {
      _showMessage('请填写股票代码和公司名称');
      return;
    }
    if (code.length != 6) {
      _showMessage('股票代码须为 6 位数字');
      return;
    }
    if (widget.stocks.any((s) => s.code == code)) {
      _showMessage('该股票代码已存在');
      return;
    }

    final updated = [...widget.stocks, StockItem(code: code, name: name)];
    _save(updated);
    _codeController.clear();
    _nameController.clear();
    FocusScope.of(context).unfocus();
  }

  void _removeStock(StockItem item) {
    final updated =
        widget.stocks.where((s) => s.code != item.code).toList();
    _save(updated);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marketLabel = widget.market == MarketType.sse ? '沪股通' : '深股通';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '$marketLabel · 代码配置',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: '股票代码',
                      hintText: '6 位数字',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '公司名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addStock,
                      icon: const Icon(Icons.add),
                      label: const Text('添加'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '已配置 ${widget.stocks.length} 只',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: widget.stocks.isEmpty
              ? Center(
                  child: Text(
                    '暂无配置，请先添加股票',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.stocks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = widget.stocks[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.displayLabel),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeStock(item),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '向右滑动可返回披露信息',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
