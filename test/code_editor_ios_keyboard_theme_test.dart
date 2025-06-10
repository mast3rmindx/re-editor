import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

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

    testWidgets('CodeEditor can be created and rendered with different themes', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final CodeLineEditingController controller = CodeLineEditingController.fromText('Hello World');
      final CodeEditor editor = CodeEditor(
        controller: controller,
        focusNode: FocusNode(), // Ensure it can gain focus
      );

      // Pump with light theme
      await tester.pumpWidget(TestWrapper(brightness: Brightness.light, child: editor));
      await tester.pumpAndSettle(); // Ensure all initializations and builds are complete

      // Verify the editor is rendered
      expect(find.byType(CodeEditor), findsOneWidget);

      // Change theme to dark
      await tester.pumpWidget(TestWrapper(brightness: Brightness.dark, child: editor));
      await tester.pumpAndSettle(); // Ensure didChangeDependencies and rebuilds are complete

      // Verify the editor is still rendered after theme change
      expect(find.byType(CodeEditor), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
