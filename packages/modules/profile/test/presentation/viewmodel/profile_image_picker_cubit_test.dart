import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/src/presentation/viewmodel/profile_image_picker_cubit.dart';

void main() {
  late MockSafeImageDetectorFactory safeImageDetectorFactory;
  late MockSafeImageDetector safeImageDetector;
  late MockCrashlyticsService crashlyticsService;

  ProfileImagePickerCubit buildCubit() {
    return ProfileImagePickerCubit(
      safeImageDetectorFactory: safeImageDetectorFactory,
      crashlyticsService: crashlyticsService,
    );
  }

  setUpAll(() => registerFallbackValue(img.Image(width: 1, height: 1)));

  setUp(() {
    safeImageDetectorFactory = MockSafeImageDetectorFactory();
    safeImageDetector = MockSafeImageDetector();
    crashlyticsService = MockCrashlyticsService();

    when(() => safeImageDetectorFactory.create()).thenAnswer((_) async => safeImageDetector);
    when(
      () => crashlyticsService.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    ).thenReturn(null);
  });

  group('ProfileImagePickerCubit.initialize', () {
    blocTest<ProfileImagePickerCubit, ProfileImagePickerState>(
      'emits loading then ready when the detector is created',
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      expect: () => [const ProfileImagePickerState.loading(), const ProfileImagePickerState.ready()],
    );

    blocTest<ProfileImagePickerCubit, ProfileImagePickerState>(
      'emits loading then error and records it when creation fails',
      build: buildCubit,
      setUp: () => when(() => safeImageDetectorFactory.create()).thenThrow(Exception('model missing')),
      act: (cubit) => cubit.initialize(),
      expect: () => [const ProfileImagePickerState.loading(), const ProfileImagePickerState.error()],
      verify: (_) {
        verify(
          () => crashlyticsService.recordError(
            exception: any(named: 'exception'),
            stackTrace: any(named: 'stackTrace'),
            reason: 'Failed to initialize safe image detector',
          ),
        ).called(1);
      },
    );

    test('disposes the detector when closed before it was created', () async {
      final completer = Completer<SafeImageDetector>();
      when(() => safeImageDetectorFactory.create()).thenAnswer((_) => completer.future);
      final cubit = buildCubit();

      final initializing = cubit.initialize();
      await cubit.close();
      completer.complete(safeImageDetector);
      await initializing;

      verify(() => safeImageDetector.dispose()).called(1);
    });
  });

  group('ProfileImagePickerCubit.selectImage', () {
    blocTest<ProfileImagePickerCubit, ProfileImagePickerState>(
      'emits picking, selected and ready for a safe image',
      build: buildCubit,
      setUp: () =>
          when(() => safeImageDetector.detectImageSafety(any()))
              .thenAnswer((_) async => ImageSafetyDetectionResult(true, 0.1)),
      act: (cubit) async {
        await cubit.initialize();
        await cubit.selectImage(() => _createTempXFile(_validImageBytes, 'cubit_valid.png'));
      },
      skip: 2,
      expect: () => [
        const ProfileImagePickerState.ready(isPicking: true),
        isA<ProfileImagePickerSelectedState>().having((s) => s.imageData, 'imageData', isNotEmpty),
        const ProfileImagePickerState.ready(),
      ],
    );

    blocTest<ProfileImagePickerCubit, ProfileImagePickerState>(
      'emits picking, failed and ready for an unsafe image',
      build: buildCubit,
      setUp: () =>
          when(() => safeImageDetector.detectImageSafety(any()))
              .thenAnswer((_) async => ImageSafetyDetectionResult(false, 0.9)),
      act: (cubit) async {
        await cubit.initialize();
        await cubit.selectImage(() => _createTempXFile(_validImageBytes, 'cubit_unsafe.png'));
      },
      skip: 2,
      expect: () => [
        const ProfileImagePickerState.ready(isPicking: true),
        const ProfileImagePickerState.failed(ProfileImagePickerError.notSafeImage),
        const ProfileImagePickerState.ready(),
      ],
    );

    blocTest<ProfileImagePickerCubit, ProfileImagePickerState>(
      'returns to ready when the pick is cancelled',
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        await cubit.selectImage(() async => null);
      },
      skip: 2,
      expect: () => [const ProfileImagePickerState.ready(isPicking: true), const ProfileImagePickerState.ready()],
      verify: (_) => verifyNever(() => safeImageDetector.detectImageSafety(any())),
    );

    blocTest<ProfileImagePickerCubit, ProfileImagePickerState>(
      'ignores selection before the detector is ready',
      build: buildCubit,
      act: (cubit) => cubit.selectImage(() async => null),
      expect: () => <ProfileImagePickerState>[],
    );
  });

  test('close disposes the detector', () async {
    final cubit = buildCubit();
    await cubit.initialize();
    await cubit.close();

    verify(() => safeImageDetector.dispose()).called(1);
  });
}

Future<XFile> _createTempXFile(Uint8List bytes, String fileName) async {
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path);
}

final Uint8List _validImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABGdBTUEAALGPC/xhBQAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAAaADAAQAAAABAAAAAQAAAADa6r/EAAAAC0lEQVQIHWNgAAIAAAUAAY27m/MAAAAASUVORK5CYII=',
);
