import 'dart:typed_data';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate invoice: $e')),
      );
    }
  }

  static Future<Uint8List> generateInvoicePdf(
    OrderModel order, {
    UserProfile? user,
  }) async {
    final pdf = pw.Document();

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
                    '₹${order.pricePerMeal.toStringAsFixed(0)}',
                    '${order.totalMeals}',
                    '₹${order.totalAmount.toStringAsFixed(0)}',
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
                            pw.Text('₹${order.totalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        if (order.discountAmount > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount / Coupon:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                              pw.Text('-₹${order.discountAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
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
                            pw.Text('₹${order.finalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F3A20'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 5. Footer & Employer Reimbursement Disclaimer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F1F5F2'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#0F3A20'), width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'OFFICIAL REIMBURSEMENT RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F3A20'),
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'This is a computer-generated tax invoice for Atithi Bhoj Tiffin Service orders. Valid for corporate meal expense claims & tax filings.',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Made with ❤️ by Atithi Bhoj  •  Kalyanpur, Kanpur',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
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
