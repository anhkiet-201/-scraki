import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/poster/presentation/stores/poster_customization_store.dart';

class EditablePosterElement extends StatelessWidget {
  final String id;
  final String defaultText;
  final Widget Function(String, double) builder;
  final PosterCustomizationStore store;

  const EditablePosterElement({
    super.key,
    required this.id,
    required this.defaultText,
    required this.builder,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final isSelected = store.selectedFieldId == id;
        final scale = store.getScale(id);
        final effectiveText = store.getText(id) ?? defaultText;

        return GestureDetector(
          onTap: () => store.selectField(id, defaultText: defaultText),
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: builder(effectiveText, scale),
          ),
        );
      },
    );
  }
}
