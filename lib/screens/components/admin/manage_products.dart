import 'package:flutter/material.dart';
import 'package:water_supply/screens/components/admin/admin_tabs/all_product_tab.dart';
import 'package:water_supply/screens/components/admin/admin_tabs/delete_product_tab.dart';
import 'package:water_supply/screens/components/admin/admin_tabs/edit_product_tab.dart';

class ManageProducts extends StatefulWidget {
  const ManageProducts({super.key});

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Manage Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.amber,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded), text: 'Edit'),
            Tab(icon: Icon(Icons.delete_outline_rounded), text: 'Delete'),
            Tab(icon: Icon(Icons.add_circle_outline_rounded), text: 'Add New'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade50],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            EditProductTab(),
            DeleteProductTab(),
            AddProductTab(),
          ],
        ),
      ),
    );
  }
}
