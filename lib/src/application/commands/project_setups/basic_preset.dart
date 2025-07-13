import 'dart:async';
import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral/events.dart' as events;
import 'package:mineral_cli/src/application/commands/project_setups/preset.dart';

final class BasicPreset with CreateProjectTools implements PresetContract {
  final _emitter = DartEmitter();
  final _formatter = DartFormatter(
      pageWidth: 150, languageVersion: DartFormatter.latestLanguageVersion);

  @override
  String get name => 'Basic';

  @override
  String get description => 'A basic preset for your project setup';

  final String _projectName;
  final bool _useHmr;
  final String _token;
  final String _logLevel;

  BasicPreset(this._projectName, this._useHmr, this._token, this._logLevel);

  @override
  FutureOr handle(List<String> arguments) async {
    final commander = Commander(level: Level.verbose);

    final task = await commander.task();

    final directory = await task.step('Creating project…', callback: () {
      return createBlankProject(_projectName);
    });

    await task.step('Creating main file…', callback: buildMain);

    await task.step('Creating environment file…', callback: () {
      return createEnvironmentFile(directory, _useHmr, _token, _logLevel);
    });

    await task.step('Creating gitignore file…', callback: () {
      return createGitignore(directory);
    });

    await task.step('Creating ready file…', callback: () {
      return buildReadyEvent(directory);
    });

    await task.step('Creating commands…', callback: () {
      final commandsDirectory = Directory('${directory.path}/lib/commands');
      return commandsDirectory.create(recursive: true);
    });

    await task.step('Creating events…', callback: () {
      final eventsDirectory = Directory('${directory.path}/lib/events');
      return eventsDirectory.create(recursive: true);
    });

    await task.step('Creating services…', callback: () {
      final modelsDirectory = Directory('${directory.path}/lib/services');
      return modelsDirectory.create(recursive: true);
    });

    await task.step('Upgrade dependencies…', callback: () {
      return runCommand('dart', ['pub', 'upgrade'], rootDir: directory);
    });

    await task.step('Fetching dependencies…', callback: () {
      return runCommand('dart', ['pub', 'get']);
    });

    task.success('Project created !');
  }

  Future<void> buildMain() async {
    final buffer = StringBuffer()
      ..writeln('''import 'package:mineral/api.dart';''')
      ..writeln('''import 'package:mineral_cache/providers/memory.dart';''')
      ..writeln('''import 'package:$_projectName/events/ready.dart';''')
      ..writeln()
      ..writeln('''Future<void> main(${_useHmr ? '_, port' : ''}) async {''')
      ..writeln('  final client = ClientBuilder()')
      ..writeln('    .setCache(MemoryProvider.new)');

    if (_useHmr) {
      buffer.writeln('    .setHmrDevPort(port)');
    }

    buffer
      ..writeln('    .build();')
      ..writeln()
      ..writeln('  client.register(Ready.new);')
      ..writeln()
      ..writeln('  await client.init();')
      ..writeln('}');
    final file = File('$_projectName/bin/main.dart');
    await file.create(recursive: true);

    await file.writeAsString(buffer.toString());
    await createPubspec(Directory(_projectName), this);
  }

  Future<void> buildReadyEvent(Directory directory) async {
    final buffer =
        StringBuffer('''logger.info('\${bot.username} is ready ! 🚀');''');

    final library = Library((library) => library
      ..body.addAll([
        Code('''import 'package:mineral/api.dart';'''),
        Code('''import 'package:mineral/events.dart';'''),
        Code('''import 'package:mineral/container.dart';'''),
        Class((clazz) => clazz
          ..name = 'Ready'
          ..modifier = ClassModifier.final$
          ..extend = refer('ReadyEvent', 'package:mineral/events.dart')
          ..mixins.add(refer('Logger', 'package:mineral/container.dart'))
          ..methods.addAll([
            Method((method) => method
              ..name = 'handle'
              ..returns = refer('Future<void>')
              ..annotations.add(refer('override'))
              ..modifier = MethodModifier.async
              ..requiredParameters.addAll([
                for (final element in events.Event.ready.parameters)
                  Parameter((parameter) => parameter
                    ..name = element.last
                    ..type = refer(element.first, 'package:mineral/api.dart'))
              ])
              ..body = Code(buffer.toString()))
          ]))
      ]));

    final file = File('${directory.path}/lib/events/ready.dart');
    await file.create(recursive: true);
    final content = _formatter.format(library.accept(_emitter).toString());

    await file.writeAsString(content);
  }
}
