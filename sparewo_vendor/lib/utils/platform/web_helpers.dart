// Web-specific implementations for platform-agnostic functionality
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Revokes an object URL to prevent memory leaks
void revokeObjectUrl(String url) {
  if (kIsWeb) {
    html.Url.revokeObjectUrl(url);
  }
}

/// Creates an HTTP request for web platforms
dynamic createHttpRequest() {
  if (kIsWeb) {
    return html.HttpRequest();
  }
  return null;
}

/// Reads a file as bytes (web implementation)
Future<Uint8List?> readFileAsBytes(dynamic file) async {
  if (!kIsWeb) return null;

  final completer = Completer<Uint8List?>();

  try {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file as html.File);

    reader.onLoad.listen((_) {
      final bytes = Uint8List.fromList(reader.result as List<int>);
      completer.complete(bytes);
    });

    reader.onError.listen((_) {
      completer.complete(null);
    });
  } catch (e) {
    completer.complete(null);
  }

  return completer.future;
}

/// Creates a file input element and returns selected files
Future<List<dynamic>?> pickFilesWithInput(
    {bool multiple = false, String accept = 'image/*'}) async {
  if (!kIsWeb) return null;

  final completer = Completer<List<dynamic>?>();

  try {
    final input = html.FileUploadInputElement();
    input.multiple = multiple;
    input.accept = accept;

    // Add to DOM temporarily
    html.document.body?.append(input);
    input.click();

    // Wait for file selection
    input.onChange.listen((_) {
      if (input.files?.isEmpty ?? true) {
        completer.complete(null);
      } else {
        completer.complete(input.files);
      }
      input.remove();
    });

    // Set a timeout
    Timer(const Duration(minutes: 1), () {
      if (!completer.isCompleted) {
        input.remove();
        completer.complete(null);
      }
    });
  } catch (e) {
    completer.complete(null);
  }

  return completer.future;
}

/// Read blob data as bytes
Future<Uint8List> readBlobData(String blobUrl) async {
  final response = await createHttpRequest()
    ..open('GET', blobUrl)
    ..responseType = 'arraybuffer'
    ..send();

  return Uint8List.fromList(response.response);
}
