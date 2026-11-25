part of 'produce_marketplace.dart';

const _enquiryTopics = ['Availability', 'Quantity', 'Pickup'];

typedef _SellerProfile = ({String name, String area});

class _SellerEnquiries {
  const _SellerEnquiries(this.marketplace);
  final ProduceMarketplace marketplace;

  Uri _endpoint(String table, Map<String, String> query) =>
      Uri.parse('$farmaProjectUrl/rest/v1/$table').replace(queryParameters: query);

  Future<List<Map<String, dynamic>>> _read(String table, Map<String, String> query) async {
    final response = await http.get(
      _endpoint(table, query),
      headers: marketplace._headers,
    ).timeout(const Duration(seconds: 12));
    marketplace._check(response);
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<_SellerProfile?> profile(String sellerId) async {
    final rows = await _read('seller_profiles', {
      'owner_id': 'eq.$sellerId',
      'select': 'display_name,area',
    });
    final row = rows.firstOrNull;
    return row == null
        ? null
        : (name: row['display_name'] as String, area: row['area'] as String);
  }

  Future<void> saveProfile(_SellerProfile profile) async {
    final response = await http.post(
      _endpoint('seller_profiles', {'on_conflict': 'owner_id'}),
      headers: {...marketplace._headers, 'Prefer': 'resolution=merge-duplicates'},
      body: jsonEncode({
        'owner_id': marketplace.accountId,
        'display_name': profile.name,
        'area': profile.area,
      }),
    ).timeout(const Duration(seconds: 12));
    marketplace._check(response);
  }

  Future<bool> ask(ProduceListing listing, String topic, String message) async {
    final response = await http.post(
      _endpoint('produce_enquiries', {}),
      headers: marketplace._headers,
      body: jsonEncode({
        'seller_id': listing.ownerId,
        'listing_date': listing.draftCreatedAt,
        'topic': topic,
        'question': message,
      }),
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode == 409 &&
        (jsonDecode(response.body) as Map)['code'] == '23505') {
      return false;
    }
    marketplace._check(response);
    return true;
  }

  Future<List<Map<String, dynamic>>> inbox({required bool incoming}) =>
      _read('produce_enquiries', {
        (incoming ? 'seller_id' : 'buyer_id'): 'eq.${marketplace.accountId}',
        'select': 'id,topic,question,reply,produce_listings(title)',
        'order': 'created_at.desc,id.desc',
      });

  Future<bool> reply(String id, String message) async {
    final response = await http.patch(
      _endpoint('produce_enquiries', {'id': 'eq.$id', 'reply': 'is.null', 'select': 'id'}),
      headers: {...marketplace._headers, 'Prefer': 'return=representation'},
      body: jsonEncode({'reply': message}),
    ).timeout(const Duration(seconds: 12));
    marketplace._check(response);
    return (jsonDecode(response.body) as List).isNotEmpty;
  }
}

Future<void> openMarketplaceTools(
  BuildContext context,
  ProduceMarketplace marketplace, {
  bool sellerTools = false,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => _MarketplaceTools(
      service: _SellerEnquiries(marketplace),
      sellerTools: sellerTools,
    ),
  ),
);

class _SellerListingActions extends StatelessWidget {
  const _SellerListingActions({required this.marketplace, required this.listing});
  final ProduceMarketplace marketplace;
  final ProduceListing listing;

  @override
  Widget build(BuildContext context) {
    final service = _SellerEnquiries(marketplace);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () {
              final details = Future.wait([
                service.profile(listing.ownerId),
                marketplace.browse(sellerId: listing.ownerId),
              ]);
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Seller profile'),
                  scrollable: true,
                  content: SizedBox(
                    width: 420,
                    child: FutureBuilder<List<Object?>>(
                      future: details,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const LinearProgressIndicator(semanticsLabel: 'Loading seller');
                        }
                        if (snapshot.hasError) return const Text('Could not load this seller.');
                        final profile = snapshot.data![0] as _SellerProfile?;
                        final listings = snapshot.data![1] as List<ProduceListing>;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile?.name ?? 'Farma seller',
                              style: Theme.of(context).textTheme.titleLarge),
                            if (profile != null) Text(profile.area),
                            const SizedBox(height: 16),
                            const Text('Active listings'),
                            if (listings.isEmpty) const Text('No active listings.'),
                            for (final item in listings)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('${item.title} · ${item.category}'),
                              ),
                          ],
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
            child: const Text('Seller profile'),
          ),
          if (listing.ownerId != marketplace.accountId)
            FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _EnquiryDialog(
                  title: 'Ask about ${listing.title}',
                  onSend: (topic, message) => service.ask(listing, topic!, message),
                ),
              ),
              child: const Text('Ask seller'),
            ),
        ],
      ),
    );
  }
}

class _MarketplaceTools extends StatefulWidget {
  const _MarketplaceTools({required this.service, required this.sellerTools});
  final _SellerEnquiries service;
  final bool sellerTools;

  @override
  State<_MarketplaceTools> createState() => _MarketplaceToolsState();
}

class _MarketplaceToolsState extends State<_MarketplaceTools> {
  late Future<List<Map<String, dynamic>>> _inbox =
      widget.service.inbox(incoming: widget.sellerTools);

  void _refresh() => setState(() {
    _inbox = widget.service.inbox(incoming: widget.sellerTools);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.sellerTools ? 'Seller tools' : 'My enquiries'),
      actions: [
        IconButton(onPressed: _refresh, tooltip: 'Refresh enquiries', icon: const Icon(Icons.refresh)),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.sellerTools)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _SellerProfileEditor(service: widget.service),
                    ),
                    child: const Text('Edit seller profile'),
                  ),
                ),
              if (widget.sellerTools) const SizedBox(height: 16),
              Text(widget.sellerTools ? 'Questions from buyers' : 'Questions you sent',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _inbox,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator(semanticsLabel: 'Loading enquiries');
                  }
                  if (snapshot.hasError) return const Text('Could not load enquiries. Try Refresh.');
                  final enquiries = snapshot.data!;
                  if (enquiries.isEmpty) return const Text('No enquiries yet.');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final enquiry in enquiries)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(enquiry['produce_listings']?['title'] as String? ?? 'Produce listing',
                                  style: Theme.of(context).textTheme.titleMedium),
                                Text(enquiry['topic'] as String),
                                const SizedBox(height: 8),
                                Text(enquiry['question'] as String),
                                const SizedBox(height: 8),
                                if (enquiry['reply'] case final String reply)
                                  Text('Seller reply: $reply')
                                else if (widget.sellerTools)
                                  OutlinedButton(
                                    onPressed: () async {
                                      await showDialog<void>(
                                        context: context,
                                        builder: (_) => _EnquiryDialog(
                                          title: 'Reply to buyer',
                                          replying: true,
                                          onSend: (_, message) => widget.service.reply(enquiry['id'] as String, message),
                                        ),
                                      );
                                      if (mounted) _refresh();
                                    },
                                    child: const Text('Reply'),
                                  )
                                else
                                  const Text('Awaiting a reply'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SellerProfileEditor extends StatefulWidget {
  const _SellerProfileEditor({required this.service});
  final _SellerEnquiries service;

  @override
  State<_SellerProfileEditor> createState() => _SellerProfileEditorState();
}

class _SellerProfileEditorState extends State<_SellerProfileEditor> {
  final _name = TextEditingController();
  final _area = TextEditingController();
  late final _profile = _load();
  bool _saving = false;
  String? _error;

  Future<void> _load() async {
    final profile = await widget.service.profile(widget.service.marketplace.accountId);
    if (mounted && profile != null) {
      _name.text = profile.name;
      _area.text = profile.area;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final area = _area.text.trim();
    if (name.isEmpty || area.isEmpty) {
      setState(() => _error = 'Enter a display name and a town or district.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.service.saveProfile((name: name, area: area));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seller profile saved.')));
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Could not save the profile. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _profile,
    builder: (context, snapshot) {
      final ready = snapshot.connectionState == ConnectionState.done && !snapshot.hasError;
      return AlertDialog(
        title: const Text('Edit seller profile'),
        scrollable: true,
        content: SizedBox(
          width: 400,
          child: ready
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Signed-in buyers can see these details. Use a town or district.'),
                    const SizedBox(height: 12),
                    TextField(controller: _name, maxLength: 80, enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Seller display name')),
                    TextField(controller: _area, maxLength: 80, enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Town or district')),
                    if (_error case final error?) Semantics(liveRegion: true, child: Text(error)),
                  ],
                )
              : snapshot.hasError
                  ? const Text('Could not load your profile. Close this dialog and try again.')
                  : const LinearProgressIndicator(semanticsLabel: 'Loading profile'),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(onPressed: ready && !_saving ? _save : null, child: const Text('Save profile')),
        ],
      );
    },
  );
}

class _EnquiryDialog extends StatefulWidget {
  const _EnquiryDialog({required this.title, required this.onSend, this.replying = false});
  final String title;
  final bool replying;
  final Future<bool> Function(String? topic, String message) onSend;

  @override
  State<_EnquiryDialog> createState() => _EnquiryDialogState();
}

class _EnquiryDialogState extends State<_EnquiryDialog> {
  final _message = TextEditingController();
  String _topic = _enquiryTopics.first;
  String? _status;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _message.text.trim();
    if (message.isEmpty) {
      setState(() => _status = 'Write a message before sending.');
      return;
    }
    setState(() { _sending = true; _status = null; });
    try {
      final sent = await widget.onSend(widget.replying ? null : _topic, message);
      if (!mounted) return;
      if (!sent) {
        setState(() {
          _sending = false;
          _status = widget.replying
              ? 'This question already has a reply.'
              : 'You already asked about this topic. Check My enquiries.';
        });
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.replying ? 'Reply sent.' : 'Question sent. Check My enquiries for replies.')),
      );
    } catch (_) {
      if (mounted) setState(() { _sending = false; _status = 'Could not send. The listing may no longer be available.'; });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.replying)
            DropdownButtonFormField<String>(
              initialValue: _topic,
              items: [
                for (final topic in _enquiryTopics)
                  DropdownMenuItem(value: topic, child: Text(topic)),
              ],
              onChanged: _sending ? null : (value) => setState(() => _topic = value ?? _topic),
              decoration: const InputDecoration(labelText: 'Topic'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            enabled: !_sending,
            maxLength: 500,
            maxLines: 4,
            decoration: InputDecoration(labelText: widget.replying ? 'Reply' : 'Question'),
          ),
          if (_status case final message?) Semantics(liveRegion: true, child: Text(message)),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: _sending ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _sending ? null : _send, child: Text(widget.replying ? 'Send reply' : 'Send question')),
    ],
  );
}
