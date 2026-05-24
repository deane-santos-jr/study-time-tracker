import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/repositories/subject_repository_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';

class _MockSubjectRepository extends Mock implements ISubjectRepository {}

Subject subjectFor({
  required String id,
  required String semesterId,
  String name = 's',
  String color = '#A23B5C',
}) {
  return Subject(
    id: id,
    semesterId: semesterId,
    name: name,
    color: color,
    icon: null,
    isActive: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  late _MockSubjectRepository repo;

  setUp(() {
    repo = _MockSubjectRepository();
  });

  blocTest<SubjectsCubit, SubjectsState>(
    'loadForSemester(null) emits Loaded with empty list',
    build: () => SubjectsCubit(subjectRepository: repo),
    act: (c) => c.loadForSemester(null),
    expect: () => [
      isA<SubjectsLoading>(),
      isA<SubjectsLoaded>()
          .having((s) => s.subjects.length, 'subjects', 0)
          .having((s) => s.semesterId, 'semesterId', null),
    ],
  );

  blocTest<SubjectsCubit, SubjectsState>(
    'loadForSemester(id) filters to that semester',
    build: () {
      when(() => repo.getAll()).thenAnswer(
        (_) async => APIListResponse<Subject>(
          success: true,
          message: 'ok',
          statusCode: 200,
          data: [
            subjectFor(id: '1', semesterId: 'sem-a'),
            subjectFor(id: '2', semesterId: 'sem-b'),
            subjectFor(id: '3', semesterId: 'sem-a'),
          ],
        ),
      );
      return SubjectsCubit(subjectRepository: repo);
    },
    act: (c) => c.loadForSemester('sem-a'),
    expect: () => [
      isA<SubjectsLoading>(),
      isA<SubjectsLoaded>()
          .having((s) => s.subjects.length, 'count', 2)
          .having(
            (s) => s.subjects.map((x) => x.id).toList(),
            'ids',
            ['1', '3'],
          )
          .having((s) => s.semesterId, 'semesterId', 'sem-a'),
    ],
  );
}
