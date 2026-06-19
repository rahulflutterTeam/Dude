import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFF080612);
const _kCard = Color(0xFF100E1E);
const _kCardBorder = Color(0xFF1E1A30);
const _kAccent = Color(0xFFD4F53C);
const _kText = Color(0xFFFFFFFF);
const _kTextSub = Color(0xFF6B6585);
const _kTextMid = Color(0xFFADA8C0);
const _kPink = Color(0xFFFF5FA2);
const _kPinkDim = Color(0xFF250B1B);
// ──────────────────────────────────────────────────────────────────────────

class RewardDetailScreen extends StatelessWidget {
  final dynamic reward;
  const RewardDetailScreen({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E0A1E),
              Color(0xFF080612),
              Color(0xFF080612),
              Color(0xFF0D0A1C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ───────────────────────────────────────────
              _buildTopBar(context),
              const SizedBox(height: 32),

              // ── Detail Body ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Reward Large Icon - Shown fully
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: _kPinkDim,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _kPink.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kPink.withOpacity(0.12),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: reward.giftImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  reward.giftImage,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.card_giftcard_rounded,
                                    color: _kPink,
                                    size: 56,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.card_giftcard_rounded,
                                color: _kPink,
                                size: 56,
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Large Value
                      Text(
                        '₹${reward.coins}',
                        style: const TextStyle(
                          color: _kAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Get on this Rupees',
                        style: TextStyle(
                          color: _kTextSub,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Details Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kCardBorder),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              label: 'Reward Item',
                              value: reward.giftName,
                              isHighlight: true,
                            ),
                            _buildDivider(),
                            _buildDetailRow(
                              label: 'Received On',
                              value: HistoryTimeFormatter.list(
                                reward.createdAt,
                              ),
                            ),
                            _buildDivider(),
                            _buildDetailRow(
                              label: 'Transaction ID',
                              value: reward.id.isNotEmpty ? reward.id : '—',
                              isCode: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kCardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _kText,
                size: 16,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Reward Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 40), // Spacer for symmetry
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isHighlight = false,
    bool isCode = false,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kTextSub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: badgeColor != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        color: isHighlight ? _kText : _kTextMid,
                        fontSize: 13.5,
                        fontWeight: isHighlight
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontFamily: isCode ? 'Courier' : null,
                      ),
                      textAlign: TextAlign.end,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(height: 1, color: _kCardBorder.withOpacity(0.5)),
    );
  }
}
