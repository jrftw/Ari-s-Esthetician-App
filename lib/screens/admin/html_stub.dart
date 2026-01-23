/*
 * Filename: html_stub.dart
 * Purpose: Stub file for dart:html when not on web platform
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: None
 * Platform Compatibility: Non-web platforms only
 */

// MARK: - Stub Classes
/// Stub implementation for non-web platforms
class Blob {
  final List<dynamic> data;
  Blob(this.data);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  String? href;
  String? target;
  String? download;
  AnchorElement({this.href});
  void click() {}
}

class Window {
  Window? open(String url, String target) => null;
  void print() {}
}

class IFrameElement {
  String? src;
  Style? style;
  IFrameElement() : style = Style();
  Stream<dynamic> get onLoad => const Stream.empty();
  void remove() {}
}

class Style {
  String? display;
}

class HtmlElement {
  void append(dynamic element) {}
}

class Document {
  HtmlElement? body;
}

// MARK: - Stub Instances
final window = Window();
final document = Document();
