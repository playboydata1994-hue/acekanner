import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// New primary key: UUID v7 (time-ordered, globally unique).
String newId() => _uuid.v7();
