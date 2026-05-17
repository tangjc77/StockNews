import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/announcement.dart';

class SseService {
  static const _baseUrl = 'https://query.sse.com.cn';
  static const _staticBase = 'https://static.sse.com.cn';

  /// [securityCode] 为空时返回全市场最新公告（默认近 3 个月）。
  Future<List<Announcement>> fetchAnnouncements({
    String? securityCode,
    int pageNo = 1,
    int pageSize = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 90));
    final fmt = DateFormat('yyyy-MM-dd');

    final uri = Uri.parse('$_baseUrl/security/stock/queryCompanyBulletinNew.do')
        .replace(
      queryParameters: {
        'isPagination': 'true',
        'pageHelp.pageSize': '$pageSize',
        'pageHelp.pageNo': '$pageNo',
        'pageHelp.cacheSize': '1',
        'START_DATE': fmt.format(start),
        'END_DATE': fmt.format(end),
        'SECURITY_CODE': securityCode ?? '',
        'reportType': 'ALL',
        'stockType': '',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Referer':
            'https://www.sse.com.cn/disclosure/listedinfo/announcement/',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('上交所数据请求失败 (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['result'] ?? (data['pageHelp'] as Map<String, dynamic>?)?['data'];

    return _parseAnnouncementRows(raw, securityCode, limit: pageSize);
  }

  /// 上交所返回的 result 为 `[[{主公告},...], ...]`，每组取第一条作为主公告。
  List<Announcement> _parseAnnouncementRows(
    dynamic raw,
    String? securityCode, {
    int? limit,
  }) {
    final maps = <Map<String, dynamic>>[];

    if (raw is List) {
      for (final group in raw) {
        if (group is List && group.isNotEmpty) {
          final first = group.first;
          if (first is Map) {
            maps.add(Map<String, dynamic>.from(first));
          }
        } else if (group is Map) {
          maps.add(Map<String, dynamic>.from(group));
        }
      }
    }

    final capped = limit != null && maps.length > limit
        ? maps.sublist(0, limit)
        : maps;

    return capped.map((map) {
      final path = map['URL'] as String? ?? '';
      final fullUrl =
          path.startsWith('http') ? path : '$_staticBase$path';
      return Announcement(
        code: map['SECURITY_CODE'] as String? ?? securityCode ?? '',
        companyName: map['SECURITY_NAME'] as String? ?? '',
        title: map['TITLE'] as String? ?? '',
        date: map['SSEDATE'] as String? ?? '',
        url: fullUrl,
      );
    }).toList();
  }
}
