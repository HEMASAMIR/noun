import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusWrapper extends StatefulWidget {
  final Widget child;

  const NetworkStatusWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<NetworkStatusWrapper> createState() => _NetworkStatusWrapperState();
}

class _NetworkStatusWrapperState extends State<NetworkStatusWrapper> {
  bool _hasInternet = true;
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          widget.child,
          StreamBuilder<List<ConnectivityResult>>(
            stream: _connectivityStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final results = snapshot.data!;
                // ConnectivityResult.none means no connection
                final isOffline = results.isEmpty || results.every((res) => res == ConnectivityResult.none);
                
                // Avoid flashing if it starts
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _hasInternet == isOffline) {
                    setState(() {
                      _hasInternet = !isOffline;
                    });
                  }
                });
              }

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                top: _hasInternet ? -100 : 50,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.shade700,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_off, color: Colors.white, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'لا يوجد اتصال بالإنترنت',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
