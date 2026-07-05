import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../models/scale_plu.dart';
import 'scale_service.dart';

class RamuzaTcpScaleService implements ScaleService {
  final String ip;
  final int port;
  final Duration timeout;

  const RamuzaTcpScaleService({
    required this.ip,
    this.port = 33581,
    this.timeout = const Duration(seconds: 3),
  });

  @override
  Future<ScaleResult> testConnection() async {
    Socket? socket;

    try {
      socket = await Socket.connect(ip, port, timeout: timeout);

      return ScaleResult.ok(
        'Conexão com a Ramuza estabelecida em $ip:$port.',
      );
    } on SocketException catch (e) {
      return ScaleResult.fail(
        'Não foi possível conectar na balança em $ip:$port. Verifique cabo, IP e rede.',
        e,
      );
    } on TimeoutException catch (e) {
      return ScaleResult.fail(
        'Tempo esgotado ao tentar conectar na balança em $ip:$port.',
        e,
      );
    } catch (e) {
      return ScaleResult.fail(
        'Erro inesperado ao testar conexão com a balança.',
        e,
      );
    } finally {
      socket?.destroy();
    }
  }

  @override
  Future<ScaleResult> sendPlu(ScalePlu plu) async {
    Socket? socket;

    try {
      socket = await Socket.connect(ip, port, timeout: timeout);

      final command = _buildTemporaryPluPayload(plu);

      socket.add(utf8.encode(command));
      await socket.flush();

      return ScaleResult.ok(
        'Comando de PLU enviado para a balança. A resposta real ainda depende do protocolo Ramuza.',
      );
    } catch (e) {
      return ScaleResult.fail(
        'Falha ao enviar PLU para a balança.',
        e,
      );
    } finally {
      socket?.destroy();
    }
  }

  @override
  Future<ScaleResult> sendAllPlus(List<ScalePlu> plus) async {
    var successCount = 0;
    var failCount = 0;

    for (final plu in plus) {
      final result = await sendPlu(plu);

      if (result.success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (failCount == 0) {
      return ScaleResult.ok('$successCount PLUs enviados para a balança.');
    }

    return ScaleResult.fail(
      '$successCount PLUs enviados, $failCount falharam.',
    );
  }

  String _buildTemporaryPluPayload(ScalePlu plu) {
    return [
      'PLU=${plu.pluCode}',
      'NOME=${plu.name}',
      'PRECO_KG=${plu.pricePerKg.toStringAsFixed(2)}',
      'CODIGO=${plu.barcode}',
      '',
    ].join('\n');
  }
}
