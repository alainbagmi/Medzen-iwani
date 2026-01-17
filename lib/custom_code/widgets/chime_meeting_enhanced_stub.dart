// Stub file for non-web platforms
// This provides minimal implementations of web-specific classes
// Used only when dart:html is not available (iOS, Android)

// ignore_for_file: non_constant_identifier_names, unused_element

typedef EventListener = Function(Object);

class CssStyleDeclaration {
  String? border;
  String? width;
  String? height;
}

class IFrameElement {
  String? id;
  String? allow;
  dynamic contentWindow;
  final style = CssStyleDeclaration();

  void addEventListener(String type, EventListener? listener) {}
  void removeEventListener(String type, EventListener? listener) {}
  void postMessage(Object message, String targetOrigin) {}
  void setAttribute(String name, String value) {}
}

class Document {
  Element? getElementById(String id) => null;
}

class Element {
  void addEventListener(String type, EventListener? listener) {}
  void removeEventListener(String type, EventListener? listener) {}
}

class Window {
  void addEventListener(String type, EventListener? listener) {}
  void removeEventListener(String type, EventListener? listener) {}
}

final document = Document();
final window = Window();

class PlatformViewRegistry {
  void registerViewFactory(String viewTypeId, dynamic Function(int viewId) factory) {}
}

final platformViewRegistry = PlatformViewRegistry();
