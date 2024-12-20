import 'dart:async';
import 'dart:io';

import 'package:mineral_cli/src/domain/commands/project_setups/preset.dart';
import 'package:commander_ui/commander_ui.dart';

final class SlimPreset with CreateProjectTools implements PresetContract {
  @override
  String get name => 'Slim';

  @override
  String get description => 'A slim preset for your project setup';

  final String _projectName;
  final bool _useHmr;
  final String _token;
  final String _logLevel;

  SlimPreset(this._projectName, this._useHmr, this._token, this._logLevel);

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
      ..writeln('''Future<void> main(${_useHmr ? '_, port' : ''}) async {''')
      ..writeln('final client = ClientBuilder()')
      ..writeln('.setCache((e) => MemoryProvider())');

    if (_useHmr) {
      buffer.writeln('.setHmrDevPort(port)');
    }

    buffer
      ..write('.build();')
      ..writeln('''client.events.ready((Bot bot) {''')
      ..writeln('''client.logger.info('\${bot.username} is ready ! 🚀');''')
      ..writeln('});');

    buffer
      ..writeln()
      ..writeln('await client.init();')
      ..writeln('}');

    final file = File('$_projectName/bin/main.dart');
    await file.create(recursive: true);
    await file.writeAsString(formatter.format(buffer.toString()));

    await createPubspec(Directory(_projectName), this);
  }
}
