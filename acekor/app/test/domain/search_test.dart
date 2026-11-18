import 'package:acekor/domain/search/student_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final search = StudentSearch(const [
    SearchableStudent(id: '1', firstName: 'Juan', lastName: 'Dela Cruz', studentNo: '2021-00123'),
    SearchableStudent(id: '2', firstName: 'Juan Miguel', lastName: 'Santos', studentNo: '2021-00456'),
    SearchableStudent(id: '3', firstName: 'Juan Carlo', lastName: 'Reyes'),
    SearchableStudent(id: '4', firstName: 'Mark Juan', lastName: 'Garcia'),
    SearchableStudent(id: '5', firstName: 'Maria', middleName: 'Clara', lastName: 'Peña'),
    SearchableStudent(id: '6', firstName: 'Ana', lastName: 'Juanillo'),
  ]);
  List<String> ids(String q) => search.search(q).map((h) => h.student.id).toList();

  test('owner example: JUAN', () {
    final r = ids('JUAN');
    expect(r.take(3).toSet(), {'1', '2', '3'});
    expect(r.indexOf('4'), greaterThan(2));
    expect(r, contains('6')); // last name starts with "Juan"
  });
  test('first, last, complete and partial names', () {
    expect(ids('dela cruz').first, '1');
    expect(ids('juan dela cruz').first, '1');
    expect(ids('Dela Cruz, Juan').first, '1');
    expect(ids('jua d'), ['1']);
    expect(ids('santos'), ['2']);
    expect(ids('igue'), ['2']); // inside "Miguel"
  });
  test('accents and middle names', () {
    expect(ids('pena'), ['5']);
    expect(ids('clara'), ['5']);
  });
  test('student number', () {
    expect(ids('00456'), ['2']);
    expect(ids('2021-00123'), ['1']);
    expect(ids('2021').toSet(), {'1', '2'});
  });
  test('no match and blank', () {
    expect(ids('zzz'), isEmpty);
    expect(ids('  '), isEmpty);
  });
}
