import Foundation
import Photos
import PhotosUI
import AVFoundation

@objc public class MultiCamera: NSObject {
    
    @objc public func checkPermissions() -> [String: Any] {
        var result: [String: Any] = [:]
        
        for permission in CameraPermissionType.allCases {
            let state: String
            
            switch permission {
                case .camera:
                    let status = AVCaptureDevice.authorizationStatus(for: .video)
                    
                    var result = "denied"
                    if status == .authorized {
                        result = "granted"
                    } else if status == .notDetermined {
                        result = "prompt"
                    }
                    
                    state = result
                    
                case .photos:
                    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                    
                    var result = "denied"
                    if status == .authorized {
                        result = "granted"
                    } else if status == .notDetermined {
                        result = "prompt"
                    }
                    
                state = result
            }
            
            result[permission.rawValue] = state
        }
        
        return result
    }
    
    
    func requestCameraPermissions(_ typeList: [CameraPermissionType])  -> DispatchGroup {
       let permissions: [CameraPermissionType] = (typeList.count > 0) ? typeList : CameraPermissionType.allCases

       // request the permissions
       let group = DispatchGroup()

       for permission in permissions {
           switch permission {
           case .camera:
               group.enter()
               AVCaptureDevice.requestAccess(for: .video) { _ in
                   group.leave()
               }
           case .photos:
               group.enter()
               if #available(iOS 14, *) {
                   PHPhotoLibrary.requestAuthorization(for: .readWrite) { (_) in
                       group.leave()
                   }
               } else {
                   PHPhotoLibrary.requestAuthorization({ (_) in
                       group.leave()
                   })
               }
           }
       }
   
       return group
   }
    
    /// Check if the required `Info.plist` usage description keys (camera and photo library permissions) are present
    /// - Returns :
    ///     - A `Strings` containing a warning message
    ///     - `nill` if all required keys are present
    func checkUsageDescriptions() -> String? {
       if let dict = Bundle.main.infoDictionary {
           for key in CameraPropertyListKeys.allCases where dict[key.rawValue] == nil {
               return key.missingMessage
           }
       }
       return nil
    }
    
}
