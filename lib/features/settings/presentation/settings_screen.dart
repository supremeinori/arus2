import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_converter.dart';
import '../../../shared/widgets/settings_tile.dart';
import 'currency_provider.dart';

/// Hub pengaturan aplikasi: kurs dan zona waktu.
///
/// Layar ini hanya memuat pintu masuk kedua domain tersebut. Rinciannya ada di
/// layar masing-masing (`/settings/currency` dan `/settings/time`) supaya daftar
/// pengaturan tetap pendek, sementara nilai aktif tiap domain langsung terbaca
/// dari chip di sisi kanan baris.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(displayCurrencyProvider);
    final timezone = ref.watch(displayTimezoneProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Pengaturan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsSectionLabel('Tampilan & Waktu'),
            const SizedBox(height: 8),
            SettingsSectionCard(
              children: [
                SettingsNavTile(
                  icon: Icons.payments_outlined,
                  title: 'Pengaturan Kurs',
                  subtitle: 'Mata uang tampilan, kalkulator, & pratinjau omzet',
                  onTap: () => context.push('/settings/currency'),
                  trailing: SettingsValueChip(
                    label: currency,
                    icon: Icons.attach_money_rounded,
                  ),
                ),
                const SettingsTileDivider(),
                SettingsNavTile(
                  icon: Icons.schedule_outlined,
                  title: 'Pengaturan Waktu',
                  subtitle: 'Zona waktu operasional & jam toko',
                  onTap: () => context.push('/settings/time'),
                  trailing: SettingsValueChip(
                    label: TimezoneConverter.getSuffix(timezone),
                    icon: Icons.public_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
