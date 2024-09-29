import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinging/data/models/sstp_data.dart';
import 'package:emoji_flag_converter/emoji_flag_converter.dart';

class SstpAddressCard extends StatelessWidget {
  final SstpDataModel sstp;
  const SstpAddressCard({Key? key, required this.sstp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Получаем код страны и удаляем лишние пробелы
    final countryCode = sstp.location?.short?.trim().toUpperCase() ?? '--';

    // Конвертируем код страны в эмодзи флаг с помощью emoji_flag_converter
    final flagEmoji = EmojiConverter.fromAlpha2CountryCode(countryCode) ?? '🏳️';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Clipboard.setData(ClipboardData(text: "${sstp.ip}:${sstp.port}"));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 500),
              backgroundColor: Colors.green.withOpacity(0.9),
              content: Text(
                "${sstp.ip}:${sstp.port} copied to clipboard",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Используем CircleAvatar для отображения эмодзи флага
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    flagEmoji,
                    style: const TextStyle(
                      fontSize: 30,
                      fontFamily: null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${sstp.ip}:${sstp.port}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sstp.info ?? ("- " * 10),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${sstp.ms ?? "---"}ms",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.network_check,
                      color: sstp.ms != null && sstp.ms! < 250
                          ? Colors.lightGreenAccent
                          : Colors.redAccent,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
