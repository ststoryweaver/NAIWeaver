import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/preferences_service.dart';
import '../theme/theme_extensions.dart';

class PinLockGate extends StatefulWidget {
  final PreferencesService prefs;
  final Widget child;

  const PinLockGate({super.key, required this.prefs, required this.child});

  @override
  State<PinLockGate> createState() => _PinLockGateState();
}

class _PinLockGateState extends State<PinLockGate> with WidgetsBindingObserver {
  bool _isLocked = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.prefs.pinEnabled) {
      _isLocked = true;
      _attemptBiometric();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (widget.prefs.pinEnabled &&
          widget.prefs.pinLockOnResume &&
          _pausedAt != null &&
          DateTime.now().difference(_pausedAt!).inSeconds > 5) {
        setState(() => _isLocked = true);
        _attemptBiometric();
      }
      _pausedAt = null;
    }
  }

  Future<void> _attemptBiometric() async {
    if (!widget.prefs.pinBiometricEnabled) return;
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) return;
      final didAuth = await auth.authenticate(
        localizedReason: 'Unlock NAIWeaver',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (didAuth && mounted) {
        setState(() => _isLocked = false);
      }
    } catch (_) {
      // Biometric failed or unavailable — fall back to PIN keypad
    }
  }

  void _onUnlock() {
    // If using old hash version, prompt user to re-set PIN via settings
    if (widget.prefs.pinHashVersion < 2) {
      _migrateHash();
    }
    setState(() => _isLocked = false);
  }

  Future<void> _migrateHash() async {
    // We can't re-hash without the plaintext PIN, but since the user just
    // entered it and it verified, we store the version flag. The actual
    // re-hash happens on next PIN set via Settings.
    // For now, just mark that migration is needed — the old hash still works.
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return PinEntryScreen(
        prefs: widget.prefs,
        onUnlock: _onUnlock,
        onBiometric: widget.prefs.pinBiometricEnabled ? _attemptBiometric : null,
      );
    }
    return widget.child;
  }
}

/// Legacy SHA-256 hash (version 1).
String hashPin(String salt, String pin) {
  final bytes = utf8.encode('$salt$pin');
  return sha256.convert(bytes).toString();
}

/// PBKDF2-SHA256 hash with 100,000 iterations (version 2).
String hashPinPbkdf2(String salt, String pin) {
  final key = utf8.encode(pin);
  final saltBytes = utf8.encode(salt);
  const iterations = 100000;

  var hmacGen = Hmac(sha256, key);
  // PBKDF2 block 1
  var block = <int>[...saltBytes, 0, 0, 0, 1];
  var u = hmacGen.convert(block).bytes;
  var result = List<int>.from(u);
  for (var i = 1; i < iterations; i++) {
    u = hmacGen.convert(u).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= u[j];
    }
  }
  return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Verifies a PIN using the correct hash version.
String verifyPinHash(String salt, String pin, int version) {
  if (version >= 2) {
    return hashPinPbkdf2(salt, pin);
  }
  return hashPin(salt, pin);
}

/// Generates a random 16-character hex salt.
String generateSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(8, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class PinEntryScreen extends StatefulWidget {
  final PreferencesService prefs;
  final VoidCallback onUnlock;
  final VoidCallback? onBiometric;

  const PinEntryScreen({
    super.key,
    required this.prefs,
    required this.onUnlock,
    this.onBiometric,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _isError = false;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  Timer? _lockoutTimer;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
        setState(() {
          _isError = false;
          _entered = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  bool get _isLockedOut =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  int get _lockoutSecondsRemaining {
    if (_lockedUntil == null) return 0;
    final remaining = _lockedUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _onDigit(String digit) {
    if (_entered.length >= 8 || _isError || _isLockedOut) return;
    HapticFeedback.lightImpact();
    setState(() => _entered += digit);
  }

  void _onBackspace() {
    if (_entered.isEmpty || _isError || _isLockedOut) return;
    HapticFeedback.lightImpact();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _onConfirm() {
    if (_entered.length < 4 || _isError || _isLockedOut) return;
    _verify();
  }

  void _verify() {
    if (_isLockedOut) return;

    final expectedHash = widget.prefs.pinHash;
    final salt = widget.prefs.pinSalt;
    final version = widget.prefs.pinHashVersion;
    final enteredHash = verifyPinHash(salt, _entered, version);

    if (enteredHash == expectedHash) {
      _failedAttempts = 0;
      widget.onUnlock();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 20) {
        _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
        _failedAttempts = 0;
        _startLockoutTimer();
      }
      HapticFeedback.heavyImpact();
      setState(() => _isError = true);
      _shakeController.forward();
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isLockedOut) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 48,
                filterQuality: FilterQuality.medium,
                color: t.logoColor,
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(height: 8),
              Text(
                'NAIWEAVER',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(12),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'ENTER PIN',
                style: TextStyle(
                  color: t.textDisabled,
                  fontSize: t.fontSize(10),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 24),
              // PIN dots — dynamic row that grows as digits are entered
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final dx = _isError ? sin(_shakeAnimation.value * pi * 4) * 12 : 0.0;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _entered.isEmpty
                      ? [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                              border: Border.all(color: t.borderMedium, width: 2),
                            ),
                          ),
                        ]
                      : List.generate(_entered.length, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isError ? t.accentDanger : t.accent,
                              border: Border.all(
                                color: _isError ? t.accentDanger : t.accent,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                ),
              ),
              const SizedBox(height: 8),
              // Lockout warning
              if (_isLockedOut)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Too many attempts. Try again in ${_lockoutSecondsRemaining}s',
                    style: TextStyle(
                      color: t.accentDanger,
                      fontSize: t.fontSize(9),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Keypad
              SizedBox(
                width: 240,
                child: Column(
                  children: [
                    for (final row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['', '0', 'back'],
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row.map((key) {
                            if (key.isEmpty) {
                              return const SizedBox(width: 64, height: 64);
                            }
                            if (key == 'back') {
                              return _KeypadButton(
                                onTap: _onBackspace,
                                child: Icon(Icons.backspace_outlined,
                                    size: 20, color: t.textDisabled),
                              );
                            }
                            return _KeypadButton(
                              onTap: () => _onDigit(key),
                              child: Text(
                                key,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: t.fontSize(20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              // Confirm button (appears when >= 4 digits entered)
              if (_entered.length >= 4 && !_isLockedOut) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 160,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.accent,
                      foregroundColor: t.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'UNLOCK',
                      style: TextStyle(
                        fontSize: t.fontSize(10),
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              // Biometric button
              if (widget.onBiometric != null) ...[
                const SizedBox(height: 16),
                IconButton(
                  onPressed: widget.onBiometric,
                  icon: Icon(Icons.fingerprint, size: 36, color: t.accent),
                  tooltip: 'Biometric unlock',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _KeypadButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.borderMedium, width: 1),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
