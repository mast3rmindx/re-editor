import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:re_editor_exmaple/editor_autocomplete.dart';
import 'package:re_editor_exmaple/editor_basic_field.dart';
import 'package:re_editor_exmaple/editor_json.dart';
import 'package:re_editor_exmaple/editor_large_text.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re-Editor',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 255, 140, 0),
        )
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue, // Or any other distinct color
        )
      ),
      themeMode: _themeMode,
      home: const MyHomePage(title: 'Re-Editor Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  static const Map<String, Widget> _editors = {
    'Basic Field': BasicField(),
    'Json Editor': JsonEditor(),
    'Auto Complete': AutoCompleteEditor(),
    'Large Text': LargeTextEditor(),
    'Native Context Menu': NativeContextMenuExamplePage(),
    'Efficient Append Demo': EfficientAppendExamplePage(),
  };

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final Widget child = _editors.values.elementAt(_index);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_4), // Icon for theme toggle
            onPressed: () {
              final currentThemeMode = MyApp.of(context)?._themeMode ?? ThemeMode.system;
              if (currentThemeMode == ThemeMode.dark) {
                MyApp.of(context)?.changeTheme(ThemeMode.light);
              } else {
                MyApp.of(context)?.changeTheme(ThemeMode.dark);
              }
            },
          )
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _editors.entries.mapIndexed((index, entry) {
                  return TextButton(
                    onPressed: () {
                      setState(() {
                        _index = index;
                      });
                    },
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: _index == index ? null : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5)
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey
                  )
                ),
                child: child,
              )
            )
          ],
        )
      ),
    );
  }
}

class EfficientAppendExamplePage extends StatefulWidget {
  const EfficientAppendExamplePage({super.key});

  @override
  State<EfficientAppendExamplePage> createState() => _EfficientAppendExamplePageState();
}

class _EfficientAppendExamplePageState extends State<EfficientAppendExamplePage> {
  late final CodeLineEditingController _controller;
  String _inefficientTime = '';
  String _efficientTime = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText('Initial text.\n');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _appendInefficient() {
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      _controller.text += 'Line $i\n'; // This is inefficient
    }
    stopwatch.stop();
    setState(() {
      _inefficientTime = 'Inefficient: ${stopwatch.elapsedMilliseconds}ms';
    });
    // ignore: avoid_print
    print('Inefficient append took: ${stopwatch.elapsedMilliseconds}ms');
  }

  void _appendEfficient() {
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      _controller.addLine('Line $i'); // Uses the new efficient method
    }
    stopwatch.stop();
    setState(() {
      _efficientTime = 'Efficient (addLine): ${stopwatch.elapsedMilliseconds}ms';
    });
    // ignore: avoid_print
    print('Efficient append (addLine) took: ${stopwatch.elapsedMilliseconds}ms');
  }

  void _clearText() {
    _controller.text = '';
    setState(() {
      _inefficientTime = '';
      _efficientTime = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CodeEditor(
            controller: _controller,
            wordWrap: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(_inefficientTime, style: const TextStyle(color: Colors.red)),
        Text(_efficientTime, style: const TextStyle(color: Colors.green)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _appendInefficient,
              child: const Text('Append 100 lines (inefficient)'),
            ),
            ElevatedButton(
              onPressed: _appendEfficient,
              child: const Text('Append 100 lines (addLine)'),
            ),
            ElevatedButton(
              onPressed: _clearText,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class NativeContextMenuExamplePage extends StatelessWidget {
  const NativeContextMenuExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      controller: CodeLineEditingController.fromText(
        '''
Press and hold (mobile) to see the native context menu.
This example demonstrates the useNativeContextMenu: true feature.

This works on all platforms:
- Mobile: iOS and Android (press and hold)

Try selecting some text and using:
- Cut
- Copy  
- Paste
        '''
      ),
      useNativeContextMenu: true,
      wordWrap: true, // Enable word wrap for better readability of sample text
    );
  }
}