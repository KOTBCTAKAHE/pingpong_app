import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinging/data/models/sstp_data.dart';

class SstpAddressCard extends StatelessWidget {
  final SstpDataModel sstp;
  const SstpAddressCard({Key? key, required this.sstp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(20),
        shadowColor: Colors.black.withOpacity(0.1),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Colors.green,
              width: 1.5,
            ),
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                sstp.location?.short ?? "--",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "${sstp.ip}:${sstp.port}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sstp.info ?? ("- " * 10),
                    style: const TextStyle(fontSize: 11.0),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          trailing: Text(
            "${sstp.ms ?? "---"}ms",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: "${sstp.ip}:${sstp.port}"));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 300),
                content: Text(
                  "${sstp.ip}:${sstp.port} скопировано в буфер обмена",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
