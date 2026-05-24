import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/repositories/semester_repository_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';

class _MockSemesterRepository extends Mock implements ISemesterRepository {}

class _FakeCreatePayload extends Fake implements SemesterCreatePayload {}

class _FakeUpdatePayload extends Fake implements SemesterUpdatePayload {}

Semester semesterFor({
  required String id,
  required String name,
  bool isActive = false,
}) {
  return Semester(
    id: id,
    name: name,
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 12, 15),
    isActive: isActive,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCreatePayload());
    registerFallbackValue(_FakeUpdatePayload());
  });

  late _MockSemesterRepository repo;

  setUp(() {
    repo = _MockSemesterRepository();
  });

  group('load', () {
    blocTest<SemestersCubit, SemestersState>(
      'emits Loading then Loaded with active id picked from is_active',
      build: () {
        when(() => repo.getAll()).thenAnswer(
          (_) async => APIListResponse<Semester>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: [
              semesterFor(id: 'a', name: 'a'),
              semesterFor(id: 'b', name: 'b', isActive: true),
            ],
          ),
        );
        return SemestersCubit(semesterRepository: repo);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<SemestersLoading>(),
        isA<SemestersLoaded>()
            .having((s) => s.semesters.length, 'count', 2)
            .having((s) => s.activeSemesterId, 'activeId', 'b'),
      ],
    );

    blocTest<SemestersCubit, SemestersState>(
      'emits Loaded with null active id when no semester isActive',
      build: () {
        when(() => repo.getAll()).thenAnswer(
          (_) async => APIListResponse<Semester>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: [semesterFor(id: 'a', name: 'a')],
          ),
        );
        return SemestersCubit(semesterRepository: repo);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<SemestersLoading>(),
        isA<SemestersLoaded>().having((s) => s.activeSemesterId, 'active', null),
      ],
    );
  });

  group('delete', () {
    blocTest<SemestersCubit, SemestersState>(
      'refuses to delete the active semester',
      build: () {
        when(() => repo.getAll()).thenAnswer(
          (_) async => APIListResponse<Semester>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: [semesterFor(id: 'a', name: 'a', isActive: true)],
          ),
        );
        return SemestersCubit(semesterRepository: repo);
      },
      act: (c) async {
        await c.load();
        await c.delete(id: 'a');
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<SemestersLoaded>());
        expect((state as SemestersLoaded).mutationError, isNotNull);
        verifyNever(() => repo.delete(id: any(named: 'id')));
      },
    );

    blocTest<SemestersCubit, SemestersState>(
      'removes a non-active semester on successful delete',
      build: () {
        when(() => repo.getAll()).thenAnswer(
          (_) async => APIListResponse<Semester>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: [
              semesterFor(id: 'a', name: 'a', isActive: true),
              semesterFor(id: 'b', name: 'b'),
            ],
          ),
        );
        when(() => repo.delete(id: 'b')).thenAnswer(
          (_) async => APIResponse<Map<String, dynamic>>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: const {'orphanedSubjectCount': 0, 'orphanedSessionCount': 0},
          ),
        );
        return SemestersCubit(semesterRepository: repo);
      },
      act: (c) async {
        await c.load();
        await c.delete(id: 'b');
      },
      verify: (cubit) {
        final state = cubit.state as SemestersLoaded;
        expect(state.semesters.length, 1);
        expect(state.semesters.first.id, 'a');
      },
    );
  });
}
