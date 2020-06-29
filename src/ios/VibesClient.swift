//
//  VibesClient.swift
//  VibesPlugin
//
//  Created by Moin' Victor on 17/02/2020.
//  Copyright © 2019 Vibes Inc. All rights reserved.
//

import VibesPush

@objc
class VibesClient: NSObject {
  static let standard = VibesClient()
   
  public let vibes: Vibes
  
  private override init() {
    // ensure we have Vibes app url set in current build config's Info.plist
    guard let appUrl = Configuration.configValue(.vibesAppURL) else {
        fatalError("`\(ConfigKey.vibesAppURL.value())` must be set in plist file of current build configuration")
    }
    // ensure we have Vibes app id set in current build config's Info.plist
    guard let appId = Configuration.configValue(.vibesAppId) else {
        fatalError("`\(ConfigKey.vibesAppId.value())` must be set in plist file of current build configuration")
    }
   
    let config = VibesConfiguration(advertisingId: nil,
                                    apiUrl: appUrl,
                                    logger: nil,
                                    storageType: .USERDEFAULTS)

    Vibes.configure(appId: appId, configuration: config)
    self.vibes = Vibes.shared
  }
}
