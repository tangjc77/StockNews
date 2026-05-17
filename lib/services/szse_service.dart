import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/announcement.dart';

class SzseService {
  static const _baseUrl = 'https://www.szse.cn/api/disc/announcement/annList';
  static const _downloadBase = 'https://disc.static.szse.cn/download';

  Future<List<Announcement>> fetchAnnouncements({
    required String stockCode,
    int pageNum = 1,
    int pageSize = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 90));
    final fmt = DateFormat('yyyy-MM-dd');

    final uri = Uri.parse(
      '$_baseUrl?random=${Random().nextDouble()}',
    );

    final body = jsonEncode({
      'seDate': [fmt.format(start), fmt.format(end)],
      'stock': [stockCode],
      'channelCode': ['listedNotice_disc'],
      'pageSize': pageSize,
      'pageNum': pageNum,
    });

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json;charset=UTF-8',
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Referer': 'https://www.szse.cn/disclosure/listed/notice/index.html',
        'Origin': 'https://www.szse.cn',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('深交所数据请求失败 (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];

    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final codes = map['secCode'] as List<dynamic>? ?? [];
      final names = map['secName'] as List<dynamic>? ?? [];
      final attachPath = map['attachPath'] as String? ?? '';
      final publishTime = map['publishTime'] as String? ?? '';
      final date = publishTime.length >= 10
          ? publishTime.substring(0, 10)
          : publishTime;

      return Announcement(
        code: codes.isNotEmpty ? codes.first.toString() : stockCode,
        companyName: names.isNotEmpty ? names.first.toString() : '',
        title: map['title'] as String? ?? '',
        date: date,
        url: attachPath.isEmpty
            ? ''
            : '$_downloadBase$attachPath',
      );
    }).toList();
  }
}
