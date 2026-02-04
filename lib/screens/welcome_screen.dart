import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_currency.dart';
import '../providers/currency_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int _page = 0;

  late final AnimationController _fadeController =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
    ..forward();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    _fadeController.forward(from: 0);
                  },
                  children: const [
                    _OnboardPage(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Daily Expense Tracker',
                      subtitle:
                      'Easily record daily expenses\nand stay aware of your spending',
                    ),
                    _OnboardPage(
                      icon: Icons.pie_chart_outline,
                      title: 'Visual Insights',
                      subtitle:
                      'Monthly summaries help you\nunderstand where your money goes',
                    ),
                    _OnboardPage(
                      icon: Icons.lock_outline,
                      title: 'Private & Offline',
                      subtitle:
                      'No sign-up required\nYour data stays on your device',
                    ),
                  ],
                ),
              ),

              // Page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Trust badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '100% Offline · No Sign-up',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),

              const SizedBox(height: 24),

              FadeTransition(
                opacity: _fadeController,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white, // ✅ white text & icon color
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_page < 2) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } else {
                        setDefaultCurrencyIfNeeded(ref);
                        Navigator.pushReplacementNamed(context, '/main');
                      }
                    },
                    child: Text(_page == 2 ? 'Get Started' : 'Next'),
                  ),
                ),
                ),

            ],
          ),
        ),
      ),
    );
  }

  void setDefaultCurrencyIfNeeded(WidgetRef ref) {
    final notifier = ref.read(currencyProvider.notifier);
    final current = ref.read(currencyProvider).currency;

    if (current.code != 'LKR') {
      notifier.setCurrency(
        AppCurrency(
          code: 'LKR',
          name: 'Sri Lankan Rupee',
          symbol: 'Rs',
        ),
      );
    }
  }

}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 72, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
        ),
      ],
    );
  }
}

