import 'package:flutter/material.dart';

class AdminAppDrawer extends StatelessWidget {
  const AdminAppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade500],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              'Dashboard',
              Icons.home,
              () => Navigator.of(context).pushReplacementNamed('/admin-home'),
            ),
            _buildDrawerItem(context, 'Profile', Icons.person, () {
              Navigator.of(context).pushNamed('/profile');
            }),
            _buildDrawerItem(
              context,
              'Manage Users',
              Icons.people,
              () => Navigator.of(context).pushNamed('/manage-users'),
            ),
            _buildDrawerItem(
              context,
              'Manage Products',
              Icons.inventory,
              () => Navigator.of(context).pushNamed('/manage-products'),
            ),
            _buildDrawerItem(
              context,
              'Manage Orders',
              Icons.shopping_cart,
              () => Navigator.of(context).pushNamed('/manage-orders'),
            ),
            _buildDrawerItem(
              context,
              'Manage Zones',
              Icons.location_city,
              () => Navigator.of(context).pushNamed('/manage-zones'),
            ),
            _buildDrawerItem(context, 'Delivery', Icons.local_shipping, () {}),
            _buildDrawerItem(context, 'Transactions', Icons.money, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          onTap: onTap,
        ),
        const Divider(color: Colors.white24, height: 1),
      ],
    );
  }
}
