import 'package:dailyexpensetracker/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_currency.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(currencyProvider);
    final currency = notifier.currency;
    final inAppReview = InAppReview.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Preferences'),

          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text('${currency.code} – ${currency.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context, ref),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            value: ref.watch(themeProvider).isDarkMode,
            onChanged: (value) =>
                ref.read(themeProvider).toggle(value),
          ),

          const Divider(),

          const _SectionHeader('Premium'),

          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Remove Ads'),
            subtitle: const Text('Go premium for an ad-free experience'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
          ),

          const Divider(),

          const _SectionHeader('Support'),

          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('Rate App'),
            onTap: () async {
              if (await inAppReview.isAvailable()) {
                await inAppReview.requestReview();
              } else {
                await inAppReview.openStoreListing();
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyPolicy(context),
          ),

          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contact Us'),
            subtitle: const Text('ceylonappstudio@gmail.com'),
            onTap: _contactUs,
          ),

          const Divider(),

          const AppVersionTile(),
        ],
      ),
    );
  }

  // ======================
  // Currency Picker
  // ======================
  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final notifier = ref.read(currencyProvider);

        return ListView(
          children: supportedCurrencies.map((c) {
            return RadioListTile<AppCurrency>(
              value: c,
              groupValue: notifier.currency,
              title: Text('${c.code} – ${c.name}'),
              secondary: Text(c.symbol),
              onChanged: (value) {
                if (value != null) {
                  notifier.setCurrency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  // ======================
  // Privacy Policy (Updated)
  // ======================
  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              Text(
                'Daily Expense Tracker respects your privacy. '
                    'We do not collect, store, or share any personal information.\n\n'

                    'All expense and income data you enter is stored locally on your device only. '
                    'We do not upload your data to any server or cloud.\n\n'

                    'The app does not access your contacts, photos, camera, microphone, or location.\n\n'

                    'The free version may display ads using Google AdMob. '
                    'Ad providers may collect anonymous device information in accordance with '
                    'their own privacy policies.\n\n'

                    'Premium purchases are handled securely by Google Play Billing. '
                    'We do not store or process any payment information.\n\n'

                    'By using this app, you agree to this Privacy Policy.',
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ======================
  // Contact Us
  // ======================
  void _contactUs() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'ceylonappstudio@gmail.com',
      query: 'subject=Daily Expense Tracker Support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// ======================
// Section Header Widget
// ======================
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

// ======================
// App Version
// ======================
class AppVersionTile extends StatelessWidget {
  const AppVersionTile({super.key});

  Future<String> _getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return 'Version ${info.version} (${info.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getVersion(),
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              snapshot.data ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
