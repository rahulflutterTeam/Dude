// import 'package:dude/DudeScreens/LoginScreens/InterestLanguage/InterestedLanguage.dart';
// import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
// import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
// import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
// import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
// import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
// import 'package:flutter/material.dart';
// import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
// import 'package:provider/provider.dart';
//
// class InterestScreen extends StatefulWidget {
//   const InterestScreen({super.key});
//
//   @override
//   State<InterestScreen> createState() => _InterestScreenState();
// }
//
// class _InterestScreenState extends State<InterestScreen> {
//   final List<Map<String, dynamic>> interests = [
//     {
//       "title": "Travel",
//       "active": "assets/Images/travelactive.png",
//       "inactive": "assets/Images/travelinactive.png",
//       "selected": false,
//     },
//     {
//       "title": "Music",
//       "active": "assets/Images/musicactive.png",
//       "inactive": "assets/Images/musicinactive.png",
//       "selected": false,
//     },
//     {
//       "title": "Fitness",
//       "active": "assets/Images/gymactive.png",
//       "inactive": "assets/Images/gyminactive.png",
//       "selected": false,
//     },
//     {
//       "title": "Movies",
//       "active": "assets/Images/movieactive.png",
//       "inactive": "assets/Images/movieinactive.png",
//       "selected": false,
//     },
//     {
//       "title": "Food",
//       "active": "assets/Images/foodactive.png",
//       "inactive": "assets/Images/foodinactive.png",
//       "selected": false,
//     },
//     {
//       "title": "Tech",
//       "active": "assets/Images/techactive.png",
//       "inactive": "assets/Images/techinactive.png",
//       "selected": false,
//     },
//     {
//       "title": "Gaming",
//       "active": "assets/Images/gameactive.png",
//       "inactive": "assets/Images/gameinactive.png",
//       "selected": false,
//     },
//     {
//       "title": "Art",
//       "active": "assets/Images/artactive.png",
//       "inactive": "assets/Images/artinactive.png",
//       "selected": false,
//     },
//   ];
//
//   int get selectedCount => interests.where((e) => e["selected"] == true).length;
//
//   List<String> get selectedTitles => interests
//       .where((e) => e["selected"] == true)
//       .map((e) => e["title"] as String)
//       .toList();
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<LoginViewModel>(
//       builder: (context, vm, child) {
//         return Scaffold(
//           body: Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topRight,
//                 end: Alignment.bottomLeft,
//                 colors: [
//                   DudeTheme.background,
//                   DudeTheme.background,
//                   DudeTheme.background,
//                   DudeTheme.background,
//                 ],
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 10),
//                         DudeLogo(height: 40),
//                         const SizedBox(height: 30),
//
//                         Row(
//                           children: [
//                             // GestureDetector(
//                             //   onTap: () => bondNavigator.backPage(context),
//                             //   child: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                             // ),
//                             const SizedBox(width: 12),
//                             AppText(
//                               "Select your Interest",
//                               fontSize: 24,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.white,
//                             ),
//                           ],
//                         ),
//
//                         const SizedBox(height: 8),
//                         AppText(
//                           "Select a Few of your Interest to match with users who have similar things in common.",
//                           fontSize: 15,
//                           color: DudeTheme.textMuted,
//                           maxLines: 2,
//                         ),
//
//                         if (vm.interestError != null) ...[
//                           const SizedBox(height: 16),
//                           Center(
//                             child: Text(
//                               vm.interestError!,
//                               style: const TextStyle(
//                                 color: Colors.redAccent,
//                                 fontSize: 14,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: GridView.builder(
//                         itemCount: interests.length,
//                         gridDelegate:
//                             const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 2,
//                               mainAxisSpacing: 1,
//                               crossAxisSpacing: 12,
//                               childAspectRatio: 1.3,
//                             ),
//                         itemBuilder: (context, index) {
//                           final item = interests[index];
//                           return _interestCard(item, index);
//                         },
//                       ),
//                     ),
//                   ),
//
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 16,
//                     ),
//                     child: GestureDetector(
//                       onTap: vm.isUpdatingInterests
//                           ? null
//                           : () async {
//                               if (selectedCount < 3) {
//                                 Utils.snackBarErrorMessage(
//                                   "Please select at least 3 interests",
//                                 );
//                                 return;
//                               }
//
//                               final success = await vm.updateAreaOfInterest(
//                                 selectedTitles,
//                               );
//
//                               if (success) {
//                                 bondNavigator.newPage(
//                                   context,
//                                   page: const InterestLanguageScreen(),
//                                 );
//                               } else {
//                                 Utils.snackBarErrorMessage(
//                                   "Failed to save interests. Try again.",
//                                 );
//                               }
//                             },
//                       child: Container(
//                         height: 54,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8),
//                           gradient:
//                               selectedCount >= 3 && !vm.isUpdatingInterests
//                               ? const LinearGradient(
//                                   colors: [
//                                     DudeTheme.accent,
//                                     DudeTheme.accent,
//                                   ],
//                                 )
//                               : const LinearGradient(
//                                   colors: [
//                                     DudeTheme.surfaceRaised,
//                                     DudeTheme.surfaceRaised,
//                                   ],
//                                 ),
//                         ),
//                         child: Center(
//                           child: vm.isUpdatingInterests
//                               ? const SizedBox(
//                                   height: 24,
//                                   width: 24,
//                                   child: CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 2.5,
//                                   ),
//                                 )
//                               : Text(
//                                   "Select atleast $selectedCount/3 Interest  →",
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _interestCard(Map<String, dynamic> item, int index) {
//     final bool selected = item["selected"];
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           interests[index]["selected"] = !selected;
//         });
//       },
//       child: Image.asset(selected ? item["active"] : item["inactive"]),
//     );
//   }
// }
