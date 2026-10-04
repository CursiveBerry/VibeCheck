import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_check/screen/app_theme.dart';
import '../providers/app_providers.dart';
import '../services/firebase_services.dart';
import 'pop_widgets.dart';

Future<void> showCreateModal(BuildContext context, int tabIndex) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateSheet(tabIndex: tabIndex),
  );
}

class CreateSheet extends ConsumerStatefulWidget {
  const CreateSheet({super.key, required this.tabIndex});
  final int tabIndex;

  @override
  ConsumerState<CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<CreateSheet> {
  final _main = TextEditingController();
  final _location = TextEditingController();
  final _name = TextEditingController();

  String _tag = vibeStyles.first.label;
  int _spots = 4;
  bool _loading = false;

  bool get _isConfession => widget.tabIndex == 0;
  String get _defaultName =>
      _isConfession ? 'Anonymous Ghost 👻' : 'Main Character 👑';

  @override
  void initState() {
    super.initState();
    _name.text = _defaultName;
    _loadSavedName();
  }

  @override
  void dispose() {
    _main.dispose();
    _location.dispose();
    _name.dispose();
    super.dispose();
  }

  // Pre-fill with the nickname this user used last time (stored in Firestore).
  Future<void> _loadSavedName() async {
    try {
      final uid = await ref.read(currentUidProvider.future);
      final profile = await ref.read(firestoreServiceProvider).getProfile(uid);
      final saved = profile[_isConfession ? 'anonName' : 'hostName'] as String?;
      if (mounted &&
          saved != null &&
          saved.isNotEmpty &&
          _name.text == _defaultName) {
        _name.text = saved;
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    final text = _main.text.trim();
    if (text.isEmpty) {
      showToast(
        context,
        _isConfession ? 'Write something first.' : 'Name your quest first.',
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _loading = true);

    try {
      final uid = await ref.read(currentUidProvider.future);
      final service = ref.read(firestoreServiceProvider);
      final name = _name.text.trim().isEmpty ? _defaultName : _name.text.trim();

      final Future<void> write;
      final String profileKey;
      if (_isConfession) {
        profileKey = 'anonName';
        write = service.addConfession(
          content: text,
          vibeTag: _tag,
          anonName: name,
          uid: uid,
        );
      } else {
        profileKey = 'hostName';
        write = service.addQuest(
          title: text,
          location: _location.text.trim().isEmpty
              ? 'Campus Quad'
              : _location.text.trim(),
          hostName: name,
          maxSpots: _spots,
          uid: uid,
        );
      }

      // Offline writes are queued by Firestore and only resolve once synced, so don't leave the user staring at a spinner.
      var queued = false;
      try {
        await write.timeout(const Duration(seconds: 6));
      } on TimeoutException {
        queued = true;
      }

      service.saveProfile(uid, {profileKey: name}).ignore();

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        popSnack(
          queued
              ? "Saved offline. It'll post when you're back online."
              : _isConfession
              ? 'Confession posted.'
              : 'Quest launched.',
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      messenger.showSnackBar(popSnack(friendlyError(e)));
    }
  }

  InputDecoration _dec({String? hint, String? label}) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w900,
      ),
      enabledBorder: border(AppColors.ink, 2),
      focusedBorder: border(AppColors.tangerine, 3),
    );
  }

  Widget _spotsStepper() {
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: popDecoration(
          onTap == null ? AppColors.disabled : AppColors.butter,
          pill: true,
          shadow: 0,
        ),
        child: Icon(icon, color: AppColors.ink),
      ),
    );

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Spots (including you)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        btn(
          Icons.remove_rounded,
          _spots > 2 ? () => setState(() => _spots--) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$_spots',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        btn(
          Icons.add_rounded,
          _spots < 12 ? () => setState(() => _spots++) : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isConfession ? AppColors.pink : AppColors.mint;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isConfession ? 'Spill the tea' : 'Host a sidequest',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Sticker(
                    label: _isConfession ? 'anonymous' : 'open to all',
                    color: accent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isConfession) ...[
                TextField(
                  controller: _main,
                  maxLines: 4,
                  maxLength: 280,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec(hint: "What's the vibe or the secret?"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  maxLength: 24,
                  decoration: _dec(label: 'Nickname'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pick a vibe',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: vibeStyles
                      .map(
                        (v) => PopChip(
                          label: '${v.emoji} ${v.label}',
                          selected: _tag == v.label,
                          color: v.color,
                          onTap: () => setState(() => _tag = v.label),
                        ),
                      )
                      .toList(),
                ),
              ] else ...[
                TextField(
                  controller: _main,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec(
                    hint: 'What are we doing? (e.g. matcha run)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _location,
                  maxLength: 40,
                  decoration: _dec(hint: 'Where? (e.g. Library 3rd floor)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  maxLength: 24,
                  decoration: _dec(label: 'Host name'),
                ),
                const SizedBox(height: 8),
                _spotsStepper(),
              ],
              const SizedBox(height: 22),
              PopButton(
                label: _isConfession ? 'Post confession' : 'Launch quest',
                color: accent,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
