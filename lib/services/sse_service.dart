import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/announcement.dart';

class SseService {
  static const _baseUrl = 'https://query.sse.com.cn';
  static const _staticBase = 'https://static.sse.com.cn';

  Future<List<Announcement>> fetchAnnouncements({
    required String securityCode,
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
        'SECURITY_CODE': securityCode,
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
    final result = data['result'] as List<dynamic>? ??
        (data['pageHelp'] as Map<String, dynamic>?)?['data'] as List<dynamic>? ??
        [];

    return result.map((item) {
      final map = item as Map<String, dynamic>;
      final path = map['URL'] as String? ?? '';
      final fullUrl = path.startsWith('http')
          ? path
          : '$_staticBase$path';
      return Announcement(
        code: map['SECURITY_CODE'] as String? ?? securityCode,
        companyName: map['SECURITY_NAME'] as String? ?? '',
        title: map['TITLE'] as String? ?? '',
        date: map['SSEDATE'] as String? ?? '',
        url: fullUrl,
      );
    }).toList();
  }
}
