import '../../models/scale_plu.dart';

class ScaleResult {
  final bool success;
  final String message;
  final Object? error;

  const ScaleResult({
    required this.success,
    required this.message,
    this.error,
  });

  factory ScaleResult.ok(String message) {
    return ScaleResult(success: true, message: message);
  }

  factory ScaleResult.fail(String message, [Object? error]) {
    return ScaleResult(success: false, message: message, error: error);
  }
}

abstract class ScaleService {
  Future<ScaleResult> testConnection();

  Future<ScaleResult> sendPlu(ScalePlu plu);

  Future<ScaleResult> sendAllPlus(List<ScalePlu> plus);
}
