enum DashboardShortcutType {
  sale,
  inventory,
  credit,
  notes,
  cash,
  reports,
  alerts,
}

extension DashboardShortcutTypeInfo on DashboardShortcutType {
  String get label {
    switch (this) {
      case DashboardShortcutType.sale:
        return 'Nova venda';
      case DashboardShortcutType.inventory:
        return 'Repor estoque';
      case DashboardShortcutType.credit:
        return 'Cobrar fiado';
      case DashboardShortcutType.notes:
        return 'Anotações';
      case DashboardShortcutType.cash:
        return 'Caixa';
      case DashboardShortcutType.reports:
        return 'Relatórios';
      case DashboardShortcutType.alerts:
        return 'Alertas';
    }
  }

  String get subtitle {
    switch (this) {
      case DashboardShortcutType.sale:
        return 'Abrir tela de caixa';
      case DashboardShortcutType.inventory:
        return 'Entrada rápida de produto';
      case DashboardShortcutType.credit:
        return 'Consultar clientes devendo';
      case DashboardShortcutType.notes:
        return 'Recados e lembretes';
      case DashboardShortcutType.cash:
        return 'Ver vendas do dia';
      case DashboardShortcutType.reports:
        return 'Resumo do sistema';
      case DashboardShortcutType.alerts:
        return 'Avisos importantes';
    }
  }

  int get moduleIndex {
    switch (this) {
      case DashboardShortcutType.sale:
        return 1;
      case DashboardShortcutType.inventory:
        return 2;
      case DashboardShortcutType.credit:
        return 3;
      case DashboardShortcutType.cash:
        return 4;
      case DashboardShortcutType.reports:
        return 5;
      case DashboardShortcutType.notes:
        return 6;
      case DashboardShortcutType.alerts:
        return 7;
    }
  }
}

DashboardShortcutType dashboardShortcutTypeFromName(String? value) {
  return DashboardShortcutType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => DashboardShortcutType.sale,
  );
}

class DashboardShortcut {
  const DashboardShortcut({
    required this.type,
    required this.enabled,
  });

  final DashboardShortcutType type;
  final bool enabled;

  DashboardShortcut copyWith({
    DashboardShortcutType? type,
    bool? enabled,
  }) {
    return DashboardShortcut(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'enabled': enabled,
    };
  }

  factory DashboardShortcut.fromMap(Map<String, dynamic> map) {
    return DashboardShortcut(
      type: dashboardShortcutTypeFromName(map['type']?.toString()),
      enabled: _toBool(map['enabled']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    return value?.toString().toLowerCase() == 'true';
  }
}

class DashboardShortcutDefaults {
  DashboardShortcutDefaults._();

  static List<DashboardShortcut> items() {
    return const [
      DashboardShortcut(type: DashboardShortcutType.sale, enabled: true),
      DashboardShortcut(type: DashboardShortcutType.inventory, enabled: true),
      DashboardShortcut(type: DashboardShortcutType.credit, enabled: true),
      DashboardShortcut(type: DashboardShortcutType.notes, enabled: true),
      DashboardShortcut(type: DashboardShortcutType.cash, enabled: false),
      DashboardShortcut(type: DashboardShortcutType.reports, enabled: false),
      DashboardShortcut(type: DashboardShortcutType.alerts, enabled: false),
    ];
  }
}
