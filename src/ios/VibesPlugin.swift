//
//  VibesPlugin.swift
//  VibesPlugin
//
//  Created by Moin' Victor on 17/02/2020.
//  Copyright © 2019 Vibes Inc. All rights reserved.
//
import VibesPush
import UserNotifications

// MARK: - In-app notifications

extension Notification.Name {
    /// sent when push notification register succeeds
    static let didRegisterForRemoteNotificationsWithDeviceToken = Notification.Name("UIApplicationDidRegisterForRemoteNotificationsWithDeviceToken")
    /// sent when push notifications register fails
    static let didFailToRegisterForRemoteNotificationsWithError = Notification.Name("UIApplicationDidFailToRegisterForRemoteNotificationsWithError")
    /// sent when push notifications is received
    static let didReceiveRemoteNotification = Notification.Name("UIApplicationDidReceiveRemoteNotification")
}

@objc(VibesPlugin)
class VibesPlugin: CDVPlugin {
    var associatePersonCallbackId: String?
    var registerDeviceCallbackId: String?
    var registerPushCallbackId: String?
    var onInboxMessageOpenCallbackId: String?
    var fetchInboxMessagesCallbackId: String?
    var markInboxMessageAsExpiredCallbackId: String?
    var unregisterPushCallbackId: String?
    var unregisterDeviceCallbackId: String?
    var markInboxMessageAsReadCallbackId: String?
    var fetchSingleInboxMessageCallbackId: String?
    static var notificationCallbackId: String?

    /// Get vibes device id, or nil if device not registered
    public class var vibesDeviceId: String? {
        return UserDefaults.vibesDeviceId
    }

    /// Checks if this device is registered with Vibes platform
    public class var isDeviceRegistered: Bool {
        return VibesClient.standard.vibes.isDeviceRegistered()
    }

    /// We override this to do our SDK initialization
    public override func pluginInitialize() {
        super.pluginInitialize()
        let vibes = VibesClient.standard.vibes
        vibes.set(delegate: self)
        doRegisterDevice()
        // listen to didRegisterForRemoteNotificationsWithDeviceToken(_:)
        NotificationCenter.default.addObserver(self, selector: #selector(didRegisterForRemoteNotificationsWithDeviceToken(_:)), name: Notification.Name.didRegisterForRemoteNotificationsWithDeviceToken, object: nil)
        // listen to didFailToRegisterForRemoteNotificationsWithError(_:)
        NotificationCenter.default.addObserver(self, selector: #selector(didFailToRegisterForRemoteNotificationsWithError), name: Notification.Name.didFailToRegisterForRemoteNotificationsWithError, object: nil)
        // listen to didReceiveRemoteNotification(_:)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveRemoteNotification), name: Notification.Name.didReceiveRemoteNotification, object: nil)
    }

    @objc func didRegisterForRemoteNotificationsWithDeviceToken(_ notification: Notification) {
        print("didRegisterForRemoteNotificationsWithDeviceToken: \(String(describing: notification.userInfo))")
        if let deviceToken = notification.userInfo?["token"] as? Data {
            let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("---------->>>>>>>>>>>didRegisterForRemoteNotificationsWithDeviceToken: \(deviceTokenString)")
            UserDefaults.apnsDeviceToken = deviceTokenString
            let vibes = VibesClient.standard.vibes
            vibes.setPushToken(fromData: deviceToken)
        }
    }

    @objc func didFailToRegisterForRemoteNotificationsWithError(_ notification: Notification) {
        print("didFailToRegisterForRemoteNotificationsWithError: \(String(describing: notification.userInfo))")
        if let error = notification.userInfo?["error"] as? NSError {
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: [error.localizedDescription]
            )
            if let callbackId = registerPushCallbackId {
                commandDelegate!.send(
                    pluginResult,
                    callbackId: callbackId
                )
            }
        }
    }

    @objc func didReceiveRemoteNotification(_ notification: Notification) {
        print("didReceiveRemoteNotification: \(String(describing: notification.object))")
        if let userInfo = notification.object as? [AnyHashable: Any] {
            var pluginResult: CDVPluginResult?
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
                // here "jsonData" is the dictionary encoded in JSON data

                let jsonString = String(data: jsonData, encoding: .utf8)
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: [jsonString as Any]
                )
                pluginResult?.setKeepCallbackAs(true)
            } catch {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: ["JSON Encoding Error"]
                )
            }
            commandDelegate!.send(
                pluginResult,
                callbackId: VibesPlugin.notificationCallbackId
            )
            let vibes = VibesClient.standard.vibes
            vibes.receivedPush(with: userInfo, at: Date())
        }
    }

    // MARK: Register device

    /// Calls register device on Vibes SDK
    func doRegisterDevice() {
        let vibes = VibesClient.standard.vibes
        vibes.registerDevice()
    }

    /// Just Requests Push Authorization
    func doRequestPushAuthorization() {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    let pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: [error.localizedDescription]
                    )
                    if let callbackId = self.registerPushCallbackId {
                        self.commandDelegate!.send(
                            pluginResult,
                            callbackId: callbackId
                        )
                    }
                    print("registerPush: requestAuthorization Failed: \(error)")
                    return
                }
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        } else {
            let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        }
    }

    @objc(registerPush:)
    public func registerPush(command: CDVInvokedUrlCommand) {
        registerPushCallbackId = command.callbackId
        doRequestPushAuthorization()
    }

    @objc(unregisterPush:)
    public func unregisterPush(command: CDVInvokedUrlCommand) {
        unregisterPushCallbackId = command.callbackId
        let vibes = VibesClient.standard.vibes
        vibes.unregisterPush()
    }

    @objc(registerDevice:)
    public func registerDevice(command: CDVInvokedUrlCommand) {
        registerDeviceCallbackId = command.callbackId
        doRegisterDevice()
    }

    // MARK: unregister device

    /// Calls unregister device on Vibes SDK
    func doUnregisterDevice() {
        let vibes = VibesClient.standard.vibes
        vibes.unregisterDevice()
    }

    @objc(unregisterDevice:)
    public func unregisterDevice(command: CDVInvokedUrlCommand) {
        unregisterDeviceCallbackId = command.callbackId
        doUnregisterDevice()
    }

    /// Sends onNotificationOpened with the notification payload back to ionic app
    @objc(onNotificationOpened:)
    public func onNotificationOpened(command: CDVInvokedUrlCommand) {
        VibesPlugin.notificationCallbackId = command.callbackId
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK
        )
        pluginResult?.setKeepCallbackAs(true)
        commandDelegate!.send(
            pluginResult,
            callbackId: VibesPlugin.notificationCallbackId
        )
    }

    // MARK: get device info

    /// Calls getDeviceInfo in vibes SDK
    @objc(getVibesDeviceInfo:)
    public func getVibesDeviceInfo(command: CDVInvokedUrlCommand) {
        let vibesDeviceInfoCallbackId = command.callbackId
        var deviceInfo = ["device_id": UserDefaults.vibesDeviceId]
        if UserDefaults.pushRegistered {
            deviceInfo["push_token"] = VibesClient.standard.vibes.pushToken
        }
        var pluginResult: CDVPluginResult?
        do {
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: [try deviceInfo.toJSONString() as Any]
            )
        } catch {
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: ["JSON Encoding Error"]
            )
        }

        if let callbackId = vibesDeviceInfoCallbackId {
            commandDelegate!.send(
                pluginResult,
                callbackId: callbackId
            )
        }
    }

    // MARK: Get person

    /// Calls getPerson in Vibes SDK
    @objc(getPerson:)
    public func getPerson(command: CDVInvokedUrlCommand) {
        let vibesGetPersonCallbackId = command.callbackId
        let vibes = VibesClient.standard.vibes
        vibes.getPerson { person, error in
            var pluginResult: CDVPluginResult?
            if let error = error {
                print("getPerson Error: \(error)")
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: [error.localizedDescription]
                )
            } else {
                do {
                    let personDict = ["person_key": person?.personKey,
                                      "external_person_id": person?.externalPersonId,
                                      "mdn": person?.mdn]
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: [try personDict.toJSONString() as Any]
                    )
                } catch {
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: ["JSON Encoding Error"]
                    )
                }
            }

            if let callbackId = vibesGetPersonCallbackId {
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: callbackId
                )
            }
        }
    }

    // MARK: associatePerson

    /// Calls associatePerson in Vibes SDK
    @objc(associatePerson:)
    public func associatePerson(command: CDVInvokedUrlCommand) {
        associatePersonCallbackId = command.callbackId
        if let externalPersonId: String = command.arguments[0] as? String,
            externalPersonId != "" {
            let vibes = VibesClient.standard.vibes
            vibes.associatePerson(externalPersonId: externalPersonId)
        } else {
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: ["external Person ID parameter expected!"]
            )
            if let callbackId = associatePersonCallbackId {
                commandDelegate!.send(
                    pluginResult,
                    callbackId: callbackId
                )
            }
        }
    }

    // MARK: Inbox Messages

    /// Calls fetchInboxMessages in Vibes SDK
    @objc(fetchInboxMessages:)
    public func fetchInboxMessages(command: CDVInvokedUrlCommand) {
        fetchInboxMessagesCallbackId = command.callbackId
        let vibes = VibesClient.standard.vibes
        vibes.fetchInboxMessages { inboxMessages, error in
            var pluginResult: CDVPluginResult?
            if let error = error {
                print("fetchInboxMessages Error: \(error)")
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: [error.localizedDescription]
                )
            } else {
                do {
                    let inboxMessagesJson = try JSONSerialization.data(withJSONObject: self.toDictionaryArray(inboxMessages: inboxMessages),
                                                                       options: [])

                    let inboxMesagesString = String(data: inboxMessagesJson,
                                                    encoding: String.Encoding.utf8)
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: [inboxMesagesString as Any]
                    )
                } catch {
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: ["JSON Encoding Error"]
                    )
                }
            }

            if let callbackId = self.fetchInboxMessagesCallbackId {
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: callbackId
                )
            }
        }
    }

    /// Calls expireInboxMessage in Vibes SDK
    @objc(expireInboxMessage:)
    public func expireInboxMessage(command: CDVInvokedUrlCommand) {
        markInboxMessageAsExpiredCallbackId = command.callbackId

        let dateFormatter = Formatter.iso8601
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        var formattedDate = Date()

        if let messageId: String = command.arguments[0] as? String,
            messageId != "" {
            if let date: String = command.arguments[1] as? String,
                date != "" {
                formattedDate = dateFormatter.date(from: date) ?? Date()
            } else {
                formattedDate = Date()
            }
            let vibes = VibesClient.standard.vibes
            vibes.expireInboxMessage(messageUID: messageId, date: formattedDate, { _, error in
                var pluginResult: CDVPluginResult!
                if let error = error {
                    print("markInboxMessageAsExpired error: \(error)")
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: [error.localizedDescription]
                    )
                } else {
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK
                    )
                }
                if let callbackId = self.markInboxMessageAsExpiredCallbackId {
                    self.commandDelegate!.send(
                        pluginResult,
                        callbackId: callbackId
                    )
                }
            })
        } else {
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: ["message ID parameter expected!"]
            )
            if let callbackId = markInboxMessageAsExpiredCallbackId {
                commandDelegate!.send(
                    pluginResult,
                    callbackId: callbackId
                )
            }
        }
    }

    /// Calls fetchInboxMessage in Vibes SDK
    @objc(fetchInboxMessage:)
    public func fetchInboxMessage(command: CDVInvokedUrlCommand) {
        fetchSingleInboxMessageCallbackId = command.callbackId
        if let messageId: String = command.arguments[0] as? String,
            messageId != "" {
            let vibes = VibesClient.standard.vibes
            vibes.fetchInboxMessage(messageUID: messageId, { inboxMsg, error in
                var pluginResult: CDVPluginResult!
                if let error = error {
                    print("fetchInboxMessage error: \(error)")
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: [error.localizedDescription]
                    )
                } else {
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: [inboxMsg?.jsonString as Any]
                    )
                }
                if let callbackId = self.fetchSingleInboxMessageCallbackId {
                    self.commandDelegate!.send(
                        pluginResult,
                        callbackId: callbackId
                    )
                }
            })
        } else {
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: ["message ID parameter expected!"]
            )
            if let callbackId = fetchSingleInboxMessageCallbackId {
                commandDelegate!.send(
                    pluginResult,
                    callbackId: callbackId
                )
            }
        }
    }

    /// Calls markInboxMessageAsRead in Vibes SDK
    @objc(markInboxMessageAsRead:)
    public func markInboxMessageAsRead(command: CDVInvokedUrlCommand) {
        markInboxMessageAsReadCallbackId = command.callbackId
        if let messageId: String = command.arguments[0] as? String,
            messageId != "" {
            let vibes = VibesClient.standard.vibes
            vibes.markInboxMessageAsRead(messageUID: messageId, { _, error in
                var pluginResult: CDVPluginResult!
                if let error = error {
                    print("markInboxMessageAsRead error: \(error)")
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAs: [error.localizedDescription]
                    )
                } else {
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK
                    )
                }
                if let callbackId = self.markInboxMessageAsReadCallbackId {
                    self.commandDelegate!.send(
                        pluginResult,
                        callbackId: callbackId
                    )
                }
            })
        } else {
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: ["message ID parameter expected!"]
            )
            if let callbackId = markInboxMessageAsReadCallbackId {
                commandDelegate!.send(
                    pluginResult,
                    callbackId: callbackId
                )
            }
        }
    }

    func toDictionaryArray(inboxMessages: [InboxMessage]) -> [VibesJSONDictionary] {
        var array = [VibesJSONDictionary]()
        for inbox in inboxMessages {
            array.append(inbox.encodeJSON())
        }
        return array
    }
    
    /// Calls expireInboxMessage in Vibes SDK
    @objc(onInboxMessageOpen:)
    public func onInboxMessageOpen(command: CDVInvokedUrlCommand) {
        onInboxMessageOpenCallbackId = command.callbackId

        var pluginResult: CDVPluginResult!
        if let inboxMessageString: String = command.arguments[0] as? String,
            inboxMessageString != "" {
            if let inboxMessagesDict = VibesPlugin.convertStringToDictionary(json: inboxMessageString),
                let inboxMessage = InboxMessage(attributes: inboxMessagesDict) {
                let vibes = VibesClient.standard.vibes
                vibes.onInboxMessageOpen(inboxMessage: inboxMessage)
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK
                )
            } else {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: ["Failed to generate InboxMessage!"]
                )
            }
        } else {
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: ["inboxMessage parameter expected!"]
            )
        }
        if let callbackId = onInboxMessageOpenCallbackId {
            commandDelegate!.send(
                pluginResult,
                callbackId: callbackId
            )
        }        
    }

    static func convertStringToDictionary(json: String) -> [String: AnyObject]? {
        var dictionary: [String: AnyObject]?
        if let data = json.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                if let myDictionary = dictionary {
                    return myDictionary
                }
            } catch let error as NSError {
                print("Something whent wrong when converting to dict: \(error)")
            }
        }
        return nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.didRegisterForRemoteNotificationsWithDeviceToken, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.didFailToRegisterForRemoteNotificationsWithError, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.didReceiveRemoteNotification, object: nil)
    }
}

// MARK: VibesAPIDelegate

extension VibesPlugin: VibesAPIDelegate {
    func didRegisterDevice(deviceId: String?, error: Error?) {
        var pluginResult: CDVPluginResult!
        if let error = error {
            print("didRegisterDevice Error: \(error)")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: [error.localizedDescription]
            )
        } else {
            print("---------->>>>>>>>>>>Register Device success ✅:")
            UserDefaults.vibesDeviceId = deviceId
            do {
                let deviceIdDict = ["device_id": deviceId]
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: [try deviceIdDict.toJSONString() as Any]
                )
            } catch {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: ["JSON Encoding Error"]
                )
            }
        }
        if let callbackId = registerDeviceCallbackId {
            commandDelegate!.send(
                pluginResult,
                callbackId: callbackId
            )
        }
    }

    func didUnregisterDevice(error: Error?) {
        var pluginResult: CDVPluginResult!
        if let error = error {
            print("didUnregisterDevice Error: \(error)")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: [error.localizedDescription]
            )
        } else {
            print("---------->>>>>>>>>>> Unregister Device success ✅:")
            UserDefaults.vibesDeviceId = nil
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
        }
        if let callbackId = unregisterDeviceCallbackId {
            commandDelegate!.send(
                pluginResult,
                callbackId: callbackId
            )
        }
    }

    func didRegisterPush(error: Error?) {
        var pluginResult: CDVPluginResult!
        if let error = error {
            print("didRegisterPush Error: \(error)")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: [error.localizedDescription]
            )
            UserDefaults.pushRegistered = false
        } else {
            UserDefaults.pushRegistered = true
            print("---------->>>>>>>>>>>Register Push success ✅:")
            do {
                let pushInfo = ["push_token": VibesClient.standard.vibes.pushToken]
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: [try pushInfo.toJSONString() as Any]
                )
            } catch {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: ["JSON Encoding Error"]
                )
            }
        }
        if let callbackId = registerPushCallbackId {
            commandDelegate!.send(
                pluginResult,
                callbackId: callbackId
            )
        }
    }

    func didUnregisterPush(error: Error?) {
        var pluginResult: CDVPluginResult!
        if let error = error {
            print("didUnregisterPush Error: \(error)")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: [error.localizedDescription]
            )
        } else {
            print("---------->>>>>>>>>>>didUnregisterPush success ✅:")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
        }
        if let callbackId = unregisterPushCallbackId {
            commandDelegate!.send(
                pluginResult,
                callbackId: callbackId
            )
        }
    }

    func didAssociatePerson(error: Error?) {
        var pluginResult: CDVPluginResult!
        if let error = error {
            print("didAssociatePerson Error: \(error)")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: [error.localizedDescription]
            )
        } else {
            print("---------->>>>>>>>>>> didAssociatePerson success ✅:")
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
        }
        if let callbackId = associatePersonCallbackId {
            commandDelegate!.send(
                pluginResult,
                callbackId: callbackId
            )
        }
    }
}

extension Dictionary where Key: Encodable, Value: Encodable {
    func toJSONString() throws -> String? {
        let jsonEncoder = JSONEncoder()
        let jsonInfo = try jsonEncoder.encode(self)
        return String(data: jsonInfo, encoding: String.Encoding.utf8)
    }
}

extension InboxMessage {
    func encodeJSON() -> VibesJSONDictionary {
        return [
            "message_uid": messageUID as AnyObject,
            "subject": subject as AnyObject,
            "content": content as AnyObject,
            "detail": detail as AnyObject,
            "expires_at": expiresAt?.iso8601 as AnyObject,
            "created_at": createdAt.iso8601 as AnyObject,
            "collapse_key": collapseKey as AnyObject,
            "images": images as AnyObject,
            "read": read as AnyObject,
            "inbox_custom_data": inboxCustomData as AnyObject,
            "client_app_data": clientAppData as AnyObject,
            "apprefdata": apprefData as AnyObject,
        ] as VibesJSONDictionary
    }
}

extension Date {
    /// An ISO8601-compatible timestamp string for this Date object.
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }

    var iso8601WithUpdatingTimezone: String {
        let formatter = Formatter.iso8601
        formatter.timeZone = TimeZone.autoupdatingCurrent
        return formatter.string(from: self)
    }
}

extension Formatter {
    /// A date formatter for generating ISO8601-compatible timestamp strings.
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()

        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        return formatter
    }()
}

extension UserDefaults {

    private enum Keys {

        static let pushRegistered = "pushRegistered"

    }

    class var pushRegistered: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.pushRegistered)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.pushRegistered)
        }
    }

}
