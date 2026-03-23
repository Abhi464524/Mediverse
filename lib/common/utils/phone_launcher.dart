import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Channel must match [MainActivity] in Android.
const MethodChannel _kAndroidPhoneChannel =
    MethodChannel('com.example.doctor_app/phone');

/// Normalizes [phoneNumber] for tel: / dial APIs (removes spaces).
String normalizePhoneDigits(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'\s+'), '');
}

Future<void> _openAndroidDialerIntentPlus(String tel) async {
  final intent = AndroidIntent(
    action: 'android.intent.action.DIAL',
    data: 'tel:$tel',
  );
  await intent.launch();
}

/// Places an **outgoing call** on Android (not only the dialer), after [Permission.phone].
/// Order: [FlutterPhoneDirectCaller] → native [ACTION_CALL] → fallbacks.
/// iOS: opens Phone app via `tel:` (system handles the call UI).
Future<bool> launchPhoneCall(String phoneNumber) async {
  final tel = normalizePhoneDigits(phoneNumber);
  if (tel.isEmpty) return false;
  if (kIsWeb) return false;

  if (defaultTargetPlatform == TargetPlatform.android) {
    final perm = await Permission.phone.request();
    if (!perm.isGranted) {
      return false;
    }

    // 1) Direct call via plugin
    try {
      final ok = await FlutterPhoneDirectCaller.callNumber(tel);
      if (ok == true) return true;
    } catch (_) {}

    // 2) Native ACTION_CALL (same as plugin when registered)
    try {
      await _kAndroidPhoneChannel.invokeMethod<void>('placeCall', {
        'number': tel,
      });
      return true;
    } catch (_) {}

    // 3) Native channel open dialer (last resort)
    try {
      await _kAndroidPhoneChannel.invokeMethod<void>('openDialer', {
        'number': tel,
      });
      return true;
    } catch (_) {}

    try {
      await _openAndroidDialerIntentPlus(tel);
      return true;
    } catch (_) {}

    try {
      final launched = await launchUrl(
        Uri.parse('tel:$tel'),
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (_) {}

    return false;
  }

  try {
    return await launchUrl(
      Uri.parse('tel:$tel'),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

/// Minimum time the loader stays visible so it never flashes (every tap).
const Duration _kMinLoaderVisible = Duration(milliseconds: 450);

/// Shows a blocking loader until call / phone UI is opened, then dismisses it.
/// Waits for the dialog to paint on every invocation, then runs the call flow.
Future<void> launchCallWithLoader(
  BuildContext context,
  String phoneNumber,
) async {
  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (ctx) => PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF6A9C89),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Connecting call…',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please wait',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // Let the overlay build + paint before starting work (otherwise 2nd+ taps
  // can complete so fast the loader never appears).
  await Future<void>.delayed(Duration.zero);
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 16));
  await WidgetsBinding.instance.endOfFrame;

  final sw = Stopwatch()..start();
  bool ok = false;
  try {
    ok = await launchPhoneCall(phoneNumber);
  } finally {
    final remaining = _kMinLoaderVisible - sw.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (context.mounted) {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    }
  }

  if (context.mounted && !ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Could not start the call. Allow Phone permission in Settings and try again.',
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// @deprecated Use [launchPhoneCall] or [launchCallWithLoader].
Future<bool> launchPhoneDialer(String phoneNumber) =>
    launchPhoneCall(phoneNumber);
