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
    public let jsName = "MultiCamera"
    
    //Public methods to comunicate with JS
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "checkPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pickImages", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "capture", returnType: CAPPluginReturnPromise),
    ]
    
    // Variables
    private var call : CAPPluginCall?
    private var settings = CameraSettings()
    
    // Camera View Controller
    private var cameraVC: CameraViewController?
    
    // Constants
    private let defaultSource = CameraSource.prompt
    private let defaultDirection = CameraDirection.rear
    private let implementation = MultiCamera()
    
    @objc func capture(_ call: CAPPluginCall) {
        self.call = call
        self.settings = cameraSettings(from: call)

        // Make sure they have all the necessary info.plist settings
        if let missingUsageDescription = implementation.checkUsageDescriptions() {
            CAPLog.print("⚡️ ", self.pluginId, "-", missingUsageDescription)
            call.reject(missingUsageDescription)
            return
        }
    
        
        DispatchQueue.main.async {
            let vc = CameraViewController()
            vc.modalPresentationStyle = .fullScreen
            vc.resultType = self.settings.resultType
            vc.saveToGallery = self.settings.saveToGallery
            vc.captureLimit = self.settings.limit
            vc.delegate = self

            self.bridge?.viewController?.present(vc, animated: true, completion: nil)
            self.cameraVC = vc
        }
        
    }
    
    
    @objc func pickImages(_ call: CAPPluginCall) {
        self.call = call
        self.settings = cameraSettings(from: call)

        // Make sure they have all the necessary info.plist settings
        if let missingUsageDescription = implementation.checkUsageDescriptions() {
           CAPLog.print("⚡️ ", self.pluginId, "-", missingUsageDescription)
           call.reject(missingUsageDescription)
           return
        }
       
        DispatchQueue.main.async {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = self.settings.limit
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
                                 resultType: CameraResultType,
                                 saveToGallery: Bool) -> [String: Any] {
        var result: [String: Any] = [:]
        var saved = false

        if saveToGallery {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            saved = true
        }

        if let data = image.jpegData(compressionQuality: settings.jpegQuality) {
            switch resultType.rawValue {
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
    
    ///  Set up  global config
    private func cameraSettings(from call: CAPPluginCall) -> CameraSettings {
        var settings = CameraSettings()

        settings.jpegQuality = min(abs(CGFloat(call.getFloat("quality") ?? 100.0)) / 100.0, 1.0)
        settings.source = CameraSource(rawValue: defaultSource.rawValue) ?? defaultSource
        settings.direction = CameraDirection(rawValue: defaultDirection.rawValue) ?? defaultDirection
        settings.saveToGallery = call.getBool("saveToGallery") ?? false
        settings.limit = call.getInt("limit", 0)

        if let typeString = call.getString("resultType"), let type = CameraResultType(rawValue: typeString) {
          settings.resultType = type
        }

        settings.userPromptText = CameraPromptText(title: call.getString("promptLabelHeader"),
                                                 photoAction: call.getString("promptLabelPhoto"),
                                                 cameraAction: call.getString("promptLabelPicture"),
                                                 cancelAction: call.getString("promptLabelCancel"))

        return settings
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
                                                         resultType: CameraResultType.uri, // always URI for gallery
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


// MARK: - CameraDelegate Implementation
extension MultiCameraPlugin: CameraDelegate {
 
     /// Called when the user finishes capturing photos in the camera UI.
     ///
     /// - Parameters:
     ///   - images: An array of `UIImage` objects representing all photos taken in the session.
     ///   - resultType: The requested format for returning the photos (`base64`, `dataUrl`, or `uri`).
     ///   - saveToGallery: Whether the photos should also be saved to the device’s Photos/Gallery.
     ///
     /// The method converts each `UIImage` into the expected result format and resolves
     /// the Capacitor plugin call with an array of photo dictionaries.
     func cameraDidFinish(images: [UIImage], resultType: CameraResultType, saveToGallery: Bool) {
         var photos: [[String: Any]] = []
         
         // Convert each UIImage into the plugin's return structure
         for image in images {
             let photo = makePhotoResult(from: image,
                                         resultType: resultType,
                                         saveToGallery: saveToGallery)
             photos.append(photo)
         }
         
         // Return all processed photos back to JavaScript
         call?.resolve(["photos": photos])
         
         // Dismiss the native camera UI
         cameraVC?.dismiss(animated: true)
         cameraVC = nil
     }

     /// Called when the user cancels the camera session.
     ///
     /// Rejects the plugin call with a "User cancelled" message and closes the camera UI.
     func cameraDidCancel() {
         let error = ErrorHandled.userCancelled
         call?.reject(error.missingMessage, error.rawValue)
         cameraVC?.dismiss(animated: true)
         cameraVC = nil
     }

}
