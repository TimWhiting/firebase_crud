class FirestoreCRUD {
  final String collection;
  const FirestoreCRUD({this.collection});
}

class FirestoreRef {
  final bool isList;
  final bool isMap;
  final bool mapKeysRef;
  final bool mapValuesRef;

  const FirestoreRef({this.isList = false, this.isMap = false, this.mapValuesRef, this.mapKeysRef});
}

class FirestoreRepository {
  const FirestoreRepository();
}
