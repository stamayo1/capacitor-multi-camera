//
//  MultiCameraSettings.swift
//  Pods
//
//  Created by Sebastian Tamayo lasso on 6/09/25.
//

import UIKit

// MARK: - Public


public enum CameraSource: String {
    case prompt = "PROMPT"
    case camera = "CAMERA"
    case photos = "PHOTOS"
}

public enum CameraDirection: String {
    case rear = "REAR"
    case front = "FRONT"
}

public enum CameraResultType: String {
    case base64
    case uri
    case dataUrl = "dataUrl"
}

public struct CameraSettings {
    var source : CameraSource = CameraSource.prompt
    var direction : CameraDirection = CameraDirection.rear
    var resultType : CameraResultType = CameraResultType.uri
    var jpegQuality : CGFloat = 1.0
    var userPromptText = CameraPromptText()
    var limit : Int = 0
    
    var width: CGFloat = 0
    var height: CGFloat = 0
    var allowEditing = false
    var shouldResize = false
    var shouldCorrectOrientation = true
    var saveToGallery = false
    var presentationStyle = UIModalPresentationStyle.fullScreen
}

/// It encapsulates the text used in a camera/photo prompt dialog
struct CameraPromptText {
    let title: String
    let photoAction: String
    let cameraAction: String
    let cancelAction: String
    
    init(title: String? = nil, photoAction: String? = nil, cameraAction: String? = nil, cancelAction: String? = nil) {
        self.title = title ?? "Photo"
        self.photoAction = photoAction ?? "From Photos"
        self.cameraAction = cameraAction ?? "Take Picture"
        self.cancelAction = cancelAction ?? "Cancel"
    }
}

// MARK: - Internal


internal enum CameraPermissionType: String, CaseIterable {
    case camera
    case photos
}

/// This enum centralizes and organizes the required `Info.plist` keys
/// for accessing the camera and photo library in iOS applications.
///
/// - Each case corresponds to a mandatory key that must exist in the
///   app's `Info.plist` in order to request camera or photo library
internal enum CameraPropertyListKeys: String, CaseIterable {
    
    case photoLibraryAddUsage = "NSPhotoLibraryAddUsageDescription"
    case photoLibraryUsage = "NSPhotoLibraryUsageDescription"
    case cameraUsage = "NSCameraUsageDescription"
    
    /// Returns the official Apple documentation URL for the specific key.
    var link: String {
        switch self {
        case .photoLibraryAddUsage:
            return "https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW73"
        case .photoLibraryUsage:
            return "https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW17"
        case .cameraUsage:
            return "https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW24"
        }
    }
    
    ///   Generates a warning message indicating that the key is missing from `Info.plist`,  and provides a link to learn more.
    var missingMessage: String {
        return "You are missing \(self.rawValue) in your Info.plist file." +
            " Camera will not function without it. Learn more: \(self.link)"
    }
}



/// This enum centralizes and organizes the Error message
internal enum ErrorHandled: String, CaseIterable {
    
    case userCancelled = "PC100"
    
    /// Returns the official Apple documentation URL for the specific key.
    var message: String {
        switch self {
        case .userCancelled:
            return "USER_CANCELLED_PROCESS"
        }
    }
    
    var missingMessage: String {
        return "\(self.rawValue) - \(self.message)"
    }
}
