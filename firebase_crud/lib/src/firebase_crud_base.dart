import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseCRUD {
  final String collection;
  const FirebaseCRUD({this.collection});
}

class FirebaseRef {
  final String collection;
  const FirebaseRef({this.collection});
}

abstract class FirestoreRepository {
  final Firestore _firestore;
  FirestoreRepository({firestore}) : _firestore = firestore;
}

// abstract class FirestoreData<T> {
//   T get firestoreData;
//   set firestoreData(T data);
// }
