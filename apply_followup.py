from pathlib import Path

ROOT = Path.cwd()
PENDING = {}

def replace_once(path: str, old: str, new: str) -> None:
    file_path = ROOT / path
    content = PENDING.get(path, file_path.read_text(encoding='utf-8'))
    count = content.count(old)
    if count != 1:
        raise SystemExit(
            f"Stopped safely: expected exactly one match in {path}, found {count}. "
            "No replacement was made for this block. Check your local file before editing manually."
        )
    PENDING[path] = content.replace(old, new, 1)
    print(f"Prepared update for {path}")

replace_once(
    'apps/mobile/lib/app.dart',
    "    final accent = accentPresets[ref.watch(accentIndexProvider)];\n",
    '',
)
replace_once(
    'apps/mobile/lib/app.dart',
    "    final isDark = themeMode == ThemeMode.dark;\n"
    "    final theme = AppTheme.build(accent: accent, isDark: isDark);\n"
    "    final darkTheme = AppTheme.build(accent: accent, isDark: true);",
    "    final theme = AppTheme.light;\n"
    "    final darkTheme = AppTheme.dark;",
)
replace_once(
    'apps/mobile/lib/features/home/home_screen.dart',
    "            const _QuickActions(),\n            const SizedBox(height: 24),",
    "            const _QuickActions(),\n"
    "            const SizedBox(height: 12),\n"
    "            const _HomeFeatureShortcuts(),\n"
    "            const SizedBox(height: 24),",
)
replace_once(
    'apps/mobile/lib/features/home/home_screen.dart',
    "  static void _goGroups(BuildContext context) => context.go('/profile');\n}\n\nclass _QuickActionTile extends StatelessWidget {",
    "  static void _goGroups(BuildContext context) => context.push('/groups');\n}\n\n"
    "class _HomeFeatureShortcuts extends StatelessWidget {\n"
    "  const _HomeFeatureShortcuts();\n\n"
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    return Row(\n"
    "      children: [\n"
    "        Expanded(\n"
    "          child: _FeatureShortcut(\n"
    "            icon: Icons.groups_2_outlined,\n"
    "            label: 'Groups',\n"
    "            onTap: () => context.push('/groups'),\n"
    "          ),\n"
    "        ),\n"
    "        const SizedBox(width: 12),\n"
    "        Expanded(\n"
    "          child: _FeatureShortcut(\n"
    "            icon: Icons.account_balance_wallet_outlined,\n"
    "            label: 'Budgets',\n"
    "            onTap: () => context.push('/budget'),\n"
    "          ),\n"
    "        ),\n"
    "      ],\n"
    "    );\n"
    "  }\n"
    "}\n\n"
    "class _FeatureShortcut extends StatelessWidget {\n"
    "  const _FeatureShortcut({\n"
    "    required this.icon,\n"
    "    required this.label,\n"
    "    required this.onTap,\n"
    "  });\n\n"
    "  final IconData icon;\n"
    "  final String label;\n"
    "  final VoidCallback onTap;\n\n"
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    final colors = Theme.of(context).colorScheme;\n"
    "    return Card(\n"
    "      margin: EdgeInsets.zero,\n"
    "      child: InkWell(\n"
    "        borderRadius: BorderRadius.circular(12),\n"
    "        onTap: onTap,\n"
    "        child: Padding(\n"
    "          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),\n"
    "          child: Row(\n"
    "            children: [\n"
    "              Icon(icon, color: colors.primary),\n"
    "              const SizedBox(width: 10),\n"
    "              Text(label, style: Theme.of(context).textTheme.titleSmall),\n"
    "              const Spacer(),\n"
    "              const Icon(Icons.chevron_right, size: 18),\n"
    "            ],\n"
    "          ),\n"
    "        ),\n"
    "      ),\n"
    "    );\n"
    "  }\n"
    "}\n\n"
    "class _QuickActionTile extends StatelessWidget {",
)

replace_once(
    'apps/mobile/test/home_screen_test.dart',
    "import 'package:settl/config/environment.dart';\n",
    '',
)
replace_once(
    'apps/mobile/test/home_screen_test.dart',
    "    await Environment.init();\n",
    '',
)
replace_once(
    'apps/mobile/test/widget_test.dart',
    "import 'package:settl/features/budget/budget_screen.dart';",
    "import 'package:settl/features/activity/activity_screen.dart';",
)
replace_once(
    'apps/mobile/test/widget_test.dart',
    "BudgetScreen",
    "ActivityScreen",
)
def replace_all(path: str, old: str, new: str) -> None:
    file_path = ROOT / path
    content = PENDING.get(path, file_path.read_text(encoding='utf-8'))
    count = content.count(old)
    if count == 0:
        raise SystemExit(f"Stopped safely: no {old!r} text found in {path}.")
    PENDING[path] = content.replace(old, new)
    print(f"Prepared update for {path} ({count} replacements)")

replace_all('apps/mobile/test/widget_test.dart', 'Budget', 'Activity')

# Commit all edits only after every expected source block has passed validation.
for relative_path, content in PENDING.items():
    (ROOT / relative_path).write_text(content, encoding='utf-8', newline='')
    print(f'Wrote {relative_path}')
