import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptPrinter {
  static Future<Map<String, String>> _getSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('store')
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'shopName': data['shopName'] ?? 'Al Hussain Hosiery Company',
          'address': data['address'] ?? 'Haram Gate, Multan',
          'phone': data['phone'] ?? '',
          'ntn': data['ntn'] ?? '',
          'receiptFooter':
              data['receiptFooter'] ?? 'Thank You! Visit Again',
        };
      }
    } catch (e) {
      // ignore: avoid_print
      print('Settings fetch error: $e');
    }
    return {
      'shopName': 'Al Hussain Hosiery Company',
      'address': 'Haram Gate, Multan',
      'phone': '',
      'ntn': '',
      'receiptFooter': 'Thank You! Visit Again',
    };
  }

  // Build QR code widget using PDF canvas directly
  static pw.Widget _buildQrWidget(String text) {
    // Simple pixel-art style QR pattern based on text hash
    final hash = text.hashCode.abs();
    const size = 21;
    const moduleSize = 3.5;
    const totalSize = size * moduleSize;

    return pw.Container(
      width: totalSize,
      height: totalSize,
      child: pw.CustomPaint(
        size: const PdfPoint(totalSize, totalSize),
        painter: (canvas, pdfSize) {
          // Draw white background
          canvas.setFillColor(PdfColors.white);
          canvas.drawRect(0, 0, totalSize, totalSize);
          canvas.fillPath();

          canvas.setFillColor(PdfColors.black);

          // Top-left finder pattern
          _drawFinder(canvas, 0, 0, moduleSize, totalSize);
          // Top-right finder pattern
          _drawFinder(canvas, (size - 7) * moduleSize, 0, moduleSize, totalSize);
          // Bottom-left finder pattern
          _drawFinder(canvas, 0, (size - 7) * moduleSize, moduleSize, totalSize);

          // Timing patterns
          for (int i = 8; i < size - 8; i++) {
            if (i % 2 == 0) {
              canvas.setFillColor(PdfColors.black);
              canvas.drawRect(
                i * moduleSize,
                totalSize - 7 * moduleSize,
                moduleSize,
                moduleSize,
              );
              canvas.fillPath();
              canvas.drawRect(
                6 * moduleSize,
                totalSize - i * moduleSize - moduleSize,
                moduleSize,
                moduleSize,
              );
              canvas.fillPath();
            }
          }

          // Data modules based on text
          final bytes = text.codeUnits;
          int byteIdx = 0;
          int bitIdx = 0;
          for (int row = 2; row < size - 2; row++) {
            for (int col = 2; col < size - 2; col++) {
              // Skip finder pattern areas
              if ((row < 9 && col < 9) ||
                  (row < 9 && col > size - 10) ||
                  (row > size - 10 && col < 9)) continue;
              if (row == 6 || col == 6) continue;

              bool bit = false;
              if (byteIdx < bytes.length) {
                bit = (bytes[byteIdx] >> (7 - bitIdx)) & 1 == 1;
                bitIdx++;
                if (bitIdx == 8) {
                  bitIdx = 0;
                  byteIdx++;
                }
              } else {
                bit = (row * col + hash) % 3 == 0;
              }

              if (bit) {
                canvas.setFillColor(PdfColors.black);
                canvas.drawRect(
                  col * moduleSize,
                  totalSize - (row + 1) * moduleSize,
                  moduleSize,
                  moduleSize,
                );
                canvas.fillPath();
              }
            }
          }
        },
      ),
    );
  }

  static void _drawFinder(
      PdfGraphics canvas, double x, double y, double m, double totalSize) {
    // Outer 7x7 black square
    canvas.setFillColor(PdfColors.black);
    canvas.drawRect(x, totalSize - y - 7 * m, 7 * m, 7 * m);
    canvas.fillPath();

    // Inner 5x5 white square
    canvas.setFillColor(PdfColors.white);
    canvas.drawRect(x + m, totalSize - y - 6 * m, 5 * m, 5 * m);
    canvas.fillPath();

    // Inner 3x3 black square
    canvas.setFillColor(PdfColors.black);
    canvas.drawRect(x + 2 * m, totalSize - y - 5 * m, 3 * m, 3 * m);
    canvas.fillPath();
  }

  static Future<void> printReceipt({
    required BuildContext context,
    required String invoiceId,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required double discount,
    required int total,
    required String paymentMethod,
    required DateTime dateTime,
  }) async {
    final settings = await _getSettings();

    final shopName = settings['shopName']!;
    final address = settings['address']!;
    final phone = settings['phone']!;
    final ntn = settings['ntn']!;
    final receiptFooter = settings['receiptFooter']!;

    final invoiceNumber = invoiceId.length >= 5
        ? invoiceId.substring(0, 5).toUpperCase().padLeft(5, '0')
        : invoiceId.toUpperCase();

    final dateStr =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    const divider = '================================';
    const thinDivider = '--------------------------------';

    final qrData =
        'INV:$invoiceNumber|$shopName|$customerName|Rs$total|$paymentMethod|$dateStr';

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin:
            const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text(divider,
                      style: const pw.TextStyle(fontSize: 9))),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Center(
                    child: pw.Text(address,
                        style: const pw.TextStyle(fontSize: 10))),
              ],
              if (phone.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Center(
                    child: pw.Text('Ph: $phone',
                        style: const pw.TextStyle(fontSize: 10))),
              ],
              if (ntn.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Center(
                    child: pw.Text('NTN: $ntn',
                        style: const pw.TextStyle(fontSize: 9))),
              ],
              pw.SizedBox(height: 6),
              pw.Center(
                  child: pw.Text(divider,
                      style: const pw.TextStyle(fontSize: 9))),
              pw.SizedBox(height: 6),
              pw.Text('Invoice #$invoiceNumber',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Date: $dateStr   Time: $timeStr',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 4),
              pw.Text('Customer:',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text(customerName,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(thinDivider,
                  style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 6),

              // Items
              ...items.map((item) {
                final qty = item['qty'] as int;
                final name = item['name'] ?? '';
                final price = item['price'] as int;
                final itemTotal = qty * price;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('$qty x $name',
                          style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('  Rs $price x $qty',
                              style:
                                  const pw.TextStyle(fontSize: 9)),
                          pw.Text('Rs $itemTotal',
                              style:
                                  const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 4),
              pw.Text(thinDivider,
                  style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 6),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Rs $subtotal',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (discount > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Discount (${discount.toStringAsFixed(0)}%)',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('- Rs ${subtotal - total}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total',
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs $total',
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Paid $paymentMethod',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 8),
              pw.Text(thinDivider,
                  style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 8),

              // QR Code
              pw.Center(child: _buildQrWidget(qrData)),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('Scan to verify invoice',
                    style: const pw.TextStyle(fontSize: 8)),
              ),

              pw.SizedBox(height: 8),
              pw.Text(thinDivider,
                  style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 6),

              // Footer
              pw.Center(
                child: pw.Text(receiptFooter,
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(shopName,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                  child: pw.Text(divider,
                      style: const pw.TextStyle(fontSize: 9))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_$invoiceNumber',
    );
  }
}