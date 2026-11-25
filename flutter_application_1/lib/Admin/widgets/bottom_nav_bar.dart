import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
class MyBottomNavBar extends StatelessWidget {
  void Function(int)? onTabChange;
  MyBottomNavBar({super.key,required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GNav(
        color: Colors.grey,
        activeColor: Colors.grey.shade700,
        mainAxisAlignment: MainAxisAlignment.center,
        onTabChange: (value)=> onTabChange!(value),
        tabs: [
          GButton(
            icon: Icons.home,
            text: "Dashboard",
            ),
            GButton(
            icon: Icons.shopping_bag_rounded,
            text: "User",
            )
        ]
        ),
    );
  }
}