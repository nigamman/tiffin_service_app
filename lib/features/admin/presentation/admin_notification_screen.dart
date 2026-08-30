import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/widgets/custom_button.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final FirebaseService _db = FirebaseService.instance;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _manualPhoneController = TextEditingController();

  bool _isLoading = true;
  String _targetType = 'all'; // 'all' or 'specific'
  String? _selectedUserPhone;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // 1. Fetch registered users to populate the dropdown selection
      final allUsers = await _db.collectionGet('users');
      final customers = allUsers.where((u) => u['isAdmin'] != true).toList();

      // 2. Fetch notification history
      final notifications = await _db.collectionGet('notifications');
      // Sort by createdAt descending
      notifications.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _users = customers;
        _history = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading notification logs: $e"), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final targetPhone = _targetType == 'all'
          ? 'all'
          : (_selectedUserPhone ?? _manualPhoneController.text.trim());

      if (targetPhone.isEmpty) {
        throw Exception("Please specify a target phone number");
      }

      final newNotification = {
        'target': targetPhone,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _db.docAdd('notifications', newNotification);

      _titleController.clear();
      _messageController.clear();
      _manualPhoneController.clear();
      
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Custom notification broadcasted successfully!"),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send: $e"), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Send Custom Notification",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Composer Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Compose Broadcast",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Target Selector
                          const Text(
                            "Send Target:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text("All Users")),
                                  selected: _targetType == 'all',
                                  onSelected: (selected) {
                                    if (selected) setState(() => _targetType = 'all');
                                  },
                                  selectedColor: AppTheme.primaryGreen,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: _targetType == 'all' ? Colors.transparent : AppTheme.borderLight,
                                  ),
                                  labelStyle: TextStyle(
                                    color: _targetType == 'all' ? Colors.white : AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text("Specific Customer")),
                                  selected: _targetType == 'specific',
                                  onSelected: (selected) {
                                    if (selected) setState(() => _targetType = 'specific');
                                  },
                                  selectedColor: AppTheme.primaryGreen,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: _targetType == 'specific' ? Colors.transparent : AppTheme.borderLight,
                                  ),
                                  labelStyle: TextStyle(
                                    color: _targetType == 'specific' ? Colors.white : AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Specific user selection dropdown
                          if (_targetType == 'specific') ...[
                            const Text(
                              "Select Registered Customer:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedUserPhone,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                hintText: "Select Customer Name (Phone)",
                              ),
                              items: _users.map((user) {
                                final name = user['name'] ?? 'No Name';
                                final phone = user['phone'] ?? '';
                                return DropdownMenuItem<String>(
                                  value: phone,
                                  child: Text("$name ($phone)"),
                                );
                              }).toList(),
                              onChanged: (phone) {
                                setState(() {
                                  _selectedUserPhone = phone;
                                });
                              },
                              validator: (v) => (_targetType == 'specific' && v == null) ? "Customer selection is required" : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Title
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: "Notification Title",
                              hintText: "e.g. Special Holiday Festities",
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? "Title is required" : null,
                          ),
                          const SizedBox(height: 16),

                          // Message Body
                          TextFormField(
                            controller: _messageController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "Message Body",
                              hintText: "Enter the announcement or message text here...",
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? "Message text is required" : null,
                          ),
                          const SizedBox(height: 24),

                          CustomButton(
                            text: "Send Custom Notification",
                            onPressed: _sendNotification,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Log History Title
                    Text(
                      "Notification Broadcast Log",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Log History List
                    _history.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: const Center(
                              child: Text(
                                "No notifications sent yet.",
                                style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              final title = item['title'] ?? 'No Title';
                              final message = item['message'] ?? '';
                              final target = item['target'] ?? 'all';
                              
                              final timeRaw = item['createdAt'] ?? '';
                              String timeFormatted = 'Just now';
                              try {
                                final timeParsed = DateTime.parse(timeRaw);
                                timeFormatted = DateFormat('dd MMM, hh:mm a').format(timeParsed);
                              } catch (_) {}

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryMarigold.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.campaign, color: AppTheme.secondaryMarigold),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        timeFormatted,
                                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Target: ${target == 'all' ? 'All Customers' : 'Phone $target'}",
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
