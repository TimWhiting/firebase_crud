import 'package:analyzer/dart/element/element.dart';
import 'package:firebase_crud/firebase_crud.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

void writeCRUDMethods(List<PropertyAccessorElement> getters, String collection, String className, StringBuffer buffer) {
  final fields = getters
      .where((getter) => getter.metadata.any(
            (annotation) => annotation.element.enclosingElement.name == "FirebaseRef",
          ))
      .toList();
  final fieldReferenceExtractors = fields
      .map((field) =>
          'final ${field.name}Field = ${field.type.returnType.getDisplayString()}FirebaseReference(this.${field.name}).firebaseRef(_firebase);')
      .join('\n');
  final fieldSettors = fields.map((field) => 'jsonMap["${field.name}"] = ${field.name}Field;').join('\n');
  buffer.writeln('''extension ${className}ToMap on $className {
        Map<String, dynamic> asFirebaseMap(_firebase) {
          final jsonMap = serializers.serialize(this, specifiedType:FullType($className)) as Map<String, dynamic>;
          $fieldReferenceExtractors
          $fieldSettors
          return jsonMap;
        }
      }
    ''');
  buffer.writeln('''extension ${className}FirebaseReference on $className {
        DocumentReference firebaseRef(_firebase) {
          return _firebase.collection('$collection').document(this.id);
        }
      }
    ''');

  buffer.writeln('''extension ${className}Reference on DocumentReference {
        Future<$className> fromFirebaseReference() async {
          final document = await this.get();
          final Map<String, dynamic> jsonMap = document.data;
          jsonMap['id'] = document.documentID;
          return serializers.deserialize(jsonMap, specifiedType: FullType($className)) as $className;
        }
      }
    ''');
}
