import Flutter
import UIKit
import Vision

enum EquipmentIdentityOcr {
  static let channelName = "com.auyltech.prokat/equipment_identity_ocr"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      #if DEBUG
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "path required", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let started = Date()
        do {
          var payload = try recognize(path: path)
          payload["elapsedMs"] = Int(Date().timeIntervalSince(started) * 1000)
          DispatchQueue.main.async { result(payload) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "ocr", message: error.localizedDescription, details: nil))
          }
        }
      }
      #else
      result(FlutterError(
        code: "debug_only",
        message: "On-device OCR spike is compiled into debug builds only.",
        details: nil
      ))
      #endif
    }
  }

  #if DEBUG
  private static func recognize(path: String) throws -> [String: Any] {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      throw OcrError("Could not read image")
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    let supported = (try? request.supportedRecognitionLanguages()) ?? []
    var languages = ["en-US"]
    if supported.contains("ru-RU") {
      languages.append("ru-RU")
    }
    let known = Set(supported)
    request.recognitionLanguages = languages.filter { known.isEmpty || known.contains($0) }

    let orientation = CGImagePropertyOrientation(image.imageOrientation)
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
    try handler.perform([request])

    let scale = image.scale
    let width = image.size.width * scale
    let height = image.size.height * scale
    let results = request.results ?? []
    let observations: [[String: Any?]] = results.map { observation in
      let candidate = observation.topCandidates(1).first
      let box = observation.boundingBox
      let left = box.origin.x * width
      let top = (1 - box.origin.y - box.size.height) * height
      return [
        "text": candidate?.string ?? "",
        "confidence": candidate.map { Double($0.confidence) },
        "left": left,
        "top": top,
        "width": box.size.width * width,
        "height": box.size.height * height,
      ]
    }
    return [
      "engine": "ios-vision-accurate",
      "imageWidth": Int(width.rounded()),
      "imageHeight": Int(height.rounded()),
      "observations": observations,
      "supportedLanguages": supported,
      "note": "Vision accurate, language correction off. customWords ignored while correction is off.",
    ]
  }
  #endif
}

#if DEBUG
private struct OcrError: LocalizedError {
  let message: String
  init(_ message: String) { self.message = message }
  var errorDescription: String? { message }
}

extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .down: self = .down
    case .left: self = .left
    case .right: self = .right
    case .upMirrored: self = .upMirrored
    case .downMirrored: self = .downMirrored
    case .leftMirrored: self = .leftMirrored
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
#endif
