import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class ReceiptService {
  static Future<void> downloadReceipt(Map<String, dynamic> order) async {
    final bytes = await _buildPdf(order);
    final orderId = order['order_id'] ?? order['id'] ?? '0';
    await Printing.sharePdf(bytes: bytes, filename: 'SupplyLink_Receipt_$orderId.pdf');
  }

  static Future<Uint8List> _buildPdf(Map<String, dynamic> order) async {
    final doc = pw.Document();

    final orderId   = order['order_id'] ?? order['id'] ?? '-';
    final product   = order['product'] as String?
        ?? '${order['product_name'] ?? ''} - ${order['variant_name'] ?? ''}';
    final qty       = (order['quantity'] as num?)?.toStringAsFixed(1)
        ?? order['qty'] as String? ?? '-';
    final unit      = order['unit'] as String? ?? '';
    final ppu       = (order['price_per_unit'] as num?)?.toDouble() ?? 0.0;
    final total     = (order['total_price'] as num?)?.toDouble()
        ?? (order['price'] as num?)?.toDouble() ?? 0.0;
    final supplier  = order['stockholder_name'] as String?
        ?? order['supplier'] as String? ?? '-';
    final shopName  = order['shop_name'] as String?
        ?? order['sop_shop_name'] as String? ?? '-';
    final address   = order['delivery_address'] as String? ?? '-';
    final createdAt = _fmtDate(order['created_at'] as String?);
    final deliveredAt = _fmtDate(order['delivered_at'] as String?);

    final headerGreen = PdfColor.fromHex('#054F3A');
    final accentGreen = PdfColor.fromHex('#0FBB84');
    final darkText    = PdfColor.fromHex('#212121');
    final grayText    = PdfColor.fromHex('#757575');
    final lightBg     = PdfColor.fromHex('#F0FBF6');
    final divider     = PdfColor.fromHex('#C8EAE0');

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── header banner ───────────────────────────────────────────
          pw.Container(
            color: headerGreen,
            padding: const pw.EdgeInsets.fromLTRB(32, 28, 32, 24),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('SUPPLYLINK',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2)),
                    pw.SizedBox(height: 2),
                    pw.Text('Retail Sourcing & Supply Platform',
                        style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.6), fontSize: 10)),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: accentGreen,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text('PAYMENT RECEIPT',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.2)),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Receipt No: #ORD-$orderId',
                        style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.7), fontSize: 10)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: accentGreen, thickness: 0.5),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                _headerKV('Order Date', createdAt, accentGreen),
                pw.SizedBox(width: 48),
                _headerKV('Delivery Date', deliveredAt.isNotEmpty ? deliveredAt : 'Pending', accentGreen),
                pw.SizedBox(width: 48),
                _headerKV('Payment Method', 'Cash on Delivery', accentGreen),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text('DELIVERED',
                      style: pw.TextStyle(
                          color: headerGreen,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold)),
                ),
              ]),
            ]),
          ),

          // ── body ────────────────────────────────────────────────────
          pw.Expanded(
            child: pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [

                  // product details
                  _section('PRODUCT DETAILS', headerGreen, children: [
                    _row('Product', product, darkText, grayText),
                    _dividerLine(divider),
                    _row('Quantity', '$qty $unit', darkText, grayText),
                    _dividerLine(divider),
                    _row('Unit Price',
                        ppu > 0 ? 'BDT ${ppu.toStringAsFixed(2)} / $unit' : '-',
                        darkText, grayText),
                  ]),
                  pw.SizedBox(height: 18),

                  // supplier
                  _section('SUPPLIER (SELLER)', headerGreen, children: [
                    _row('Company', supplier, darkText, grayText),
                  ]),
                  pw.SizedBox(height: 18),

                  // buyer
                  _section('BUYER (SHOP OWNER)', headerGreen, children: [
                    _row('Shop Name', shopName, darkText, grayText),
                    _dividerLine(divider),
                    _row('Delivery Address', address, darkText, grayText),
                  ]),
                  pw.SizedBox(height: 18),

                  // payment summary box
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: divider),
                    ),
                    padding: const pw.EdgeInsets.all(18),
                    child: pw.Column(children: [
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('PAYMENT SUMMARY',
                                style: pw.TextStyle(
                                    color: headerGreen,
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    letterSpacing: 0.8)),
                          ]),
                      pw.SizedBox(height: 12),
                      _payRow('Subtotal', 'BDT ${total.toStringAsFixed(2)}', darkText, grayText),
                      pw.SizedBox(height: 6),
                      _payRow('Delivery Charge', 'Included', darkText, grayText),
                      pw.SizedBox(height: 6),
                      _payRow('Payment Method', 'Cash on Delivery', darkText, grayText),
                      pw.SizedBox(height: 10),
                      pw.Divider(color: divider, thickness: 1),
                      pw.SizedBox(height: 10),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL PAID',
                                style: pw.TextStyle(
                                    color: headerGreen,
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('BDT ${total.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    color: headerGreen,
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold)),
                          ]),
                    ]),
                  ),

                  pw.Spacer(),

                  // footer
                  pw.Divider(color: divider, thickness: 0.5),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Generated by SupplyLink',
                          style: pw.TextStyle(color: grayText, fontSize: 9)),
                      pw.Text('This is a computer-generated receipt.',
                          style: pw.TextStyle(color: grayText, fontSize: 9)),
                      pw.Text('© 2026 SupplyLink Bangladesh',
                          style: pw.TextStyle(color: grayText, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));

    return doc.save();
  }

  // ── PDF widget helpers ────────────────────────────────────────────────────

  static pw.Widget _headerKV(String label, String value, PdfColor accent) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.6), fontSize: 8)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(color: PdfColors.white,
            fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ]);

  static pw.Widget _section(String title, PdfColor color,
      {required List<pw.Widget> children}) =>
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6), topRight: pw.Radius.circular(6)),
        ),
        child: pw.Text(title,
            style: pw.TextStyle(color: PdfColors.white,
                fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 0.6)),
      ),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromHex('#C8EAE0')),
          borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(6), bottomRight: pw.Radius.circular(6)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: pw.Column(children: children),
      ),
    ]);

  static pw.Widget _row(String label, String value, PdfColor dark, PdfColor gray) =>
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(children: [
          pw.SizedBox(width: 140,
              child: pw.Text(label,
                  style: pw.TextStyle(color: gray, fontSize: 10))),
          pw.Expanded(child: pw.Text(value,
              style: pw.TextStyle(color: dark, fontSize: 10,
                  fontWeight: pw.FontWeight.bold))),
        ]));

  static pw.Widget _payRow(String label, String value, PdfColor dark, PdfColor gray) =>
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(color: gray, fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(color: dark, fontSize: 10,
            fontWeight: pw.FontWeight.bold)),
      ]);

  static pw.Widget _dividerLine(PdfColor color) =>
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Divider(color: color, thickness: 0.5));

  static String _fmtDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day.toString().padLeft(2,'0')} ${months[dt.month-1]} ${dt.year}';
  }
}
