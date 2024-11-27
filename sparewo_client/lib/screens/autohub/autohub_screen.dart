// lib/screens/autohub/autohub_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import 'widgets/service_grid.dart';

class AutoHubScreen extends StatefulWidget {
  const AutoHubScreen({super.key});

  @override
  _AutoHubScreenState createState() => _AutoHubScreenState();
}

class _AutoHubScreenState extends State<AutoHubScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;

  final Map<String, String?> formData = {
    'serviceType': '',
    'name': '',
    'phone': '',
    'email': '',
    'carMakeModel': '',
    'yearOfManufacture': '',
    'serviceDescription': '',
    'appointmentDateTime': '',
    'pickupLocation': '',
  };

  final Map<String, TextEditingController> _controllers = {};
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(5, (_) => GlobalKey<FormState>());
  bool _termsAccepted = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    formData.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value ?? '');
    });
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      setState(() {
        formData['name'] = user.name ?? '';
        formData['phone'] = user.phone ?? '';
        formData['email'] = user.email ?? '';
        _controllers['name']?.text = formData['name'] ?? '';
        _controllers['phone']?.text = formData['phone'] ?? '';
        _controllers['email']?.text = formData['email'] ?? '';
      });
    }
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      setState(() {
        if (_currentStep < 4) {
          _currentStep += 1;
          _animationController.forward(from: 0);
        } else {
          if (!_termsAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please accept the Terms and Conditions')),
            );
            return;
          }
          _submitForm();
        }
      });
    }
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep -= 1;
        _animationController.forward(from: 0);
      }
    });
  }

  void _submitForm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/notepad_background.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animations/success.json',
                    repeat: false,
                    height: 150,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Appointment Booked!',
                    style:
                        AppTextStyles.heading3.copyWith(color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you for your submission. We will contact you shortly.',
                    style: AppTextStyles.body2.copyWith(color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('OK', style: AppTextStyles.button),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchTermsUrl() async {
    const url =
        'https://sparewo.ug/wp-content/uploads/2024/08/CUSTOMER-Ts-and-Cs.pdf.pdf';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Terms and Conditions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book a Garage Appointment',
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildStepContentWrapper(),
        ),
      ),
    );
  }

  Widget _buildStepContentWrapper() {
    final isLargeScreen = MediaQuery.of(context).size.width > 720;

    return SingleChildScrollView(
      key: ValueKey<int>(_currentStep),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 24.0 : 16.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(),
            const SizedBox(height: 16),
            Form(
              key: _formKeys[_currentStep],
              child: _buildStepContent(),
            ),
            const SizedBox(height: 16),
            if (_currentStep != 0 && _currentStep != 4) _buildAnimation(),
            const SizedBox(height: 16),
            _buildNavigationButtons(),
            const SizedBox(height: 8),
            _buildProgressIndicator(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 500));
  }

  Widget _buildStepHeader() {
    final stepTitles = [
      "Service Type",
      "Personal Information",
      "Vehicle Info",
      "Appointment Details",
      "Confirmation",
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          stepTitles[_currentStep],
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text('Step ${_currentStep + 1} of 5', style: AppTextStyles.body2),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildServiceTypeStep();
      case 1:
        return _buildPersonalInfoStep();
      case 2:
        return _buildVehicleInfoStep();
      case 3:
        return _buildAppointmentDetailsStep();
      case 4:
        return _buildConfirmationStep();
      default:
        return Container();
    }
  }

  Widget _buildServiceTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Service Type", style: AppTextStyles.body1),
        const SizedBox(height: 16),
        ServiceGrid(
          selectedService: formData['serviceType'] ?? '',
          onServiceSelect: (selected) {
            setState(() {
              formData['serviceType'] = selected;
            });
          },
        ),
        const SizedBox(height: 16),
        if (formData['serviceType'] == null || formData['serviceType']!.isEmpty)
          const Text(
            'Please select a service type.',
            style: TextStyle(color: AppColors.error),
          ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("Name*", "name", validator: _requiredValidator),
        const SizedBox(height: 12),
        _buildTextField("Phone*", "phone",
            keyboardType: TextInputType.phone, validator: _requiredValidator),
        const SizedBox(height: 12),
        _buildTextField("Email*", "email",
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator),
      ],
    );
  }

  Widget _buildVehicleInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("Car Make and Model*", "carMakeModel",
            placeholder: "e.g., Toyota Harrier", validator: _requiredValidator),
        const SizedBox(height: 12),
        _buildTextField("Year of Manufacture*", "yearOfManufacture",
            keyboardType: TextInputType.number, validator: _requiredValidator),
        const SizedBox(height: 12),
        _buildTextField("Service Description", "serviceDescription",
            maxLines: 4),
      ],
    );
  }

  Widget _buildAppointmentDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          "Preferred Appointment Time and Date*",
          "appointmentDateTime",
          isDateTime: true,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 12),
        _buildTextField("Pickup Location*", "pickupLocation",
            validator: _requiredValidator),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/notepad_background.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Please confirm your details below:",
              style: AppTextStyles.body1),
          const SizedBox(height: 16),
          _buildConfirmationItem("Service Type", formData['serviceType'] ?? ''),
          _buildConfirmationItem("Name", formData['name'] ?? ''),
          _buildConfirmationItem("Phone", formData['phone'] ?? ''),
          _buildConfirmationItem("Email", formData['email'] ?? ''),
          _buildConfirmationItem(
              "Car Make and Model", formData['carMakeModel'] ?? ''),
          _buildConfirmationItem(
              "Year of Manufacture", formData['yearOfManufacture'] ?? ''),
          _buildConfirmationItem(
              "Service Description", formData['serviceDescription'] ?? 'N/A'),
          _buildConfirmationItem(
              "Appointment Date & Time", formData['appointmentDateTime'] ?? ''),
          _buildConfirmationItem(
              "Pickup Location", formData['pickupLocation'] ?? ''),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _launchTermsUrl,
                  child: RichText(
                    text: TextSpan(
                      text: 'I accept the SpareWo ',
                      style: AppTextStyles.body2.copyWith(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body1),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String field, {
    bool isDateTime = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? placeholder,
    String? Function(String?)? validator,
  }) {
    final controller = _controllers[field]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body2),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: isDateTime,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onTap: isDateTime
              ? () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    DateTime dateTime;
                    if (pickedTime != null) {
                      dateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    } else {
                      dateTime = pickedDate;
                    }
                    final formattedDateTime =
                        "${dateTime.toLocal()}".split('.')[0];
                    setState(() {
                      formData[field] = formattedDateTime;
                      controller.text = formattedDateTime;
                    });
                  }
                }
              : null,
          onChanged: (value) => formData[field] = value,
          validator: validator,
          decoration: InputDecoration(
            hintText: placeholder ?? "Enter your ${label.toLowerCase()}",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: _prevStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Previous",
                  style: AppTextStyles.button.copyWith(fontSize: 14)),
            ),
          )
        else
          const SizedBox(width: 100),
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(_currentStep == 4 ? "Submit" : "Next",
              style: AppTextStyles.button.copyWith(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: LinearProgressIndicator(
        value: (_currentStep + 1) / 5,
        backgroundColor: Colors.grey[300],
        color: AppColors.primary,
        minHeight: 6,
      ),
    );
  }

  Widget _buildAnimation() {
    return Center(
      child: Lottie.asset(
        'assets/animations/gears.json',
        height: 150,
        width: 150,
      ),
    );
  }
}
