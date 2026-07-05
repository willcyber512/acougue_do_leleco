import 'fake_scale_service.dart';
import 'ramuza_tcp_scale_service.dart';
import 'scale_service.dart';

enum ScaleConnectionMode {
  simulator,
  ramuzaTcp,
}

class ScaleServiceFactory {
  static ScaleService create({
    required ScaleConnectionMode mode,
    String? ip,
    int? port,
  }) {
    switch (mode) {
      case ScaleConnectionMode.simulator:
        return FakeScaleService();

      case ScaleConnectionMode.ramuzaTcp:
        if (ip == null || ip.trim().isEmpty) {
          throw ArgumentError('IP da balança não informado.');
        }

        return RamuzaTcpScaleService(
          ip: ip.trim(),
          port: port ?? 33581,
        );
    }
  }
}
