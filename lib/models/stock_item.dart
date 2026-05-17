class StockItem {
  const StockItem({required this.code, required this.name});

  final String code;
  final String name;

  String get displayLabel => '$code $name';

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
