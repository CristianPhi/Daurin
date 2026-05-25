// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class PinGate {
  static const String _activeAccountIdentifierKey = 'active_account_identifier';
  static const String _pinPrefix = 'account_pin_';
  static const String _failCountPrefix = 'pin_fail_count_';
  static const String _lockUntilPrefix = 'pin_lock_until_';

  static String _normalize(String value) => value.trim().toLowerCase();

  static String _pinKey(String accountIdentifier) =>
      '$_pinPrefix${_normalize(accountIdentifier)}';

  static String _failCountKey(String accountIdentifier) =>
      '$_failCountPrefix${_normalize(accountIdentifier)}';

  static String _lockUntilKey(String accountIdentifier) =>
      '$_lockUntilPrefix${_normalize(accountIdentifier)}';

  static Future<void> setActiveAccountIdentifier(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeAccountIdentifierKey, _normalize(identifier));
  }

  static Future<String?> getActiveAccountIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString(_activeAccountIdentifierKey);
    if (identifier == null || identifier.trim().isEmpty) {
      return null;
    }
    return identifier;
  }

  static Future<void> savePinForAccount({
    required String identifier,
    required String pin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accountKey = _normalize(identifier);
    await prefs.setString(_pinKey(accountKey), pin);
    await prefs.setInt(_failCountKey(accountKey), 0);
    await prefs.remove(_lockUntilKey(accountKey));
  }

  static Future<void> savePinForAliases({
    required String email,
    required String username,
    required String pin,
  }) async {
    await savePinForAccount(identifier: email, pin: pin);
    await savePinForAccount(identifier: username, pin: pin);
    await setActiveAccountIdentifier(email);
  }

  static Future<bool> requirePin(
    BuildContext context, {
    required String purpose,
    required ScaffoldMessengerState messenger,
    String? identifier,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accountIdentifier = _normalize(
      identifier ?? prefs.getString(_activeAccountIdentifierKey) ?? '',
    );

    if (accountIdentifier.isEmpty) {
      _showSnackBar(messenger, 'Akun belum dipilih, silakan login ulang.');
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lockedUntil = prefs.getInt(_lockUntilKey(accountIdentifier)) ?? 0;
    if (lockedUntil > now) {
      final remainingSeconds = ((lockedUntil - now) / 1000).ceil();
      _showSnackBar(
        messenger,
        'Akun dibekukan $remainingSeconds detik karena PIN salah.',
      );
      return false;
    }

    if (!context.mounted) {
      return false;
    }

    final enteredPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = TextEditingController();

        void updatePin(
          String nextValue,
          void Function(void Function()) setState,
        ) {
          if (nextValue.length > 6) return;
          setState(() {
            controller.text = nextValue;
            controller.selection = TextSelection.collapsed(
              offset: controller.text.length,
            );
          });
        }

        Widget pinCircle(bool filled) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? Colors.green.shade700 : Colors.transparent,
              border: Border.all(color: Colors.green.shade700, width: 1.8),
            ),
          );
        }

        Widget numButton(
          String label,
          void Function(void Function()) setState,
        ) {
          return SizedBox(
            width: 74,
            height: 74,
            child: FilledButton(
              onPressed: () => updatePin(controller.text + label, setState),
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final pinLength = controller.text.length.clamp(0, 6).toInt();
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
                  maxWidth: 420,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Masukkan PIN',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Untuk $purpose, masukkan PIN 6 digit.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            6,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: pinCircle(index < pinLength),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                numButton('1', setState),
                                numButton('2', setState),
                                numButton('3', setState),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                numButton('4', setState),
                                numButton('5', setState),
                                numButton('6', setState),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                numButton('7', setState),
                                numButton('8', setState),
                                numButton('9', setState),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width: 74,
                                  height: 74,
                                  child: OutlinedButton(
                                    onPressed: pinLength == 0
                                        ? null
                                        : () => updatePin(
                                            controller.text.substring(
                                              0,
                                              controller.text.length - 1,
                                            ),
                                            setState,
                                          ),
                                    style: OutlinedButton.styleFrom(
                                      shape: const CircleBorder(),
                                    ),
                                    child: const Icon(Icons.backspace_outlined),
                                  ),
                                ),
                                numButton('0', setState),
                                SizedBox(
                                  width: 74,
                                  height: 74,
                                  child: TextButton(
                                    onPressed: () => updatePin('', setState),
                                    style: TextButton.styleFrom(
                                      shape: const CircleBorder(),
                                    ),
                                    child: const Icon(Icons.refresh),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: pinLength == 6
                                    ? () {
                                        Navigator.of(
                                          dialogContext,
                                        ).pop(controller.text.trim());
                                      }
                                    : null,
                                child: const Text('Lanjut'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (enteredPin == null || enteredPin.length != 6) {
      if (enteredPin != null) {
        _showSnackBar(messenger, 'PIN harus 6 digit angka.');
      }
      return false;
    }

    final isPinValid = await _verifyPinWithBackend(
      identifier: accountIdentifier,
      pin: enteredPin,
      prefs: prefs,
    );

    if (!isPinValid) {
      final failCount =
          (prefs.getInt(_failCountKey(accountIdentifier)) ?? 0) + 1;
      if (failCount >= 3) {
        await prefs.setInt(_failCountKey(accountIdentifier), 0);
        await prefs.setInt(
          _lockUntilKey(accountIdentifier),
          DateTime.now()
              .add(const Duration(seconds: 30))
              .millisecondsSinceEpoch,
        );
        _showSnackBar(messenger, 'PIN salah 3 kali. Akun dibekukan 30 detik.');
      } else {
        await prefs.setInt(_failCountKey(accountIdentifier), failCount);
        _showSnackBar(messenger, 'PIN salah. Sisa percobaan ${3 - failCount}.');
      }
      return false;
    }

    await prefs.setInt(_failCountKey(accountIdentifier), 0);
    await prefs.remove(_lockUntilKey(accountIdentifier));
    return true;
  }

  static Future<bool> _verifyPinWithBackend({
    required String identifier,
    required String pin,
    required SharedPreferences prefs,
  }) async {
    try {
      final response = await postJsonWithFallback(
        path: '/auth/verify-pin',
        body: jsonEncode({'identifier': identifier, 'pin': pin}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await prefs.setString(_pinKey(identifier), pin);
        return true;
      }

      return false;
    } catch (_) {
      final cachedPin = prefs.getString(_pinKey(identifier));
      return cachedPin != null && cachedPin == pin;
    }
  }

  static void _showSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
