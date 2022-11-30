//
//  Configuration.swift
//  VibesPlugin
//
//  Created by Moin' Victor on 17/02/2020.
//  Copyright © 2019 Vibes Inc. All rights reserved.
//

import Foundation

/// Keys found in Info.plist file
///
/// - appBuildNumber: The app build number
/// - appVersionNumber: The app version number
/// - vibesAppURL: Vibes app url
/// - vibesAppId: Vibes app id
public enum ConfigKey {
  case appBuildNumber
  case appVersionNumber
  case vibesAppURL
  case vibesAppId

  /// Actual string vakue for this enum as used in plist file
  ///
  /// - Returns: The string value
  func value() -> String {
      switch self {
        case .appBuildNumber:
          return "CFBundleShortVersionString"
        case .appVersionNumber:
          return "CFBundleVersion"
        case .vibesAppURL:
          return "VibesAppURL"
        case .vibesAppId:
          return "VibesAppId"
      }
  }
}

/// This struct will load the plist file for current build
public struct Configuration {
    
  fileprivate static var infoDict: [String: Any]  {
    get {
      if let dict = Bundle.main.infoDictionary {
        return dict
      } else {
        fatalError("Plist file not found")
      }
    }
  }
  
  /// Get the config value of a certain config key from current configuration
  ///
  /// - Parameter key: The key to get value for
  /// - Returns: The value or nil if not found
  public static func configValue(_ key: ConfigKey) -> String? {
    return infoDict[key.value()] as? String
  }
}

/// Class that will deal with basic application settings that have been stored in the uesr defaults data store
extension UserDefaults {

    class var vibesDeviceId: String? {
        get { return standard.string(forKey: "vibesDeviceId") }
        set { standard.set(newValue, forKey: "vibesDeviceId") }
    }

    class var apnsDeviceToken: String? {
        get { return standard.string(forKey: "apnsDeviceToken") }
        set { standard.set(newValue, forKey: "apnsDeviceToken") }
    }
}
