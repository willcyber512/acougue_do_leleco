import '../../models/scale_plu.dart';
import 'scale_service.dart';

class FakeScaleService implements ScaleService {
  @override
  Future<ScaleResult> testConnection() async {
    await Future.delayed(const Duration(milliseconds: 700));

    return ScaleResult.ok(
      'Simulador conectado. Use este modo enquanto a balança real não estiver ligada ao sistema.',
    );
  }

  @override
  Future<ScaleResult> sendPlu(ScalePlu plu) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return ScaleResult.ok(
      'PLU simulado enviado: ${plu.pluCode} - ${plu.name}',
    );
  }

  @override
  Future<ScaleResult> sendAllPlus(List<ScalePlu> plus) async {
    await Future.delayed(const Duration(seconds: 1));

    return ScaleResult.ok(
      '${plus.length} PLUs simulados enviados com sucesso.',
    );
  }
}
