import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:mineral_cli/src/application/commands/project_setups/preset.dart';

final class BasicPreset with CreateProjectTools implements PresetContract {
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

    await task.step('Creating main file…', callback: () => _createMainFile());

    await task.step('Creating environment file…', callback: () {
      return createEnvironmentFile(directory, _useHmr, _token, _logLevel);
    });

    await task.step('Creating gitignore file…', callback: () {
      return createGitignore(directory);
    });

    await task.step('Creating ready file…', callback: () {
      return createReadyEvent(directory);
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

  Future<void> _createMainFile() async {
    final buffer = StringBuffer()
      ..writeln('''import 'package:mineral/api.dart';''')
      ..writeln('''import 'package:mineral_cache/providers/memory.dart';''')
      ..writeln('''import 'package:$_projectName/events/ready.dart';''')
      ..writeln('''Future<void> main(${_useHmr ? '_, port' : ''}) async {''')
      ..writeln('final client = ClientBuilder()')
      ..writeln('.setCache((e) => MemoryProvider())');

    if (_useHmr) {
      buffer.writeln('.setHmrDevPort(port)');
    }
    buffer.write('.build();');

    buffer
      ..writeln()
      ..writeln('client.register(Ready.new);')
      ..writeln('await client.init();')
      ..writeln('}');

    final file = File('$_projectName/bin/main.dart');
    await file.create(recursive: true);
    await file.writeAsString(formatter.format(buffer.toString()));

    await createPubspec(Directory(_projectName), this);
  }

  Future<void> createReadyEvent(Directory directory) async {
    // final buffer = StringBuffer()
    //   ..writeln('''logger.info('\${bot.username} is ready ! 🚀');''');

    // final classBuilder = ClassBuilder()
    //     .setClassName('Ready')
    //     .setExtends(ParameterStruct(
    //         name: 'ReadyEvent', import: 'package:mineral/events.dart'))
    //     .addMixin(ParameterStruct(
    //         name: 'Logger', import: 'package:mineral/container.dart'))
    //     .addMethod(MethodStruct(
    //         name: 'handle',
    //         isOverride: true,
    //         parameters: events.Event.ready.parameters
    //             .map((parameter) => ParameterStruct(
    //                 name: parameter, import: 'package:mineral/api.dart'))
    //             .toList(),
    //         returnType: ParameterStruct(name: 'void'),
    //         body: buffer));

    // final file = File('${directory.path}/lib/events/ready.dart');
    // await file.create(recursive: true);
    // await file.writeAsString(formatter.format(classBuilder.build()));
  }
}
