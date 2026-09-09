import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Text;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/orders/data/orders_repository.dart';
import '../../features/auth/data/auth_repository.dart';

class InvoiceService {
  static Future<void> downloadOrPrintInvoice(
    BuildContext context,
    OrderModel order, {
    UserProfile? user,
  }) async {
    try {
      final pdfBytes = await generateInvoicePdf(order, user: user);
      final shortId = order.id.length > 6
          ? order.id.toUpperCase().substring(order.id.length - 6)
          : order.id.toUpperCase();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'AtithiBhoj_Invoice_$shortId.pdf',
      );
    } catch (e) {
      final msg = e.toString().contains('MissingPluginException')
          ? 'Native printing plugin not loaded. Please perform a full app rebuild / restart (stop app and run flutter run).'
          : 'Failed to generate invoice: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  static Future<Uint8List> generateInvoicePdf(
    OrderModel order, {
    UserProfile? user,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? playStoreIcon1;
    pw.MemoryImage? playStoreIcon2;
    try {
      final iconBytes1 = await rootBundle.load('assets/icons/playstore-icon1.png');
      playStoreIcon1 = pw.MemoryImage(iconBytes1.buffer.asUint8List());
    } catch (_) {}
    try {
      final iconBytes2 = await rootBundle.load('assets/icons/playstore-icon2.png');
      playStoreIcon2 = pw.MemoryImage(iconBytes2.buffer.asUint8List());
    } catch (_) {}

    final shortId = order.id.length > 6
        ? order.id.toUpperCase().substring(order.id.length - 6)
        : order.id.toUpperCase();
    final invoiceDate = DateFormat('dd MMM yyyy').format(order.createdAt);
    final startDateFormatted = DateFormat('dd MMM yyyy').format(order.startDate);

    final customerName = user?.name.isNotEmpty == true ? user!.name : 'Customer';
    final customerPhone = order.contactPhone.isNotEmpty
        ? '+91 ${order.contactPhone}'
        : (user?.phone.isNotEmpty == true ? '+91 ${user!.phone}' : 'N/A');

    final customerAddressParts = [
      order.houseNo.isNotEmpty ? order.houseNo : (user?.houseNo ?? ''),
      order.area.isNotEmpty ? order.area : (user?.area ?? ''),
      order.landmark.isNotEmpty ? order.landmark : (user?.landmark ?? ''),
    ].where((s) => s.isNotEmpty).toList();

    final customerAddress = customerAddressParts.isEmpty
        ? 'Kalyanpur, Kanpur'
        : customerAddressParts.join(', ');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header (Brand Name & Invoice Meta)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ATITHI BHOJ',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0F3A20'),
                        ),
                      ),
                      pw.Text(
                        'Authentic Home-Style Tiffin Service',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Kalyanpur, Kanpur, Uttar Pradesh - 208017',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Contact: +91 9119724875 | support@atithibhoj.com',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'FSSAI Lic. No.: 22726670000196',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0F3A20'),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#0F3A20'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Invoice #: INV-$shortId',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Invoice Date: $invoiceDate',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Payment Status: PAID',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      if (order.razorpayPaymentId != null && order.razorpayPaymentId!.isNotEmpty) ...[  
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Txn ID: ${order.razorpayPaymentId}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 15),

              // 2. Billed To Details Card
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8F9FA'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILLED TO:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F3A20'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      customerName,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Phone: $customerPhone',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                    pw.Text(
                      'Address: $customerAddress',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // 3. Itemized Table Breakdown
              pw.Table.fromTextArray(
                headers: ['Item Description', 'Slot', 'Thali Rate', 'Total Meals', 'Amount'],
                data: [
                  [
                    'Home Tiffin Meal (${order.frequency.toUpperCase().replaceAll('_', ' ')} Plan)\nQty: ${order.quantity} Box | Start: $startDateFormatted',
                    order.deliverySlot.toUpperCase(),
                    'Rs. ${order.pricePerMeal.toStringAsFixed(0)}',
                    '${order.totalMeals}',
                    'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0F3A20'),
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),

              pw.SizedBox(height: 15),

              // 4. Financial Calculations Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('Rs. ${order.totalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        if (order.discountAmount > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount / Coupon:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                              pw.Text('-Rs. ${order.discountAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Paid:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F3A20'))),
                            pw.Text('Rs. ${order.finalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F3A20'))),
                          ],
                        ),
                        if (order.razorpayPaymentId != null && order.razorpayPaymentId!.isNotEmpty) ...[
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#F0FDF4'),
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(color: PdfColors.green300, width: 0.5),
                            ),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Payment Ref:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                                pw.Text(order.razorpayPaymentId!, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 5. Minimal Clean Footer
              pw.UrlLink(
                destination: 'https://play.google.com/store/apps/details?id=com.nigamman.atithibhoj',
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F1F5F2'),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColor.fromHex('#0F3A20'), width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Line 1: Full text centered
                      pw.Text(
                        'Download on Google Play Atithi Bhoj Home Tiffin Service',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0F3A20'),
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 6),
                      // Line 2: Badge icon centered
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (playStoreIcon2 != null)
                            pw.Image(playStoreIcon2, height: 20, fit: pw.BoxFit.contain),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
