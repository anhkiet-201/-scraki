import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../models/script_model.dart';
import '../../domain/entities/script_entity.dart';

abstract class LocalScriptDataSource {
  Future<List<ScriptEntity>> getAllScripts();
  Future<void> saveScript(ScriptEntity script);
  Future<void> deleteScript(String id);
}

@Named('local_script')
@LazySingleton(as: LocalScriptDataSource)
class LocalScriptDataSourceImpl implements LocalScriptDataSource {
  static const String _boxName = 'scripts_box';

  Future<Box<ScriptModel>> get _box async => await Hive.openBox<ScriptModel>(_boxName);

  @override
  Future<List<ScriptEntity>> getAllScripts() async {
    final box = await _box;
    return box.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveScript(ScriptEntity script) async {
    final box = await _box;
    await box.put(script.id, ScriptModel.fromEntity(script));
  }

  @override
  Future<void> deleteScript(String id) async {
    final box = await _box;
    await box.delete(id);
  }
}
