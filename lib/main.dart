import 'package:flutter/material.dart';
import 'services/news_service.dart';
import 'models/article.dart';

void main() => runApp(const NoticiasApp());

class NoticiasApp extends StatelessWidget {
  const NoticiasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noticias Seguras',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const NewsPage(),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _svc = NewsService();
  final _queryCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'mx');

  String _category = ''; // '' = Todas (sin categoría)
  bool _loading = false;
  String? _error;
  List<Article> _items = [];

  static const _categories = <String>[
    '', // Todas
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology',
  ];

  @override
  void dispose() {
    _queryCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
    });
    try {
      final res = await _svc.topHeadlines(
        country: _countryCtrl.text,
        q: _queryCtrl.text,
        category: _category.isEmpty ? null : _category,
      );
      setState(() => _items = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Sin datos. Prueba cambiar el país (ej. us, gb), '
            'seleccionar otra categoría o escribir una búsqueda (ej. tecnología).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final a = _items[i];
        final subtitle = [
          if (a.source.isNotEmpty) a.source,
          if ((a.description ?? '').isNotEmpty) a.description!,
        ].join(' · ');
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text(a.title),
            subtitle: Text(subtitle),
            onTap: (a.url == null || a.url!.isEmpty) ? null : () {},
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = const OutlineInputBorder();

    return Scaffold(
      appBar: AppBar(title: const Text('Noticias Seguras')),
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              // Usamos Wrap para que los controles bajen a segunda fila si no caben
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // País (ancho fijo pequeño)
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _countryCtrl,
                        decoration: InputDecoration(
                          labelText: 'País',
                          border: border,
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.none,
                      ),
                    ),

                    // Búsqueda (ancho flexible/grande)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        // que sea amplio en pantallas pequeñas
                        minWidth: isNarrow ? constraints.maxWidth - 32 : 240,
                        // y máximo razonable en grandes
                        maxWidth: 600,
                      ),
                      child: TextField(
                        controller: _queryCtrl,
                        decoration: InputDecoration(
                          labelText: 'Búsqueda (opcional)',
                          border: border,
                          isDense: true,
                          suffixIcon: (_queryCtrl.text.isEmpty)
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _queryCtrl.clear();
                                    setState(() {});
                                  },
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),

                    // Categoría (Dropdown con borde + botón de limpiar)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 170,
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Categoría',
                              border: border,
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem<String>(
                                      value: c,
                                      child: Text(c.isEmpty ? 'Todas' : c),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _category = v ?? ''),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Quitar categoría',
                          onPressed: _category.isEmpty
                              ? null
                              : () => setState(() => _category = ''),
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),

                    // Botón Cargar
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Cargar'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
