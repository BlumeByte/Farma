import 'dart:convert';
import 'dart:typed_data';

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
    Uint8List? photo,
    String? photoDescription,
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
        'photo_base64': photo == null ? null : base64Encode(photo),
        'photo_description': photo == null ? null : photoDescription,
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
      body: jsonEncode({
        'published': false,
        'photo_base64': null,
        'photo_description': null,
      }),
    ).timeout(const Duration(seconds: 12));
    _check(response);
    return (jsonDecode(response.body) as List).isNotEmpty;
  }

  Future<List<ProduceListing>> browse() async {
    final response = await http.get(
      _endpoint({
        'published': 'eq.true',
        'select': 'owner_id,draft_created_at,title,category,description,photo_description',
        'order': 'published_at.desc',
        'limit': '100',
      }),
      headers: _headers,
    ).timeout(const Duration(seconds: 12));
    _check(response);
    return _listings(response);
  }

  Future<ProduceListing?> open(ProduceListing item) async {
    final response = await http.get(
      _endpoint({
        'owner_id': 'eq.${item.ownerId}',
        'draft_created_at': 'eq.${item.draftCreatedAt}',
        'published': 'eq.true',
        'select': 'owner_id,draft_created_at,title,category,description,photo_description,photo_base64',
      }),
      headers: _headers,
    ).timeout(const Duration(seconds: 12));
    _check(response);
    return _listings(response).firstOrNull;
  }

  List<ProduceListing> _listings(http.Response response) =>
      (jsonDecode(response.body) as List)
          .map((item) => ProduceListing.fromJson(item as Map<String, dynamic>))
          .toList();

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Marketplace request failed');
    }
  }
}

class ProduceListing {
  const ProduceListing({
    required this.ownerId,
    required this.draftCreatedAt,
    required this.title,
    required this.category,
    required this.description,
    this.photo,
    this.photoDescription,
  });

  factory ProduceListing.fromJson(Map<String, dynamic> row) {
    final photo = row['photo_base64'] as String?;
    return ProduceListing(
      ownerId: row['owner_id'] as String,
      draftCreatedAt: row['draft_created_at'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      description: row['description'] as String,
      photoDescription: row['photo_description'] as String?,
      photo: photo == null ? null : base64Decode(photo),
    );
  }

  final String ownerId;
  final String draftCreatedAt;
  final String title;
  final String category;
  final String description;
  final Uint8List? photo;
  final String? photoDescription;
}

class ProduceListingDetails extends StatelessWidget {
  const ProduceListingDetails({
    required this.title,
    required this.category,
    required this.description,
    this.photo,
    this.photoDescription,
    super.key,
  });

  final String title;
  final String category;
  final String description;
  final Uint8List? photo;
  final String? photoDescription;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      Text(category),
      if (photo != null) ...[
        const SizedBox(height: 12),
        Image.memory(
          photo!,
          height: 180,
          fit: BoxFit.contain,
          semanticLabel: photoDescription ?? 'Photo of $title',
          errorBuilder: (_, _, _) => const Text('Photo could not be displayed.'),
        ),
      ],
      if (description.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(description),
      ],
    ],
  );
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
            return const LinearProgressIndicator(semanticsLabel: 'Loading produce');
          }
          if (snapshot.hasError) {
            return Semantics(
              liveRegion: true,
              child: const Text('Could not load produce. Sign in again or try Refresh.'),
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
                    subtitle: Text(item.photoDescription == null
                        ? item.category
                        : '${item.category} · Photo available'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final details = widget.marketplace.open(item);
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Produce listing'),
                          scrollable: true,
                          content: SizedBox(
                            width: 420,
                            child: FutureBuilder<ProduceListing?>(
                              future: details,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState != ConnectionState.done) {
                                  return const LinearProgressIndicator(
                                    semanticsLabel: 'Loading listing',
                                  );
                                }
                                if (snapshot.hasError) {
                                  return const Text('Could not open the listing. Try again.');
                                }
                                final listing = snapshot.data;
                                if (listing == null) {
                                  return const Text('This listing is no longer available.');
                                }
                                return ProduceListingDetails(
                                  title: listing.title,
                                  category: listing.category,
                                  description: listing.description,
                                  photo: listing.photo,
                                  photoDescription: listing.photoDescription,
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
