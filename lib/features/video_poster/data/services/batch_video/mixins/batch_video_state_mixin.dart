import 'dart:io';

mixin BatchVideoStateMixin {
  final List<Process> activeProcesses = [];
  bool cancelled = false;

  void resetState() {
    activeProcesses.clear();
    cancelled = false;
  }
}
