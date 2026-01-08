import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

part 'poster_customization_store.g.dart';

@injectable
class PosterCustomizationStore = _PosterCustomizationStore
    with _$PosterCustomizationStore;

abstract class _PosterCustomizationStore with Store {
  @observable
  @observable
  String? selectedFieldId;

  @observable
  String? selectedDefaultText;

  @observable
  ObservableMap<String, double> textScales = ObservableMap<String, double>();

  @observable
  ObservableMap<String, String> textOverrides = ObservableMap<String, String>();

  @action
  void selectField(String? id, {String? defaultText}) {
    if (selectedFieldId == id) {
      selectedFieldId = null; // Toggle off if tapping same field
      selectedDefaultText = null;
    } else {
      selectedFieldId = id;
      selectedDefaultText = defaultText;
    }
  }

  @action
  void updateScale(double scale) {
    if (selectedFieldId != null) {
      textScales[selectedFieldId!] = scale;
    }
  }

  @action
  void updateText(String text) {
    if (selectedFieldId != null) {
      textOverrides[selectedFieldId!] = text;
    }
  }

  @action
  void resetText() {
    if (selectedFieldId != null) {
      textOverrides.remove(selectedFieldId);
    }
  }

  @action
  void reset() {
    selectedFieldId = null;
    selectedDefaultText = null;
    textScales.clear();
    textOverrides.clear();
  }

  double getScale(String id) => textScales[id] ?? 1.0;

  String? getText(String id) => textOverrides[id];
}
