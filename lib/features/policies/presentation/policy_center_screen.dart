import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

enum PolicySection {
  aboutUs,
  contactUs,
  pricing,
  terms,
  privacy,
  cancellationRefund,
  shippingDelivery,
}

class PolicyCenterScreen extends StatefulWidget {
  final PolicySection initialSection;

  const PolicyCenterScreen({
    Key? key,
    this.initialSection = PolicySection.aboutUs,
  }) : super(key: key);

  @override
  State<PolicyCenterScreen> createState() => _PolicyCenterScreenState();
}

class _PolicyCenterScreenState extends State<PolicyCenterScreen> {
  late PolicySection _selectedSection;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      appBar: AppBar(
        title: Text(
          "Policies & Company Info",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal Navigation Pill Selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildPillTab("About Us", PolicySection.aboutUs, Icons.info_outline),
                    _buildPillTab("Contact Us", PolicySection.contactUs, Icons.support_agent),
                    _buildPillTab("Pricing & Plans", PolicySection.pricing, Icons.payments_outlined),
                    _buildPillTab("Cancellation & Refund", PolicySection.cancellationRefund, Icons.replay),
                    _buildPillTab("Shipping & Delivery", PolicySection.shippingDelivery, Icons.local_shipping_outlined),
                    _buildPillTab("Terms & Conditions", PolicySection.terms, Icons.gavel_outlined),
                    _buildPillTab("Privacy Policy", PolicySection.privacy, Icons.privacy_tip_outlined),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Main Policy Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildSelectedContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab(String label, PolicySection section, IconData icon) {
    const primaryGreen = Color(0xFF0F3A20);
    const turmericGold = Color(0xFFC3A575);
    final isSelected = _selectedSection == section;

    return GestureDetector(
      onTap: () => setState(() => _selectedSection = section),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? turmericGold : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? turmericGold : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedSection) {
      case PolicySection.aboutUs:
        return _buildAboutUs();
      case PolicySection.contactUs:
        return _buildContactUs();
      case PolicySection.pricing:
        return _buildPricing();
      case PolicySection.cancellationRefund:
        return _buildCancellationRefund();
      case PolicySection.shippingDelivery:
        return _buildShippingDelivery();
      case PolicySection.terms:
        return _buildTerms();
      case PolicySection.privacy:
        return _buildPrivacy();
    }
  }

  // 1. ABOUT US
  Widget _buildAboutUs() {
    return _buildCard(
      title: "About Atithi Bhoj",
      subtitle: "Kanpur's Premier Home-Style Tiffin Subscription Service",
      icon: Icons.storefront_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraph(
            "Atithi Bhoj is a dedicated culinary service operating from Kalyanpur, Kanpur, Uttar Pradesh. Inspired by the traditional Indian ethos of 'Atithi Devo Bhava' (Guest is God), we provide fresh, wholesome, pure vegetarian home-cooked tiffins to students, working professionals, and families.",
          ),
          const SizedBox(height: 14),
          _buildSectionHeader("Our Core Pillars"),
          _buildBulletPoint("Hygienic Preparation: Prepared in FSSAI-compliant clean kitchens with premium ingredients and minimal oil."),
          _buildBulletPoint("Nutritious & Balanced: Weekly rotational menu crafted to provide home-style nutrition without commercial preservatives."),
          _buildBulletPoint("Flexible Subscriptions: Pause, skip meals, or customize delivery slots effortlessly via our mobile app."),
          const SizedBox(height: 16),
          _buildSectionHeader("Business Entity Info"),
          _buildInfoRow("Business Name", "Atithi Bhoj Tiffin Services"),
          _buildInfoRow("Operating Headquarters", "Kalyanpur Zone, Kanpur, UP - 208017"),
          _buildInfoRow("Service Focus", "Subscription & Single Tiffin Meals Delivery"),
        ],
      ),
    );
  }

  // 2. CONTACT US
  Widget _buildContactUs() {
    return _buildCard(
      title: "Contact Us",
      subtitle: "We are here to help you 7 days a week",
      icon: Icons.headset_mic_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraph(
            "Have questions about your meal plan, need to customize a delivery, or want to share feedback? Reach out to our customer care team anytime.",
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                _buildContactTile(
                  icon: Icons.phone,
                  title: "Customer Support Helpline",
                  value: "+91 9119724875",
                ),
                const Divider(height: 20),
                _buildContactTile(
                  icon: Icons.email_outlined,
                  title: "Official Email Addresses",
                  value: "nigamman20@gmail.com / aniketprakash121@gmail.com",
                ),
                const Divider(height: 20),
                _buildContactTile(
                  icon: Icons.location_on_outlined,
                  title: "Physical Kitchen & Office Address",
                  value: "Atithi Bhoj Kitchens, Main Road, Near CSJM University, Kalyanpur, Kanpur, Uttar Pradesh - 208017",
                ),
                const Divider(height: 20),
                _buildContactTile(
                  icon: Icons.access_time,
                  title: "Support Operating Hours",
                  value: "Monday to Sunday: 8:00 AM – 9:30 PM",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. PRICING & SUBSCRIPTION PLANS
  Widget _buildPricing() {
    return _buildCard(
      title: "Pricing Details & Tiffin Plans",
      subtitle: "Transparent pricing with zero hidden fees",
      icon: Icons.sell_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraph(
            "At Atithi Bhoj, all subscription rates and plan prices are fully transparent and accessible to everyone prior to checkout.",
          ),
          const SizedBox(height: 16),
          _buildSectionHeader("Meal Rates Breakdown"),
          _buildPricingRow("Single Tiffin Trial Meal", "₹80 / meal", "1 Meal (Lunch or Dinner)"),
          _buildPricingRow("Weekly 5-Day Plan (Mon–Fri)", "₹400 / week", "5 Meals (₹80/meal)"),
          _buildPricingRow("Weekly 6-Day Plan (Mon–Sat)", "₹480 / week", "6 Meals (₹80/meal)"),
          _buildPricingRow("Weekly 7-Day Plan (Mon–Sun)", "₹560 / week", "7 Meals (₹80/meal)"),
          _buildPricingRow("Monthly 20-Day Plan (Mon–Fri)", "₹1,600 / month", "20 Meals (1 Month Duration)"),
          _buildPricingRow("Monthly 24-Day Plan (Mon–Sat)", "₹1,920 / month", "24 Meals (1 Month Duration)"),
          _buildPricingRow("Monthly 30-Day Plan (Mon–Sun)", "₹2,400 / month", "30 Meals (1 Month Duration)"),
          const SizedBox(height: 14),
          _buildParagraph(
            "Note: Selecting BOTH Lunch & Dinner doubles the meal count per plan at the standard ₹80/meal rate. FREE doorstep delivery is included in all plans.",
          ),
        ],
      ),
    );
  }

  // 4. CANCELLATION & REFUND POLICY
  Widget _buildCancellationRefund() {
    return _buildCard(
      title: "Cancellation & Refund Policy",
      subtitle: "Clear guidelines on subscription cancellations and refunds",
      icon: Icons.published_with_changes_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("1. Subscription Cancellation"),
          _buildParagraph(
            "Customers can cancel an active subscription plan at any time through the app or by calling customer care at +91 9119724875.",
          ),
          _buildBulletPoint("Pre-Start Cancellation: Full 100% refund if cancelled before the start date."),
          _buildBulletPoint("Mid-Plan Cancellation: If cancelled after deliveries have started, unconsumed meals will be calculated and refunded pro-rata."),
          const SizedBox(height: 16),
          _buildSectionHeader("2. Refund Processing Window"),
          _buildParagraph(
            "All approved refund amounts are processed back to the customer's original payment method (Bank Account / UPI / Debit/Credit Card via Razorpay) within 5 to 7 working days.",
          ),
          const SizedBox(height: 16),
          _buildSectionHeader("3. Missed, Delayed, or Quality Issues"),
          _buildParagraph(
            "If a tiffin is missed, damaged, or fails to meet quality standards:",
          ),
          _buildBulletPoint("Please notify customer support within 2 hours of the delivery window."),
          _buildBulletPoint("We issue an immediate replacement or credit equal to the meal cost back to your account."),
          const SizedBox(height: 16),
          _buildSectionHeader("4. Daily Meal Skipping & Extensibility"),
          _buildParagraph(
            "You do not need to cancel your entire subscription to skip a day! Simply tap 'Skip Meal' in your app before cutoff times (9:30 AM for Lunch / 5:00 PM for Dinner). Skipped meals automatically extend your subscription duration at zero cost.",
          ),
        ],
      ),
    );
  }

  // 5. SHIPPING & DELIVERY POLICY
  Widget _buildShippingDelivery() {
    return _buildCard(
      title: "Shipping & Delivery Policy",
      subtitle: "Delivery radius, timings, and fulfillment terms",
      icon: Icons.local_shipping_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("1. Delivery Zone & 5km Radius"),
          _buildParagraph(
            "Atithi Bhoj delivers hot home-cooked tiffins strictly within a 5 km radius of Kalyanpur, Kanpur, Uttar Pradesh. Active delivery areas include:",
          ),
          _buildBulletPoint("Kalyanpur (All blocks & main road)"),
          _buildBulletPoint("IIT Kanpur Campus"),
          _buildBulletPoint("CSJM Kanpur University Campus"),
          _buildBulletPoint("Kakadeo & Coaching Hub"),
          _buildBulletPoint("Indira Nagar & Rawatpur"),
          const SizedBox(height: 16),
          _buildSectionHeader("2. Daily Delivery Timings & Cutoff Rules"),
          _buildTimingRow("Lunch Delivery Window", "12:00 PM – 2:00 PM", "Skip/Order Cutoff: 9:30 AM"),
          _buildTimingRow("Dinner Delivery Window", "7:00 PM – 9:00 PM", "Skip/Order Cutoff: 5:00 PM"),
          const SizedBox(height: 16),
          _buildSectionHeader("3. Delivery Fees & Packaging"),
          _buildParagraph(
            "Delivery is 100% FREE on all subscription plans and trial orders. Tiffins are packed in food-grade insulated containers to maintain fresh food temperature.",
          ),
        ],
      ),
    );
  }

  // 6. TERMS & CONDITIONS
  Widget _buildTerms() {
    return _buildCard(
      title: "Terms & Conditions",
      subtitle: "Rules and agreements governing your use of Atithi Bhoj",
      icon: Icons.gavel_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraph(
            "Welcome to Atithi Bhoj. By downloading, accessing, or subscribing to our service, you agree to comply with the following Terms and Conditions.",
          ),
          const SizedBox(height: 14),
          _buildSectionHeader("1. Account Registration"),
          _buildParagraph(
            "Users must provide an accurate phone number and valid delivery address in Kanpur to receive services. Accounts registered with fraudulent info may be suspended.",
          ),
          const SizedBox(height: 14),
          _buildSectionHeader("2. Payments & Razorpay Security"),
          _buildParagraph(
            "All subscription fees are collected digitally via Razorpay secure payment gateway. Orders are confirmed upon payment status verification.",
          ),
          const SizedBox(height: 14),
          _buildSectionHeader("3. Service Modifications"),
          _buildParagraph(
            "Atithi Bhoj reserves the right to modify tiffin menu items based on daily fresh seasonal vegetable availability without compromising meal quantity or nutritional value.",
          ),
        ],
      ),
    );
  }

  // 7. PRIVACY POLICY
  Widget _buildPrivacy() {
    return _buildCard(
      title: "Privacy Policy",
      subtitle: "How we collect, protect, and use your personal information",
      icon: Icons.shield_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraph(
            "At Atithi Bhoj, we value your trust and are committed to protecting your privacy and personal data.",
          ),
          const SizedBox(height: 14),
          _buildSectionHeader("1. Information We Collect"),
          _buildBulletPoint("Contact Info: Name, Phone Number, Email address."),
          _buildBulletPoint("Delivery Info: House number, Area, Landmark, and GPS coordinates for delivery navigation."),
          _buildBulletPoint("Payment Data: Processed directly by Razorpay (we do not store credit card/CVV numbers on our servers)."),
          const SizedBox(height: 16),
          _buildSectionHeader("2. How We Use Information"),
          _buildParagraph(
            "Your information is strictly used to fulfill tiffin deliveries, send delivery notification alerts, and provide customer support.",
          ),
          const SizedBox(height: 16),
          _buildSectionHeader("3. Zero Data Selling"),
          _buildParagraph(
            "We NEVER sell, rent, or lease your personal information to third parties.",
          ),
        ],
      ),
    );
  }

  // HELPER UI BUILDERS
  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    const primaryGreen = Color(0xFF0F3A20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryGreen,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12.5,
        color: AppTheme.textDark,
        height: 1.6,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          color: const Color(0xFF0F3A20),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC3A575), fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textDark, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F3A20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingRow(String title, String price, String details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text(details, style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(price, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F3A20))),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String slot, String window, String cutoff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3A20).withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F3A20).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F3A20))),
              Text(cutoff, style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textMuted)),
            ],
          ),
          Text(window, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFC3A575))),
        ],
      ),
    );
  }
}
