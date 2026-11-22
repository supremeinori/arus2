import 'package:arus/core/theme/app_theme.dart';
import 'package:arus/features/about/presentation/about_screen.dart';
import 'package:arus/features/analytics/domain/analytics_models.dart';
import 'package:arus/features/analytics/presentation/analytics_provider.dart';
import 'package:arus/features/auth/domain/user_model.dart';
import 'package:arus/features/auth/presentation/auth_provider.dart';
import 'package:arus/features/auth/presentation/auth_state.dart';
import 'package:arus/features/auth/presentation/login_screen.dart';
import 'package:arus/features/dashboard/presentation/dashboard_screen.dart';
import 'package:arus/features/notifications/domain/notification_models.dart';
import 'package:arus/features/notifications/presentation/notification_screen.dart';
import 'package:arus/features/notifications/presentation/notifications_provider.dart';
import 'package:arus/features/outlets/domain/outlet_models.dart';
import 'package:arus/features/outlets/presentation/outlet_list_screen.dart';
import 'package:arus/features/outlets/presentation/outlets_provider.dart';
import 'package:arus/features/profile/presentation/profile_screen.dart';
import 'package:arus/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _AuditAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _AuditAuthNotifier(super.initialState);

  @override
  Future<void> checkAuth() async {}

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<void> logout() async {
    state = AuthState.unauthenticated();
  }

  @override
  Future<UserModel?> getPersistedUser() async => state.user;

  @override
  void setUnauthenticated([String? message]) {
    state = AuthState.unauthenticated(message);
  }

  @override
  void restoreSessionInstant(UserModel user, [String? refreshToken]) {
    state = AuthState.authenticated(user);
  }

  @override
  Future<void> applyDisplayCurrency(String currency) async {}
}

Widget _wrapNarrowPhone(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: ShadTheme(
      data: AppTheme.shadcnThemeLight,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, widget) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: const TextScaler.linear(1.3)),
            child: widget ?? const SizedBox.shrink(),
          );
        },
        home: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const ownerUser = UserModel(
    id: 'u-owner-audit',
    name: 'Rina Permatasari Pemilik Cabang Utama',
    email: 'owner.audit@arus.id',
    role: UserRole.owner,
  );

  void useSmallPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Antislop UI Audit - Responsive 360x640 & 1.3x TextScaler', () {
    testWidgets('AboutScreen merender logo aset asli tanpa placeholder A dan bebas overflow', (tester) async {
      useSmallPhoneViewport(tester);

      await tester.pumpWidget(_wrapNarrowPhone(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('A'), findsNothing);
      expect(find.text('ARUS Decision Hub'), findsOneWidget);
    });

    testWidgets('ProfileScreen bebas overflow pada layar sempit dan tanpa double divider', (tester) async {
      useSmallPhoneViewport(tester);

      await tester.pumpWidget(
        _wrapNarrowPhone(
          const ProfileScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => _AuditAuthNotifier(AuthState.authenticated(ownerUser)),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Keluar Akun'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Keluar Akun'), findsOneWidget);
    });

    testWidgets('NotificationScreen tidak menampilkan tombol uji sementara dan bebas overflow', (tester) async {
      useSmallPhoneViewport(tester);

      await tester.pumpWidget(
        _wrapNarrowPhone(
          const NotificationScreen(),
          overrides: [
            notificationsListProvider.overrideWith(
              (ref) async => NotificationsResponse(
                unreadCount: 1,
                notifications: [
                  NotificationModel(
                    id: 'notif-audit-1',
                    userId: 'u-owner-audit',
                    type: 'low_stock',
                    priority: 'high',
                    title: 'Stok Susu Oat Menipis di Cabang Utama',
                    body: 'Sisa stok 2 liter, di bawah ambang batas aman.',
                    createdAt: DateTime(2026, 11, 12, 9, 30),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Uji Notifikasi'), findsNothing);
      expect(find.textContaining('Test Push'), findsNothing);
      expect(find.text('Stok Susu Oat Menipis di Cabang Utama'), findsOneWidget);
    });

    testWidgets('OutletListScreen wiring retry memulihkan daftar outlet dan bebas overflow', (tester) async {
      useSmallPhoneViewport(tester);
      var attempts = 0;

      await tester.pumpWidget(
        _wrapNarrowPhone(
          const OutletListScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => _AuditAuthNotifier(AuthState.authenticated(ownerUser)),
            ),
            outletsListProvider.overrideWith((ref) async {
              attempts += 1;
              if (attempts == 1) {
                throw Exception('Koneksi timeout sementara');
              }
              return [
                OutletModel(
                  id: 'out-1',
                  name: 'ARUS Cabang Yogyakarta',
                  address: 'Jl. Jenderal Sudirman No. 12',
                  latitude: -7.7828,
                  longitude: 110.3670,
                  timezone: 'Asia/Jakarta',
                  isActive: true,
                  inventoryCount: 28,
                  assignedUsersCount: 5,
                  createdAt: DateTime(2026, 1, 1),
                ),
              ];
            }),
            nearestOutletProvider.overrideWith(
              (ref) async => const NearestOutletResult(allOutletsSorted: []),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final retryBtn = find.widgetWithText(ShadButton, 'Coba Lagi');
      expect(retryBtn, findsOneWidget);
      expect(tester.getSize(retryBtn).height, greaterThanOrEqualTo(44.0));

      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('ARUS Cabang Yogyakarta'), findsOneWidget);
    });

    testWidgets('LoginScreen bebas overflow pada viewport 360x640 dengan skala teks 1.3x', (tester) async {
      useSmallPhoneViewport(tester);

      await tester.pumpWidget(_wrapNarrowPhone(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final masukBtn = find.widgetWithText(PrimaryButton, 'Masuk');
      expect(masukBtn, findsOneWidget);
      expect(tester.getSize(masukBtn).height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('DashboardScreen bebas overflow pada 360x640 dengan skala teks 1.3x dan nama cabang panjang', (tester) async {
      useSmallPhoneViewport(tester);

      const longOutletOwner = UserModel(
        id: 'u-owner-long',
        name: 'Pak Budi',
        email: 'budi@arus.demo',
        role: UserRole.owner,
        outlets: [
          OutletSummary(
            id: 'out-long',
            name: 'Kopi Arus - Cabang Sangat Panjang Sekali Sudirman HQ Mall Grand Indonesia',
            timezone: 'Asia/Jakarta',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapNarrowPhone(
          const DashboardScreen(),
          overrides: [
            authProvider.overrideWith(
              (ref) => _AuditAuthNotifier(AuthState.authenticated(longOutletOwner)),
            ),
            analyticsOverviewProvider.overrideWith(
              (ref) async => const AnalyticsOverviewModel(
                revenueIdr: 2500000,
                subtotalIdr: 2500000,
                discountIdr: 0,
                transactionCount: 50,
                avgBasketSizeIdr: 50000,
                totalCostIdr: 1000000,
                grossProfitIdr: 1500000,
                grossMarginPct: 60,
              ),
            ),
            salesTrendProvider.overrideWith(
              (ref) async => const [
                SalesTrendPoint(date: '2026-10-01', revenueIdr: 300000, count: 6),
                SalesTrendPoint(date: '2026-10-02', revenueIdr: 450000, count: 9),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Semua Cabang'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Kopi Arus - Cabang Sangat Panjang').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Omzet'), findsOneWidget);
    });
  });
}
