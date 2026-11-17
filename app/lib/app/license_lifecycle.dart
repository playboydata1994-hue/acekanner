import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'bootstrap.dart';
import 'licensing_providers.dart';
import 'providers.dart';

/// Keeps the plan fresh: once the database is open, and whenever the app
/// returns to the foreground, it reports new scans and refreshes the plan if
/// due (silently; offline is fine). It also re-checks Play for a purchase that
/// completed while the app was closed.
class LicenseLifecycle extends ConsumerStatefulWidget {
  const LicenseLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LicenseLifecycle> createState() => _LicenseLifecycleState();
}

class _LicenseLifecycleState extends ConsumerState<LicenseLifecycle> with WidgetsBindingObserver {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(startup: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  bool get _ready => ref.read(bootstrapControllerProvider).value is BootstrapReady;

  Future<void> _refresh({bool startup = false}) async {
    if (_running || !_ready || ref.read(licenseApiProvider) == null) return;
    _running = true;
    try {
      final service = ref.read(licenseServiceProvider);
      await service.refreshIfDue(maxAge: startup ? const Duration(hours: 1) : const Duration(hours: 12));
      if (!mounted) return;
      final status = await ref.read(licenseRepositoryProvider).status();
      if (startup && status.signedIn && !status.premiumActive) {
        await ref.read(billingControllerProvider.notifier).restore(userInitiated: false);
      }
    } catch (_) {
      // Background refresh: never interrupts the user.
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Run once the database opens after a cold start.
    ref.listen(bootstrapControllerProvider, (_, next) {
      if (next.value is BootstrapReady) _refresh(startup: true);
    });
    final ready = ref.watch(bootstrapControllerProvider).value is BootstrapReady;
    if (ready && ref.watch(billingGatewayProvider) != null) {
      // Listen for purchase updates for the whole app session (needs the database).
      ref.watch(billingControllerProvider);
    }
    return widget.child;
  }
}
