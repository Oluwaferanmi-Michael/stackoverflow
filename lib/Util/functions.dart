import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> launchUrl(BuildContext context, String uri) async {
  if(await canLaunchUrlString(uri)){
    await launchUrl(context, uri);
  } else {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Navigation Error'),
          content: const Text('could not launch url'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
          ],
        );
      });
  }
}