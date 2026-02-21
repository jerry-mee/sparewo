// lib/features/autohub/presentation/autohub_conversational.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/core/router/navigation_extensions.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/addresses/application/saved_address_provider.dart';
import 'package:sparewo_client/features/addresses/domain/saved_address.dart';
import 'package:sparewo_client/features/autohub/application/autohub_provider.dart';
import 'package:sparewo_client/features/autohub/domain/service_booking_model.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/autohub/presentation/widgets/vehicle_search_widget.dart';
import 'package:sparewo_client/features/shared/services/notification_service.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';

class AutoHubConversationalScreen extends ConsumerStatefulWidget {
  const AutoHubConversationalScreen({super.key});

  @override
  ConsumerState<AutoHubConversationalScreen> createState() =>
      _AutoHubConversationalScreenState();
}

class _AutoHubConversationalScreenState
    extends ConsumerState<AutoHubConversationalScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Local state for UI selection
  String? selectedBrand;
  String? selectedModel;
  int? selectedYear;
  List<String> selectedServices = [];
  DateTime? selectedDate;
  String? selectedTime;
  bool _isSubmitting = false;
  String? _selectedSavedAddressId;

  @override
  void initState() {
    super.initState();
    AppLogger.ui('AutoHubConversational', 'Loaded conversational flow');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  SavedAddress? _resolveSavedAddress(List<SavedAddress> addresses) {
    if (addresses.isEmpty) return null;
    if (_selectedSavedAddressId != null) {
      for (final address in addresses) {
        if (address.id == _selectedSavedAddressId) return address;
      }
    }
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  void _applyPickupAddress(SavedAddress address) {
    final next = address.fullAddress.isNotEmpty
        ? address.fullAddress
        : address.line1;
    _locationController.text = next;
    ref.read(bookingFlowNotifierProvider.notifier).setPickupLocation(next);
    setState(() {
      _selectedSavedAddressId = address.id;
    });
  }

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeOutCubic);
      setState(() => _currentStep++);
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep--);
    } else {
      context.goBackOr('/autohub');
    }
  }

  /// Checks if the current step is valid.
  /// Now uses the Provider state for Description/Location validation
  /// to ensure reactivity when typing.
  bool _isCurrentStepValid(BookingState bookingState) {
    switch (_currentStep) {
      case 0: // Vehicle
        return selectedBrand != null && selectedModel != null;
      case 1: // Services
        return selectedServices.isNotEmpty;
      case 2: // Description
        // Use provider state to ensure button enables on type
        return (bookingState.description ?? '').trim().isNotEmpty;
      case 3: // Date/Time
        return selectedDate != null && selectedTime != null;
      case 4: // Location
        // Use provider state
        return (bookingState.pickupLocation ?? '').trim().isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: SafeArea(child: _buildFlowContent(context, isDesktop: false)),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.wide,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DesktopSection(
                title: 'AutoHub Request',
                subtitle: 'Step-by-step service booking',
                padding: EdgeInsets.only(top: 24, bottom: 12),
                child: SizedBox.shrink(),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                      boxShadow: AppShadows.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: _buildFlowContent(context, isDesktop: true),
                    ),
                  ),
                ),
              ),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowContent(BuildContext context, {required bool isDesktop}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (_currentStep + 1) / _totalSteps;
    final bookingState = ref.watch(bookingFlowNotifierProvider);
    final isValid = _isCurrentStepValid(bookingState);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.cardColor,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  Image.asset(
                    isDark
                        ? 'assets/logo/branding.png'
                        : 'assets/logo/branding_dark.png',
                    height: 24,
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    AnimatedContainer(
                      duration: 500.ms,
                      curve: Curves.easeOutExpo,
                      height: 6,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isDesktop)
          SizedBox(
            height: 610,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepVehicle(context),
                _buildStepServices(context),
                _buildStepDescription(context),
                _buildStepDateTime(context),
                _buildStepLocation(context),
                _buildStepSummary(context),
              ],
            ),
          )
        else
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepVehicle(context),
                _buildStepServices(context),
                _buildStepDescription(context),
                _buildStepDateTime(context),
                _buildStepLocation(context),
                _buildStepSummary(context),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            boxShadow: AppShadows.bottomNavShadow,
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: _previousPage,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              Expanded(
                child: FilledButton(
                  onPressed: isValid && !_isSubmitting
                      ? () {
                          if (_currentStep == _totalSteps - 1) {
                            _submitBooking();
                          } else {
                            _nextPage();
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: theme.disabledColor.withValues(
                      alpha: 0.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: isValid ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Text(
                          _currentStep == _totalSteps - 1
                              ? 'Confirm Request'
                              : 'Next Step',
                        ),
                      if (_currentStep < _totalSteps - 1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepVehicle(BuildContext context) {
    final isAuthenticated =
        ref.watch(currentUserProvider).asData?.value != null;
    final savedCarsAsync = ref.watch(carsProvider);
    final hasSelection = selectedBrand != null && selectedModel != null;

    return _buildStepContainer(
      title: "What are we working on?",
      subtitle: "Select the vehicle that needs service.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSelection) ...[
            _buildSelectionCard(
              context: context,
              isSelected: true,
              onTap: () {},
              icon: Icons.check_circle,
              title: '$selectedYear $selectedBrand $selectedModel',
              subtitle: 'Selected Vehicle',
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAuthenticated) ...[
                    Text(
                      "Your Saved Vehicles:",
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isAuthenticated)
                    savedCarsAsync.when(
                      data: (cars) {
                        if (cars.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              "No saved cars found.",
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: cars.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final car = cars[index];
                            final isSelected =
                                selectedBrand == car.make &&
                                selectedModel == car.model &&
                                selectedYear == car.year;

                            return _buildSelectionCard(
                              context: context,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  selectedBrand = car.make;
                                  selectedModel = car.model;
                                  selectedYear = car.year;
                                });
                                ref
                                    .read(bookingFlowNotifierProvider.notifier)
                                    .setVehicle(car.make, car.model, car.year);
                              },
                              icon: Icons.directions_car_filled_rounded,
                              title: car.displayName,
                              subtitle:
                                  '${car.year} • ${car.plateNumber ?? "No Plate"}',
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Could not load saved cars. Please use manual selection below.",
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "You're in guest mode. Select your vehicle details below.",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    isAuthenticated ? "Or choose another:" : "Choose vehicle:",
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildAddNewCarButton(
                    context,
                    isGuest: !isAuthenticated,
                    hasSelection: hasSelection,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepServices(BuildContext context) {
    return _buildStepContainer(
      title: "How can we help?",
      subtitle: "Choose one or more services.",
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        itemCount: ServiceType.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = ServiceType.values[index];
          final isSelected = selectedServices.contains(service.displayName);

          return _buildSelectionCard(
            context: context,
            isSelected: isSelected,
            isMultiSelect: true,
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedServices.remove(service.displayName);
                } else {
                  selectedServices.add(service.displayName);
                }
              });
              ref
                  .read(bookingFlowNotifierProvider.notifier)
                  .toggleService(service.displayName);
            },
            icon: _getServiceIcon(service),
            title: service.displayName,
          );
        },
      ),
    );
  }

  Widget _buildStepDescription(BuildContext context) {
    return _buildStepContainer(
      title: "Any details to add?",
      subtitle: "Describe the issue or specific requirements.",
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.cardShadow,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: "e.g., I hear a rattling noise when braking...",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                ),
                onChanged: (val) {
                  // Update state, which triggers ref.watch in build to re-evaluate validation
                  ref
                      .read(bookingFlowNotifierProvider.notifier)
                      .setServiceDescription(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDateTime(BuildContext context) {
    return _buildStepContainer(
      title: "When works best?",
      subtitle: "Schedule your pickup time.",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final appTheme = Theme.of(context);
                final isDark = appTheme.brightness == Brightness.dark;
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) => Theme(
                    data: appTheme.copyWith(
                      colorScheme: appTheme.colorScheme.copyWith(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        onSurface: isDark ? Colors.white : null,
                        surface: isDark
                            ? const Color(0xFF111827)
                            : appTheme.cardColor,
                      ),
                      datePickerTheme: DatePickerThemeData(
                        backgroundColor: isDark
                            ? const Color(0xFF111827)
                            : appTheme.cardColor,
                        surfaceTintColor: Colors.transparent,
                        dayForegroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return isDark ? Colors.white : null;
                        }),
                        yearForegroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return isDark ? Colors.white : null;
                        }),
                        weekdayStyle: TextStyle(
                          color: isDark ? Colors.white70 : null,
                        ),
                        headerForegroundColor: Colors.white,
                        todayForegroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return AppColors.primary;
                        }),
                      ),
                      dialogTheme: DialogThemeData(
                        backgroundColor: isDark
                            ? const Color(0xFF111827)
                            : (appTheme.dialogTheme.backgroundColor ??
                                  appTheme.colorScheme.surface),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedDate != null
                        ? AppColors.primary
                        : Theme.of(context).dividerColor,
                  ),
                  boxShadow: AppShadows.cardShadow,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: selectedDate != null
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      selectedDate != null
                          ? _formatDate(selectedDate!)
                          : "Select Date",
                      style: AppTextStyles.h4,
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (selectedDate != null) ...[
              Text("Available Slots", style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              FutureBuilder<List<TimeSlot>>(
                future: ref.read(
                  availableTimeSlotsProvider(selectedDate!).future,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: snapshot.data!.map((slot) {
                      final isSelected = selectedTime == slot.time;
                      return InkWell(
                        onTap: slot.isAvailable
                            ? () {
                                setState(() => selectedTime = slot.time);
                                ref
                                    .read(bookingFlowNotifierProvider.notifier)
                                    .setPickupDateTime(
                                      selectedDate!,
                                      slot.time,
                                    );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (slot.isAvailable
                                      ? Theme.of(context).cardColor
                                      : Theme.of(
                                          context,
                                        ).disabledColor.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            slot.display,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (slot.isAvailable ? null : Colors.grey),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepLocation(BuildContext context) {
    final savedAddresses = ref
        .watch(savedAddressesStreamProvider)
        .asData
        ?.value;
    final selectedAddress = _resolveSavedAddress(savedAddresses ?? const []);
    if (_locationController.text.trim().isEmpty && selectedAddress != null) {
      final next = selectedAddress.fullAddress.isNotEmpty
          ? selectedAddress.fullAddress
          : selectedAddress.line1;
      _locationController.text = next;
      ref.read(bookingFlowNotifierProvider.notifier).setPickupLocation(next);
    }

    return _buildStepContainer(
      title: "Where are you?",
      subtitle: "Enter the pickup address or use a saved one.",
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (savedAddresses != null && savedAddresses.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: selectedAddress?.id,
                decoration: const InputDecoration(
                  labelText: 'Saved pickup address',
                  prefixIcon: Icon(Icons.bookmark_outline),
                ),
                items: savedAddresses
                    .map(
                      (address) => DropdownMenuItem<String>(
                        value: address.id,
                        child: Text(
                          '${address.shortTitle} • ${address.subtitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  for (final address in savedAddresses) {
                    if (address.id == value) {
                      _applyPickupAddress(address);
                      break;
                    }
                  }
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push('/addresses'),
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: const Text('Manage addresses'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.cardShadow,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _locationController,
                maxLines: 3,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: "Street address, apartment, etc...",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                ),
                onChanged: (val) {
                  if (_selectedSavedAddressId != null) {
                    setState(() => _selectedSavedAddressId = null);
                  }
                  // Update state, triggering rebuild of the Next button
                  ref
                      .read(bookingFlowNotifierProvider.notifier)
                      .setPickupLocation(val);
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "We currently offer free pickup within Kampala limits.",
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSummary(BuildContext context) {
    final theme = Theme.of(context);
    final dateDisplay = selectedDate != null
        ? _formatDate(selectedDate!)
        : "Date Pending";
    final timeDisplay = selectedTime != null
        ? _formatTime(selectedTime!)
        : "Time Pending";

    return _buildStepContainer(
      title: "Almost done!",
      subtitle: "Review your booking details.",
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.cardShadow,
              ),
              child: Column(
                children: [
                  _buildSummaryItem(
                    context,
                    Icons.directions_car,
                    "Vehicle",
                    "${selectedYear ?? ''} ${selectedBrand ?? 'Unknown'} ${selectedModel ?? 'Vehicle'}",
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.build,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Services",
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (selectedServices.isEmpty)
                                Text(
                                  "None Selected",
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                )
                              else
                                Column(
                                  children: selectedServices
                                      .map(
                                        (service) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "• $service",
                                                  style: AppTextStyles.bodyLarge
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedServices.remove(
                                                      service,
                                                    );
                                                  });
                                                  ref
                                                      .read(
                                                        bookingFlowNotifierProvider
                                                            .notifier,
                                                      )
                                                      .toggleService(service);
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .error
                                                        .withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 14,
                                                    color:
                                                        theme.colorScheme.error,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                  _buildSummaryItem(
                    context,
                    Icons.calendar_today,
                    "Time",
                    "$dateDisplay at $timeDisplay",
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                  _buildSummaryItem(
                    context,
                    Icons.location_on,
                    "Location",
                    _locationController.text.isEmpty
                        ? 'No Location'
                        : _locationController.text,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "By confirming, you agree to our service terms. Payment is due upon completion of service.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 30 : 24,
        vertical: isDesktop ? 14 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h2,
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          Expanded(
            child: child
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.1, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    String? subtitle,
    bool isMultiSelect = false,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [] : AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : theme.iconTheme.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4.copyWith(fontSize: 16)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                isMultiSelect ? Icons.check_box : Icons.radio_button_checked,
                color: AppColors.primary,
              )
            else
              Icon(
                isMultiSelect
                    ? Icons.check_box_outline_blank
                    : Icons.radio_button_unchecked,
                color: theme.disabledColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewCarButton(
    BuildContext context, {
    required bool isGuest,
    required bool hasSelection,
  }) {
    final ctaLabel = isGuest
        ? 'Select Vehicle'
        : (hasSelection ? 'Select Another Car' : 'Select Vehicle');

    return OutlinedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scroll) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text("Select Vehicle", style: AppTextStyles.h3),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scroll,
                      child: VehicleSearchWidget(
                        onVehicleSelected: (make, model, year) {
                          Navigator.pop(context);
                          setState(() {
                            selectedBrand = make;
                            selectedModel = model;
                            selectedYear = year;
                          });
                          ref
                              .read(bookingFlowNotifierProvider.notifier)
                              .setVehicle(make, model, year);
                        },
                        initialBrand: selectedBrand,
                        initialModel: selectedModel,
                        initialYear: selectedYear,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: Text(ctaLabel),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(0, 56),
      ),
    );
  }

  void _submitBooking() async {
    if (_isSubmitting) return;

    final bookingState = ref.read(bookingFlowNotifierProvider);
    if (!_hasRequiredBookingData(bookingState)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required booking details first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    AppLogger.info(
      'autohub.submitButton.tap',
      'User tapped Confirm Request',
      extra: {'step': _currentStep},
    );

    try {
      final authUser = ref.read(authStateChangesProvider).asData?.value;
      if (authUser == null) {
        AuthGuardModal.check(
          context: context,
          ref: ref,
          title: 'Sign in to submit',
          message: 'We saved your details. Sign in to complete your booking.',
          onAuthenticated: _submitBooking,
        );
        return;
      }

      final user = ref.read(currentUserProvider).asData?.value;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Finishing account setup. Please try again.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      if (mounted) {
        setState(() => _isSubmitting = true);
      }

      final booking = await ref
          .read(bookingFlowNotifierProvider.notifier)
          .submitBooking();
      if (booking != null && mounted) {
        AppLogger.info(
          'autohub.submit.success',
          'Booking completed, navigating home',
          extra: {
            'bookingId': booking.id,
            'bookingNumber': booking.bookingNumber,
          },
        );

        // TRIGGER NOTIFICATION
        final vehicleName =
            '${selectedYear ?? ''} ${selectedBrand ?? ''} ${selectedModel ?? ''}';
        await ref
            .read(notificationServiceProvider)
            .showBookingReceived(
              bookingNumber: booking.bookingNumber ?? 'PENDING',
              vehicleName: vehicleName,
              bookingId: booking.id,
            );

        if (!mounted) return;
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking Received!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('autohub.submit.uiError', e.toString(), stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _hasRequiredBookingData(BookingState state) {
    return (state.brand ?? '').trim().isNotEmpty &&
        (state.model ?? '').trim().isNotEmpty &&
        state.year != null &&
        state.services.isNotEmpty &&
        (state.description ?? '').trim().isNotEmpty &&
        state.pickupDate != null &&
        (state.pickupTime ?? '').trim().isNotEmpty &&
        (state.pickupLocation ?? '').trim().isNotEmpty;
  }

  IconData _getServiceIcon(ServiceType service) {
    switch (service) {
      case ServiceType.oilChange:
        return Icons.oil_barrel_outlined;
      case ServiceType.brakeService:
        return Icons.disc_full_outlined;
      case ServiceType.tireRotation:
        return Icons.tire_repair;
      default:
        return Icons.car_repair;
    }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";
  String _formatTime(String t) => t;
}
