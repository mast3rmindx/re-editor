import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_editor/src/editor/code_editor.dart'; // Required for _CodeEditorState
import 'package:re_editor/src/editor/code_input.dart'; // Required for _CodeInputController

// A StatefulWidget wrapper to easily change the theme brightness for testing.
class TestWrapper extends StatefulWidget {
  final Brightness brightness;
  final Widget child;

  const TestWrapper({super.key, required this.brightness, required this.child});

  @override
  State<TestWrapper> createState() => _TestWrapperState();
}

class _TestWrapperState extends State<TestWrapper> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(brightness: widget.brightness),
      home: Scaffold(body: widget.child),
    );
  }
}

void main() {
  group('CodeEditor iOS Keyboard Theme Tests', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Keyboard appearance updates with theme brightness change', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final CodeLineEditingController controller = CodeLineEditingController.fromText('Hello World');
      final CodeEditor editor = CodeEditor(
        controller: controller,
        focusNode: FocusNode(), // Ensure it can gain focus
      );

      // Pump with light theme
      await tester.pumpWidget(TestWrapper(brightness: Brightness.light, child: editor));
      await tester.pumpAndSettle(); // Ensure all initializations and builds are complete

      // Get CodeEditorState
      final _CodeEditorState editorState = tester.state(find.byType(CodeEditor));
      // Access the _CodeInputController (this relies on _inputController not being private)
      final _CodeInputController inputController = editorState.inputController;

      expect(inputController.debugKeyboardAppearance, Brightness.light,
          reason: 'Keyboard appearance should be light when theme is light.');

      // Change theme to dark
      await tester.pumpWidget(TestWrapper(brightness: Brightness.dark, child: editor));
      await tester.pumpAndSettle(); // Ensure didChangeDependencies and rebuilds are complete

      // Re-accessing state or controller might not be strictly necessary if the instance is the same
      // but good to be explicit or verify. For inputController, it's final in _CodeEditorState,
      // so the instance should be the same.
      expect(inputController.debugKeyboardAppearance, Brightness.dark,
          reason: 'Keyboard appearance should update to dark when theme changes to dark.');

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
