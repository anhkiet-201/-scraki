import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../models/script_model.dart';

abstract class RemoteScriptDataSource {
  Stream<List<ScriptModel>> watchAllScripts();
  Future<List<ScriptModel>> getAllScripts();
  Future<void> saveScript(ScriptModel script);
  Future<void> deleteScript(String id);
}

@LazySingleton(as: RemoteScriptDataSource)
class RemoteScriptDataSourceImpl implements RemoteScriptDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'scripts';

  RemoteScriptDataSourceImpl() : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  @override
  Stream<List<ScriptModel>> watchAllScripts() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ScriptModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<List<ScriptModel>> getAllScripts() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => ScriptModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> saveScript(ScriptModel script) async {
    await _collection.doc(script.id).set(script.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteScript(String id) async {
    await _collection.doc(id).delete();
  }
}
