import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/VerifyOtpStaffScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFbdd534),
              onPrimary: Colors.white,
              surface: Color(0xFF1C1426),
              onSurface: Colors.white,
              secondary: Color(0xFF7B4DFF),
            ),
            dialogBackgroundColor: const Color(0xFF241b40),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFbdd534),
              ),
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
              backgroundColor: const Color(0xFF241b40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                        color: const Color(0xFFbdd534).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
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
                          hintText: "Search city...",
                          hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFbdd534),
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
                          ? const Center(
                              child: Text(
                                "No cities found",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                    filteredCities[index],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () {
                                    _selectedCity = filteredCities[index];
                                    cityController.text = filteredCities[index];
                                    Navigator.pop(context);
                                  },
                                  hoverColor: const Color(
                                    0xFFbdd534,
                                  ).withOpacity(0.1),
                                  splashColor: const Color(
                                    0xFFbdd534,
                                  ).withOpacity(0.2),
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
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF241b40),
                  Color(0xFF1C1426),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    SvgPicture.asset("assets/Images/dude.svg", height: 50),
                    const SizedBox(height: 30),

                    Center(
                      child: AppText(
                        "Staff registration",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    AppText(
                      "Join as a verified female staff member and start earning through audio and video calls.",
                      fontSize: 15,
                      color: const Color(0xFFc7c7cc),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // ─── Name ──────────────────────────────────────────────────
                    AppText(
                      "Name:",
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                        filled: true,
                        fillColor: const Color(0xFFbdd534).withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Date of Birth ────────────────────────────────────────
                    AppText(
                      "Date Of Birth:",
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onTap: () => _selectDate(context),
                      controller: dobController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "DD/MM/YYYY",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                        filled: true,
                        fillColor: const Color(0xFFbdd534).withOpacity(0.06),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            "assets/Images/calender.svg",
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFbdd534),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Email ────────────────────────────────────────────────
                    AppText(
                      "Email Address:",
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "xyz@gmail.com",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                        filled: true,
                        fillColor: const Color(0xFFbdd534).withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── City Dropdown with Search ─────────────────────────────────
                    AppText(
                      "City:",
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showCitySearchDialog,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: cityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Select your city",
                            hintStyle: const TextStyle(
                              color: Color(0xFFc7c7cc),
                            ),
                            filled: true,
                            fillColor: const Color(
                              0xFFbdd534,
                            ).withOpacity(0.06),
                            suffixIcon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFFbdd534),
                              size: 30,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          vm.errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // ─── Continue Button ──────────────────────────────────────
                    GestureDetector(
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

                              if (success) {
                                print("━━━━━━━━━━━━━━━━━━━━━");
                                print("SUCCESS = true → should navigate now");
                                print(
                                  "Register response: ${vm.registerResponse}",
                                );
                                print("━━━━━━━━━━━━━━━━━━━━━");
                                bondNavigator.newPage(
                                  context,
                                  page: ProfileVerficationScreen(),
                                );
                              } else {
                                Utils.snackBarErrorMessage(
                                  "Registration failed. Please try again.",
                                );
                              }
                            },
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: vm.isRegistering
                              ? const LinearGradient(
                                  colors: [Colors.grey, Colors.blueGrey],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFbdd534),
                                    Color(0xFFbdd534),
                                  ],
                                ),
                        ),
                        child: Center(
                          child: vm.isRegistering
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Continue to Verification  →",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
