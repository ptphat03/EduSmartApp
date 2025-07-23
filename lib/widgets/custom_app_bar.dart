import 'package:flutter/material.dart';

PreferredSizeWidget buildCustomAppBar(
    String title,
    IconData icon, {
      bool showBack = false,
      BuildContext? context,
    }) {
  return AppBar(
    automaticallyImplyLeading: false,
    centerTitle: true,
    elevation: 4,
    backgroundColor: Colors.blue.shade700,
    // shape: const RoundedRectangleBorder(
    //   borderRadius: BorderRadius.vertical(
    //     bottom: Radius.circular(16),
    //   ),
    // ),
    leading: showBack && context != null
        ? IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    )
        : null,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    ),
  );
}
