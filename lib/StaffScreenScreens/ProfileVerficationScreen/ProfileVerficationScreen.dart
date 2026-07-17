import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/LiveSeflieVerificationScreen/LiveVerificationScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileVerficationScreen extends StatefulWidget {
  const ProfileVerficationScreen({super.key});

  @override
  State<ProfileVerficationScreen> createState() =>
      _ProfileVerficationScreenState();
}

class _ProfileVerficationScreenState extends State<ProfileVerficationScreen> {
  final TextEditingController idTypeController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();

  String? _selectedIdType;
  String? _idNumberError;

  final List<String> idTypes = ["Aadhaar Card", "PAN Card"];

  @override
  void initState() {
    super.initState();
    idTypeController.text = "Aadhaar Card";
    _selectedIdType = "Aadhaar Card";
    idNumberController.addListener(_validateIdNumber);
  }

  @override
  void dispose() {
    idTypeController.dispose();
    idNumberController.removeListener(_validateIdNumber);
    idNumberController.dispose();
    super.dispose();
  }

  void _validateIdNumber() {
    final value = idNumberController.text.trim();
    String? error;

    if (_selectedIdType == "Aadhaar Card") {
      if (value.isEmpty) {
        error = "Please enter Aadhaar number";
      } else if (value.length != 12 || !RegExp(r'^\d{12}$').hasMatch(value)) {
        error = "Aadhaar must be exactly 12 digits";
      }
    } else if (_selectedIdType == "PAN Card") {
      if (value.isEmpty) {
        error = "Please enter PAN number";
      } else if (!RegExp(
        r'^[A-Z]{5}[0-9]{4}[A-Z]$',
      ).hasMatch(value.toUpperCase())) {
        error = "Invalid PAN format (e.g., ABCDE1234F)";
      }
    }

    setState(() {
      _idNumberError = error;
    });
  }

  bool get _isFormValid {
    final idType = idTypeController.text.trim();
    final idNumber = idNumberController.text.trim();

    if (idType.isEmpty) return false;
    if (idNumber.isEmpty) return false;

    if (idType == "Aadhaar Card") {
      return idNumber.length == 12 && RegExp(r'^\d{12}$').hasMatch(idNumber);
    } else if (idType == "PAN Card") {
      return idNumber.length == 10 &&
          RegExp(
            r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
          ).hasMatch(idNumber.toUpperCase());
    }

    return false;
  }

  void _showIDTypeDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: DudeTheme.surfaceRaised,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: DudeTheme.borderSubtle)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ...idTypes.map(
              (type) => _dropdownItem(type, () {
                setState(() {
                  _selectedIdType = type;
                  idTypeController.text = type;
                });
                _validateIdNumber();
                Navigator.pop(context);
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _dropdownItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Text(
          title,
          style: TextStyle(
            color: title == _selectedIdType
                ? DudeTheme.accentBright
                : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: DudeTheme.background,
          resizeToAvoidBottomInset: true,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: DudeLogo(height: 54)),
                    const SizedBox(height: 28),
                    _stepLabel("STEP 1 OF 2  •  GOVERNMENT ID"),
                    const SizedBox(height: 14),
                    const Text(
                      "Let’s verify it’s really you",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Add one government-issued ID. Dude uses it only to keep the community safe and authentic.",
                      style: TextStyle(
                        color: DudeTheme.textSubtle,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: DudeTheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: DudeTheme.borderSubtle),
                        boxShadow: DudeTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel("ID type"),
                          const SizedBox(height: 9),
                          GestureDetector(
                            onTap: () => _showIDTypeDropdown(context),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: idTypeController,
                                readOnly: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _inputDecoration("Select an ID")
                                    .copyWith(
                                      suffixIcon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: DudeTheme.accentBright,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _fieldLabel("ID number"),
                          const SizedBox(height: 9),
                          TextField(
                            controller: idNumberController,
                            keyboardType: _selectedIdType == "Aadhaar Card"
                                ? TextInputType.number
                                : TextInputType.text,
                            textCapitalization: _selectedIdType == "PAN Card"
                                ? TextCapitalization.characters
                                : TextCapitalization.none,
                            maxLength: _selectedIdType == "Aadhaar Card"
                                ? 12
                                : 10,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                            decoration:
                                _inputDecoration(
                                  _selectedIdType == "Aadhaar Card"
                                      ? "Enter your 12-digit Aadhaar"
                                      : "Example: ABCDE1234F",
                                ).copyWith(
                                  errorText: _idNumberError,
                                  counterText: "",
                                ),
                          ),
                        ],
                      ),
                    ),

                    if (vm.idVerifyError != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          vm.idVerifyError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _privacyNote(),
                  ],
                ),
              ),
            ),
          ),

          // ─── Bottom Continue Button (disabled until valid) ────────────────
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: vm.isVerifyingId || !_isFormValid
                    ? null
                    : () async {
                        final success = await vm.verifyStaffId(
                          // Keep the API's existing values while showing the
                          // correctly styled names in the UI.
                          idType: _selectedIdType == "Aadhaar Card"
                              ? "Aadhar Card"
                              : "Pan Card",
                          idNumber: idNumberController.text.trim(),
                        );

                        if (!context.mounted) return;
                        if (success) {
                          bondNavigator.newPage(
                            context,
                            page: const LiveVerificationScreen(),
                          );
                        } else {
                          Utils.snackBarErrorMessage(
                            "ID verification failed. Please try again.",
                          );
                        }
                      },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: (vm.isVerifyingId || !_isFormValid)
                        ? const LinearGradient(
                            colors: [Color(0xFF452331), Color(0xFF301923)],
                          )
                        : DudeTheme.premiumAccentGradient,
                  ),
                  child: Center(
                    child: vm.isVerifyingId
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Continue to selfie  →",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stepLabel(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: DudeTheme.accentDim,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: DudeTheme.accent.withValues(alpha: 0.35)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: DudeTheme.accentBright,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    ),
  );

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: DudeTheme.textSubtle, letterSpacing: 0),
    filled: true,
    fillColor: DudeTheme.surfaceRaised,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: DudeTheme.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: DudeTheme.accent, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: DudeTheme.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: DudeTheme.danger, width: 1.4),
    ),
  );

  Widget _privacyNote() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DudeTheme.accentDim.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: DudeTheme.accentBright,
          size: 20,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "Your ID details are encrypted and used only for identity verification.",
            style: TextStyle(
              color: DudeTheme.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
