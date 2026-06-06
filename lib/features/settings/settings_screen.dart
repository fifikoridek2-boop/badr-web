import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final Uri _developerUri = Uri.parse('https://Akio-web.vercel.app');

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text(
          'الإعدادات',
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
            color: color.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ThemeSettingsCard(),
          SizedBox(height: 12),
          _SettingsInfoCard(),
          SizedBox(height: 12),
          _SettingsTipsCard(),
          SizedBox(height: 20),
          _DeveloperCard(),
        ],
      ),
    );
  }

  static Future<void> openDeveloperWebsite() async {
    await launchUrl(_developerUri, mode: LaunchMode.externalApplication);
  }
}

class _ThemeSettingsCard extends StatelessWidget {
  const _ThemeSettingsCard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return _SettingsCard(
      title: 'المظهر',
      icon: Icons.palette_outlined,
      child: Column(
        children: [
          _ThemeOptionTile(
            title: 'تلقائي',
            subtitle: 'يتبع إعدادات الجهاز',
            icon: Icons.brightness_auto_outlined,
            value: ThemeMode.system,
            selectedValue: themeProvider.themeMode,
            onTap: () => themeProvider.setTheme('auto'),
          ),
          Divider(color: color.outlineVariant, height: 1),
          _ThemeOptionTile(
            title: 'الوضع الفاتح',
            subtitle: 'ألوان مشرقة للقراءة النهارية',
            icon: Icons.light_mode_outlined,
            value: ThemeMode.light,
            selectedValue: themeProvider.themeMode,
            onTap: () => themeProvider.setTheme('light'),
          ),
          Divider(color: color.outlineVariant, height: 1),
          _ThemeOptionTile(
            title: 'الوضع الداكن',
            subtitle: 'ألوان هادئة للقراءة الليلية',
            icon: Icons.dark_mode_outlined,
            value: ThemeMode.dark,
            selectedValue: themeProvider.themeMode,
            onTap: () => themeProvider.setTheme('dark'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode selectedValue;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final selected = value == selectedValue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? color.primaryContainer
                    : color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? color.primary : color.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<ThemeMode>(
              value: value,
              groupValue: selectedValue,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  const _SettingsInfoCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'عن التطبيق',
      icon: Icons.info_outline_rounded,
      child: const Column(
        children: [
          _SimpleSettingRow(
            icon: Icons.apps_outlined,
            title: AppConstants.appName,
            value: 'تطبيق للقرآن والأذكار والصلاة',
          ),
          SizedBox(height: 12),
          _SimpleSettingRow(
            icon: Icons.verified_outlined,
            title: 'الإصدار',
            value: AppConstants.appVersion,
          ),
        ],
      ),
    );
  }
}

class _SettingsTipsCard extends StatelessWidget {
  const _SettingsTipsCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'تجربة الاستخدام',
      icon: Icons.tune_outlined,
      child: const Column(
        children: [
          _SimpleSettingRow(
            icon: Icons.language_outlined,
            title: 'اللغة',
            value: 'العربية',
          ),
          SizedBox(height: 12),
          _SimpleSettingRow(
            icon: Icons.cloud_outlined,
            title: 'المزامنة السحابية',
            value: 'قريباً',
          ),
        ],
      ),
    );
  }
}

class _SimpleSettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SimpleSettingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: color.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppConstants.fontCairo,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 13,
            color: color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: color.tertiary, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    'المطور',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DeveloperAvatar(color: color),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Akio | اكيو',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مرحباً! أنا Akio، مطور شغوف بعمر 15 سنة. بدأت رحلتي مع البرمجة منذ عام تقريباً، ومنذ ذلك الحين وأنا أتعلم وآتي بمشاريع جديدة باستمرار.',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 18,
                          height: 1.55,
                          color: color.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            OutlinedButton.icon(
              onPressed: SettingsScreen.openDeveloperWebsite,
              icon: Icon(Icons.open_in_new, color: color.tertiary, size: 30),
              label: Text(
                'Akio | Codex',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 22,
                  color: color.tertiary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 64),
                side: BorderSide(color: color.outline, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeveloperAvatar extends StatelessWidget {
  final ColorScheme color;

  const _DeveloperAvatar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Icon(
        Icons.face_6_outlined,
        color: color.onPrimary,
        size: 56,
      ),
    );
  }
}
