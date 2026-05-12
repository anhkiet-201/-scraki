
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// abstract class LifecycleWidget<T> extends StatelessWidget {
//   const LifecycleWidget({super.key});

//   T onCreate(BuildContext context);
//   Widget buildChild(BuildContext context, T value);
//   void onDispose(BuildContext context, T value) {}

//   @override
//   Widget build(BuildContext context) {
//     return Provider<T>(
//       create: onCreate,
//       dispose: onDispose,
//       builder: (context, child) {
//         final value = context.read<T>();
//         return buildChild(context, value);
//       },
//     );
//   }
// }

// mixin LifecycelMixin<T> on  {
//   T onCreate(BuildContext context);
//   Widget buildChild(BuildContext context, T value);
//   void onDispose(BuildContext context, T value) {}
// }