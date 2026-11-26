part of 'field_records.dart';

class _DistrictOperations extends StatefulWidget {
  const _DistrictOperations({required this.service, required this.district});

  final FieldRecords service;
  final String district;

  @override
  State<_DistrictOperations> createState() => _DistrictOperationsState();
}

class _DistrictOperationsState extends State<_DistrictOperations> {
  late var _summary = _load();
  bool _saving = false;

  Future<List<_Row>> _load() => widget.service._request(
    'POST', 'rpc/district_review_summary', {}, data: {},
  );

  Future<void> _save(String account, bool active, {String? name}) async {
    if (_saving) return;
    setState(() => _saving = true);
    var message = active ? 'Officer access enabled.' : 'Officer access suspended.';
    try {
      await widget.service._request(
        'POST', 'rpc/set_district_officer', {},
        data: {'target_account': account, 'target_name': name, 'target_active': active},
      );
    } catch (_) {
      message = 'Could not update access. Check the account ID and district assignment.';
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _summary = _load();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final officer = await showDialog<({String account, String name})>(
      context: context, builder: (_) => const _ApproveOfficer(),
    );
    if (mounted && officer != null) {
      await _save(officer.account, true, name: officer.name);
    }
  }

  Future<void> _changeAccess(_Row officer) async {
    final active = officer['active'] as bool;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? 'Suspend officer access?' : 'Restore officer access?'),
        content: Text(active
            ? 'The officer will lose access to assigned records. Existing review requests will stay in the district totals.'
            : 'The officer will regain access to records that farmers are still sharing with them.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(active ? 'Suspend access' : 'Restore access'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await _save(officer['officer_id'] as String, !active);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('District operations'),
      actions: [
        IconButton(
          onPressed: _saving ? null : () => setState(() => _summary = _load()),
          tooltip: 'Refresh district report',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: FutureBuilder<List<_Row>>(
            future: _summary,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading district report'));
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Could not load district operations. Try Refresh.'));
              }
              final officers = snapshot.data!;
              var waiting = 0;
              var completed = 0;
              var suspendedWaiting = 0;
              for (final officer in officers) {
                final count = officer['awaiting'] as int;
                waiting += count;
                completed += officer['completed'] as int;
                if (officer['active'] == false) suspendedWaiting += count;
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Semantics(
                    header: true,
                    child: Text(widget.district, style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 12),
                  if (_saving) const LinearProgressIndicator(semanticsLabel: 'Updating officer access'),
                  Text('Awaiting follow-up: $waiting'),
                  Text('Follow-ups sent: $completed'),
                  if (suspendedWaiting > 0)
                    Text('Awaiting follow-up with suspended officers: $suspendedWaiting'),
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _add,
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Approve officer'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (officers.isEmpty) const Text('This district has no approved officers yet.'),
                  for (final officer in officers)
                    Card(
                      child: ListTile(
                        title: Text(officer['display_name'] as String),
                        subtitle: Text(
                          '${officer['active'] == true ? 'Active' : 'Suspended'}'
                          ' · ${officer['awaiting']} awaiting · ${officer['completed']} completed',
                        ),
                        trailing: PopupMenuButton<void>(
                          enabled: !_saving,
                          tooltip: 'Manage access for ${officer['display_name']}',
                          itemBuilder: (_) => [
                            PopupMenuItem<void>(
                              onTap: () => _changeAccess(officer),
                              child: Text(officer['active'] == true ? 'Suspend access' : 'Restore access'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _ApproveOfficer extends StatefulWidget {
  const _ApproveOfficer();

  @override
  State<_ApproveOfficer> createState() => _ApproveOfficerState();
}

class _ApproveOfficerState extends State<_ApproveOfficer> {
  final _account = TextEditingController();
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  static final _uuid = RegExp(r'^[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}$');

  @override
  void dispose() {
    _account.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Approve a field officer'),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('The officer must already have a Farma account. Farmers can see their display name and district.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _account,
              decoration: const InputDecoration(labelText: 'Account UUID'),
              validator: (value) => _uuid.hasMatch(value?.trim() ?? '') ? null : 'Enter the officer’s account UUID.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Officer display name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter a display name.' : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, (account: _account.text.trim(), name: _name.text.trim()));
          }
        },
        child: const Text('Approve officer'),
      ),
    ],
  );
}
