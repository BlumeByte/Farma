import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'farma_app.dart';
import 'farma_backend.dart';

part 'district_operations.dart';

typedef _Row = Map<String, dynamic>;

class FieldRecords {
  const FieldRecords(this.accountId, this.accessToken);

  final String accountId;
  final String accessToken;

  Future<List<_Row>> _request(
    String method,
    String table,
    Map<String, String> query, {
    _Row? data,
    String? prefer,
  }) async {
    final uri = Uri.parse('$farmaProjectUrl/rest/v1/$table').replace(queryParameters: query);
    final headers = {
      'apikey': farmaPublishableKey,
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Prefer': ?prefer,
    };
    final response = await (switch (method) {
      'POST' => http.post(uri, headers: headers, body: jsonEncode(data)),
      'PATCH' => http.patch(uri, headers: headers, body: jsonEncode(data)),
      'DELETE' => http.delete(uri, headers: headers),
      _ => http.get(uri, headers: headers),
    }).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Field records request failed');
    }
    if (response.body.isEmpty) return [];
    final payload = jsonDecode(response.body);
    return payload == null ? [] : (payload as List).cast<_Row>();
  }

  Future<void> save(FieldEntry entry) async {
    final photo = entry.photo;
    await _request(
      'POST',
      'cloud_observations',
      {'on_conflict': 'owner_id,observed_at'},
      data: {
        'owner_id': accountId,
        'observed_at': entry.date.toUtc().toIso8601String(),
        'title': entry.title,
        'category': entry.category,
        'notes': entry.notes,
        'photo_base64': photo == null ? null : base64Encode(photo),
        'photo_description': photo == null ? null : entry.photoDescription,
      },
      prefer: 'resolution=merge-duplicates',
    );
  }
}

class FieldRecordsScreen extends StatefulWidget {
  const FieldRecordsScreen({required this.service, super.key});
  final FieldRecords service;

  @override
  State<FieldRecordsScreen> createState() => _FieldRecordsScreenState();
}

class _FieldRecordsScreenState extends State<FieldRecordsScreen> {
  late var _data = _load();

  Future<({List<_Row> records, List<_Row> reviews, List<_Row> officers, String? district})> _load() async {
    final service = widget.service;
    final results = await Future.wait([
      service._request('GET', 'cloud_observations', {
        'owner_id': 'eq.${service.accountId}',
        'select': 'owner_id,observed_at,title,category',
        'order': 'observed_at.desc',
        'limit': '100',
      }),
      service._request('GET', 'observation_reviews', {
        'select': 'id,farmer_id,observation_date,officer_id,follow_up,field_officers(display_name),cloud_observations(title)',
        'order': 'requested_at.desc',
        'limit': '100',
      }),
      service._request('GET', 'field_officers', {'select': 'id,display_name,district', 'active': 'eq.true', 'order': 'display_name'}),
      service._request('GET', 'district_managers', {
        'account_id': 'eq.${service.accountId}',
        'select': 'district',
      }),
    ]);
    return (
      records: results[0],
      reviews: results[1],
      officers: results[2],
      district: results[3].firstOrNull?['district'] as String?,
    );
  }

  void _refresh() => setState(() => _data = _load());

  Future<void> _change(Future<List<_Row>> Function() operation, String success) async {
    String message;
    try {
      final rows = await operation();
      message = rows.isEmpty ? 'No change was made. Refresh and try again.' : success;
    } catch (_) {
      message = 'Could not update field records. Check your connection and try again.';
    }
    if (!mounted) return;
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(_Row row, {String? reviewId}) async {
    final owner = row['owner_id'] ?? row['farmer_id'];
    final date = row['observed_at'] ?? row['observation_date'];
    final record = widget.service._request('GET', 'cloud_observations', {
      'owner_id': 'eq.$owner',
      'observed_at': 'eq.$date',
      'select': 'title,category,notes,photo_base64,photo_description',
    });
    final reply = await showDialog<String>(
      context: context,
      builder: (_) => _RecordDetails(record: record, canReply: reviewId != null),
    );
    if (!mounted || reviewId == null || reply == null) return;
    await _change(() => widget.service._request(
      'PATCH', 'observation_reviews', {'id': 'eq.$reviewId', 'follow_up': 'is.null', 'select': 'id'},
      data: {'follow_up': reply},
      prefer: 'return=representation',
    ), 'Review sent.');
  }

  Future<void> _share(_Row row, List<_Row> officers) async {
    if (officers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No approved field officers are available.')),
      );
      return;
    }
    final officer = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Share this record with an officer'),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('The officer can see the online record, including its notes, photo, and later updates until you withdraw access.'),
          ),
          for (final officer in officers)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, officer['id']),
              child: Text('${officer['display_name']} · ${officer['district']}'),
            ),
        ],
      ),
    );
    if (!mounted || officer == null) return;
    await _change(() => widget.service._request(
      'POST', 'observation_reviews', {'on_conflict': 'farmer_id,observation_date,officer_id'},
      data: {'observation_date': row['observed_at'], 'officer_id': officer},
      prefer: 'resolution=ignore-duplicates,return=representation',
    ), 'Record shared for review.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Online field records'),
      actions: [
        IconButton(onPressed: _refresh, tooltip: 'Refresh records', icon: const Icon(Icons.refresh)),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading field records'));
              }
              if (snapshot.hasError) return const Center(child: Text('Could not load field records. Try Refresh.'));
              final data = snapshot.data!;
              final owner = widget.service.accountId;
              final assigned = data.reviews.where((row) => row['officer_id'] == owner);
              final sent = data.reviews.where((row) => row['farmer_id'] == owner);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (data.district case final district?)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => _DistrictOperations(
                              service: widget.service,
                              district: district,
                            ),
                          ),
                        );
                        if (mounted) _refresh();
                      },
                      icon: const Icon(Icons.manage_accounts_outlined),
                      label: const Text('District operations'),
                    ),
                  const Text('My online observations'),
                  if (data.records.isEmpty) const Text('Open a local observation and choose Save online to see it here.'),
                  for (final record in data.records)
                    ListTile(
                      title: Text(record['title'] as String),
                      subtitle: Text(record['category'] as String),
                      onTap: () => _open(record),
                      trailing: IconButton(
                        tooltip: 'Share ${record['title']} for review',
                        icon: const Icon(Icons.person_add_outlined),
                        onPressed: () => _share(record, data.officers.where((row) => row['id'] != owner).toList()),
                      ),
                    ),
                  const Divider(),
                  const Text('Reviews I requested'),
                  if (sent.isEmpty) const Text('No review requests.'),
                  for (final review in sent)
                    ListTile(
                      title: Text(review['cloud_observations']?['title'] as String? ?? 'Field observation'),
                      subtitle: Text(
                        '${review['field_officers']?['display_name'] ?? 'Field officer'}'
                        ' · ${review['follow_up'] ?? 'Awaiting review'}',
                      ),
                      onTap: () => _open(review),
                      trailing: IconButton(
                        tooltip: 'Withdraw review and remove access',
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () => _change(
                          () => widget.service._request(
                            'DELETE', 'observation_reviews',
                            {'id': 'eq.${review['id']}', 'select': 'id'},
                            prefer: 'return=representation',
                          ),
                          'Review withdrawn and access removed.',
                        ),
                      ),
                    ),
                  if (data.officers.any((row) => row['id'] == owner)) ...[
                    const Divider(),
                    const Text('Assigned field reviews'),
                    if (assigned.isEmpty) const Text('No records assigned for review.'),
                    for (final review in assigned)
                      ListTile(
                        title: Text(review['cloud_observations']?['title'] as String? ?? 'Field observation'),
                        subtitle: Text(review['follow_up'] as String? ?? 'Open the observation to respond.'),
                        onTap: () => _open(review, reviewId: review['follow_up'] == null ? review['id'] as String : null),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _RecordDetails extends StatefulWidget {
  const _RecordDetails({required this.record, required this.canReply});
  final Future<List<_Row>> record;
  final bool canReply;

  @override
  State<_RecordDetails> createState() => _RecordDetailsState();
}

class _RecordDetailsState extends State<_RecordDetails> {
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: widget.record,
    builder: (context, snapshot) {
      final record = snapshot.data?.firstOrNull;
      final photo = record?['photo_base64'] as String?;
      return AlertDialog(
        title: Text(record?['title'] as String? ?? 'Field observation'),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: record == null
              ? snapshot.connectionState != ConnectionState.done
                  ? const LinearProgressIndicator(semanticsLabel: 'Loading observation')
                  : const Text('This observation is unavailable.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(record['category'] as String),
                    Text(record['notes'] as String),
                    if (photo != null)
                      Image.memory(
                        base64Decode(photo),
                        height: 200,
                        fit: BoxFit.contain,
                        semanticLabel: record['photo_description'] as String? ?? 'Observation photo',
                        errorBuilder: (_, _, _) => const Text('Photo could not be displayed.'),
                      ),
                    if (widget.canReply)
                      TextField(
                        controller: _reply,
                        onChanged: (_) => setState(() {}),
                        maxLength: 1000,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Follow-up for the farmer'),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (widget.canReply && record != null)
            FilledButton(
              onPressed: _reply.text.trim().isEmpty ? null : () => Navigator.pop(context, _reply.text.trim()),
              child: const Text('Send follow-up'),
            ),
        ],
      );
    },
  );
}
