import 'package:flutter/material.dart';
import 'package:indie_demo/screens/connection_detail_screen.dart';
import 'package:indie_demo/screens/mrz_scanner.dart';

class Routes{
  Routes._();

  static const connectionDetail = '/connectionDetail';
  static const mrzScanner = '/mrzScanner';
  static const connections = '/connections';

  static MaterialPageRoute onGenerateRoute(RouteSettings settings){
    if (settings == null) return null;
    if (settings.name == '/') return null;

    Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      connectionDetail: (context) => ConnectionDetailScreen(argument: settings.arguments),
      mrzScanner : (context) => MRZScannerScreen(argument: settings.arguments)
    };

    WidgetBuilder builder = routes[settings.name];
    return MaterialPageRoute(builder: (ctx) => builder(ctx));
  }
}