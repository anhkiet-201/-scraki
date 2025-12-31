import 'package:flutter/material.dart';

class ProtocolIcon extends StatelessWidget {
  final bool isTcp;

  const ProtocolIcon({super.key, required this.isTcp});

  @override
  Widget build(BuildContext context) {
    return Icon(
      isTcp ? Icons.wifi : Icons.usb,
      color: Theme.of(context).primaryColor,
    );
  }
}
