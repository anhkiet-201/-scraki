import 'package:mobx/mobx.dart';

part 'poster_customization_store.g.dart';

class PosterCustomizationStore = _PosterCustomizationStore
    with _$PosterCustomizationStore;

abstract class _PosterCustomizationStore with Store {
  @observable
  String? selectedFieldId;

  @observable
  ObservableMap<String, double> textScales = ObservableMap<String, double>();

  @action
  void selectField(String? id) {
    if (selectedFieldId == id) {
      selectedFieldId = null; // Toggle off if tapping same field
    } else {
      selectedFieldId = id;
    }
  }

  @action
  void updateScale(double scale) {
    if (selectedFieldId != null) {
      textScales[selectedFieldId!] = scale;
    }
  }

  double getScale(String id) => textScales[id] ?? 1.0;
}
