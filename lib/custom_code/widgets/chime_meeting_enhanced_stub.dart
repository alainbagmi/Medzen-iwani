// Stub file for conditional imports on non-web platforms
// This file is only imported when dart:html is not available (mobile/desktop)
// It provides stub implementations that will never be called at runtime

// =============================================
// Stub for dart:html types
// =============================================

class IFrameElement {
  String src = '';
  String? id;
  String? allow;
  CssStyleDeclaration get style => CssStyleDeclaration();
  WindowBase? get contentWindow => null;
  void setAttribute(String name, String value) {}
  void remove() {}
}

class WindowBase {
  void postMessage(dynamic message, String targetOrigin) {}
}

class CssStyleDeclaration {
  String border = '';
  String width = '';
  String height = '';
}

class Window {
  void addEventListener(String type, dynamic callback) {}
  void removeEventListener(String type, dynamic callback) {}
}

typedef EventListener = void Function(dynamic event);

Window get window => Window();

class Document {
  Element? getElementById(String id) => null;
}

class Element {}

Document get document => Document();

// =============================================
// Stub for dart:ui_web platformViewRegistry
// =============================================

class _PlatformViewRegistry {
  void registerViewFactory(
    String viewType,
    dynamic Function(int viewId) viewFactory,
  ) {}
}

final platformViewRegistry = _PlatformViewRegistry();
