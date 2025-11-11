
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkAware extends StatelessWidget {
  final Widget child;

  const NetworkAware({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final connectivityResult = snapshot.data;
        if (connectivityResult == ConnectivityResult.none) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}
