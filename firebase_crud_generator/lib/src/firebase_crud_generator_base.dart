import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:firebase_crud/firebase_crud.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class FirebaseRefInfo {
  final String field;
  final String type;
  const FirebaseRefInfo({this.field, this.type});
}

String toLowerCamelCase(String string) {
  return string[0].toLowerCase() + string.substring(1);
}

void writeCRUDMethods(List<PropertyAccessorElement> getters, String collection, String className, StringBuffer buffer) {
  final lowerCaseClassName = toLowerCamelCase(className);

  final fields = getters
      .where(
        (getter) => getter.metadata.any(
          (annotation) => annotation.element.enclosingElement.name == 'FirebaseRef',
        ),
      )
      .toList();
  final fieldReferenceExtractors = fields
      .map(
        (field) =>
            'final ${field.name}Field = ${field.type.returnType.getDisplayString()}FirestoreUtils(this.${field.name}).firestoreRef(_firestore);',
      )
      .join('\n');
  final fieldSettors = fields.map((field) => 'jsonMap["${field.name}"] = ${field.name}Field;').join('\n');
  buffer.writeln('''extension ${className}FirestoreUtils on $className {
        Map<String, dynamic> asFirestoreMap(Firestore _firestore) {
          final jsonMap = serializers.serialize(this, specifiedType:FullType($className)) as Map<String, dynamic>;
          $fieldReferenceExtractors
          $fieldSettors
          return jsonMap;
        }

        Future<void> addToFirestore(Firestore _firestore) async {
          final map = ${className}FirestoreUtils(this).asFirestoreMap(_firestore);
          _firestore.collection('$collection').document(this.id).setData(map);
        }

        Future<void> updateInFirestore(Firestore _firestore) async {
          final map = ${className}FirestoreUtils(this).asFirestoreMap(_firestore);
          return await _firestore.collection('$collection').document(this.id).setData(map);
        }

        Future<void> deleteFromFirestore(Firestore _firestore) async {
          return await _firestore.collection('$collection').document(this.id).delete();
        }

        DocumentReference firestoreRef(Firestore _firestore) {
          return _firestore.collection('$collection').document(this.id);
        }
      }
    ''');

  buffer.writeln('''extension ${className}FirestoreGetters on Firestore {
        Future<$className> get$className(String id) async {
          final documentRef = await this.collection('$collection').document(id);
          return await ${className}Reference(documentRef).${lowerCaseClassName}FromReference();
        }

        Future<List<$className>> getAll${className}s() async {
            final snapshot = await this.collection('people').getDocuments();
            return snapshot.documents.map((document) => ${className}Snapshot(document).${lowerCaseClassName}FromSnapshot()).toList();
        }
      }
    ''');

  final refs = fields
      .map(
        (getter) => FirebaseRefInfo(
          field: getter.name,
          type: getter.type.returnType.getDisplayString(),
        ),
      )
      .toList();
  final fieldAssigners = refs
      .map((ref) =>
          'jsonMap["${ref.field}"] = ${ref.type}Reference(jsonMap["${ref.field}"]).${toLowerCamelCase(ref.type)}FromReference();')
      .join('\n');
  buffer.writeln('''extension ${className}Reference on DocumentReference {
        Future<$className> ${lowerCaseClassName}FromReference() async {
          final document = await this.get();
          return ${className}Snapshot(document).${lowerCaseClassName}FromSnapshot();
        }

       
      }
    ''');

  buffer.writeln('''extension ${className}Snapshot on DocumentSnapshot {
      $className ${lowerCaseClassName}FromSnapshot() {
          final Map<String, dynamic> jsonMap = this.data;
          jsonMap['id'] = this.documentID;
          $fieldAssigners
          return serializers.deserialize(jsonMap, specifiedType: FullType($className)) as $className;
        }
      }''');
}
