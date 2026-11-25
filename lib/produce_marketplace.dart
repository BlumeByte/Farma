import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'farma_backend.dart';

class ProduceMarketplace {
  const ProduceMarketplace(this.accountId, this.accessToken);
  final String accountId;
  final String accessToken;

  Uri _endpoint(Map<String, String> query) =>
      Uri.parse('$farmaProjectUrl/rest/v1/produce_listings')
          .replace(queryParameters: query);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $accessToken',
    'apikey': farmaPublishableKey,
    'Content-Type': 'application/json',
  };

  Future<void> publish({
    required DateTime draftDate,
    required String title,
    required String category,
    required String description,
  }) async {
    final response = await http.post(
      _endpoint({'on_conflict': 'owner_id,draft_created_at'}),
      headers: {..._headers, 'Prefer': 'resolution=merge-duplicates'},
      body: jsonEncode({
        'owner_id': accountId,
        'draft_created_at': draftDate.toUtc().toIso8601String(),
        'title': title,
        'category': category,
        'description': description,
        'published': true,
        'published_at': DateTime.now().toUtc().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 12));
    _check(response);
  }

  Future<bool> withdraw(DateTime draftDate) async {
    final response = await http.patch(
      _endpoint({
        'owner_id': 'eq.$accountId',
        'draft_created_at': 'eq.${draftDate.toUtc().toIso8601String()}',
        'published': 'eq.true',
        'select': 'draft_created_at',
      }),
      headers: {..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode({'published': false}),
    ).timeout(const Duration(seconds: 12));
    _check(response);
    return (jsonDecode(response.body) as List).isNotEmpty;
  }

  Future<List<ProduceListing>> browse() async {
    final response = await http.get(
      _endpoint({
        'published': 'eq.true',
        'select': 'title,category,description',
        'order': 'published_at.desc',
        'limit': '100',
      }),
      headers: _headers,
    ).timeout(const Duration(seconds: 12));
    _check(response);
    return (jsonDecode(response.body) as List).map((item) {
      final row = item as Map<String, dynamic>;
      return ProduceListing(
        title: row['title'] as String,
        category: row['category'] as String,
        description: row['description'] as String,
      );
    }).toList();
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Marketplace request failed');
    }
  }
}

class ProduceListing {
  const ProduceListing({
    required this.title,
    required this.category,
    required this.description,
  });
  final String title;
  final String category;
  final String description;
}

class ProduceBrowse extends StatefulWidget {
  const ProduceBrowse({required this.marketplace, super.key});
  final ProduceMarketplace marketplace;

  @override
  State<ProduceBrowse> createState() => _ProduceBrowseState();
}

class _ProduceBrowseState extends State<ProduceBrowse> {
  late Future<List<ProduceListing>> _items = widget.marketplace.browse();
  String _search = '';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        decoration: const InputDecoration(
          labelText: 'Search latest produce listings',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton.icon(
          onPressed: () => setState(() => _items = widget.marketplace.browse()),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ),
      FutureBuilder<List<ProduceListing>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return LinearProgressIndicator(semanticsLabel: 'Loading produce');
          }
          if (snapshot.hasError) {
            return const Semantics(
              liveRegion: true,
              child: Text('Could not load produce. Sign in again or try Refresh.'),
            );
          }
          final items = snapshot.data ?? const <ProduceListing>[];
          final visible = items.where((item) =>
              item.title.toLowerCase().contains(_search) ||
              item.category.toLowerCase().contains(_search));
          if (visible.isEmpty) {
            return Text(items.isEmpty
                ? 'No produce has been published yet.'
                : 'No matching produce found.');
          }
          return Column(
            children: [
              for (final item in visible)
                Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.category),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(item.title),
                        scrollable: true,
                        content: Text(item.description.isEmpty
                            ? item.category
                            : '${item.category}\n\n${item.description}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
