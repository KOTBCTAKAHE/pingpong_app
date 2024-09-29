import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pinging/data/models/sstp_data.dart';

class SstpAddressCard extends StatelessWidget {
  final SstpDataModel sstp;
  const SstpAddressCard({Key? key, required this.sstp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Убираем лишние пробелы и приводим код страны к нижнему регистру
    final countryCode = sstp.location?.short?.trim().toLowerCase() ?? 'unknown';

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
                // Обернули флаг в ClipOval, чтобы сделать его круглым
                ClipOval(
                  child: Container(
                    color: Colors.white, // Белый фон для флага
                    child: SvgPicture.asset(
                      'packages/country_icons/icons/flags/svg/$countryCode.svg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain, // Обеспечиваем правильное соотношение сторон
                      placeholderBuilder: (context) => const Icon(
                        Icons.flag,
                        color: Colors.grey,
                        size: 30,
                      ),
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
                      color: sstp.ms != null && sstp.ms! < 100
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
