import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:firebase_crud/firebase_crud.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class FirebaseRefInfo {
  final String field;
  final String type;
  final bool isList;
  const FirebaseRefInfo({this.field, this.type, this.isList});
}

final refName = 'FirestoreRef';

String toLowerCamelCase(String string) {
  return string[0].toLowerCase() + string.substring(1);
}

FirebaseRefInfo getRefInfo(PropertyAccessorElement field) {
  final isList = field.metadata
      .firstWhere(
        (annotation) => annotation.element.enclosingElement.name == refName,
      )
      .computeConstantValue()
      .getField('isList')
      .toBoolValue();
  final rawType = field.type.returnType.getDisplayString();
  final type = isList
      ? rawType.substring(rawType.indexOf('<') + 1, rawType.indexOf('>'))
      : field.type.returnType.getDisplayString();
  return FirebaseRefInfo(field: field.name, type: type, isList: isList);
}

void writeCRUDMethods(List<PropertyAccessorElement> getters, String collection, String className, StringBuffer buffer) {
  final lowerCaseClassName = toLowerCamelCase(className);

  final refs = getters
      .where(
        (getter) => getter.metadata.any(
          (annotation) => annotation.element.enclosingElement.name == refName,
        ),
      )
      .map(getRefInfo)
      .toList();

  final fieldReferenceExtractors = refs
      .map(
        (ref) => ref.isList
            ? 'final ${ref.field}Field = this.${ref.field}.map((${ref.type} item) => ${ref.type}FirestoreUtils(item).firestoreRef(_firestore)).toList();'
            : 'final ${ref.field}Field = ${ref.type}FirestoreUtils(this.${ref.field}).firestoreRef(_firestore);',
      )
      .join('\n');
  final fieldSettors = refs.map((ref) => 'jsonMap["${ref.field}"] = ${ref.field}Field;').join('\n');
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
            return await Future.wait(snapshot.documents.map((document) => ${className}Snapshot(document).${lowerCaseClassName}FromSnapshot()).toList());
        }
      }
    ''');

  buffer.writeln('''extension ${className}Reference on DocumentReference {
        Future<$className> ${lowerCaseClassName}FromReference() async {
          final document = await this.get();
          return await ${className}Snapshot(document).${lowerCaseClassName}FromSnapshot();
        }
      }
    ''');

  final fieldAssigners = refs
      .map((ref) => ref.isList
          ? 'jsonMap["${ref.field}"] = await Future.wait((jsonMap["${ref.field}"] as List<DocumentReference>).map((DocumentReference item) => ${ref.type}Reference(item).${toLowerCamelCase(ref.type)}FromReference()).toList());'
          : 'jsonMap["${ref.field}"] = await ${ref.type}Reference(jsonMap["${ref.field}"] as DocumentReference).${toLowerCamelCase(ref.type)}FromReference();')
      .join('\n');
  buffer.writeln('''extension ${className}Snapshot on DocumentSnapshot {
      Future<$className> ${lowerCaseClassName}FromSnapshot() async {
          final Map<String, dynamic> jsonMap = this.data;
          jsonMap['id'] = this.documentID;
          $fieldAssigners
          return serializers.deserialize(jsonMap, specifiedType: FullType($className)) as $className;
        }
      }''');
}

void writeRepositoryMethods(String className, StringBuffer buffer) {
  buffer.writeln('''extension ${className}Extensions on $className {
    
    }''');
}
