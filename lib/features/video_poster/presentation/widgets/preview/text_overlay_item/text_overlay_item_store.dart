// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart' show FocusNode, TextEditingController, TextAlign;
import 'package:mobx/mobx.dart';
import 'package:scraki/overlay/overlay.dart';

part 'text_overlay_item_store.g.dart';

class TextOverlayItemStore = _TextOverlayItemStore with _$TextOverlayItemStore;

abstract class _TextOverlayItemStore with Store {
  late final TextEditingController controller;
  late final FocusNode focusNode;

  @observable
  TextOverlayProperties properties;

  _TextOverlayItemStore({required this.properties}) {
    initial();
  }

  void initial() {
    controller = TextEditingController(text: properties.text);
    focusNode = FocusNode();
    focusNode.addListener(() {
      if (!focusNode.hasFocus && properties.isEditing) {
        setEditing(false);
      }
    });
  }

  @action
  void setEditing(bool value) {
    properties.isEditing = value;
  }

  @action
  void setHovered(bool value) {
    properties.isHovered = value;
  }

  @action
  void setInteracting(bool value) {
    properties.isInteracting = value;
  }

  @action
  void onTextChange(String text) {
    properties.text = text;
  }

  @action
  void setTextAlign(TextAlign textAlign) {
    properties.textAlign = textAlign;
  }
}
