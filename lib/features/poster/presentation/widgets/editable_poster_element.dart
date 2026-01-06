import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/poster/presentation/store/poster_customization_store.dart';

class EditablePosterElement extends StatelessWidget {
  final String id;
  final Widget Function(double) builder;
  final PosterCustomizationStore store;

  const EditablePosterElement({
    super.key,
    required this.id,
    required this.builder,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final isSelected = store.selectedFieldId == id;
        final scale = store.getScale(id);

        return GestureDetector(
          onTap: () => store.selectField(id),
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
            child: builder(scale),
          ),
        );
      },
    );
  }
}
