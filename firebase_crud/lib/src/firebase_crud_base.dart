class FirestoreCRUD {
  final String collection;
  const FirestoreCRUD({this.collection});
}

class FirestoreRef {
  final bool isList;
  const FirestoreRef({this.isList = false});
}

class FirestoreRepository {
  const FirestoreRepository();
}
