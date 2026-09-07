// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void setWebCameraZoom(double scale) {
  try {
    js.context.callMethod('setCameraZoom', [scale]);
  } catch (e) {
    // Ignore if function not found or failed
  }
}
