import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/app_constants.dart';
import '../models/payment_method.dart';
import '../models/cash_closure.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';
import '../models/sale.dart';

class DailyReportPdfOptions {
  const DailyReportPdfOptions({
    this.keepOnePage = true,
    this.includeSummary = true,
    this.includePaymentTotals = true,
    this.includeProductSales = true,
    this.includeCategorySales = false,
    this.includeDetailedSales = false,
    this.includeLowStock = false,
    this.includeCashClosure = false,
  });

  final bool keepOnePage;
  final bool includeSummary;
  final bool includePaymentTotals;
  final bool includeProductSales;
  final bool includeCategorySales;
  final bool includeDetailedSales;
  final bool includeLowStock;
  final bool includeCashClosure;
}

class DailyReportPdfService {
  DailyReportPdfService._();

  static Future<void> openDailyReport({
    required List<SaleRecord> sales,
    required List<Product> products,
    required double openCredit,
    CashClosure? cashClosure,
    DailyReportPdfOptions options = const DailyReportPdfOptions(),
  }) async {
    final bytes = await buildDailyReport(
      sales: sales,
      products: products,
      openCredit: openCredit,
      cashClosure: cashClosure,
      options: options,
    );

    await Printing.layoutPdf(
      name: 'relatorio-fim-do-dia.pdf',
      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> buildDailyReport({
    required List<SaleRecord> sales,
    required List<Product> products,
    required double openCredit,
    required CashClosure? cashClosure,
    required DailyReportPdfOptions options,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    final activeProducts = products.where((product) => !product.isDeleted).toList();
    final lowStock = activeProducts.where((product) => product.isLowStock).toList();
    final emptyStock = activeProducts.where((product) => product.stockQuantity <= 0).toList();

    final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final totalQuantitySold = _soldItemsQuantity(sales);
    final averageTicket = sales.isEmpty ? 0.0 : totalRevenue / sales.length;
    final paymentTotals = _paymentTotals(sales);
    final topProducts = _topProducts(sales);
    final categoryTotals = _categoryTotals(sales, products);

    final productLimit = options.keepOnePage ? 8 : 40;
    final categoryLimit = options.keepOnePage ? 6 : 30;
    final salesLimit = options.keepOnePage ? 8 : 80;
    final stockLimit = options.keepOnePage ? 8 : 50;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          final widgets = <pw.Widget>[
            _header(now),
            pw.SizedBox(height: 14),
          ];

          if (options.includeSummary) {
            widgets.addAll([
              _sectionTitle('Resumo geral'),
              _summaryGrid([
                _SummaryItem('Vendas', sales.length.toString()),
                _SummaryItem('Faturamento', _formatMoney(totalRevenue)),
                _SummaryItem('Ticket médio', _formatMoney(averageTicket)),
                _SummaryItem('Itens/produtos', _formatNumber(totalQuantitySold)),
                _SummaryItem('Fiado aberto', _formatMoney(openCredit)),
                _SummaryItem('Estoque baixo', lowStock.length.toString()),
                _SummaryItem('Estoque zerado', emptyStock.length.toString()),
              ]),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includePaymentTotals) {
            widgets.addAll([
              _sectionTitle('Totais por pagamento'),
              _paymentTable(paymentTotals),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeProductSales) {
            widgets.addAll([
              _sectionTitle('Vendas por produto'),
              topProducts.isEmpty
                  ? _emptyText('Nenhum produto vendido hoje.')
                  : _topProductsTable(topProducts.take(productLimit).toList()),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeCategorySales) {
            widgets.addAll([
              _sectionTitle('Vendas por categoria'),
              categoryTotals.isEmpty
                  ? _emptyText('Nenhuma categoria vendida hoje.')
                  : _categoryTotalsTable(categoryTotals.take(categoryLimit).toList()),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeDetailedSales) {
            widgets.addAll([
              _sectionTitle('Vendas detalhadas'),
              sales.isEmpty
                  ? _emptyText('Nenhuma venda hoje.')
                  : _salesTable(sales.take(salesLimit).toList()),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeLowStock) {
            widgets.addAll([
              _sectionTitle('Estoque baixo'),
              lowStock.isEmpty
                  ? _emptyText('Nenhum produto em estoque baixo.')
                  : _stockTable(lowStock.take(stockLimit).toList()),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeCashClosure) {
            widgets.addAll([
              _sectionTitle('Fechamento de caixa'),
              cashClosure == null
                  ? _emptyText('Nenhum fechamento de caixa salvo para hoje.')
                  : _cashClosureTable(cashClosure),
              pw.SizedBox(height: 14),
            ]);
          }

          widgets.add(_footer(options.keepOnePage));

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _header(DateTime now) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            AppConstants.appName,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Relatório de fim do dia',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Gerado em ${_formatDateTime(now)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _summaryGrid(List<_SummaryItem> items) {
    return pw.Wrap(
      spacing: 7,
      runSpacing: 7,
      children: items.map((item) {
        return pw.Container(
          width: 118,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(item.label, style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 3),
              pw.Text(
                item.value,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _paymentTable(Map<PaymentMethod, double> totals) {
    final rows = PaymentMethod.values.map((method) {
      return [
        method.label,
        _formatMoney(totals[method] ?? 0.0),
      ];
    }).toList();

    return _table(headers: ['Forma', 'Total'], rows: rows);
  }

  static pw.Widget _topProductsTable(List<_TopProduct> products) {
    final rows = products.map((item) {
      return [
        item.name,
        _formatNumber(item.quantity),
        _formatMoney(item.total),
      ];
    }).toList();

    return _table(headers: ['Produto', 'Qtd', 'Total'], rows: rows);
  }

  static pw.Widget _categoryTotalsTable(List<_CategoryTotal> categories) {
    final rows = categories.map((item) {
      return [
        item.category,
        _formatNumber(item.quantity),
        _formatMoney(item.total),
      ];
    }).toList();

    return _table(headers: ['Categoria', 'Qtd', 'Total'], rows: rows);
  }

  static pw.Widget _salesTable(List<SaleRecord> sales) {
    final rows = sales.map((sale) {
      return [
        '#${sale.shortId}',
        _formatTime(sale.createdAt),
        sale.paymentMethod.label,
        sale.totalItems.toString(),
        _formatMoney(sale.total),
      ];
    }).toList();

    return _table(
      headers: ['Venda', 'Hora', 'Pagamento', 'Itens', 'Total'],
      rows: rows,
    );
  }

  static pw.Widget _cashClosureTable(CashClosure closure) {
    return _table(
      headers: ['Item', 'Valor'],
      rows: [
        ['Valor inicial', _formatMoney(closure.openingAmount)],
        ['Vendas em dinheiro', _formatMoney(closure.moneySales)],
        ['Reforço / entrada', _formatMoney(closure.cashInAmount)],
        ['Sangria / retirada', _formatMoney(closure.cashOutAmount)],
        ['Dinheiro esperado', _formatMoney(closure.expectedCash)],
        ['Dinheiro contado', _formatMoney(closure.countedAmount)],
        ['Diferença', _formatMoney(closure.difference)],
        ['Status', closure.statusLabel],
        if (closure.notes.trim().isNotEmpty) ['Observações', closure.notes],
      ],
    );
  }

  static pw.Widget _stockTable(List<Product> products) {
    final rows = products.map((product) {
      return [
        product.code,
        product.name,
        '${_formatNumber(product.stockQuantity)} ${product.unit.label}',
        '${_formatNumber(product.minStock)} ${product.unit.label}',
      ];
    }).toList();

    return _table(
      headers: ['Código', 'Produto', 'Estoque', 'Mínimo'],
      rows: rows,
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    );
  }

  static pw.Widget _emptyText(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _footer(bool keepOnePage) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
      ),
      child: pw.Text(
        keepOnePage
            ? 'Relatório enxuto. Alguns itens podem ser limitados para manter o documento curto.'
            : 'Relatório completo gerado pelo sistema.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    );
  }

  static double _soldItemsQuantity(List<SaleRecord> sales) {
    var total = 0.0;

    for (final sale in sales) {
      for (final item in sale.items) {
        total += item.quantity;
      }
    }

    return total;
  }

  static Map<PaymentMethod, double> _paymentTotals(List<SaleRecord> sales) {
    final totals = <PaymentMethod, double>{};

    for (final sale in sales) {
      totals[sale.paymentMethod] = (totals[sale.paymentMethod] ?? 0.0) + sale.total;
    }

    return totals;
  }

  static List<_TopProduct> _topProducts(List<SaleRecord> sales) {
    final map = <String, _TopProduct>{};

    for (final sale in sales) {
      for (final item in sale.items) {
        final existing = map[item.productId];

        if (existing == null) {
          map[item.productId] = _TopProduct(
            name: item.productName,
            quantity: item.quantity,
            total: item.subtotal,
          );
        } else {
          map[item.productId] = existing.copyWith(
            quantity: existing.quantity + item.quantity,
            total: existing.total + item.subtotal,
          );
        }
      }
    }

    final result = map.values.toList();
    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  static List<_CategoryTotal> _categoryTotals(
    List<SaleRecord> sales,
    List<Product> products,
  ) {
    final categoryByProductId = <String, String>{};

    for (final product in products) {
      categoryByProductId[product.id] = product.category.label;
    }

    final map = <String, _CategoryTotal>{};

    for (final sale in sales) {
      for (final item in sale.items) {
        final category = categoryByProductId[item.productId] ?? 'Sem categoria';
        final existing = map[category];

        if (existing == null) {
          map[category] = _CategoryTotal(
            category: category,
            quantity: item.quantity,
            total: item.subtotal,
          );
        } else {
          map[category] = existing.copyWith(
            quantity: existing.quantity + item.quantity,
            total: existing.total + item.subtotal,
          );
        }
      }
    }

    final result = map.values.toList();
    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  static String _formatMoney(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  static String _formatNumber(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(3).replaceAll('.', ',');
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value);

  final String label;
  final String value;
}

class _TopProduct {
  const _TopProduct({
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String name;
  final double quantity;
  final double total;

  _TopProduct copyWith({
    double? quantity,
    double? total,
  }) {
    return _TopProduct(
      name: name,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }
}

class _CategoryTotal {
  const _CategoryTotal({
    required this.category,
    required this.quantity,
    required this.total,
  });

  final String category;
  final double quantity;
  final double total;

  _CategoryTotal copyWith({
    double? quantity,
    double? total,
  }) {
    return _CategoryTotal(
      category: category,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }
}
