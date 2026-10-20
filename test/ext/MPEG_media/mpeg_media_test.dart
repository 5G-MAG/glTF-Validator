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
}
