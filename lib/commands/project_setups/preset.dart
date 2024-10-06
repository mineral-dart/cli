import 'dart:async';
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:mineral/utils.dart';
import 'package:recase/recase.dart';

abstract interface class PresetContract {
  String get name;

  String get description;

  FutureOr handle(List<String> arguments);
}

mixin CreateProjectTools {
  final formatter = DartFormatter(pageWidth: 100);

  Future<Directory> createBlankProject(String projectName) async {
    try {
      final projectDir = Directory(projectName);
      final srcDir = Directory('${projectDir.path}/src');

      await projectDir.create();
      await srcDir.create(recursive: true);

      return Directory(projectName);
    } catch (e) {
      throw Exception('Failed to create project');
    }
  }

  Future<void> createPubspec(Directory projectRoot, PresetContract preset) async {
    final pubspecFile = File('${projectRoot.path}/pubspec.yaml');

    final Map<String, dynamic> yaml = {
      'name': projectRoot.path.split('/').last,
      'description': 'A ${preset.name.sentenceCase} mineral application.',
      'version': '0.0.1',
      'publish_to': 'none',
      'mineral': {
        'commands': {},
      },
      'environment': {'sdk': '\'>=3.3.0 <4.0.0\''},
      'dependencies': {
        'mineral': '^4.0.0-dev.4',
        'mineral_cache': '^1.0.0-dev.2',
      },
      'dev_dependencies': {
        'lints': '^2.0.0',
        'test': '^1.21.0',
      },
    };

    final buffer = StringBuffer();
    yaml.writeAsYaml(buffer: buffer, payload: yaml.entries.toList());

    await pubspecFile.create();
    await pubspecFile.writeAsString(buffer.toString());
  }

  Future<void> runCommand(
    String command,
    List<String> arguments, {
    FutureOr Function()? onSuccess,
    FutureOr Function(Object)? onError,
    Directory? rootDir,
  }) async {
    try {
      await Process.start(command, arguments,
          workingDirectory: rootDir?.path ?? Directory.current.path);
      onSuccess?.call();
    } catch (error) {
      onError?.call(error);
    }
  }
}
