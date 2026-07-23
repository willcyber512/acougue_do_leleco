import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/payment_method.dart';
import '../models/sale.dart';

class ReceiptPdfService {
  ReceiptPdfService._();

  static Future<void> openReceiptPdf(SaleRecord sale) async {
    final pdfBytes = await buildReceiptPdf(sale);

    await Printing.layoutPdf(
      name: 'comprovante_${sale.shortId}.pdf',
      onLayout: (_) async => pdfBytes,
    );
  }

  static Future<Uint8List> buildReceiptPdf(SaleRecord sale) async {
    final document = pw.Document();

    final logo = await _loadLogo();

    final wine = PdfColor.fromInt(0xFF561C24);
    final beige = PdfColor.fromInt(0xFFE8D8C4);
    final danger = PdfColor.fromInt(0xFFC62828);
    final success = PdfColor.fromInt(0xFF2E7D32);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 28,
          marginRight: 28,
          marginTop: 28,
          marginBottom: 28,
        ),
        build: (context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Container(
                    width: 70,
                    height: 70,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: wine,
                      borderRadius: pw.BorderRadius.circular(16),
                    ),
                    child: logo == null
                        ? pw.Center(
                            child: pw.Text(
                              'AL',
                              style: pw.TextStyle(
                                color: beige,
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          )
                        : pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Açougue do Leleco',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Comprovante de venda #${sale.shortId}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),
            _sectionTitle('Dados da venda', wine),
            pw.SizedBox(height: 8),
            _infoRow('Data', _formatDateTime(sale.createdAt)),
            _infoRow('Pagamento', sale.paymentMethod.label),
            if (sale.customerName != null)
              _infoRow('Cliente', sale.customerName!),
            _infoRow(
              'Status',
              sale.isCanceled ? 'Cancelada' : 'Finalizada',
              valueColor: sale.isCanceled ? danger : success,
            ),
            if (sale.isCanceled) ...[
              _infoRow(
                'Cancelada em',
                _formatDateTime(sale.canceledAt!),
                valueColor: danger,
              ),
              _infoRow(
                'Motivo',
                sale.cancelReason ?? 'Cancelamento manual',
                valueColor: danger,
              ),
            ],
            pw.SizedBox(height: 18),
            _sectionTitle('Itens', wine),
            pw.SizedBox(height: 8),
            _itemsTable(sale),
            pw.SizedBox(height: 18),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: wine,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (sale.hasDiscount) ...[
                    _pdfTotalLine(
                      'Subtotal',
                      _formatMoney(sale.grossTotal),
                      beige,
                    ),
                    pw.SizedBox(height: 4),
                    _pdfTotalLine(
                      'Desconto',
                      '- ${_formatMoney(sale.safeDiscountAmount)}',
                      beige,
                    ),
                    pw.SizedBox(height: 8),
                  ],
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      color: beige,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    _formatMoney(sale.total),
                    style: pw.TextStyle(
                      color: beige,
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      decoration: sale.isCanceled
                          ? pw.TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Obrigado pela preferência.',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _pdfTotalLine(String label, String value, PdfColor color) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
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

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _infoRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 95,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(SaleRecord sale) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromInt(0xFFE0E0E0),
        width: 0.6,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3E8DF)),
          children: [
            _tableCell('Produto', bold: true),
            _tableCell('Qtd', bold: true),
            _tableCell('Preço', bold: true),
            _tableCell('Subtotal', bold: true),
          ],
        ),
        ...sale.items.map((item) {
          return pw.TableRow(
            children: [
              _tableCell('${item.productName}\nCódigo ${item.productCode}'),
              _tableCell('${_formatNumber(item.quantity)} ${item.unitLabel}'),
              _tableCell(_formatMoney(item.unitPrice)),
              _tableCell(_formatMoney(item.subtotal), bold: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _formatMoney(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  static String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(3).replaceAll('.', ',');
  }

  static String _formatDateTime(DateTime value) {
    final day = _two(value.day);
    final month = _two(value.month);
    final year = value.year;
    final hour = _two(value.hour);
    final minute = _two(value.minute);

    return '$day/$month/$year $hour:$minute';
  }

  static String _two(int value) {
    return value.toString().padLeft(2, '0');
  }
}
