import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import '../env.dart';
import '../models/article.dart';

class NewsService {
  // Categorías permitidas por top-headlines
  static const allowedCategories = <String>{
    'business',
    'entertainment',
    'general',
    'health',
    'science',
    'sports',
    'technology',
  };

  List<Article>? _cache;
  DateTime? _cacheAt;

  bool _fresh() =>
      _cache != null &&
      _cacheAt != null &&
      DateTime.now().difference(_cacheAt!) < const Duration(minutes: 5);

  String _sanitizeCountry(String input) {
    final cleaned = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return cleaned.length >= 2 ? cleaned.substring(0, 2) : '';
  }

  String? _sanitizeCategory(String? cat) {
    if (cat == null || cat.trim().isEmpty) return null;
    final c = cat.toLowerCase().trim();
    return allowedCategories.contains(c) ? c : null;
  }

  String _sanitizeQuery(String input) {
    final s = input.replaceAll(RegExp(r"[^a-zA-Z0-9À-ÿ\s,\.\-]"), "");
    return s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<List<Article>> topHeadlines({
    String country = 'mx',
    String? q,
    String? category, // <- nuevo
  }) async {
    final c = _sanitizeCountry(country);
    if (c.isEmpty) throw const FormatException('País inválido');

    final cat = _sanitizeCategory(category);

    // Cache defensiva (solo titulares sin query ni categoría)
    final onlyTop = (q == null || q.isEmpty) && (cat == null);
    if (_fresh() && onlyTop) return _cache!;

    // Parámetros de titulares
    final params = <String, String>{
      'country': c,
      'pageSize': '20',
      if (q != null && q.trim().isNotEmpty) 'q': _sanitizeQuery(q),
      if (cat != null) 'category': cat,
    };
    final uri = Uri.https('newsapi.org', '/v2/top-headlines', params);

    final r = RetryOptions(
      maxAttempts: 3,
      delayFactor: const Duration(milliseconds: 500),
      maxDelay: const Duration(seconds: 3),
    );

    http.Response resp;
    try {
      resp = await r.retry(
        () => http
            .get(uri, headers: {'X-Api-Key': Env.newsApiKey})
            .timeout(const Duration(seconds: 8)),
        retryIf: (e) =>
            e is SocketException ||
            e is TimeoutException ||
            e is http.ClientException,
      );
    } on http.ClientException catch (e) {
      throw HttpException('Fallo de red/cliente: ${e.message}');
    }

    // ignore: avoid_print
    print('[TopHeadlines] status=${resp.statusCode} params=$params');

    if (resp.statusCode == 200) {
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      if (map['status'] != 'ok') {
        final msg = (map['message'] ?? 'Respuesta inválida').toString();
        throw HttpException('NewsAPI: $msg');
      }

      final List items = (map['articles'] as List?) ?? [];
      if (items.isNotEmpty) {
        final articles =
            items.map((e) => Article.fromJson(e)).toList().cast<Article>();
        if (onlyTop) {
          _cache = articles;
          _cacheAt = DateTime.now();
        }
        return articles;
      }

      // —— Fallbacks:
      // 1) Si HAY búsqueda, probar /v2/everything con esa búsqueda
      if (q != null && q.trim().isNotEmpty) {
        final alt = await searchEverything(q);
        if (alt.isNotEmpty) return alt;
      }

      // 2) Si NO hay búsqueda (solo país/categoría), intenta un término neutro
      //    útil para MX cuando top-headlines regresa vacío
      final neutral = (c == 'mx') ? 'México' : null;
      if (neutral != null) {
        final alt = await searchEverything(neutral);
        if (alt.isNotEmpty) return alt;
      }

      return <Article>[];
    }

    if (resp.statusCode == 401) {
      throw const HttpException('API key inválida o ausente (401)');
    } else if (resp.statusCode == 429) {
      throw const HttpException('Rate limit excedido (429). Intenta más tarde.');
    } else if (resp.statusCode == 400) {
      throw HttpException('Petición inválida (400): ${resp.body}');
    } else if (resp.statusCode >= 500) {
      throw HttpException('Error del servidor (${resp.statusCode})');
    } else {
      throw HttpException('Error inesperado (${resp.statusCode})');
    }
  }

  Future<List<Article>> searchEverything(String q) async {
    final query = _sanitizeQuery(q);
    if (query.isEmpty) return <Article>[];

    final uri = Uri.https('newsapi.org', '/v2/everything', {
      'q': query,
      'language': 'es', // prioriza español
      'sortBy': 'publishedAt',
      'pageSize': '20',
    });

    final resp = await http
        .get(uri, headers: {'X-Api-Key': Env.newsApiKey})
        .timeout(const Duration(seconds: 8));

    // ignore: avoid_print
    print('[Everything] status=${resp.statusCode} q="$query"');

    if (resp.statusCode != 200) {
      throw HttpException('Everything error (${resp.statusCode})');
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    if (map['status'] != 'ok') {
      final msg = (map['message'] ?? 'Respuesta inválida').toString();
      throw HttpException('Everything: $msg');
    }
    final List items = (map['articles'] as List?) ?? [];
    return items.map((e) => Article.fromJson(e)).toList().cast<Article>();
  }
}
