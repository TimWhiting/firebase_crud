// Copyright (c) 2018, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'package:source_gen/source_gen.dart';
import 'firebase_crud_generator.dart';

Builder firebaseCrudBuilder(BuilderOptions _) => SharedPartBuilder([FirestoreCRUDGenerator()], 'firestore_crud');
Builder firebaseRepositoryBuilder(BuilderOptions _) =>
    SharedPartBuilder([FirestoreRepositoryGenerator()], 'firestore_repository');
