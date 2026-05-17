import 'package:flutter/material.dart';

import '../models/stock_item.dart';

/// 股票代码 + 名称 + 持仓状态（持仓红色，未持仓黑色）
class StockLabel extends StatelessWidget {
  const StockLabel({
    super.key,
    required this.stock,
    this.style,
    this.maxLines = 1,
  });

  final StockItem stock;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 14);

    return Text.rich(
      TextSpan(
        style: baseStyle.copyWith(color: baseStyle.color ?? Colors.black87),
        children: [
          TextSpan(text: '${stock.code} ${stock.name} · '),
          TextSpan(
            text: stock.holdingStatus.label,
            style: baseStyle.copyWith(
              color: stock.holdingStatus.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
