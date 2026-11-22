import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/strings_id.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/storage/secure_store.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../auth/presentation/auth_provider.dart';
import 'health_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;
  bool _hasStartedCheck = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startSessionCheck();
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  /// Navigasi keluar ke Beranda (Dashboard)
  void _goToDashboard() {
    _fallbackTimer?.cancel();
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    debugPrint('[SplashScreen] EXIT ROUTE -> Beranda (/shell)');
    context.go('/shell');
  }

  /// Navigasi keluar ke Halaman Login (Email/Password)
  void _goToLogin() {
    _fallbackTimer?.cancel();
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    debugPrint('[SplashScreen] EXIT ROUTE -> Login (/login)');
    ref.read(authProvider.notifier).setUnauthenticated();
    context.go('/login');
  }

  void _startSessionCheck() {
    if (_hasStartedCheck || _hasNavigated) return;
    _hasStartedCheck = true;

    // Safety fallback timer 3000ms: Memastikan aplikasi tidak pernah stuck di logo jika
    // storage OS mengalami kebuntuan atau latency tidak normal.
    _fallbackTimer = Timer(const Duration(milliseconds: 3000), () {
      if (!_hasNavigated && mounted) {
        debugPrint('[SplashScreen] Safety fallback timeout fired. Forcing exit to /login.');
        _goToLogin();
      }
    });

    _initiateSessionCheck();
  }

  Future<void> _initiateSessionCheck() async {
    try {
      final secureStore = ref.read(secureStoreProvider);
      final localDb = ref.read(localDbProvider);

      debugPrint('[SplashScreen] 1. Memeriksa status kedaluwarsa sesi...');
      final isExpired = await secureStore.isSessionExpired();
      if (isExpired) {
        debugPrint('[SplashScreen] Cabang: Sesi kedaluwarsa (> 7 hari). Navigasi ke /login.');
        await ref.read(authProvider.notifier).logout();
        _goToLogin();
        return;
      }

      debugPrint('[SplashScreen] 2. Membaca sesi dari secure storage & local DB...');
      final hasStoredSecureSession = await secureStore.hasValidStoredSession();
      final cachedUser = await ref.read(authProvider.notifier).getPersistedUser();
      final refreshToken = await secureStore.getRefreshToken() ??
          (await localDb.getLatestSessionSettings())?.refreshToken;

      final hasValidSession = hasStoredSecureSession ||
          (cachedUser != null &&
              cachedUser.id.isNotEmpty &&
              cachedUser.email.isNotEmpty &&
              refreshToken != null &&
              refreshToken.isNotEmpty);

      debugPrint('[SplashScreen] hasValidSession: $hasValidSession, user: ${cachedUser?.email}');

      // Token kosong atau tidak ada sesi valid -> Langsung keluar ke /login
      if (!hasValidSession || cachedUser == null) {
        debugPrint('[SplashScreen] Cabang: Belum ada sesi tersimpan. Exit ke /login.');
        _goToLogin();
        return;
      }

      // Sesi valid langsung restore ke dashboard
      debugPrint('[SplashScreen] Sesi valid ditemukan. Masuk ke Beranda (/shell).');
      _fallbackTimer?.cancel();
      ref.read(authProvider.notifier).restoreSessionInstant(cachedUser, refreshToken);
      _goToDashboard();
    } catch (e, stack) {
      debugPrint('[SplashScreen] Catch: Terjadi error saat inisialisasi storage: $e\n$stack');
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthCheckProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // App Logo & Brand Identity
                Image.asset(
                  'assets/images/app_logo_mark.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  StringsId.appName,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  StringsId.appTagline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textMutedDark,
                  ),
                ),
                const Spacer(),
                // Health Check Status Block (Milestone 1 Core Verification)
                Card(
                  color: AppTheme.darkCardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.darkCardBorder, width: 1.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AsyncStateView(
                      value: healthState,
                      loadingMessage: StringsId.checkingServer,
                      onRetry: () => ref.refresh(healthCheckProvider),
                      dataBuilder: (health) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.successGreen,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                StringsId.serverOnline,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${health.status.toUpperCase()} • DB: ${health.db} • v${health.version}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Waktu Server: ${health.time}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textMutedDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
