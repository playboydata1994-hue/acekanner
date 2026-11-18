import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/feedback.dart';
import '../../data/security/pin_store.dart';
import '../../data/settings/settings_repository.dart';
import '../lock/app_lock.dart';

/// Optional PIN lock and fingerprint/face unlock.
class LockSettingsScreen extends ConsumerStatefulWidget {
  const LockSettingsScreen({super.key});

  @override
  ConsumerState<LockSettingsScreen> createState() => _LockSettingsScreenState();
}

class _LockSettingsScreenState extends ConsumerState<LockSettingsScreen> {
  bool _bio = false;

  @override
  void initState() {
    super.initState();
    ref.read(biometricsProvider).available().then((v) {
      if (mounted) setState(() => _bio = v);
    });
  }

  Future<String?> _askPin(String title) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          style: const TextStyle(fontSize: 28, letterSpacing: 8),
          decoration: const InputDecoration(helperText: '4 to 6 digits'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<bool> _setPin() async {
    final first = await _askPin('Choose a PIN');
    if (first == null || !mounted) return false;
    if (!PinStore.validFormat(first)) {
      showMessage(context, 'The PIN must be 4 to 6 digits.', error: true);
      return false;
    }
    final second = await _askPin('Enter the PIN again');
    if (second == null || !mounted) return false;
    if (first != second) {
      showMessage(context, 'The PINs did not match. Try again.', error: true);
      return false;
    }
    await ref.read(pinStoreProvider).setPin(first);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appSettingsProvider);
    final repo = ref.read(settingsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('App lock')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Lock with a PIN'),
            subtitle: const Text('Asked when ACEkor opens and after 1 minute away'),
            value: s.lockEnabled,
            onChanged: (v) async {
              if (v) {
                if (await _setPin()) {
                  await repo.setBool(SettingKeys.lockEnabled, true);
                  if (context.mounted) showMessage(context, 'App lock is on. Do not forget your PIN.');
                }
              } else {
                final pin = await _askPin('Enter your PIN to turn the lock off');
                if (pin == null) return;
                if (await ref.read(pinStoreProvider).verify(pin)) {
                  await ref.read(pinStoreProvider).clear();
                  await repo.setBool(SettingKeys.lockEnabled, false);
                  await repo.setBool(SettingKeys.lockBiometric, false);
                } else if (context.mounted) {
                  showMessage(context, 'Wrong PIN.', error: true);
                }
              }
            },
          ),
          if (s.lockEnabled) ...[
            ListTile(
              title: const Text('Change PIN'),
              onTap: () async {
                final old = await _askPin('Current PIN');
                if (old == null) return;
                if (!await ref.read(pinStoreProvider).verify(old)) {
                  if (context.mounted) showMessage(context, 'Wrong PIN.', error: true);
                  return;
                }
                if (await _setPin() && context.mounted) showMessage(context, 'PIN changed.');
              },
            ),
            SwitchListTile(
              title: const Text('Unlock with fingerprint or face'),
              subtitle: Text(_bio ? 'The PIN still works too' : 'Not available on this phone'),
              value: s.lockBiometric && _bio,
              onChanged: _bio
                  ? (v) async {
                      if (v && !await ref.read(biometricsProvider).authenticate('Confirm to use your fingerprint')) {
                        return;
                      }
                      await repo.setBool(SettingKeys.lockBiometric, v);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: AppColors.teal),
              title: const Text('Lock now'),
              onTap: () => ref.read(appLockProvider.notifier).lock(),
            ),
          ],
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'If you forget the PIN, ACEkor cannot unlock your records. Keep a backup (Settings › Backup) '
              'so you can reinstall and restore if needed.',
              style: TextStyle(fontSize: 16, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
