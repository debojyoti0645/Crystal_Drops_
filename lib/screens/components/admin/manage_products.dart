import 'package:flutter/material.dart';
import 'package:water_supply/screens/components/admin/admin_tabs/add_product_tab.dart';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.blue.shade800,
          title: const Text(
            'Manage Products',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.orange.shade400,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.edit_note_rounded,
                      color: Colors.orange.shade300,
                    ),
                    text: 'Edit',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade300,
                    ),
                    text: 'Delete',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: Colors.green.shade300,
                    ),
                    text: 'Add New',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
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
