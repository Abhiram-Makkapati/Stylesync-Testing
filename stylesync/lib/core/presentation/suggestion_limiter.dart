import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'suggestion_limiter_service.dart';

class SuggestionLimiterScreen extends StatefulWidget {
  final String userId; // <-- pass userId from auth

  const SuggestionLimiterScreen({super.key, required this.userId});

  @override
  State<SuggestionLimiterScreen> createState() =>
      _SuggestionLimiterScreenState();
}

class _SuggestionLimiterScreenState extends State<SuggestionLimiterScreen> {
  static const Color kGreen = Color(0xFF2FAA52);

  bool suggestionsEnabled = true;
  double limit = 3;
  String mode = "per_week"; // per_day, per_week, per_month

  final SuggestionLimiterService _service = SuggestionLimiterService();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await _service.loadSettings(widget.userId);
    if (data != null) {
      setState(() {
        suggestionsEnabled = data["enabled"] ?? true;
        limit = (data["limit"] ?? 3).toDouble();
        mode = data["mode"] ?? "per_week";
      });
    }
    loading = false;
    setState(() {});
  }

  Future<void> _saveSettings() async {
    await _service.saveSettings(widget.userId, {
      "enabled": suggestionsEnabled,
      "limit": limit.toInt(),
      "mode": mode,
      "updatedAt": Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: kGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Suggestion Limit",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // SUGGESTION TOGGLE SWITCH
            // -------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Enable Suggestions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: suggestionsEnabled,
                  activeColor: kGreen,
                  onChanged: (v) => setState(() {
                    suggestionsEnabled = v;
                  }),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              suggestionsEnabled
                  ? "Suggestions will be limited based on your settings below."
                  : "Suggestions are turned off completely.",
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.3),
            ),

            const SizedBox(height: 30),

            if (suggestionsEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -----------------------------------
                  // FREQUENCY MODE PICKER
                  // -----------------------------------
                  const Text(
                    "Frequency",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModeButton("Per Day", "per_day"),
                      _buildModeButton("Per Week", "per_week"),
                      _buildModeButton("Per Month", "per_month"),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // -------------------------
                  // LIMIT SLIDER CARD
                  // -------------------------
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Suggestions ${_modeLabel()}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Slider(
                          value: limit,
                          min: 0,
                          max: (mode == "per_month") ? 30 : (mode == "per_week") ? 10 : 5,
                          divisions: (mode == "per_month") ? 30 : (mode == "per_week") ? 10 : 5,
                          activeColor: kGreen,
                          label: "${limit.toInt()}",
                          onChanged: (v) => setState(() => limit = v),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Min: 0",
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              "Current: ${limit.toInt()}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                                "Max: ${(mode == "per_month") ? 30 : (mode == "per_week") ? 10 : 5}",
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const Spacer(),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saveSettings,
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // MODE BUTTON WIDGET
  // ------------------------------------------------
  Widget _buildModeButton(String text, String value) {
    final bool isSelected = mode == value;

    return GestureDetector(
      onTap: () => setState(() => mode = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? kGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? kGreen : Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Dynamic text based on selected mode
  String _modeLabel() {
    switch (mode) {
      case "per_day":
        return "per day";
      case "per_week":
        return "per week";
      case "per_month":
        return "per month";
      default:
        return "";
    }
  }
}
