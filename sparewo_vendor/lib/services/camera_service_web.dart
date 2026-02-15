// lib/services/camera_service_web.dart
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

Future<String?> takePhotoWeb(
    String? vendorId, String? productId, dynamic service) async {
  try {
    // Create video element for camera stream
    final videoElement = html.VideoElement()
      ..autoplay = true
      ..style.width = '100%'
      ..style.height = 'auto';

    // Request camera access
    final stream = await html.window.navigator.mediaDevices!.getUserMedia({
      'video': {
        'facingMode': 'environment', // Use back camera if available
        'width': {'ideal': 1920},
        'height': {'ideal': 1080},
      }
    });

    videoElement.srcObject = stream;

    // Create a dialog to show camera preview
    final dialog = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '50%'
      ..style.left = '50%'
      ..style.transform = 'translate(-50%, -50%)'
      ..style.backgroundColor = 'white'
      ..style.padding = '20px'
      ..style.borderRadius = '8px'
      ..style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)'
      ..style.zIndex = '9999'
      ..style.maxWidth = '90vw'
      ..style.maxHeight = '90vh';

    final title = html.HeadingElement.h3()
      ..text = 'Take Photo'
      ..style.marginTop = '0';

    final videoContainer = html.DivElement()
      ..style.position = 'relative'
      ..style.marginBottom = '10px'
      ..append(videoElement);

    final buttonContainer = html.DivElement()
      ..style.display = 'flex'
      ..style.justifyContent = 'space-between'
      ..style.gap = '10px';

    final captureButton = html.ButtonElement()
      ..text = 'Capture'
      ..style.padding = '10px 20px'
      ..style.backgroundColor = '#4CAF50'
      ..style.color = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '4px'
      ..style.cursor = 'pointer';

    final cancelButton = html.ButtonElement()
      ..text = 'Cancel'
      ..style.padding = '10px 20px'
      ..style.backgroundColor = '#f44336'
      ..style.color = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '4px'
      ..style.cursor = 'pointer';

    buttonContainer.append(captureButton);
    buttonContainer.append(cancelButton);

    dialog.append(title);
    dialog.append(videoContainer);
    dialog.append(buttonContainer);

    // Overlay background
    final overlay = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'rgba(0, 0, 0, 0.5)'
      ..style.zIndex = '9998'
      ..append(dialog);

    html.document.body!.append(overlay);

    // Wait for user action
    final completer = Completer<String?>();

    captureButton.onClick.listen((_) async {
      try {
        // Capture image from video
        final canvas = html.CanvasElement()
          ..width = videoElement.videoWidth
          ..height = videoElement.videoHeight;

        final context = canvas.context2D;
        context.drawImage(videoElement, 0, 0);

        // Convert canvas to blob
        final blob = await canvas.toBlob('image/jpeg', 0.8);
        if (blob != null) {
          // Convert blob to Uint8List
          final reader = html.FileReader();
          reader.readAsArrayBuffer(blob);
          await reader.onLoadEnd.first;

          final data = reader.result as Uint8List;

          // Upload the captured image
          final url = await service.uploadImageData(
            imageData: data,
            vendorId: vendorId,
            productId: productId,
            contentType: 'image/jpeg',
          );

          completer.complete(url);
        } else {
          completer.complete(null);
        }
      } catch (e) {
        completer.completeError(e);
      } finally {
        // Clean up
        stream.getTracks().forEach((track) => track.stop());
        overlay.remove();
      }
    });

    cancelButton.onClick.listen((_) {
      stream.getTracks().forEach((track) => track.stop());
      overlay.remove();
      completer.complete(null);
    });

    return await completer.future;
  } catch (e) {
    // Fall back to file picker if camera access fails
    return null;
  }
}
