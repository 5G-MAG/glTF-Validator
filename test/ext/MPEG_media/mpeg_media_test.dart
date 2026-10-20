import 'package:gltf/src/base/gltf.dart';
import 'package:gltf/src/context.dart';
import 'package:gltf/src/errors.dart';
import 'package:gltf/src/ext/MPEG_media/mpeg_media.dart';
import 'package:gltf/src/utils.dart';
import 'package:test/test.dart';

void main() {
  test('media alternatives allow omitted tracks', () {
    final context = Context();
    final alternative = MPEGMediaAlternatives.fromMap(
        <String, Object>{'uri': 'media.mp4', 'mimeType': 'video/mp4'}, context);

    expect(alternative.tracks, isEmpty);
    expect(context.issues, isEmpty);
  });

  test('optional tracks still reject invalid values', () {
    for (final value in <Object>['invalid', <Object>[], <Object>[1]]) {
      final context = Context();
      MPEGMediaAlternatives.fromMap(<String, Object>{
        'uri': 'media.mp4',
        'mimeType': 'video/mp4',
        'tracks': value,
      }, context);

      expect(context.errors, isNotEmpty, reason: 'tracks: $value');
    }
  });

  test('map lists remain required by default', () {
    final context = Context();
    getMapList(<String, Object>{}, 'items', context);

    expect(context.errors, hasLength(1));
  });

  test('MPEG_media is only allowed at the glTF root', () {
    final context = Context();
    Gltf.fromMap(<String, Object>{
      'asset': <String, Object>{'version': '2.0'},
      'extensionsUsed': <Object>['MPEG_media'],
      'scenes': <Object>[
        <String, Object>{
          'nodes': <Object>[0]
        }
      ],
      'nodes': <Object>[
        <String, Object>{
          'extensions': <String, Object>{
            'MPEG_media': <String, Object>{'media': <Object>[]}
          }
        }
      ],
    }, context);

    expect(
        context.errors.map((issue) => issue.type),
        contains(LinkError.unexpectedExtensionObject));
    expect(context.errors.map((issue) => issue.type),
        isNot(contains(SchemaError.undefinedProperty)));
  });

  group('autoplayGroup is an integer', () {
    MPEGMedia parse(Object value, Context context) =>
        MPEGMedia.fromMap(<String, Object>{
          'autoplay': true,
          'autoplayGroup': value,
          'alternatives': <Object>[
            <String, Object>{'uri': 'media.mp4', 'mimeType': 'video/mp4'}
          ],
        }, context);

    test('accepts a non-negative integer', () {
      for (final value in <Object>[0, 1, 7]) {
        final context = Context();
        final media = parse(value, context);
        expect(context.issues, isEmpty, reason: 'autoplayGroup: $value');
        expect(media.autoplayGroup, value);
      }
    });

    test('rejects a boolean, a string, a fraction and a negative number', () {
      for (final value in <Object>[true, false, '1', 1.5, -1]) {
        final context = Context();
        parse(value, context);
        expect(context.errors, isNotEmpty, reason: 'autoplayGroup: $value');
      }
    });
  });

  group('timing properties', () {
    Iterable<IssueType> issues(Map<String, Object> media) {
      final context = Context();
      MPEGMedia.fromMap(<String, Object>{
        ...media,
        'alternatives': <Object>[
          <String, Object>{'uri': 'media.mp4', 'mimeType': 'video/mp4'}
        ],
      }, context);
      return context.issues.map((issue) => issue.type);
    }

    test('autoplayGroup needs autoplay', () {
      expect(issues(<String, Object>{'autoplayGroup': 1}),
          [SemanticError.mpegMediaAutoplayGroupWithoutAutoplay]);
      expect(issues(<String, Object>{'autoplay': false, 'autoplayGroup': 1}),
          [SemanticError.mpegMediaAutoplayGroupWithoutAutoplay]);
      expect(issues(<String, Object>{'autoplay': true, 'autoplayGroup': 1}),
          isEmpty);
    });

    test('startTime with autoplay is a warning', () {
      final context = Context();
      MPEGMedia.fromMap(<String, Object>{
        'autoplay': true,
        'startTime': 1.0,
        'alternatives': <Object>[
          <String, Object>{'uri': 'media.mp4', 'mimeType': 'video/mp4'}
        ],
      }, context);
      expect(context.errors, isEmpty);
      expect(context.warnings.map((issue) => issue.type),
          [SemanticError.mpegMediaStartTimeWithAutoplay]);
      expect(issues(<String, Object>{'startTime': 1.0}), isEmpty);
    });

    test('endTimeOffset not after startTimeOffset is a warning', () {
      final context = Context();
      MPEGMedia.fromMap(<String, Object>{
        'startTimeOffset': 5.0,
        'endTimeOffset': 1.0,
        'alternatives': <Object>[
          <String, Object>{'uri': 'media.mp4', 'mimeType': 'video/mp4'}
        ],
      }, context);
      expect(context.errors, isEmpty);
      expect(context.warnings.map((issue) => issue.type),
          [SemanticError.mpegMediaEmptyTimeRange]);
      expect(issues(<String, Object>{'endTimeOffset': 5.0}), isEmpty);
      expect(
          issues(<String, Object>{'startTimeOffset': 1.0, 'endTimeOffset': 2.0}),
          isEmpty);
    });
  });
}
