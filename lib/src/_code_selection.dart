part of re_editor;

class _CodeSelectionGestureDetector extends StatefulWidget {

  final CodeLineEditingController controller;
  final _CodeInputController inputController;
  final CodeChunkController chunkController;
  final HitTestBehavior? behavior;
  final GlobalKey editorKey;
  final _SelectionOverlayController selectionOverlayController;
  final Widget child;

  const _CodeSelectionGestureDetector({
    required this.controller,
    required this.inputController,
    required this.chunkController,
    this.behavior,
    required this.editorKey,
    required this.selectionOverlayController,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _CodeSelectionGestureDetectorState();

}

class _CodeSelectionGestureDetectorState extends State<_CodeSelectionGestureDetector> {
  Offset? _dragPosition;
  bool _dragging = false;
  DateTime? _pointerTapTimestamp;
  Offset? _pointerTapPosition;
  bool? _handleByNextEvent;
  bool _longPressOnSelection = false;
  CodeLineSelection? _anchorSelection;

  _CodeFieldRender get render => widget.editorKey.currentContext?.findRenderObject() as _CodeFieldRender;

  bool _tapping = false;

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return GestureDetector(
        onLongPressMoveUpdate: (details) {
          if (_longPressOnSelection == true) {
            return;
          }
          if (details.localOffsetFromOrigin.distance < 1) {
            return;
          }
          _dragging = true;
          _onLongPressMove(details);
        },
        onLongPressStart: (details) {
          _dragPosition = details.globalPosition;
          widget.inputController.ensureInput();
          _longPressOnSelection = _isPositionOnSelection(details.globalPosition);
          if (_longPressOnSelection != true) {
            _onMobileLongPressedStart(details.globalPosition);
            _autoScrollWhenDragging();
          } else {
            widget.selectionOverlayController.showToolbar(context, details.globalPosition);
          }
          widget.selectionOverlayController.showHandle(context);
        },
        onLongPressEnd: (details) {
          if (_longPressOnSelection != true) {
            widget.selectionOverlayController.showToolbar(context, details.globalPosition);
          }
          _dragPosition = null;
          _longPressOnSelection = false;
          _dragging = false;
          widget.selectionOverlayController.showHandle(context);
        },
        onLongPressCancel: () {
          _dragPosition = null;
          _longPressOnSelection = false;
          _dragging = false;
          widget.selectionOverlayController.hideToolbar();
          widget.selectionOverlayController.hideHandle();
        },
        onLongPressUp: () {
          _dragPosition = null;
        },
        onTapUp: (details) {
          _onMobileTapUp(details.globalPosition);
        },
        onTapDown: (details) {
          if (!render.hasFocus) {
            _onMobileTapDown(details.globalPosition);
          }
        },
        behavior: widget.behavior,
        child: widget.child,
      );
    } else {
      return GestureDetector(
        onVerticalDragUpdate: _onDrag,
        onHorizontalDragUpdate: _onDrag,
        onVerticalDragStart: (details) {
          if (!_tapping) {
            return;
          }
          _dragPosition = details.globalPosition;
          _dragging = true;
          _autoScrollWhenDragging();
        },
        onVerticalDragEnd: (_) {
          _dragPosition = null;
          _dragging = false;
        },
        onVerticalDragCancel: () {
          _dragPosition = null;
          _dragging = false;
        },
        onHorizontalDragStart: (details) {
          if (!_tapping) {
            return;
          }
          _dragPosition = details.globalPosition;
          _dragging = true;
          _autoScrollWhenDragging();
        },
        onHorizontalDragEnd: (_) {
          _dragPosition = null;
          _dragging = false;
        },
        onHorizontalDragCancel: () {
          _dragPosition = null;
          _dragging = false;
        },
        behavior: widget.behavior,
        onSecondaryTapDown: (detail) {
          _onSecondaryTapDown(context, detail);
        },
        onTapUp: (_) {
          widget.inputController.ensureInput();
        },
        child: Listener(
          onPointerDown: (event) {
            _tapping = render.isValidPointer2(event.position);
            // A trick, delay the focus request here to avoid loss.
            Future(widget.inputController.ensureInput);
            _onDesktopTapDown(event.position);
          },
          onPointerUp: (event) {
            _tapping = false;
            _onDesktopTapUp(event.position);
          },
          onPointerCancel: (event) {
            _tapping = false;
            _handleByNextEvent = false;
            _pointerTapTimestamp = null;
            _pointerTapPosition = null;
          },
          behavior: widget.behavior ?? HitTestBehavior.translucent,
          child: widget.child,
        ),
      );
    }
  }

  bool get _isMobile => kIsAndroid || kIsIOS;

  bool get _isShiftPressed => _isMobile ? false : HardwareKeyboard.instance.logicalKeysPressed
    .any(<LogicalKeyboardKey>{
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    }.contains);

  void _onMobileTapDown(Offset position) {
    _selectPosition(position, _SelectionChangedCause.tapDown);
    widget.selectionOverlayController.hideHandle();
    widget.selectionOverlayController.hideToolbar();
  }

  void _onMobileTapUp(Offset position) {
    final DateTime now = DateTime.now();
    if (_pointerTapTimestamp != null && (now.millisecondsSinceEpoch - _pointerTapTimestamp!.millisecondsSinceEpoch) <
      kDoubleTapTimeout.inMilliseconds && _pointerTapPosition != null && _pointerTapPosition!.isSamePosition(position)) {
      _onDoubleTap(position);
      widget.selectionOverlayController.showHandle(context);
      widget.selectionOverlayController.showToolbar(context, position);
    } else {
      _pointerTapTimestamp = now;
      _pointerTapPosition = position;
      _selectPosition(position, _SelectionChangedCause.tapUp);
      widget.selectionOverlayController.hideHandle();
      widget.selectionOverlayController.hideToolbar();
    }
    widget.inputController.ensureInput();
  }

  void _onMobileLongPressedStart(Offset position) {
    final CodeLineRange? range = render.selectWord(
      position: position,
    );
    if (range == null) {
      return;
    }
    final CodeLineSelection selection = CodeLineSelection.fromRange(
      range: range
    );
    widget.controller.selection = selection;
    widget.controller.makeCursorVisible();
    _anchorSelection = selection;
    widget.selectionOverlayController.hideHandle();
    widget.selectionOverlayController.hideToolbar();
  }

  void _onDesktopTapDown(Offset position) {
    if (widget.controller.isComposing) {
      return;
    }
    final DateTime now = DateTime.now();
    if (_pointerTapTimestamp != null && (now.millisecondsSinceEpoch - _pointerTapTimestamp!.millisecondsSinceEpoch) <
      kDoubleTapTimeout.inMilliseconds && _pointerTapPosition != null && _pointerTapPosition!.isSamePosition(position)) {
      _onDoubleTap(position);
    } else {
      if (widget.controller.selection.baseOffset != -1) {
        if (_isShiftPressed) {
          _extendSelection(position, _SelectionChangedCause.tapDown);
          return;
        }
      }
      _pointerTapTimestamp = now;
      _pointerTapPosition = position;
      _selectPosition(position, _SelectionChangedCause.tapDown);
    }
  }

  void _onDesktopTapUp(Offset position) {
    _anchorSelection = null;
    if (_dragPosition != null) {
      return;
    }
    if (_handleByNextEvent != true) {
      return;
    }
    _handleByNextEvent = false;
    _selectPosition(position, _SelectionChangedCause.tapUp);
  }

  void _onDoubleTap(Offset position) {
    final CodeLineRange? range = render.selectWord(
      position: position,
    );
    if (range == null) {
      return;
    }
    final CodeLineSelection selection;
    if (_isShiftPressed && widget.controller.selection.base.offset <= range.start) {
      selection = widget.controller.selection.copyWith(
        extentIndex: range.index,
        extentOffset: range.end
      );
    } else if (_isShiftPressed && widget.controller.selection.base.offset >= range.end) {
      selection = widget.controller.selection.copyWith(
        extentIndex: range.index,
        extentOffset: range.start
      );
    } else {
      selection = CodeLineSelection.fromRange(
        range: range
      );
    }
    widget.controller.selection = selection;
    widget.controller.makeCursorVisible();
    _anchorSelection = selection;
  }

  void _onDrag(DragUpdateDetails details) {
    if (!_tapping) {
      // https://github.com/flutter/flutter/issues/114889
      return;
    }
    if (widget.controller.isComposing) {
      return;
    }
    if (_isMobile) {
      return;
    }
    _dragPosition = details.globalPosition;
    _extendSelection(details.globalPosition, _SelectionChangedCause.drag);
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    if (widget.controller.isComposing) {
      return;
    }
    if (!_isMobile) {
      return;
    }
    _dragPosition = details.globalPosition;
    _extendSelection(details.globalPosition, _SelectionChangedCause.drag);
  }

  void _onSecondaryTapDown(BuildContext context, TapDownDetails details) {
    _handleByNextEvent = false;
    if (!render.size.contains(render.globalToLocal(details.globalPosition))) {
      return;
    }
    
    widget.controller.clearComposing();
    widget.selectionOverlayController.showToolbar(context, details.globalPosition);
  }

  void _extendSelection(Offset offset, _SelectionChangedCause cause) {
    if (cause == _SelectionChangedCause.tapDown || cause == _SelectionChangedCause.tapUp) {
      if (expandChunkIfNeeded(render.chunkIndicatorHitIndex(offset))) {
        return;
      }
    }
    final CodeLineSelection? selection = render.extendPositionTo(
      oldSelection: widget.controller.selection,
      position: offset,
      anchor: _isMobile ? null : _anchorSelection,
      allowOverflow: cause == _SelectionChangedCause.drag,
    );
    if (selection == null) {
      return;
    }
    if (widget.controller.selection == selection) {
      return;
    }
    widget.controller.value = widget.controller.value.copyWith(
      selection: selection,
      composing: TextRange.empty,
    );
    widget.controller.makeCursorVisible();
  }

  void _selectPosition(Offset offset, _SelectionChangedCause cause) {
    if (cause == _SelectionChangedCause.tapDown || cause == _SelectionChangedCause.tapUp) {
      if (expandChunkIfNeeded(render.chunkIndicatorHitIndex(offset))) {
        return;
      }
    }
    final CodeLineSelection? selection = render.setPositionAt(
      position: offset,
    );
    if (selection == null) {
      return;
    }
    if (widget.controller.selection == selection) {
      return;
    }

    if (cause == _SelectionChangedCause.tapDown) {
      if (!widget.controller.selection.isCollapsed && widget.controller.selection.contains(selection)) {
        _handleByNextEvent = true;
        return;
      }
    }
    widget.controller.value = widget.controller.value.copyWith(
      selection: selection,
      composing: TextRange.empty,
    );
    widget.controller.makeCursorVisible();
  }

  bool _isPositionOnSelection(Offset position) {
    final CodeLineSelection? selection = render.setPositionAt(
      position: position,
    );
    if (selection == null) {
      return false;
    }
    if (widget.controller.selection == selection) {
      return false;
    }
    return widget.controller.selection.contains(selection);
  }

  void _autoScrollWhenDragging() {
    final Offset? position = _dragPosition;
    Future.delayed(const Duration(milliseconds: 100), (() {
      if (_dragPosition == null || position == null) {
        return;
      }
      if (_dragging) {
        render.autoScrollWhenDragging(_dragPosition!);
        _extendSelection(_dragPosition!, _SelectionChangedCause.drag);
      }
      _autoScrollWhenDragging();
    }));
  }

  bool expandChunkIfNeeded(int index) {
    if (index < 0) {
      return false;
    }
    widget.chunkController.expand(index);
    return true;
  }

}

enum _SelectionChangedCause {
  /// The user tapped down on the text and that caused the selection (or the location
  /// of the cursor) to change.
  tapDown,

  /// The user tapped up on the text and that caused the selection (or the location
  /// of the cursor) to change.
  tapUp,

  /// The user used the mouse to change the selection by dragging over a piece
  /// of text.
  drag,

}

abstract class _SelectionOverlayController {

  void showHandle(BuildContext context);

  void hideHandle();

  void showToolbar(BuildContext context, Offset position);

  void hideToolbar();

  void dispose();

}

typedef OnToolbarShow = void Function(BuildContext context, TextSelectionToolbarAnchors anchors, Rect? renderRect);

class _DesktopSelectionOverlayController implements _SelectionOverlayController {

  final OnToolbarShow onShowToolbar;
  final VoidCallback onHideToolbar;

  const _DesktopSelectionOverlayController({
    required this.onShowToolbar,
    required this.onHideToolbar,
  });

  @override
  void hideHandle() {
  }

  @override
  void showHandle(BuildContext context) {
  }

  @override
  void hideToolbar() {
    onHideToolbar();
  }

  @override
  void showToolbar(BuildContext context, Offset? position) {
    if (position == null) {
      return;
    }
    
    // Always show the custom toolbar on desktop platforms
    onShowToolbar(context, TextSelectionToolbarAnchors(
      primaryAnchor: position
    ), null);
  }

  @override
  void dispose() {
  }

}

class _MobileSelectionOverlayController extends _SelectionOverlayController {

  final BuildContext context;
  final GlobalKey editorKey;
  final ValueNotifier<bool> toolbarVisibility;
  final CodeLineEditingController controller;
  final FocusNode focusNode;
  final void Function(BuildContext, TextSelectionToolbarAnchors, Rect?)? onShowToolbar;
  final VoidCallback? onHideToolbar;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final bool useNativeContextMenu;

  _MobileSelectionOverlayController({
    required this.context,
    required this.controller,
    required this.editorKey,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.toolbarVisibility,
    required this.focusNode,
    this.onShowToolbar,
    this.onHideToolbar,
    this.useNativeContextMenu = false,
  });

  @override
  Widget build(BuildContext context, Widget child) {
    return SelectionArea(
      focusNode: focusNode,
      onSelectionChanged: (selection) {
        // Handle selection changes if needed
        // Note: CodeLineEditingController doesn't have textEditingValue property
        // Selection is handled by the underlying text editing system
      },
      contextMenuBuilder: useNativeContextMenu ? null : (context, selectableRegionState) {
        // Use custom context menu
        // For now, we'll use a simple approach to show the toolbar
        // The actual selection handling is done by the underlying system
        final anchors = TextSelectionToolbarAnchors(
          primaryAnchor: Offset.zero, // This will be updated by the actual implementation
        );
        onShowToolbar?.call(context, anchors, null);
        return const SizedBox.shrink();
      },
      child: child,
    );
  }





  @override
  void showHandle(BuildContext context) {
    // Implementation needed
  }

  @override
  void hideHandle() {
    // Implementation needed
  }

  @override
  void showToolbar(BuildContext context, Offset globalPosition) {
    // Implementation needed
  }

  @override
  void hideToolbar() {
    // Implementation needed
  }

  @override
  void dispose() {
    // Implementation needed
  }

}

class _SelectionHandleOverlay extends StatefulWidget {
  /// Create selection overlay.
  const _SelectionHandleOverlay({
    required this.type,
    required this.handleLayerLink,
    this.onSelectionHandleTapped,
    this.onSelectionHandleDragStart,
    this.onSelectionHandleDragUpdate,
    this.onSelectionHandleDragEnd,
    this.onSelectionHandleDragCancel,
    required this.selectionControls,
    this.visibility,
    required this.preferredLineHeight,
  });

  final LayerLink handleLayerLink;
  final VoidCallback? onSelectionHandleTapped;
  final ValueChanged<DragStartDetails>? onSelectionHandleDragStart;
  final ValueChanged<DragUpdateDetails>? onSelectionHandleDragUpdate;
  final ValueChanged<DragEndDetails>? onSelectionHandleDragEnd;
  final VoidCallback? onSelectionHandleDragCancel;
  final TextSelectionControls selectionControls;
  final ValueListenable<bool>? visibility;
  final double preferredLineHeight;
  final TextSelectionHandleType type;

  @override
  State<_SelectionHandleOverlay> createState() => _SelectionHandleOverlayState();
}

class _SelectionHandleOverlayState extends State<_SelectionHandleOverlay> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: SelectionOverlay.fadeDuration, vsync: this);

    _handleVisibilityChanged();
    widget.visibility?.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget.visibility?.value ?? true) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(_SelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.visibility?.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget.visibility?.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget.visibility?.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Offset handleAnchor = widget.selectionControls.getHandleAnchor(
      widget.type,
      widget.preferredLineHeight,
    );
    final Size handleSize = widget.selectionControls.getHandleSize(
      widget.preferredLineHeight,
    );

    final Rect handleRect = Rect.fromLTWH(
      -handleAnchor.dx,
      -handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    // Make sure the GestureDetector is big enough to be easily interactive.
    final Rect interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(center: handleRect.center, radius: kMinInteractiveDimension/ 2),
    );
    final RelativeRect padding = RelativeRect.fromLTRB(
      max((interactiveRect.width - handleRect.width) / 2, 0),
      max((interactiveRect.height - handleRect.height) / 2, 0),
      max((interactiveRect.width - handleRect.width) / 2, 0),
      max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: widget.handleLayerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          alignment: Alignment.topLeft,
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: <Type, GestureRecognizerFactory>{
              PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                () => PanGestureRecognizer(
                  debugOwner: this,
                  // Mouse events select the text and do not drag the cursor.
                  supportedDevices: <PointerDeviceKind>{
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown,
                  },
                ),
                (PanGestureRecognizer instance) {
                  instance
                    ..dragStartBehavior = DragStartBehavior.start
                    ..onStart = widget.onSelectionHandleDragStart
                    ..onUpdate = widget.onSelectionHandleDragUpdate
                    ..onCancel = widget.onSelectionHandleDragCancel
                    ..onEnd = widget.onSelectionHandleDragEnd;
                },
              ),
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
              ),
              child: widget.selectionControls.buildHandle(
                context,
                widget.type,
                widget.preferredLineHeight,
                widget.onSelectionHandleTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileSelectionToolbarController implements MobileSelectionToolbarController {

  final ToolbarMenuBuilder builder;
  OverlayEntry? _entry;

  _MobileSelectionToolbarController({
    required this.builder
  });

  @override
  void hide(BuildContext context) {
    _entry?.remove();
    _entry = null;
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
    hide(context);
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    final OverlayEntry entry = OverlayEntry(
      builder: (_) => _SelectionToolbarWrapper(
        visibility: visibility,
        layerLink: layerLink,
        offset: -renderRect!.topLeft,
        child: builder(
          context: context,
          anchors: anchors,
          controller: controller,
          onDismiss: () {
            hide(context);
          },
          onRefresh: () {
            show(
              context: context,
              controller: controller,
              anchors: anchors,
              renderRect: renderRect,
              layerLink: layerLink,
              visibility: visibility
            );
          },
        )
      )
    );
    overlay.insert(entry);
    _entry = entry;
  }

}

// TODO(justinmc): Currently this fades in but not out on all platforms. It
// should follow the correct fading behavior for the current platform, then be
// made public and de-duplicated with widgets/selectable_region.dart.
// https://github.com/flutter/flutter/issues/107732
// Wrap the given child in the widgets common to both contextMenuBuilder and
// TextSelectionControls.buildToolbar.
class _SelectionToolbarWrapper extends StatefulWidget {
  const _SelectionToolbarWrapper({
    this.visibility,
    required this.layerLink,
    required this.offset,
    required this.child,
  });

  final Widget child;
  final Offset offset;
  final LayerLink layerLink;
  final ValueListenable<bool>? visibility;

  @override
  State<_SelectionToolbarWrapper> createState() => _SelectionToolbarWrapperState();
}

class _SelectionToolbarWrapperState extends State<_SelectionToolbarWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: SelectionOverlay.fadeDuration, vsync: this);

    _toolbarVisibilityChanged();
    widget.visibility?.addListener(_toolbarVisibilityChanged);
  }

  @override
  void didUpdateWidget(_SelectionToolbarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibility == widget.visibility) {
      return;
    }
    oldWidget.visibility?.removeListener(_toolbarVisibilityChanged);
    _toolbarVisibilityChanged();
    widget.visibility?.addListener(_toolbarVisibilityChanged);
  }

  @override
  void dispose() {
    widget.visibility?.removeListener(_toolbarVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _toolbarVisibilityChanged() {
    if (widget.visibility?.value ?? true) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CodeEditorTapRegion(
      child: Directionality(
        textDirection: Directionality.of(this.context),
        child: FadeTransition(
          opacity: _opacity,
          child: CompositedTransformFollower(
            link: widget.layerLink,
            showWhenUnlinked: false,
            offset: widget.offset,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}