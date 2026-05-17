import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/announcement.dart';
import '../models/stock_item.dart';
import '../services/sse_service.dart';
import '../services/stock_storage.dart';
import '../services/szse_service.dart';

class DisclosurePage extends StatefulWidget {
  const DisclosurePage({
    super.key,
    required this.market,
    required this.stocks,
  });

  final MarketType market;
  final List<StockItem> stocks;

  @override
  State<DisclosurePage> createState() => _DisclosurePageState();
}

class _DisclosurePageState extends State<DisclosurePage> {
  final _sseService = SseService();
  final _szseService = SzseService();

  StockItem? _selected;
  List<Announcement> _announcements = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSelection();
  }

  @override
  void didUpdateWidget(DisclosurePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stocks != widget.stocks) {
      _initSelection();
    }
  }

  void _initSelection() {
    if (widget.stocks.isEmpty) {
      setState(() {
        _selected = null;
        _announcements = [];
        _error = null;
      });
      return;
    }

    final currentCode = _selected?.code;
    final next = currentCode == null
        ? widget.stocks.first
        : widget.stocks.firstWhere(
            (s) => s.code == currentCode,
            orElse: () => widget.stocks.first,
          );

    if (_selected?.code != next.code) {
      setState(() => _selected = next);
      _loadAnnouncements();
    } else {
      setState(() => _selected = next);
    }
  }

  Future<void> _loadAnnouncements() async {
    final stock = _selected;
    if (stock == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = widget.market == MarketType.sse
          ? await _sseService.fetchAnnouncements(securityCode: stock.code)
          : await _szseService.fetchAnnouncements(stockCode: stock.code);

      if (!mounted) return;
      setState(() {
        _announcements = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _announcements = [];
      });
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开公告链接')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marketLabel = widget.market == MarketType.sse ? '沪股通' : '深股通';
    final sourceUrl = widget.market == MarketType.sse
        ? 'https://www.sse.com.cn/disclosure/listedinfo/announcement/'
        : 'https://www.szse.cn/disclosure/listed/notice/index.html';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '$marketLabel · 披露信息',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: widget.stocks.isEmpty
              ? InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '上市公司',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '请先在「代码配置」中添加股票',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : DropdownButtonFormField<StockItem>(
                  key: ValueKey(_selected?.code ?? 'none'),
                  initialValue: _selected,
                  decoration: const InputDecoration(
                    labelText: '上市公司',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.stocks
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selected = value);
                    _loadAnnouncements();
                  },
                ),
        ),
        if (_loading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: widget.stocks.isEmpty
              ? _buildEmptyHint(theme, sourceUrl)
              : _buildList(theme),
        ),
      ],
    );
  }

  Widget _buildEmptyHint(ThemeData theme, String sourceUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '请切换到「代码配置」添加股票代码',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '数据来源：$sourceUrl',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadAnnouncements,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_loading && _announcements.isEmpty) {
      return const Center(child: Text('近三个月暂无公告'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _announcements.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _announcements[index];
          return Card(
            child: InkWell(
              onTap: item.url.isEmpty ? null : () => _openUrl(item.url),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          item.date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        if (item.url.isNotEmpty)
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
