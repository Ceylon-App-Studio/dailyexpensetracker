import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_provider.dart';

enum PlanChoice { monthly, yearly }

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  PlanChoice _choice = PlanChoice.yearly;

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(subscriptionUiProvider);
    final notifier = ref.read(subscriptionUiProvider.notifier);

    final isPremium = ui.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
        actions: [
          TextButton(
            onPressed: ui.loading ? null : notifier.restore,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(isPremium: isPremium),
              const SizedBox(height: 16),

              if (ui.error != null) ...[
                _ErrorBanner(message: ui.error!),
                const SizedBox(height: 12),
              ],

              const Text(
                'What you get',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              //const _FeatureItem('Unlimited categories'),
              const _FeatureItem('Advanced charts & insights'),
              const _FeatureItem('PDF export insights'),
              const _FeatureItem('Smart budget alerts (Coming Soon)'),
              const _FeatureItem('Recurring expenses & reminders (Coming Soon)'),
              const _FeatureItem('Ad-free experience'),

              const SizedBox(height: 18),

              if (!isPremium) ...[
                const Text(
                  'Choose your plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _PlanToggle(
                  choice: _choice,
                  onChanged: (c) => setState(() => _choice = c),
                ),

                const SizedBox(height: 12),

                _SavingsHint(choice: _choice),
              ] else ...[
                _ActiveInfo(validTill: ui.localSub!.endDate),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (ui.loading || isPremium) ? null : () async {
                    // For MVP we purchase the single subscription product.
                    // Monthly vs yearly base plan selection can be added after you confirm Play Console setup.
                    await notifier.buyPremium();
                  },
                  child: ui.loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(isPremium ? 'Premium Active' : 'Continue'),
                ),
              ),

              const SizedBox(height: 10),
              Text(
                'You can cancel anytime in Google Play → Subscriptions.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isPremium;
  const _HeaderCard({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPremium ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium,
            size: 34,
            color: isPremium ? Colors.green : Colors.amber.shade800,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPremium ? 'Premium is active 🎉' : 'Upgrade to Premium',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PlanToggle extends StatelessWidget {
  final PlanChoice choice;
  final ValueChanged<PlanChoice> onChanged;

  const _PlanToggle({required this.choice, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              selected: choice == PlanChoice.monthly,
              title: 'Monthly',
              subtitle: 'Rs. 300',
              onTap: () => onChanged(PlanChoice.monthly),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              selected: choice == PlanChoice.yearly,
              title: 'Yearly',
              subtitle: 'Rs. 3000',
              onTap: () => onChanged(PlanChoice.yearly),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _SavingsHint extends StatelessWidget {
  final PlanChoice choice;
  const _SavingsHint({required this.choice});

  @override
  Widget build(BuildContext context) {
    // 300 x 12 = 3600, yearly 3000 => save 600
    final text = choice == PlanChoice.yearly
        ? 'Save Rs. 600 per year compared to monthly.'
        : 'Switch to yearly to save Rs. 600 per year.';
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}

class _ActiveInfo extends StatelessWidget {
  final DateTime validTill;
  const _ActiveInfo({required this.validTill});

  @override
  Widget build(BuildContext context) {
    final date = validTill.toLocal().toString().split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('Valid until: $date'),
    );
  }
}
