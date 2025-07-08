
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_frontend/config/constant.dart';

final FlutterSecureStorage _storage = FlutterSecureStorage();

Future<void> logout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            elevation: 8,
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to log out?',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  side: BorderSide(color: linkColor, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: mainButtonColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _storage.delete(key: 'jwt_token');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
      }
    }
  }