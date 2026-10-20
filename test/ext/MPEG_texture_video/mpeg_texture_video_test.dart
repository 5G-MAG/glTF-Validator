import 'package:gltf/gltf.dart';
import 'package:gltf/src/ext/MPEG_texture_video/mpeg_texture_video.dart'
    as video;
import 'package:gltf/src/errors.dart';
import 'package:test/test.dart';

import '../mpeg_test_utils.dart';

void main() {
  test('video extension is registered and exported through the public API', () {
    final context = Context();
    final gltf = Gltf.fromMap(mpegTestAsset(), context);
    final extension =
        gltf.textures[0].extensions['MPEG_texture_video'] as MPEGTextureVideo;
    expect(extension.accessor, same(gltf.accessors[0]));
    expect(extension.videoTextureWidth, 2);
    expect(extension.videoTextureHeight, 2);
    expect(extension.textureFormat, 'RED');
    expect(gltf.accessors[0].isUsed, isTrue);
    expect(context.errors, isEmpty);
    expect(context.extensionsLoaded, contains('MPEG_texture_video'));
  });

  test('video format defaults to RGB', () {
    final context = Context();
    final extension = MPEGTextureVideo.fromMap(<String, Object>{
      'accessor': 0,
      'width': 2,
      'height': 2,
    }, context);
    expect(extension.textureFormat, 'RGB');
    expect(context.issues, isEmpty);
  });

  for (final format in video.MPEG_TEXTURE_VIDEO_FORMATS) {
    test('accepts video format $format', () {
      final context = Context();
      MPEGTextureVideo.fromMap(<String, Object>{
        'accessor': 0,
        'width': 2,
        'height': 2,
        'format': format,
      }, context);
      expect(context.issues, isEmpty);
    });
  }

  for (final name in ['width', 'height', 'accessor']) {
    test('requires $name', () {
      final asset = mpegTestAsset();
      videoProperties(asset).remove(name);
      final context = Context();
      Gltf.fromMap(asset, context);
      expect(context.errors, isNotEmpty);
    });
  }

  for (final value in <Object>[0, -1, 1.5, '2', null]) {
    test('rejects invalid dimensions $value (${value.runtimeType})', () {
      final context = Context();
      MPEGTextureVideo.fromMap(<String, Object>{
        'accessor': 0,
        'width': value,
        'height': value,
      }, context);
      expect(context.errors, isNotEmpty);
    });
  }

  test('unknown video formats produce a report issue', () {
    final context = Context();
    MPEGTextureVideo.fromMap(<String, Object>{
      'accessor': 0,
      'width': 2,
      'height': 2,
      'format': 'INVALID',
    }, context);
    expect(context.issues, isNotEmpty);
  });

  test('invalid accessor reference reports its JSON path', () {
    final asset = mpegTestAsset();
    videoProperties(asset)['accessor'] = 999;
    final context = Context();
    Gltf.fromMap(asset, context);
    expect(context.errors.map((i) => i.toMap()['pointer']),
        contains('/textures/0/extensions/MPEG_texture_video/accessor'));
  });

  test('the accessor must have MPEG_accessor_timed', () {
    final asset = mpegTestAsset();
    accessorExtensions(asset, 0).remove('MPEG_accessor_timed');
    final context = Context();
    Gltf.fromMap(asset, context);
    final issues = context.errors
        .where((i) => i.type == LinkError.mpegTextureVideoAccessorNotTimed);
    expect(issues, hasLength(1));
    expect(issues.first.pointer,
        '/textures/0/extensions/MPEG_texture_video/accessor');
  });

  const components = <String, int>{
    'RED': 1,
    'GREEN': 1,
    'BLUE': 1,
    'DEPTH_COMPONENT': 1,
    'RG': 2,
    'RGB': 3,
    'BGR': 3,
    'RGBA': 4,
    'BGRA': 4,
  };
  const types = <int, String>{1: 'SCALAR', 2: 'VEC2', 3: 'VEC3', 4: 'VEC4'};

  for (final format in components.keys) {
    for (final n in types.keys) {
      test('format $format with accessor type ${types[n]}', () {
        final asset = mpegTestAsset();
        videoProperties(asset)['format'] = format;
        (asset['accessors'] as List)[0]['type'] = types[n];
        final context = Context();
        Gltf.fromMap(asset, context);
        final issues = context.errors.where(
            (i) => i.type == LinkError.mpegTextureVideoFormatAccessorType);
        if (components[format] == n) {
          expect(issues, isEmpty);
        } else {
          expect(issues, hasLength(1));
          expect(issues.first.pointer,
              '/textures/0/extensions/MPEG_texture_video/format');
        }
      });
    }
  }
}
