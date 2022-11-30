//
//  NotificationViewController.swift
//  VibesPushPlugin
//
//  Created by Moin' Victor on 17/02/2020.
//  Copyright © 2019 Vibes Inc. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    @IBOutlet var subTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body + ""
        self.subTitle?.text = "This a category test push notification"
    }
}
