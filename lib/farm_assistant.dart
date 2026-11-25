import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browser_camera_stub.dart'
    if (dart.library.js_interop) 'browser_camera.dart';
import 'farma_backend.dart';

class FarmAssistant extends StatefulWidget {
  const FarmAssistant({
    required this.accountId,
    required this.accessToken,
    required this.language,
    super.key,
  });

  final String accountId;
  final String accessToken;
  final String language;

  @override
  State<FarmAssistant> createState() => _FarmAssistantState();
}

class _FarmAssistantState extends State<FarmAssistant> {
  static const _starterQuestions = [
    'Help me check a crop photo',
    'Help me describe a livestock symptom',
    'What should I plant this season?',
    'Help me ask a farming question',
  ];

  final _question = TextEditingController();
  final _feedback = TextEditingController();
  String _previousQuestion = '';
  String _answer = '';
  List<String> _suggestions = _starterQuestions;
  Uint8List? _photo;
  String? _mime;
  String? _status;
  bool _busy = false;
  bool _restoring = true;
  bool _saving = false;
  bool _includeFeedback = false;

  String get _storageKey => 'farma.assistant.saved.${widget.accountId}';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (!mounted || saved == null) return;
      final data = jsonDecode(saved) as Map<String, dynamic>;
      setState(() {
        _previousQuestion = data['question'] as String? ?? '';
        _answer = data['answer'] as String? ?? '';
        _feedback.text = data['feedback'] as String? ?? '';
      });
    } catch (_) {
      // An unavailable local record does not prevent new questions.
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _save() async {
    final saved = jsonEncode({
      'question': _previousQuestion,
      'answer': _answer,
      'feedback': _feedback.text.trim(),
    });
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_storageKey, saved);
      if (mounted) {
        setState(() => _status = success
            ? 'Saved your latest answer and feedback on this device.'
            : 'Could not save on this device.');
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not save on this device.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _question.dispose();
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      Uint8List? bytes;
      if (kIsWeb && source == ImageSource.camera) {
        bytes = await captureBrowserPhoto();
      } else {
        final file = await ImagePicker().pickImage(
          source: source,
          maxWidth: 960,
          maxHeight: 960,
          imageQuality: 75,
        );
        if (file == null || await file.length() > 1024 * 1024) {
          if (file != null && mounted) {
            setState(() => _status = 'Choose a photo under 1 MB.');
          }
          return;
        }
        bytes = await file.readAsBytes();
      }
      if (!mounted || bytes == null) return;
      final mime = _imageMime(bytes);
      setState(() {
        if (bytes!.length > 1024 * 1024) {
          _status = 'Choose a photo under 1 MB.';
        } else if (mime == null) {
          _status = 'Choose a JPEG, PNG, WebP or GIF photo.';
        } else {
          _photo = bytes;
          _mime = mime;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _status = 'Photo unavailable. Try uploading a file.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _imageMime(Uint8List data) {
    if (data.length < 12) return null;
    if (data[0] == 255 && data[1] == 216 && data[2] == 255) return 'image/jpeg';
    if (data[0] == 137 && ascii.decode(data.sublist(1, 4), allowInvalid: true) == 'PNG') {
      return 'image/png';
    }
    if (ascii.decode(data.sublist(0, 4), allowInvalid: true) == 'GIF8') return 'image/gif';
    if (ascii.decode(data.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(data.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  Future<void> _ask() async {
    final photo = _photo;
    final question = _question.text.trim().isEmpty && photo != null
        ? 'What farming problem might this photo show?'
        : _question.text.trim();
    if (question.isEmpty) {
      setState(() => _status = 'Enter a farming question or add a photo.');
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final response = await http.post(
        Uri.parse('$farmaProjectUrl/functions/v1/farm-assistant'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'apikey': farmaPublishableKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
          'language': widget.language,
          'previousQuestion': _previousQuestion,
          'previousAnswer': _answer,
          'feedback': _includeFeedback ? _feedback.text.trim() : '',
          if (photo != null) 'photo': 'data:$_mime;base64,${base64Encode(photo)}',
        }),
      ).timeout(const Duration(seconds: 32));
      if (!mounted) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        setState(() => _status = switch (response.statusCode) {
          401 => 'Sign in again to continue.',
          404 || 503 => 'Farm Assistant is unavailable right now.',
          429 => 'Hourly question limit reached. Try again later.',
          _ => 'Farm Assistant could not answer. Try again.',
        });
        return;
      }
      final answer = data['answer'] as String;
      final suggestions = (data['suggestions'] as List).whereType<String>().toList();
      setState(() {
        _previousQuestion = question;
        _answer = answer;
        _suggestions = suggestions;
        _question.clear();
        _photo = null;
        _mime = null;
        _status = 'Answer ready.';
      });
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not connect. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final camera = kIsWeb || platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;
    final available = !_busy && !_restoring && !_saving;
    final photo = _photo;
    return Scaffold(
      appBar: AppBar(title: const Text('Farm Assistant')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Ask about farming in ${widget.language}.'),
                const SizedBox(height: 12),
                if (_answer.isNotEmpty) ...[
                  Semantics(header: true, child: const Text('Latest answer')),
                  Text(_previousQuestion, style: Theme.of(context).textTheme.titleMedium),
                  SelectableText(_answer),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final question in _suggestions)
                      ActionChip(
                        label: Text(question),
                        onPressed: available ? () => _question.text = question : null,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _question,
                  enabled: available,
                  maxLength: 1200,
                  maxLines: 4,
                  minLines: 2,
                  decoration: const InputDecoration(labelText: 'Farming question'),
                ),
                if (photo != null)
                  Image.memory(photo, height: 160, semanticLabel: 'Attached farm photo'),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: available ? () => _pickPhoto(ImageSource.gallery) : null,
                      child: const Text('Upload photo'),
                    ),
                    if (camera)
                      OutlinedButton(
                        onPressed: available ? () => _pickPhoto(ImageSource.camera) : null,
                        child: const Text('Take photo'),
                      ),
                    if (photo != null)
                      TextButton(
                        onPressed: available ? () => setState(() {
                          _photo = null;
                          _mime = null;
                        }) : null,
                        child: const Text('Remove photo'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Sending a question shares it and any attached photo with the AI provider.'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: available ? _ask : null,
                  child: const Text('Ask Farm Assistant'),
                ),
                if (_busy || _restoring)
                  const LinearProgressIndicator(semanticsLabel: 'Working'),
                if (_status case final message?)
                  Semantics(liveRegion: true, child: Text(message)),
                if (_answer.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _feedback,
                    enabled: available,
                    maxLength: 600,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Correction or follow-up outcome (optional)',
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Include feedback in my next question'),
                    value: _includeFeedback,
                    onChanged: available
                        ? (enabled) => setState(() => _includeFeedback = enabled)
                        : null,
                  ),
                  OutlinedButton(
                    onPressed: available ? _save : null,
                    child: const Text('Save latest answer and feedback'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
