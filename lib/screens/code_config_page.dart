import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stock_item.dart';
import '../services/stock_storage.dart';
import '../widgets/stock_label.dart';

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

  String? _editingCode;
  HoldingStatus _holdingStatus = HoldingStatus.notHolding;

  bool get _isEditing => _editingCode != null;

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

  void _clearForm() {
    _editingCode = null;
    _codeController.clear();
    _nameController.clear();
    _holdingStatus = HoldingStatus.notHolding;
  }

  void _startEdit(StockItem item) {
    setState(() {
      _editingCode = item.code;
      _codeController.text = item.code;
      _nameController.text = item.name;
      _holdingStatus = item.holdingStatus;
    });
  }

  void _cancelEdit() {
    setState(_clearForm);
    FocusScope.of(context).unfocus();
  }

  bool _validateInput() {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();

    if (code.isEmpty || name.isEmpty) {
      _showMessage('请填写股票代码和公司名称');
      return false;
    }
    if (code.length != 6) {
      _showMessage('股票代码须为 6 位数字');
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_validateInput()) return;

    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final item = StockItem(
      code: code,
      name: name,
      holdingStatus: _holdingStatus,
    );

    if (_isEditing) {
      final updated = widget.stocks
          .map((s) => s.code == _editingCode ? item : s)
          .toList();
      _save(updated);
      _showMessage('已更新 $code');
    } else {
      if (widget.stocks.any((s) => s.code == code)) {
        _showMessage('该股票代码已存在');
        return;
      }
      _save([...widget.stocks, item]);
      _showMessage('已添加 $code');
    }

    setState(_clearForm);
    FocusScope.of(context).unfocus();
  }

  void _removeStock(StockItem item) {
    if (_editingCode == item.code) {
      _cancelEdit();
    }
    final updated = widget.stocks.where((s) => s.code != item.code).toList();
    _save(updated);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _buildHoldingRadios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '持仓状态',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        SegmentedButton<HoldingStatus>(
          segments: HoldingStatus.values
              .map(
                (status) => ButtonSegment<HoldingStatus>(
                  value: status,
                  label: Text(status.label),
                ),
              )
              .toList(),
          selected: {_holdingStatus},
          onSelectionChanged: (selected) {
            setState(() => _holdingStatus = selected.first);
          },
        ),
      ],
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '正在编辑：$_editingCode',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  TextField(
                    controller: _codeController,
                    enabled: !_isEditing,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyMedium,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: '股票代码',
                      hintText: '6 位数字',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: theme.textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: '公司名称',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildHoldingRadios(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_isEditing)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelEdit,
                            child: const Text('取消'),
                          ),
                        ),
                      if (_isEditing) const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: Icon(_isEditing ? Icons.save : Icons.add),
                          label: Text(_isEditing ? '保存修改' : '添加'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Text(
                '已配置代码',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.stocks.length} 只',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.stocks.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 12,
                          endIndent: 12,
                        ),
                        itemBuilder: (context, index) {
                          final item = widget.stocks[index];
                          final isActive = _editingCode == item.code;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (isActive)
                                  Container(
                                    width: 3,
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                Expanded(
                                  child: StockLabel(
                                    stock: item,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: '修改',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () => _startEdit(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: '删除',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () => _removeStock(item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
