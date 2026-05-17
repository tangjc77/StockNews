import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum HoldingStatus {
  holding,
  notHolding,
}

extension HoldingStatusStyle on HoldingStatus {
  String get label => this == HoldingStatus.holding ? '持仓' : '未持仓';

  Color get color => this == HoldingStatus.holding
      ? AppTheme.holdingRed
      : AppTheme.notHoldingBlack;
}

class StockItem {
  const StockItem({
    required this.code,
    required this.name,
    this.holdingStatus = HoldingStatus.notHolding,
  });

  final String code;
  final String name;
  final HoldingStatus holdingStatus;

  String get displayLabel => '$code $name · ${holdingStatus.label}';

  StockItem copyWith({
    String? code,
    String? name,
    HoldingStatus? holdingStatus,
  }) {
    return StockItem(
      code: code ?? this.code,
      name: name ?? this.name,
      holdingStatus: holdingStatus ?? this.holdingStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'holdingStatus': holdingStatus.name,
      };

  factory StockItem.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['holdingStatus'] as String?;
    HoldingStatus status = HoldingStatus.notHolding;
    if (statusRaw == HoldingStatus.holding.name) {
      status = HoldingStatus.holding;
    }
    return StockItem(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      holdingStatus: status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockItem &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          name == other.name &&
          holdingStatus == other.holdingStatus;

  @override
  int get hashCode => Object.hash(code, name, holdingStatus);
}
