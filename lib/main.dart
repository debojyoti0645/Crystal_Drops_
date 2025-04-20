import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:water_supply/screens/components/Customer/cust_mng_connection.dart';
import 'package:water_supply/screens/components/Customer/cust_payment_history_screen.dart';
import 'package:water_supply/screens/components/Customer/order_history.dart';
import 'package:water_supply/screens/components/Customer/subscription/subscription_page.dart';
import 'package:water_supply/screens/components/Delivery/assigned_orders.dart';
import 'package:water_supply/screens/components/Delivery/delivery_history.dart';
import 'package:water_supply/screens/components/Distributer/dist_payment_history.dart';
import 'package:water_supply/screens/components/Distributer/dist_order_summary.dart';
import 'package:water_supply/screens/components/admin/all_transaction_screen.dart';
import 'package:water_supply/screens/components/admin/delivery_screen.dart';
import 'package:water_supply/screens/components/admin/manage_orders.dart';
import 'package:water_supply/screens/components/admin/manage_products.dart';
import 'package:water_supply/screens/components/admin/manage_users.dart';
import 'package:water_supply/screens/components/Customer/cart/cart_screen.dart';
import 'package:water_supply/screens/components/admin/manage_zones.dart';
import 'package:water_supply/screens/profile_screen.dart';
import 'package:water_supply/service/api_service.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/components/Customer/cart/cart.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Water Supply App',
        theme: AppTheme.lightTheme,
        home: SplashScreen(),
        routes: {
          '/cart': (context) => CartScreen(),
          '/manage-users': (context) => ManageUsers(),
          '/manage-products': (context) => ManageProducts(),
          '/manage-orders': (context) => ManageOrders(),
          '/manage-zones': (context) => ManageZonesScreen(),
          '/subscription': (context) => SubscribePage(),
          '/orders': (context) => CustOrderSummary(),
          '/dist_orders': (context) => OrderSummary(),
          '/dist_payment': (context) => PaymentHistory(),
          '/cust_payment': (context) => CustomerPaymentHistory(),
          '/transactions': (context) => AllTransactionScreen(),
          '/delivery': (context) => DeliveryTrackingScreen(),
          '/del_orders': (context) => AssignedOrders(),
          '/del_history': (context) => DeliveryHistory(),
          '/profile': (context) => ProfileScreen(),
          '/connection': (context) => CustMngConnection(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => SplashScreen());
        },
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              platformBrightness: Theme.of(context).brightness,
              textScaler: TextScaler.linear(1.0),
            ),
            child: RepaintBoundary(child: child ?? Container()),
          );
        },
      ),
    );
  }
}
