import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';

class DesktopShellScreen extends StatefulWidget {
  const DesktopShellScreen({super.key});

  @override
  State<DesktopShellScreen> createState() => _DesktopShellScreenState();
}

class _DesktopShellScreenState extends State<DesktopShellScreen> {
  int selectedIndex = 0;

  final pages = const [
    'Hoje',
    'Venda',
    'Estoque',
    'Fiado',
    'Caixa',
    'Relatórios',
    'Alertas',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: selectedIndex,
            pages: pages,
            onSelect: (index) => setState(() => selectedIndex = index),
          ),
          Expanded(
            child: Container(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              child: Column(
                children: [
                  _TopBar(title: pages[selectedIndex]),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _PageContent(title: pages[selectedIndex]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.pages,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<String> pages;
  final ValueChanged<int> onSelect;

  IconData iconFor(int index) {
    return [
      Icons.dashboard_rounded,
      Icons.point_of_sale_rounded,
      Icons.inventory_2_rounded,
      Icons.people_alt_rounded,
      Icons.payments_rounded,
      Icons.bar_chart_rounded,
      Icons.notifications_rounded,
      Icons.settings_rounded,
    ][index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 235,
      color: isDark ? const Color(0xFF1C1516) : const Color(0xFFFFFBF7),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.wine900,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: Text(
                '🥩',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Açougue do\nLeleco',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 32),
          for (int i = 0; i < pages.length; i++)
            _MenuItem(
              label: pages[i],
              icon: iconFor(i),
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.wine900 : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        leading: Icon(
          icon,
          color: selected ? AppColors.beige100 : AppColors.wine700,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            color: selected ? AppColors.beige100 : null,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const Spacer(),
          SizedBox(
            width: 360,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar produto, cliente ou código...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: themeProvider.toggleTheme,
            icon: const Icon(Icons.dark_mode_rounded),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    if (title != 'Hoje') {
      return _PlaceholderPage(title: title);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.payments_rounded,
                title: 'Faturamento hoje',
                value: 'R\$ 1.250,00',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                icon: Icons.people_alt_rounded,
                title: 'Fiado aberto',
                value: 'R\$ 350,00',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_rounded,
                title: 'Vendas realizadas',
                value: '24',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                icon: Icons.warning_rounded,
                title: 'Alertas',
                value: '5',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _ActionCard(
              icon: Icons.point_of_sale_rounded,
              title: 'Nova venda',
              subtitle: 'Abrir tela de caixa',
            ),
            _ActionCard(
              icon: Icons.add_box_rounded,
              title: 'Repor estoque',
              subtitle: 'Entrada rápida de produto',
            ),
            _ActionCard(
              icon: Icons.person_search_rounded,
              title: 'Cobrar fiado',
              subtitle: 'Consultar clientes devendo',
            ),
            _ActionCard(
              icon: Icons.note_alt_rounded,
              title: 'Anotações',
              subtitle: 'Recados e lembretes',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 136,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.wine700, size: 28),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 112,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.wine900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: AppColors.beige100),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title será implementado nas próximas sprints.',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
