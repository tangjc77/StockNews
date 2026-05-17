import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/announcement.dart';
import '../models/stock_item.dart';
import '../services/sse_service.dart';
import '../widgets/stock_label.dart';
import '../services/stock_storage.dart';
import '../services/szse_service.dart';

const _defaultPageSize = 10;
const _refreshInterval = Duration(seconds: 5);

class DisclosurePage extends StatefulWidget {
  const DisclosurePage({
    super.key,
    required this.market,
    required this.stocks,
    this.autoRefresh = true,
  });

  final MarketType market;
  final List<StockItem> stocks;
  final bool autoRefresh;

  @override
  State<DisclosurePage> createState() => _DisclosurePageState();
}

class _DisclosurePageState extends State<DisclosurePage> {
  final _sseService = SseService();
  final _szseService = SzseService();

  /// null 表示「全部（最新10条）」。
  String? _selectedCode;
  List<Announcement> _announcements = [];
  bool _loading = false;
  bool _initialLoaded = false;
  String? _error;
  Timer? _refreshTimer;

  bool get _isAllStocks => _selectedCode == null;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements(showLoading: true);
    _startAutoRefresh();
  }

  @override
  void didUpdateWidget(DisclosurePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoRefresh != widget.autoRefresh) {
      if (widget.autoRefresh) {
        _startAutoRefresh();
      } else {
        _stopAutoRefresh();
      }
    }
    if (oldWidget.stocks != widget.stocks &&
        _selectedCode != null &&
        !widget.stocks.any((s) => s.code == _selectedCode)) {
      setState(() => _selectedCode = null);
      _loadAnnouncements(showLoading: true);
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    if (!widget.autoRefresh) return;
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _loadAnnouncements(showLoading: false);
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _loadAnnouncements({required bool showLoading}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final list = widget.market == MarketType.sse
          ? await _sseService.fetchAnnouncements(
              securityCode: _selectedCode,
              pageSize: _defaultPageSize,
            )
          : await _szseService.fetchAnnouncements(
              stockCode: _selectedCode,
              pageSize: _defaultPageSize,
            );

      if (!mounted) return;
      setState(() {
        _announcements = list;
        _loading = false;
        _initialLoaded = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (showLoading || !_initialLoaded) {
          _error = e.toString();
          _announcements = [];
        }
        _loading = false;
        _initialLoaded = true;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$marketLabel · 披露信息',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (widget.autoRefresh)
                Text(
                  '每 5 秒刷新',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '上市公司',
              border: const OutlineInputBorder(),
              helperText:
                  _isAllStocks ? '当前显示全市场最新 $_defaultPageSize 条' : null,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _selectedCode != null &&
                        widget.stocks.any((s) => s.code == _selectedCode)
                    ? _selectedCode
                    : null,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('全部（最新10条）'),
                  ),
                  ...widget.stocks.map(
                    (s) => DropdownMenuItem<String?>(
                      value: s.code,
                      child: StockLabel(stock: s),
                    ),
                  ),
                ],
                onChanged: (code) {
                  setState(() => _selectedCode = code);
                  _loadAnnouncements(showLoading: true);
                },
              ),
            ),
          ),
        ),
        if (_loading && !_initialLoaded)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildList(theme)),
      ],
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_error != null && _announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadAnnouncements(showLoading: true),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading && !_initialLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcements.isEmpty) {
      return Center(
        child: _loading
            ? const CircularProgressIndicator()
            : const Text('暂无公告'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAnnouncements(showLoading: true),
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
                    if (item.code.isNotEmpty || item.companyName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${item.code} ${item.companyName}'.trim(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
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
