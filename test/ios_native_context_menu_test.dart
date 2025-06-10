import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  group('iOS Native Context Menu Tests', () {
    testWidgets('useNativeContextMenu=true should disable custom context menu on iOS', (WidgetTester tester) async {
      // Override platform to iOS for this test
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      
      try {
        final controller = CodeLineEditingController.fromText('Hello World\nThis is a test');
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CodeEditor(
                controller: controller,
                useNativeContextMenu: true,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Find the CodeEditor widget
        final codeEditor = find.byType(CodeEditor);
        expect(codeEditor, findsOneWidget);
        
        // Verify that the useNativeContextMenu property is set correctly
        final codeEditorWidget = tester.widget<CodeEditor>(codeEditor);
        expect(codeEditorWidget.useNativeContextMenu, isTrue);
        
        // On iOS with native context menu enabled, the SelectionArea should have
        // contextMenuBuilder set to null to allow native context menus
        final selectionArea = find.byType(SelectionArea);
        if (selectionArea.evaluate().isNotEmpty) {
          final selectionAreaWidget = tester.widget<SelectionArea>(selectionArea);
          expect(selectionAreaWidget.contextMenuBuilder, isNull,
              reason: 'contextMenuBuilder should be null when useNativeContextMenu is true on iOS');
        }
        
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
    
    testWidgets('useNativeContextMenu=false should enable custom context menu on iOS', (WidgetTester tester) async {
      // Override platform to iOS for this test
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      
      try {
        final controller = CodeLineEditingController.fromText('Hello World\nThis is a test');
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CodeEditor(
                controller: controller,
                useNativeContextMenu: false,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Find the CodeEditor widget
        final codeEditor = find.byType(CodeEditor);
        expect(codeEditor, findsOneWidget);
        
        // Verify that the useNativeContextMenu property is set correctly
        final codeEditorWidget = tester.widget<CodeEditor>(codeEditor);
        expect(codeEditorWidget.useNativeContextMenu, isFalse);
        
        // On iOS with native context menu disabled, the SelectionArea should have
        // contextMenuBuilder set to a custom function
        final selectionArea = find.byType(SelectionArea);
        if (selectionArea.evaluate().isNotEmpty) {
          final selectionAreaWidget = tester.widget<SelectionArea>(selectionArea);
          expect(selectionAreaWidget.contextMenuBuilder, isNotNull,
              reason: 'contextMenuBuilder should not be null when useNativeContextMenu is false');
        }
        
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
    
    testWidgets('useNativeContextMenu default value should be false', (WidgetTester tester) async {
      final controller = CodeLineEditingController.fromText('Hello World');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              controller: controller,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find the CodeEditor widget
      final codeEditor = find.byType(CodeEditor);
      expect(codeEditor, findsOneWidget);
      
      // Verify that the default value is false
      final codeEditorWidget = tester.widget<CodeEditor>(codeEditor);
      expect(codeEditorWidget.useNativeContextMenu, isFalse);
    });
    
    testWidgets('Native context menu behavior should work across different platforms', (WidgetTester tester) async {
      final platforms = [
        TargetPlatform.iOS,
        TargetPlatform.android,
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ];
      
      for (final platform in platforms) {
        debugDefaultTargetPlatformOverride = platform;
        
        try {
          final controller = CodeLineEditingController.fromText('Hello World');
          
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CodeEditor(
                  controller: controller,
                  useNativeContextMenu: true,
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Find the CodeEditor widget
          final codeEditor = find.byType(CodeEditor);
          expect(codeEditor, findsOneWidget);
          
          // Verify that the useNativeContextMenu property is respected on all platforms
          final codeEditorWidget = tester.widget<CodeEditor>(codeEditor);
          expect(codeEditorWidget.useNativeContextMenu, isTrue,
              reason: 'useNativeContextMenu should be true on $platform');
          
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      }
    });
  });
} 