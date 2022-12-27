# 📦 Command line interface

The official Mineral framework command line interface.

```dart
import 'package:mineral_cli/mineral_cli.dart';
import 'package:mineral_cli/src/commands/create_project.dart';
import 'package:mineral_cli/src/commands/help.dart';

Future<void> main (List<String> arguments) async {
  final cli = MineralCli(DefaultTheme());
  final console = Console(theme: DefaultTheme());

  cli.register([
    CreateProject(console),
    Help(console, cli)
  ]);

  await cli.handle(arguments);
}
```