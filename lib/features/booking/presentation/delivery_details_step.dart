import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'booking_cubit.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import 'dart:math' as math;

class DeliveryDetailsStep extends StatefulWidget {
  const DeliveryDetailsStep({Key? key}) : super(key: key);

  @override
  State<DeliveryDetailsStep> createState() => _DeliveryDetailsStepState();
}

class _DeliveryDetailsStepState extends State<DeliveryDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _houseNoController;
  late TextEditingController _areaController;
  late TextEditingController _landmarkController;
  late TextEditingController _phoneController;
  late TextEditingController _instructionsController;

  bool _isDetecting = false;
  double? _gpsDistance;

  @override
  void initState() {
    super.initState();
    final state = context.read<BookingCubit>().state;
    _houseNoController = TextEditingController(text: state.houseNo);
    _areaController = TextEditingController(text: state.area);
    _landmarkController = TextEditingController(text: state.landmark);
    _phoneController = TextEditingController(text: state.contactPhone);
    _instructionsController = TextEditingController(text: state.deliveryInstructions);

    // Pre-fill from saved Auth UserProfile if checkout fields are empty
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      if (_houseNoController.text.isEmpty && user.houseNo.isNotEmpty) {
        _houseNoController.text = user.houseNo;
      }
      if (_areaController.text.isEmpty && user.area.isNotEmpty) {
        _areaController.text = user.area;
      }
      if (_landmarkController.text.isEmpty && user.landmark.isNotEmpty) {
        _landmarkController.text = user.landmark;
      }
      if (_phoneController.text.isEmpty && user.phone.isNotEmpty) {
        _phoneController.text = user.phone;
      }
    }

    // Automatically trigger GPS detection on page load if area is empty!
    if (_areaController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detectLocation();
      });
    }
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetecting = true;
      _areaController.text = "📍 Auto-detecting location...";
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in settings.';
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      const double kalyanpurLat = 26.5025;
      const double kalyanpurLon = 80.2583;

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        kalyanpurLat,
        kalyanpurLon,
      );

      _gpsDistance = distance;

      String detectedHouseNo = "";
      String detectedArea = "";

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          
          if (placemark.name != null && 
              placemark.name!.isNotEmpty && 
              placemark.name != placemark.subLocality && 
              placemark.name != placemark.locality) {
            detectedHouseNo = placemark.name!;
          }

          final List<String> addressParts = [];
          if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty && placemark.thoroughfare != placemark.name) {
            addressParts.add(placemark.thoroughfare!);
          }
          if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
            addressParts.add(placemark.subLocality!);
          }
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            addressParts.add(placemark.locality!);
          }
          detectedArea = addressParts.isEmpty ? "Kalyanpur, Kanpur" : addressParts.join(", ");
        }
      } catch (_) {
        detectedArea = "Kalyanpur, Kanpur";
      }

      if (mounted) {
        setState(() {
          _isDetecting = false;
          if (_houseNoController.text.isEmpty && detectedHouseNo.isNotEmpty) {
            _houseNoController.text = detectedHouseNo;
          }
          _areaController.text = detectedArea;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
          _areaController.text = "Kalyanpur, Kanpur";
        });
      }
    }
  }

  bool _isWithinDeliveryZone(String area, String landmark) {
    final search = "$area $landmark".toLowerCase();
    final allowedAreas = [
      'kalyanpur', 'indira nagar', 'indiranagar', 'kakadeo', 'kakadev',
      'iit', 'rawatpur', 'csjmu', 'university', 'geeta nagar', 'pant nagar',
      'vishwavidyalaya', 'gurudev', 'sharda nagar', 'crossings', 'kanpur'
    ];
    return allowedAreas.any((a) => search.contains(a));
  }

  void _showOutOfZoneDialog(double? distance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: AppTheme.errorColor),
            const SizedBox(width: 10),
            Text(
              "Outside Delivery Zone",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
            ),
          ],
        ),
        content: Text(
          distance != null
              ? "Your detected location is ${distance.toStringAsFixed(1)}km away from Kalyanpur. We currently deliver only within 5km radius."
              : "The entered area is outside our 5km Kalyanpur delivery radius.",
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Change Address",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final areaText = _areaController.text.trim();
      final landmarkText = _landmarkController.text.trim();
      
      if (_gpsDistance != null) {
        if (_gpsDistance! > 5.0) {
          _showOutOfZoneDialog(_gpsDistance!);
          return;
        }
      } else {
        if (!_isWithinDeliveryZone(areaText, landmarkText)) {
          _showOutOfZoneDialog(null);
          return;
        }
      }
      
      context.read<BookingCubit>().setAddressDetails(
            houseNo: _houseNoController.text.trim(),
            area: areaText,
            landmark: landmarkText,
            phone: _phoneController.text.trim(),
            deliveryInstructions: _instructionsController.text.trim(),
          );
      
      // Auto-save updated address & phone to User Profile in AuthCubit & Firestore
      context.read<AuthCubit>().syncAddressAndPhone(
            houseNo: _houseNoController.text.trim(),
            area: areaText,
            landmark: landmarkText,
            phone: _phoneController.text.trim(),
          );

      context.read<BookingCubit>().nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Where should we deliver?",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Deliveries are restricted to active zones in Kanpur.",
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // Delivery Zone Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFC3A575).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC3A575).withOpacity(0.2), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFC3A575), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Service Area Warning",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: const Color(0xFF0F3A20),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "We are currently delivering only within a 5km radius of Kalyanpur, Kanpur (includes Indira Nagar, Kakadeo, IIT Kanpur, Rawatpur, CSJMU).",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // House/Flat No
            Text(
              "House / Flat No.",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _houseNoController,
              decoration: const InputDecoration(
                hintText: "e.g. 10/482, Flat 302",
              ),
              validator: (v) => (v == null || v.isEmpty) ? "House number is required" : null,
            ),
            const SizedBox(height: 18),

            // Area/Locality Header with GPS detector button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Area / Locality / Street",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
                ),
                _isDetecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                      )
                    : TextButton.icon(
                        onPressed: _detectLocation,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppTheme.primaryGreen,
                        ),
                        icon: const Icon(Icons.my_location, size: 14),
                        label: Text(
                          "Detect GPS Location",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                hintText: "e.g. Swaroop Nagar, Civil Lines",
              ),
              validator: (v) => (v == null || v.isEmpty) ? "Area details are required" : null,
            ),
            const SizedBox(height: 18),

            // Landmark
            Text(
              "Landmark",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                hintText: "e.g. Near HDFC Bank, Opposite Park",
              ),
              validator: (v) => (v == null || v.isEmpty) ? "Please add a nearby landmark" : null,
            ),
            const SizedBox(height: 18),

            // Delivery phone
            Text(
              "Contact Phone Number",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                hintText: "10-digit delivery phone number",
                counterText: "",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Delivery phone number is required";
                }
                if (value.length < 10) {
                  return "Please enter a valid 10-digit number";
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Delivery Instructions
            Text(
              "Delivery Instructions (Optional)",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                "🚪 Leave at Doorstep",
                "🛡️ Leave with Guard",
                "🔔 Ring Doorbell",
                "📞 Call on Arrival",
              ].map((chipLabel) {
                final isSelected = _instructionsController.text == chipLabel;
                return ChoiceChip(
                  label: Text(
                    chipLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _instructionsController.text = chipLabel;
                      } else {
                        _instructionsController.clear();
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                hintText: "e.g. Gate code #1234 or special notes",
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "Continue to Summary",
              onPressed: _submit,
            ),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 8
                  : 16,
            ),
          ],
        ),
      ),
    );
  }
}
