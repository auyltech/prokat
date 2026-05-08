import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/section_title.dart';

class OwnerSettingsScreen extends StatelessWidget {
  const OwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  "Settings",
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SectionTitle(title: "Availability"),

                // _card([
                //   _switchTile("Auto-accept bookings", true, (v) {}),
                //   _switchTile("Allow same-day bookings", false, (v) {}),
                //   _tile("Minimum rental duration", "1 day", () {}),
                // ]),

                // const SizedBox(height: 16),

                // SectionTitle(title: "Booking Preferences"),

                // _card([
                //   _switchTile("Require approval", true, (v) {}),
                //   _switchTile("Allow instant booking", false, (v) {}),
                //   _tile("Advance notice", "2 hours", () {}),
                // ]),

                // const SizedBox(height: 16),

                // SectionTitle(title: "Pricing Behavior"),
                // _card([
                //   _switchTile("Enable dynamic pricing", false, (v) {}),
                //   _switchTile("Weekend price adjustment", true, (v) {}),
                //   _tile("Security deposit", "\$100", () {}),
                // ]),

                // const SizedBox(height: 16),

                SectionTitle(title: "Notifications"),
                _card([
                  _switchTile("New booking requests", true, (v) {}),
                  _switchTile("Messages", true, (v) {}),
                  _switchTile("Reminders", true, (v) {}),
                ]),

                const SizedBox(height: 16),

                SectionTitle(title: "Safety & Rules"),

                _card([
                  _tile("Cancellation policy", "Moderate", () {}),
                  _tile("Damage policy", "Standard coverage", () {}),
                ]),

                const SizedBox(height: 16),

                SectionTitle(title: "Danger Zone"),

                _card([
                  _dangerTile("Deactivate account", () {}),
                  _dangerTile("Delete account", () {}),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(child: Column(children: children));
  }

  Widget _switchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _tile(String title, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _dangerTile(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.red)),
      onTap: onTap,
    );
  }
}
