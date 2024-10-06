import 'dart:async';
import 'dart:io';

import 'package:cli/commands/project_setups/preset.dart';
import 'package:commander_ui/commander_ui.dart';

final class SlimPreset with CreateProjectTools, Tools implements PresetContract {
  @override
  String get name => 'Slim';

  @override
  String get description => 'A slim preset for your project setup';

  final String _projectName;
  final bool _useHmr;

  SlimPreset(this._projectName, this._useHmr);

  @override
  FutureOr handle(List<String> arguments) async {
    hideInput();

    final delayed = Delayed();

    delayed.step('Creating project…');
    final directory = await createBlankProject(_projectName);

    delayed.step('Creating main.dart…');
    await _createMainFile();

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
      ..writeln('''Future<void> main(${_useHmr ? '_, port' : ''}) async {''')
      ..writeln('final client = Client()')
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

    final file = File('$_projectName/src/main.dart');
    await file.create(recursive: true);
    await file.writeAsString(formatter.format(buffer.toString()));

    await createPubspec(Directory(_projectName), this);
  }
}
