import 'package:analyzer/dart/element/element.dart';
import 'package:firebase_crud/firebase_crud.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

void writeCRUDMethods(List<PropertyAccessorElement> getters, String collection, String className, StringBuffer buffer) {
  buffer.writeln('''extension ${className}ToMap on $className {
        Map<String, dynamic> get asFirebaseMap {
          final jsonMap = serializers.serialize(this, specifiedType:$className) as Map<String, dynamic>;
          //${getters.where((getter) => getter.metadata.any((annotation) => annotation.element.displayName == "FirebaseRef")).toList()}
          return jsonMap;
        }
      }
    ''');
}
