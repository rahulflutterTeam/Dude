import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/login_auth_shell.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StaffRegisterScreen extends StatefulWidget {
  const StaffRegisterScreen({super.key});

  @override
  State<StaffRegisterScreen> createState() => _StaffRegisterScreenState();
}

class _StaffRegisterScreenState extends State<StaffRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  bool _isMale = true;
  String? _selectedCity;

  // List of major Indian cities
  final List<String> _indianCities = [
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Hyderabad",
    "Ahmedabad",
    "Chennai",
    "Kolkata",
    "Surat",
    "Pune",
    "Jaipur",
    "Lucknow",
    "Kanpur",
    "Nagpur",
    "Indore",
    "Thane",
    "Bhopal",
    "Visakhapatnam",
    "Pimpri-Chinchwad",
    "Patna",
    "Vadodara",
    "Ghaziabad",
    "Ludhiana",
    "Agra",
    "Nashik",
    "Faridabad",
    "Meerut",
    "Rajkot",
    "Kalyan-Dombivli",
    "Vasai-Virar",
    "Varanasi",
    "Srinagar",
    "Aurangabad",
    "Dhanbad",
    "Amritsar",
    "Navi Mumbai",
    "Allahabad",
    "Howrah",
    "Ranchi",
    "Gwalior",
    "Jabalpur",
    "Coimbatore",
    "Vijayawada",
    "Jodhpur",
    "Madurai",
    "Raipur",
    "Kota",
    "Guwahati",
    "Chandigarh",
    "Solapur",
    "Hubli-Dharwad",
    "Bareilly",
    "Moradabad",
    "Mysore",
    "Gurugram",
    "Aligarh",
    "Jalandhar",
    "Tiruchirappalli",
    "Bhubaneswar",
    "Salem",
    "Mira-Bhayandar",
    "Thiruvananthapuram",
    "Bhiwandi",
    "Saharanpur",
    "Gorakhpur",
    "Guntur",
    "Bikaner",
    "Amravati",
    "Noida",
    "Jamshedpur",
    "Bhilai",
    "Warangal",
    "Cuttack",
    "Firozabad",
    "Kochi",
    "Bhavnagar",
    "Dehradun",
    "Durgapur",
    "Asansol",
    "Nanded",
    "Kolhapur",
    "Ajmer",
    "Gulbarga",
    "Jamnagar",
    "Ujjain",
    "Loni",
    "Siliguri",
    "Jhansi",
    "Ulhasnagar",
    "Nellore",
    "Jammu",
    "Belgaum",
    "Mangalore",
    "Ambattur",
    "Tirunelveli",
    "Malegaon",
    "Gaya",
    "Tiruppur",
    "Davangere",
    "Kozhikode",
    "Kurnool",
  ];

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cityController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: DudeTheme.accent,
              onPrimary: DudeTheme.textOnAccent,
              surface: DudeTheme.surface,
              onSurface: DudeTheme.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: DudeTheme.surface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: DudeTheme.accent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      String formatted =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
      dobController.text = formatted;
    }
  }

  Future<void> _showCitySearchDialog() async {
    TextEditingController searchController = TextEditingController();
    List<String> filteredCities = List.from(_indianCities);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: DudeTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: DudeTheme.border.withValues(alpha: 0.6)),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Field
                    Container(
                      decoration: BoxDecoration(
                        color: DudeTheme.accentDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DudeTheme.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(color: DudeTheme.textPrimary),
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              filteredCities = List.from(_indianCities);
                            } else {
                              filteredCities = _indianCities
                                  .where(
                                    (city) => city.toLowerCase().contains(
                                      value.toLowerCase(),
                                    ),
                                  )
                                  .toList();
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search city...',
                          hintStyle: TextStyle(
                            color: DudeTheme.textSubtle.withValues(alpha: 0.9),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: DudeTheme.accent,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cities List
                    Expanded(
                      child: filteredCities.isEmpty
                          ? Center(
                              child: Text(
                                'No cities found',
                                style: TextStyle(
                                  color: DudeTheme.textMuted.withValues(alpha: 0.9),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                    filteredCities[index],
                                    style: TextStyle(
                                      color: DudeTheme.textPrimary,
                                    ),
                                  ),
                                  onTap: () {
                                    _selectedCity = filteredCities[index];
                                    cityController.text = filteredCities[index];
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isValidInput() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final city = cityController.text.trim();
    final dob = dobController.text.trim();

    if (name.isEmpty || name.length < 2) {
      Utils.snackBarErrorMessage("Please enter a valid name");
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      Utils.snackBarErrorMessage("Please enter a valid email");
      return false;
    }
    if (city.isEmpty) {
      Utils.snackBarErrorMessage("Please select your city");
      return false;
    }
    if (dob.isEmpty) {
      Utils.snackBarErrorMessage("Please select your date of birth");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        return LoginAuthShell(
          showBack: true,
          title: 'Complete your profile',
          subtitle:
              'A few details to set up your staff account and start earning.',
          form: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                label: 'Full name',
                hint: 'Enter your name',
                icon: Icons.person_outline_rounded,
                controller: nameController,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: AuthInputField(
                    label: 'Date of birth',
                    hint: 'DD/MM/YYYY',
                    icon: Icons.calendar_today_outlined,
                    controller: dobController,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthInputField(
                label: 'Email address',
                hint: 'xyz@gmail.com',
                icon: Icons.email_outlined,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showCitySearchDialog,
                child: AbsorbPointer(
                  child: AuthInputField(
                    label: 'City',
                    hint: 'Select your city',
                    icon: Icons.location_city_outlined,
                    controller: cityController,
                  ),
                ),
              ),
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  vm.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PremiumPrimaryButton(
                label: 'Continue →',
                loading: vm.isRegistering,
                height: 54,
                onTap: vm.isRegistering
                    ? null
                    : () async {
                        if (!_isValidInput()) return;

                        final success = await vm.registerStaff(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          city: cityController.text.trim(),
                          dob: dobController.text.trim(),
                        );

                        if (!mounted) return;

                        if (success) {
                          bondNavigator.newPage(
                            context,
                            page: const ProfileVerficationScreen(),
                          );
                        } else {
                          Utils.snackBarErrorMessage(
                            'Registration failed. Please try again.',
                          );
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
