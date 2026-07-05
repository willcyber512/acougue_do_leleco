import '../lib/models/scale_plu.dart';
import '../lib/services/scales/scale_service_factory.dart';

Future<void> main() async {
  final testPlu = ScalePlu(
    id: 'teste-1',
    productId: 'produto-1',
    pluCode: '000001',
    barcode: '2000001000000',
    name: 'Carne moida teste',
    pricePerKg: 35.90,
    isWeightProduct: true,
  );

  print('==============================');
  print('TESTE 1: SIMULADOR');
  print('==============================');

  final fakeService = ScaleServiceFactory.create(
    mode: ScaleConnectionMode.simulator,
  );

  final fakeConnection = await fakeService.testConnection();
  print('Conexao simulador: ${fakeConnection.success}');
  print(fakeConnection.message);

  final fakeSend = await fakeService.sendPlu(testPlu);
  print('Envio PLU simulador: ${fakeSend.success}');
  print(fakeSend.message);

  print('');
  print('==============================');
  print('TESTE 2: RAMUZA TCP');
  print('==============================');
  print('Sem cabo de rede, esse teste provavelmente vai falhar. Isso é normal.');

  final ramuzaService = ScaleServiceFactory.create(
    mode: ScaleConnectionMode.ramuzaTcp,
    ip: '192.168.0.150',
    port: 33581,
  );

  final ramuzaConnection = await ramuzaService.testConnection();
  print('Conexao Ramuza TCP: ${ramuzaConnection.success}');
  print(ramuzaConnection.message);
}
