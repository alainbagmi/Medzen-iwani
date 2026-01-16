/// Stub file for web-specific imports on non-web platforms
/// This allows conditional imports to work on mobile/IO platforms
/// The actual web functionality is only used in web builds

// Stub implementations of dart:html types
class CSSStyleDeclaration {
  String border = '';
  String width = '';
  String height = '';
}

class IFrameElement {
  late String id;
  late CSSStyleDeclaration style;
  late String allow;
  late _Window? contentWindow;

  IFrameElement() {
    style = CSSStyleDeclaration();
    contentWindow = _Window();
  }

  void setAttribute(String name, String value) {}
}

class _Window {
  void postMessage(dynamic message, String targetOrigin) {}
}

class Window {
  void addEventListener(String event, EventListener? listener) {}
  void removeEventListener(String event, EventListener? listener) {}
  dynamic postMessage(dynamic message, String targetOrigin) => null;
}

class Document {
  Element? getElementById(String id) => null;
}

class Element {}

typedef EventListener = void Function(Event);

class Event {
  final String type;
  Event(this.type);
}

// Stub window and document instances
final window = Window();
final document = Document();

// Stub implementations of dart:ui_web types
class _PlatformViewRegistry {
  void registerViewFactory(String viewTypeId, dynamic factory) {}
}

final platformViewRegistry = _PlatformViewRegistry();
