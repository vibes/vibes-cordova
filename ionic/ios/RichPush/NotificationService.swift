//
//  NotificationService.swift
//  VibesPushPlugin
//
//  Created by Moin' Victor on 17/02/2020.
//  Copyright © 2019 Vibes Inc. All rights reserved.
//

import UserNotifications
import MobileCoreServices

@available(iOS 10.0, *)
class NotificationService: UNNotificationServiceExtension {
  let parse = RichPushNotificationParsing()
  
  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    parse.didReceive(request, withContentHandler: contentHandler)
  }
  
  override func serviceExtensionTimeWillExpire() {
    parse.serviceExtensionTimeWillExpire()
  }
}
