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
    ]
    
    // Variables
    private var call : CAPPluginCall?
    private var settigs = CameraSettings()
    
    // Constants
    private let defaultSource = CameraSource.prompt
    private let defaultDirection = CameraDirection.rear
    private let implementation = MultiCamera()
    

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
}
