import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/StaffScreenScreens/StaffProfileScreen/RewardDetailScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class StaffRewardsScreen extends StatefulWidget {
  const StaffRewardsScreen({super.key});

  @override
  State<StaffRewardsScreen> createState() => _StaffRewardsScreenState();
}

class _StaffRewardsScreenState extends State<StaffRewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffViewModel>().fetchStaffGifts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        final rewardsList = vm.gifts; // parses response.data list

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 16),

                  if (vm.isFetchingGifts && rewardsList.isEmpty)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: DudeTheme.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (vm.giftsError != null && rewardsList.isEmpty)
                    Expanded(child: _buildErrorState(vm))
                  else ...[
                    Expanded(
                      child: RefreshIndicator(
                        color: DudeTheme.accent,
                        backgroundColor: DudeTheme.surface,
                        onRefresh: () => vm.fetchStaffGifts(),
                        child: rewardsList.isEmpty
                            ? _buildEmptyState()
                            : _buildRewardsList(rewardsList),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              bondNavigator.backPage(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DudeTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DudeTheme.border),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: DudeTheme.textPrimary,
                size: 16,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'My Rewards',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 40), // Spacer for balance symmetry
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // REWARDS LIST
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildRewardsList(List<dynamic> rewards) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final item = rewards[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            bondNavigator.newPage(
              context,
              page: RewardDetailScreen(reward: item),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DudeTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DudeTheme.border),
            ),
            child: Row(
              children: [
                // Reward Image / Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: DudeTheme.accentDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DudeTheme.accent.withOpacity(0.15)),
                  ),
                  child: item.giftImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.giftImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.card_giftcard_rounded,
                              color: DudeTheme.accent,
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.card_giftcard_rounded,
                          color: DudeTheme.accent,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 14),

                // Reward Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.giftName,
                        style: TextStyle(
                          color: DudeTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        HistoryTimeFormatter.list(item.createdAt),
                        style: TextStyle(color: DudeTheme.textSubtle, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Rupees Value
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DudeTheme.accentDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DudeTheme.accent.withOpacity(0.25)),
                  ),
                  child: Text(
                    '₹${item.coins}',
                    style: TextStyle(
                      color: DudeTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: DudeTheme.accentDim,
                  shape: BoxShape.circle,
                  border: Border.all(color: DudeTheme.accent.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: DudeTheme.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text('No Rewards Yet', style: TextStyle(
                  color: DudeTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Rewards earned from calls or activities will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DudeTheme.textSubtle, fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // ERROR STATE
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildErrorState(StaffViewModel vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF2D1418),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            vm.giftsError ?? 'Failed to load rewards',
            style: TextStyle(
              color: DudeTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: vm.fetchStaffGifts,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: DudeTheme.accent,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: DudeTheme.accent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
