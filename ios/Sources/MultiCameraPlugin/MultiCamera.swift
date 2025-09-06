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
}
