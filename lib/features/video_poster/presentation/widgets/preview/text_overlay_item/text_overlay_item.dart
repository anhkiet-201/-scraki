
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/overlay_item/overlay_item.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/text_overlay_item/text_overlay_item_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/video_overlay_item/components/text_line_background_renderer.dart';
import 'package:scraki/overlay/overlay.dart';

class TextOverlayItem extends StatefulWidget {
  const TextOverlayItem({super.key, required this.properties});
  final TextOverlayProperties properties;

  @override
  State<TextOverlayItem> createState() => _TextOverlayItemState();
}

class _TextOverlayItemState extends State<TextOverlayItem> {
  late final TextOverlayItemStore _store;

  @override
  void initState() {
    super.initState();
    _store = TextOverlayItemStore(properties: widget.properties);
  }

  @override
  Widget build(BuildContext context) {
    return widget.properties.isEditing ? _buildTextField() : _buildTextView();
  }

  Widget _buildTextField() {
    return Observer(
      builder: (context) {
        final propeprties = _store.properties;
        return IntrinsicWidth(
          child: TextField(
            controller: _store.controller,
            focusNode: _store.focusNode,
            autofocus: true,
            // style: _getTextStyle(),
            maxLines: null,
            textAlign: propeprties.textAlign,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: propeprties.backgroundColor != null
                  ? const EdgeInsets.symmetric(horizontal: 16)
                  : EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onSubmitted: (_) {
              _store.setEditing(false);
              _store.onTextChange(_store.controller.text);
            },
          ),
        );
      }
    );
  }

  Widget _buildTextView() {
    if (_store.properties.backgroundColor != null || _store.properties.backgroundStyle != TextBackgroundStyle.rectangle) {
      // return TextWithLineBackgrounds(
      //   text: _store.label,
      //   style: _getTextStyle(),
      //   textAlign: widget.textAlign,
      //   backgroundColor: widget.backgroundColor ?? Colors.white,
      //   backgroundOpacity: widget.backgroundOpacity,
      //   backgroundRadius: widget.backgroundRadius,
      //   backgroundStyle: widget.backgroundStyle,
      //   backgroundPadding: widget.backgroundPadding,
      //   backgroundBorderColor: widget.backgroundBorderColor,
      //   backgroundBorderWidth: widget.backgroundBorderWidth,
      //   strokeColor: widget.strokeColor,
      //   strokeWidth: widget.strokeWidth,
      //   brushIntensity: widget.brushIntensity,
      //   brushThickness: widget.brushThickness,
      //   brushComplexity: widget.brushComplexity,
      //   styleParams: widget.styleParams,
      // );
      return Text(
        _store.properties.text
      );
    }

    return Text(_store.properties.text);

    // return Padding(
    //   padding: const EdgeInsets.symmetric(horizontal: 16),
    //   child: Stack(
    //     children: [
    //       if (widget.strokeColor != null && widget.strokeWidth > 0)
    //         Text(
    //           _store.label,
    //           style: _getTextStyle().copyWith(
    //             color: null,
    //             foreground: Paint()
    //               ..style = PaintingStyle.stroke
    //               ..strokeJoin = StrokeJoin.round
    //               ..strokeCap = StrokeCap.round
    //               ..strokeWidth = widget.strokeWidth
    //               ..color = widget.strokeColor!,
    //           ),
    //           softWrap: true,
    //           textAlign: widget.textAlign,
    //         ),
    //       Text(
    //         _store.label,
    //         style: _getTextStyle(),
    //         softWrap: true,
    //         textAlign: widget.textAlign,
    //       ),
    //     ],
    //   ),
    // );
  }

  // TextStyle _getTextStyle() {
  //   if (widget.fontFamily != null) {
  //     return PanelComponents.getSafeFont(
  //       widget.fontFamily!,
  //       color: widget.color,
  //       fontSize: _store.fontSize,
  //       fontWeight: widget.fontWeight,
  //       fontStyle: widget.fontStyle,
  //       height: widget.textHeight,
  //       letterSpacing: widget.letterSpacing,
  //     );
  //   }
  //   return TextStyle(
  //     color: widget.color,
  //     fontSize: _store.fontSize,
  //     fontWeight: widget.fontWeight,
  //     fontStyle: widget.fontStyle,
  //     height: widget.textHeight,
  //     letterSpacing: widget.letterSpacing,
  //   );
  // }
}