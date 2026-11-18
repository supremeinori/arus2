import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../dashboard/presentation/shift_summary_screen.dart';
import '../../pos/presentation/pos_screen.dart';
import '../../operations/presentation/operations_hub_screen.dart';
import '../../inventory/presentation/inventory_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../core/theme/app_theme.dart';

/// State Provider untuk mengontrol tab aktif pada MainShell (0-indexed).
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(shellTabIndexProvider.notifier).state = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isStaff = user?.role == UserRole.staff;
    final currentIndex = ref.watch(shellTabIndexProvider);

    // Kasir: Tab 0 langsung Kasir (POS) agar zero-friction saat mulai transaksi.
    // Owner / Manager: 3 tab esensial (Beranda, Operasi, Profil).
    final List<Widget> pages = isStaff
        ? const [
            PosScreen(),
            InventoryListScreen(),
            ShiftSummaryScreen(),
            ProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            OperationsHubScreen(),
            ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isStaff
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_outlined),
              activeIcon: Icon(Icons.point_of_sale),
              label: 'Kasir',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Stok',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Shift',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_outlined),
              activeIcon: Icon(Icons.menu),
              label: 'Profil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Operasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_outlined),
              activeIcon: Icon(Icons.menu),
              label: 'Profil',
            ),
          ];

    final safeIndex = currentIndex >= pages.length ? 0 : currentIndex;

    final scaffold = Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.lightCardSurface,
          border: Border(
            top: BorderSide(color: AppTheme.lightCardBorder, width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.lightCardSurface,
          elevation: 0,
          currentIndex: safeIndex,
          onTap: (index) {
            ref.read(shellTabIndexProvider.notifier).state = index;
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryAction,
          unselectedItemColor: AppTheme.textMutedLight,
          selectedFontSize: 11.5,
          unselectedFontSize: 11.5,
          items: navItems,
        ),
      ),
    );

    if (ShadTheme.maybeOf(context) == null) {
      return ShadTheme(
        data: AppTheme.shadcnThemeLight,
        child: scaffold,
      );
    }
    return scaffold;
  }
}
