import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransceiverChatBubble extends StatelessWidget {
  final String text;
  final String translatedText; // For the Babel Fish effect
  final bool isSentByMe;
  final String time;

  const TransceiverChatBubble({
    super.key,
    required this.text,
    required this.translatedText,
    required this.isSentByMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isSentByMe ? const Color(0xFFD946EF).withOpacity(0.1) : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isSentByMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !isSentByMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          border: Border.all(
            color: isSentByMe ? const Color(0xFFD946EF).withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original Language
            Text(
              text,
              style: GoogleFonts.inter(
                color: isSentByMe ? Colors.white : Colors.grey[300],
                fontSize: 14,
              ),
            ),
            // The "Babel Fish" Translation Layer
            if (translatedText.isNotEmpty && translatedText != text) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Divider(color: Colors.grey, height: 1),
              ),
              Text(
                translatedText,
                style: GoogleFonts.inter(
                  color: const Color(0xFFD2691E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 6),
            // Timestamp and Status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSentByMe ? Icons.check_circle : Icons.volume_up, 
                  size: 12, 
                  color: Colors.grey[500]
                ),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}