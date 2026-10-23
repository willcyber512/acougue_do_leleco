import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sale.dart';

class ReceiptPdfService {
  ReceiptPdfService._();

  static Future<void> openReceiptPdf(SaleRecord sale) async {
    final format = _receiptPageFormat(sale);
    final bytes = await _buildReceiptPdf(sale, format);

    await Printing.layoutPdf(
      name: 'comprovante_${sale.shortId}.pdf',
      format: format,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> buildReceiptPdf(SaleRecord sale) {
    return _buildReceiptPdf(sale, _receiptPageFormat(sale));
  }

  static PdfPageFormat _receiptPageFormat(SaleRecord sale) {
    // Formato para bobina térmica de 80 mm.
    double heightMm = 76.0;

    for (final item in sale.items) {
      final nameLength = item.productName.toString().length;
      final lines = ((nameLength + 37) ~/ 38).clamp(1, 4).toInt();
      heightMm += 14.0 + (lines - 1) * 3.5;
    }

    heightMm += sale.paymentReceiptLines.length * 4.5;

    if (sale.hasDiscount) heightMm += 9.0;

    if (sale.customerName?.trim().isNotEmpty ?? false) {
      heightMm += 6.0;
    }

    if (sale.isCanceled) {
      final reasonLength = (sale.cancelReason ?? '').length;
      heightMm += 9.0 + ((reasonLength + 39) ~/ 40) * 3.5;
    }

    if (heightMm < 90.0) heightMm = 90.0;

    return PdfPageFormat(80.0 * PdfPageFormat.mm, heightMm * PdfPageFormat.mm);
  }

  static Future<Uint8List> _buildReceiptPdf(
    SaleRecord sale,
    PdfPageFormat format,
  ) async {
    final document = pw.Document();
    final logo = await _loadLogo();

    document.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.fromLTRB(
          4 * PdfPageFormat.mm,
          3 * PdfPageFormat.mm,
          4 * PdfPageFormat.mm,
          3 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (logo != null) ...[
                pw.Center(
                  child: pw.SizedBox(
                    width: 24 * PdfPageFormat.mm,
                    height: 13 * PdfPageFormat.mm,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 2),
              ],

              pw.Center(
                child: pw.Text(
                  'ACOUgue DO LELECO'.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'COMPROVANTE DE VENDA #${sale.shortId}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  _formatDateTime(sale.createdAt),
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
              ),

              _separator(),

              if (sale.customerName?.trim().isNotEmpty ?? false) ...[
                pw.Text(
                  'Cliente: ${sale.customerName!.trim()}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 3),
              ],

              pw.Text(
                'ITENS DA VENDA',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),

              ...sale.items.map(_itemWidget),

              _separator(),

              if (sale.hasDiscount) ...[
                _pair('Subtotal', _formatMoney(sale.grossTotal)),
                _pair('Desconto', '- ${_formatMoney(sale.safeDiscountAmount)}'),
                pw.SizedBox(height: 2),
              ],

              _pair(
                'TOTAL',
                _formatMoney(sale.total),
                bold: true,
                fontSize: 11,
              ),

              _separator(),

              _paymentWidget(sale),

              if (sale.isCanceled) ...[
                _separator(),
                pw.Text(
                  'STATUS: VENDA CANCELADA',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (sale.canceledAt != null)
                  pw.Text(
                    'Cancelada em: ${_formatDateTime(sale.canceledAt!)}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                if (sale.cancelReason?.trim().isNotEmpty ?? false)
                  pw.Text(
                    'Motivo: ${sale.cancelReason!.trim()}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
              ],

              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Obrigado pela preferencia!',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Acougue do Leleco',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _itemWidget(dynamic item) {
    final name = item.productName.toString();
    final code = item.productCode.toString();
    final quantity = _formatNumber((item.quantity as num).toDouble());
    final unitPrice = _formatMoney((item.unitPrice as num).toDouble());
    final subtotal = _formatMoney((item.subtotal as num).toDouble());

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            name,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          ),
          if (code.trim().isNotEmpty)
            pw.Text('Codigo: $code', style: const pw.TextStyle(fontSize: 7)),
          pw.SizedBox(height: 1),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '$quantity ${item.unitLabel} x $unitPrice',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
              ),
              pw.SizedBox(width: 2),
              pw.Text(
                subtotal,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          _separator(),
        ],
      ),
    );
  }

  static pw.Widget _paymentWidget(SaleRecord sale) {
    final lines = sale.paymentReceiptLines
        .map((line) => line.toString())
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PAGAMENTO',
          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),

        if (sale.isMixedPayment) ...[
          pw.Text('Forma: Misto', style: const pw.TextStyle(fontSize: 8)),
          if (lines.isEmpty)
            pw.Text(
              'Detalhamento nao disponivel para esta venda.',
              style: const pw.TextStyle(fontSize: 7),
            )
          else
            ...lines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 1),
                child: pw.Text(line, style: const pw.TextStyle(fontSize: 8)),
              ),
            ),
        ] else
          pw.Text(
            'Forma: ${sale.paymentSummary}',
            style: const pw.TextStyle(fontSize: 8),
          ),
      ],
    );
  }

  static pw.Widget _pair(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 8,
  }) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 3),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static pw.Widget _separator() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Divider(height: 1, thickness: 0.5, color: PdfColors.black),
    );
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/logo/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }

  static String _formatDateTime(DateTime value) {
    return '${_two(value.day)}/${_two(value.month)}/${value.year} '
        '${_two(value.hour)}:${_two(value.minute)}';
  }

  static String _two(int value) {
    return value.toString().padLeft(2, '0');
  }
}
