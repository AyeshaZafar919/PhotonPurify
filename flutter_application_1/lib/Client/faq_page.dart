import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {

  final List<Map<String, String>> faqs = [
    {
      "q": "How does the solar panel cleaning system work?",
      "a": "The system uses automated motors and brushes to clean dust from solar panels, improving efficiency."
    },
    {
      "q": "Can I control cleaning manually?",
      "a": "Yes, you can start or stop cleaning anytime from the control panel in the app."
    },
    {
      "q": "What happens during bad weather?",
      "a": "The system automatically stops cleaning during rain, storms, or high winds for safety."
    },
    {
      "q": "How is efficiency calculated?",
      "a": "Efficiency is calculated based on voltage output before and after cleaning."
    },
    {
      "q": "What if water level is low?",
      "a": "You will receive a notification when water level drops below the threshold."
    },
    {
      "q": "Can I track cleaning history?",
      "a": "Yes, you can view cleaning cycles and performance analytics in the dashboard."
    },
  ];

  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0F1C),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        title: Text(
          "FAQ",
          style: GoogleFonts.poppins(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return _faqTile(index);
        },
      ),
    );
  }

  /// 🔥 FAQ TILE
  Widget _faqTile(int index) {
    final item = faqs[index];
    final isExpanded = expandedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),

          // 🔥 Glass Effect
          color: Colors.white.withOpacity(0.05),

          border: Border.all(
            color: isExpanded
                ? Colors.cyanAccent
                : Colors.white12,
          ),

          // 🔥 Glow effect
          boxShadow: [
            if (isExpanded)
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 15,
              ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// QUESTION ROW
            Row(
              children: [
                Expanded(
                  child: Text(
                    item["q"]!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.cyanAccent,
                  ),
                )
              ],
            ),

            /// ANSWER
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  item["a"]!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}