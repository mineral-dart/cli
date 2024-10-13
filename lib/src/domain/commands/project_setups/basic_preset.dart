import 'dart:async';
import 'dart:io';

import 'package:mineral_cli/src/infrastructure/builder/class/class_builder.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/method_struct.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/parameter_struct.dart';
import 'package:mineral_cli/src/domain/commands/project_setups/preset.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:mineral/events.dart';

final class BasicPreset with CreateProjectTools, Tools implements PresetContract {
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
    hideInput();

    final delayed = Delayed();

    delayed.step('Creating project…');
    final directory = await createBlankProject(_projectName);

    delayed.step('Creating mineral_cli.dart…');
    await _createMainFile();

    delayed.step('Creating environment file…');
    await createEnvironmentFile(directory, _useHmr, _token, _logLevel);

    delayed.step('Creating gitignore file…');
    createGitignore(directory);

    delayed.step('Creating ready event…');
    await createReadyEvent(directory);

    delayed.step('Creating commands…');
    final commandsDirectory = Directory('${directory.path}/src/commands');
    await commandsDirectory.create(recursive: true);

    delayed.step('Creating services…');
    final servicesDirectory = Directory('${directory.path}/src/services');
    await servicesDirectory.create(recursive: true);

    delayed.step('Upgrade dependencies…');
    await runCommand('dart', ['pub', 'upgrade'], rootDir: directory);

    await Future.delayed(const Duration(milliseconds: 500));

    delayed.step('Fetching dependencies…');
    await runCommand('dart', ['pub', 'get']);

    delayed.success('Project created !');

    showInput();

    await Future.delayed(const Duration(milliseconds: 1000), () => exit(0));
  }

  Future<void> _createMainFile() async {
    final buffer = StringBuffer()
      ..writeln('''import 'package:mineral/api.dart';''')
      ..writeln('''import 'package:mineral_cache/providers/memory.dart';''')
      ..writeln('''import 'events/ready.dart';''')
      ..writeln('''Future<void> main(${_useHmr ? '_, port' : ''}) async {''')
      ..writeln('final client = Client()')
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

    final file = File('$_projectName/src/mineral_cli.dart');
    await file.create(recursive: true);
    await file.writeAsString(formatter.format(buffer.toString()));

    await createPubspec(Directory(_projectName), this);
  }

  Future<void> createReadyEvent(Directory directory) async {
    final buffer = StringBuffer()..writeln('''logger.info('\${bot.username} is ready ! 🚀');''');

    final classBuilder = ClassBuilder()
        .setClassName('Ready')
        .setExtends(ParameterStruct(name: 'ReadyEvent', import: 'package:mineral/events.dart'))
        .addMixin(ParameterStruct(name: 'InjectLogger', import: 'package:mineral/container.dart'))
        .addMethod(MethodStruct(
            name: 'handle',
            isOverride: true,
            parameters: Event.ready.parameters
                .map((parameter) =>
                    ParameterStruct(name: parameter, import: 'package:mineral/api.dart'))
                .toList(),
            returnType: ParameterStruct(name: 'void'),
            body: buffer));

    final file = File('${directory.path}/src/events/ready.dart');
    await file.create(recursive: true);
    await file.writeAsString(formatter.format(classBuilder.build()));
  }
}
