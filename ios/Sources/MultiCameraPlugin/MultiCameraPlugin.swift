import Foundation
import Capacitor
import Photos
import PhotosUI
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(MultiCameraPlugin)
public class MultiCameraPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MultiCameraPlugin"
    public let jsName = "Camera"
    
    //Public methods to comunicate with JS
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "checkPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pickImages", returnType: CAPPluginReturnPromise),
    ]
    
    // Variables
    private var call : CAPPluginCall?
    private var settings = CameraSettings()
    
    // Constants
    private let defaultSource = CameraSource.prompt
    private let defaultDirection = CameraDirection.rear
    private let implementation = MultiCamera()
    
    
    @objc func pickImages(_ call: CAPPluginCall) {
        self.call = call

        // Make sure they have all the necessary info.plist settings
        if let missingUsageDescription = implementation.checkUsageDescriptions() {
           CAPLog.print("⚡️ ", self.pluginId, "-", missingUsageDescription)
           call.reject(missingUsageDescription)
           return
        }
       
        DispatchQueue.main.async {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = call.getInt("limit") ?? 0 // 0 = unlimited, or set X for a max limit
            config.filter = .images
            
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            picker.modalPresentationStyle = .fullScreen
            
            self.bridge?.viewController?.present(picker, animated: true, completion: nil)
        }
   }
    
    @objc override public func checkPermissions(_ call: CAPPluginCall) {
        
        let result: [String: Any] = implementation.checkPermissions()
        call.resolve(result)
    }
    
    
    @objc override public func requestPermissions(_ call: CAPPluginCall) {
        // get the list of desired types, if passed
        let typeList = call.getArray("permissions", String.self)?.compactMap({ (type) -> CameraPermissionType? in
                        return CameraPermissionType(rawValue: type)
                    }) ?? []
        
        let group = implementation.requestCameraPermissions(typeList)
    
        group.notify(queue: DispatchQueue.main) { [weak self] in
            self?.checkPermissions(call)
        }
    }
    
    
    /// Converts a `UIImage` into a dictionary that matches the JavaScript `Photo` interface.
    ///
    /// - Parameters:
    ///   - image: The photo as a `UIImage`.
    ///   - resultType: Desired return type: `"base64"`, `"dataUrl"`, or `"uri"`.
    ///   - saveToGallery: Whether the photo should also be stored in the device’s gallery.
    /// - Returns: A `[String: Any]` dictionary containing the photo data and metadata.
    private func makePhotoResult(from image: UIImage,
                                 resultType: String,
                                 saveToGallery: Bool) -> [String: Any] {
        var result: [String: Any] = [:]
        var saved = false

        if saveToGallery {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            saved = true
        }

        if let data = image.jpegData(compressionQuality: settings.jpegQuality) {
            switch resultType {
                case "base64":
                    result["base64String"] = data.base64EncodedString()

                case "dataUrl":
                    let base64 = data.base64EncodedString()
                    result["dataUrl"] = "data:image/jpeg;base64," + base64

                default: // "uri"
                    let filename = UUID().uuidString + ".jpg"
                    let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)

                    do {
                        try data.write(to: fileURL)

                        // Internal path
                        result["path"] = fileURL.absoluteString

                        // Path for use <img> inside WebView)
                        if let webURL = bridge?.portablePath(fromLocalURL: fileURL) {
                            result["webPath"] = webURL.absoluteString
                        }
                    } catch {
                        CAPLog.print("❌ Error writing image to disk:", error.localizedDescription)
                    }
            }
        }

        result["format"] = "jpeg"
        result["saved"] = saved
        result["exif"] = true

        return result
    }
}


// MARK: - PHPicker Delegate
extension MultiCameraPlugin: PHPickerViewControllerDelegate {
    
    /// Controller photo gallery
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)

        guard !results.isEmpty else {
            let error = ErrorHandled.userCancelled
            call?.reject(error.missingMessage, error.rawValue)
            return
        }

        var photos: [[String: Any]] = []
        let group = DispatchGroup()

        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { (reading, error) in
                    defer { group.leave() }
                    
                    if let image = reading as? UIImage {
                        let photo = self.makePhotoResult(from: image,
                                                         resultType: "uri", // always URI for gallery
                                                         saveToGallery: false)
                        photos.append(photo)
                    }
                }
            }
        }

        group.notify(queue: .main) {
            self.call?.resolve(["photos": photos])
            self.call = nil
        }
    }
}
