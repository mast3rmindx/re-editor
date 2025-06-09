import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_editor/src/editor/code_editor.dart'; // Required for _CodeSelectionGestureDetector
import 'package:flutter/gestures.dart';

// A fake implementation of SelectionToolbarController to track method calls.
class FakeSelectionToolbarController implements SelectionToolbarController {
  bool showCalled = false;
  bool hideCalled = false;
  BuildContext? lastContext;
  CodeLineEditingController? lastController;
  TextSelectionToolbarAnchors? lastAnchors;
  Rect? lastRenderRect;
  ValueNotifier<bool>? lastVisibility;

  @override
  void hide(BuildContext context) {
    hideCalled = true;
    lastContext = context;
  }

  @override
  void show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    Rect? renderRect,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
  }) {
    showCalled = true;
    lastContext = context;
    lastController = controller;
    lastAnchors = anchors;
    lastRenderRect = renderRect;
    lastVisibility = visibility;
  }
}

void main() {
  group('CodeEditor Toolbar Tests on Mobile', () {
    late FakeSelectionToolbarController fakeToolbarController;
    final CodeLineEditingController codeController =
        CodeLineEditingController.fromText('Hello\nWorld\nFlutter');

    setUp(() {
      fakeToolbarController = FakeSelectionToolbarController();
      // Ensure the editor has focus, which is often a prerequisite for selection handling
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Toolbar should NOT show when useNativeContextMenu is true', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              controller: codeController,
              toolbarController: fakeToolbarController,
              focusNode: FocusNode()..requestFocus(), // Ensure editor is focused
              useNativeContextMenu: true,
            ),
          ),
        ),
      );

      // Ensure the widget is fully rendered and has focus
      await tester.pumpAndSettle();

      // Select some text to trigger selection handles and potential toolbar
      codeController.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.pumpAndSettle(); // Allow selection changes to propagate

      // Find the gesture detector responsible for selection gestures
      final Finder gestureDetectorFinder = find.byType(_CodeSelectionGestureDetector);
      expect(gestureDetectorFinder, findsOneWidget);

      // Simulate a long press on the editor area where text is present.
      // Long press is often how the selection toolbar is triggered on mobile.
      await tester.longPress(gestureDetectorFinder);
      await tester.pumpAndSettle(); // Allow gesture to be processed

      expect(fakeToolbarController.showCalled, isFalse, reason: 'Toolbar show() should not have been called when useNativeContextMenu is true.');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Toolbar SHOULD show when useNativeContextMenu is false', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              controller: codeController,
              toolbarController: fakeToolbarController,
              focusNode: FocusNode()..requestFocus(), // Ensure editor is focused
              useNativeContextMenu: false,
            ),
          ),
        ),
      );

      // Ensure the widget is fully rendered and has focus
      await tester.pumpAndSettle();

      // Select some text
      codeController.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.pumpAndSettle();

      final Finder gestureDetectorFinder = find.byType(_CodeSelectionGestureDetector);
      expect(gestureDetectorFinder, findsOneWidget);

      // Simulate a long press
      await tester.longPress(gestureDetectorFinder);
      await tester.pumpAndSettle();

      expect(fakeToolbarController.showCalled, isTrue, reason: 'Toolbar show() should have been called when useNativeContextMenu is false.');
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
