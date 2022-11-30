# vibes-cordova
This plugin exposes the Vibes Mobile SDK to cross-platform applications built using with the Cordova runtime in mind.


## How To Install in an Ionic Cordova App
Run the following to install this plugin into your application.


```
ionic cordova plugin add vibes-cordova --variable VIBES_APP_ID=MY_APP_ID 
--variable VIBES_API_URL=MY_ENVIRONMENT_URL```

```
 * `MY_APP_ID` will be the application id that you obtained from a Vibes Customer Care representative.
 * `MY_ENVIRONMENT_URL` will be the API environment that your application is targetted at. If no value is supplied for VIBES_API_URL, then the default data center URL is used.

 The valid environment urls are 
 1. https://public-api.vibescm.com/mobile_apps - Default non-EU data center
 2. https://public-api.vibescmeurope.com/mobile_apps - EU data center

> Warning:
 _During testing, it is typical to have a different Vibes APPID for your test app and a different one for your production app. We recommend having different bundleId (iOS) or applicationId (Android) for each environment, as using the same value for different environments can cause unexpected behaviour._

> _However, if you find that you can't use separate values for bundleId/applicationId for each Vibes APPID, then make sure you clear the application data when switching between apps for each environment._

## Push Notifications Usage
With the supplied credentials, the plugin initializes itself and calls `registerDevice` and `registerPush` when a Firebase token or APNS token is available within the app. This should be enough to start receiving push notifications. However, these additional functions can be called within your application's own lifecycle after the initialization process.

### registerDevice
This call registers the device with the Vibes environment, returning a promise that either contains a unique `device_id` that stays with the app until it is uninstalled, or an error message if registration fails. **This is invoked automatically at startup, and is not required unless you desire to do so. Calling it multiple times has no negative effect.**

### unregisterDevice
This call unregisters the device with the Vibes environment, as well as stops a device from receiving a push notification. It also disables any data collection or reporting functionality on this device. This call returns a promise, which on success contains no data and on failure contains an error message. To recover from this you need to invoke both `registerDevice` and `registerPush`.

### registerPush
This call fetches the platform specific token for the device and submits it to the Vibes environment, which it can then use to target this device. This call returns a promise, which on success contains no data and on failure contains an error message. 

> For Android, this is invoked automatically at startup of application, and is not required unless you desire to do so.

> For iOS, you will need to manually call `vibes.registerPush()` from the lifecycle point of entry of your landing page inside the ionic project. Depending on your ionic version, this could either be at `ngOnInit`(for ionic v4+) or `ionViewDidLoad` (for ionic 3 and below). This should show push notifications permissions alert dialog, which once granted, will trigger registerPush call on the Vibes SDK with the APNS push token.

```js
import { Vibes } from '@ionic-native/vibes/ngx';
...
// inside ngOnInit or ionViewDidLoad
if (this.platform.is('ios')) {
    this.vibes.registerPush()
    .then(() => {
      this.registeredPush = true;
    })
    .catch((errorMsg: any) => {
      console.log(errorMsg);
    });
}
...
```

### unregisterPush
This call notifies the Vibes environment not to send any more push notifications to this device.  This call returns a promise, which on success contains no data and on failure contains an error message. 

### getVibesDeviceInfo
This call returns a json payload containing the `device_id` and `push_token`  which identifies an installed instance of the app. This call returns a promise with the json payload on success and on failure contains an error message. The payload looks like below.

```
{
    'device_id': 'vXJ6f67XfnH/OYWskzUakSczrQ8=',
    'push_token': 'eAY6g9q3raJ4P03wNdSWC5MOW1EfxoomWNXsPhi7T6Q9yAqmxqn0sLEUjLL1Ib0LCH3nKQWBXdxapQ5LgbHu+g==',
}
```

### getPerson
This call returns a json payload identifying the Vibes person as documented [here](https://developer.vibes.com/display/APIs/Person). The promise returns an error message on failure. The payload looks like below.

```
{
    'person_key': 'wguW2MYXdIqvHBYCF2DNJ',
    'mdn': '+1234567891',
    'external_person_id': 'user@vibes.com',
}
```

### associatePerson
This call associates the [Person](https://developer.vibes.com/display/APIs/Person) record of this device with an external identifer used to identify this user. This call accepts the external identifier, and the promise completes with no data, or fails with an error message.  

### onNotificationOpened
This call enables the application developer to subscribe to be notified whenever all forms of push notifications are received within the application, with the full message json payload returned. 

 **The json payload may look like below for an Android app**

```json
{  
   "message_uid":"d4799f7e-442e-45e6-a2d7-e7a82785333a",
   "body":"Test Message",
   "title":"Test Message",
   ...
}
```

 **The json payload may look like below for an iOS app**

```json
{  
    "aps":{ 
      "alert":{ 
         "title":"Test Message",
         "body":"Test Message",
      },
      "badge":1,
      "content-available":1,
      "mutable-content":1
   }
   ...
}
```

## Usage in Ionic Framework
This plugin can be used as is within an Ionic application. However, it is preferred to use the `@ionic-native/vibes` wrapper.

### Installation

```
npm install @ionic-native/vibes
```

#### Usage (Ionic Wrapper)
```js
import { Vibes } from '@ionic-native/vibes/ngx';
```

### Advance Push Setup
The Vibes Push SDK supports many rich push messaging features, but some of them require the existence of specific files at locations within your Ionic application to be auto-detected by the SDK, or the entry of specific instructions in your config files. Ionic provides [hooks](https://forum.ionicframework.com/t/adding-build-scripts-using-hooks-folder/68673), which can be invoked during the build process to copy resources, modify files etc before and after the build process. To take advantage of these hooks, do the following.

### Android
* Copy our script file `copy-android-resources.js` in the **ionic/android** folder in this repo into your own project, preferrably in a `scripts` folder.
*  Add this to your `ionic.config.json` file
```
"hooks": {
    "build:before": "./scripts/copy-android-resources.js"
  }
```
* Create a folder called `/native/android`
* Place your small notification icon drawble in this folder, with the name of each drawable being **ic_stat_vibes_notif_icon.png**
* To support playing sound when a notification is received, place your sound files in the `raw` folder. You can reference that name on the Vibes Campaign Manager UI when sending a push with sound.
* You may use this `native/android` folder to place any other drawables into the application's resources directory, as the hook will copy everything in that folder over into the appropriate folders in `platforms/android` before building the app.

*Further documentation on advanced Push setup and capabilities in Android are available in the native Android SDK documentation [here](https://developer.vibes.com/display/APIs/Integrating+the+Android+Push+Notifications+SDK)*

### iOS
* Copy our script files in the **ionic/ios** folder in this repo into your own project, preferrably in a `scripts` folder.
*  Add this to your `config.xml` file 
```
   <hook src="scripts/ios-add-rich-push.js" type="after_prepare" />

```
* Edit the `ios-add-rich-push.js` and make sure the values for your environment, certificate and app details match yours.
* Notice that this script expects a `native/ios` folder, which should contain the `NotificationContentExtension` and `RichPush` folders from our **ionic/ios** folder above.
* Notice that it also contains a reference to `vibes_custom.wav` as a sound file. You should replace that with the name of your own sound file placed inside the `RichPush` folder, and reference that name on the Vibes Campaign Manager UI when sending a push with sound

*Further documentation on advanced Push setup and capabilities in iOS are available in the native iOS SDK documentation [here](https://developer.vibes.com/display/APIs/Integrating+the+iOS+Push+Notifications+SDK)*


## Inbox Support
This SDK also supports interaction with inbox messages. The following actions are available for inbox message support.

### fetchInboxMessages
This call returns a JSON array of inbox messages that have been received for this person. The promise returns on success with the array of inbox messages, or an error message when there's a failure. The array of fetched inbox messages should like like below.

```
[
  {
    
    "content": "Content here",
    "created_at": "Jun 16, 2020 6:26:52 PM",
    "expires_at": "Sep 14, 2020 12:00:00 AM",
    "message_uid": "a62b9c70-3b50-40c0-aaf5-9d55c0149e7c",
    "read": false,
    "subject": "Subject here",
    "collapse_key": "vibes-acee3b99-10c1-4dd5-b0e5-1589296ba3a2",
    "apprefdata": {
      "personUid": "83497970-280e-4cc8-92c3-e699c3db0738",
      "activityUid": "acee3b99-10c1-4dd5-b0e5-1589296ba3a2",
      "vibesDeviceId": "32515f9b-f722-4914-9afc-c734790e5789",
      "flightUid": "f76cd0c9-6245-4ea1-ae36-0b5a13b8fba5",
      "deviceUid": "7e0d100e-c549-4d0d-a28f-3f7336c04f3e",
      "activityType": "Broadcast",
      "last_opened_at": "2020-06-16T18:25:55Z"
    }
  },
  {
    
    "content": "This is the content",
    "created_at": "Jun 16, 2020 6:26:20 PM",
    "expires_at": "Sep 14, 2020 12:00:00 AM",
    "message_uid": "3407658c-85d2-439c-9c6d-2b642ef78761",
    "read": false,
    "subject": "This is the message",
    "collapse_key": "vibes-c9ae6ba9-8041-437d-9521-c3db803c19ce",
    "apprefdata": {
      "personUid": "83497970-280e-4cc8-92c3-e699c3db0738",
      "activityUid": "c9ae6ba9-8041-437d-9521-c3db803c19ce",
      "vibesDeviceId": "32515f9b-f722-4914-9afc-c734790e5789",
      "flightUid": "bcfe6100-516a-484f-84cb-60686e216041",
      "deviceUid": "7e0d100e-c549-4d0d-a28f-3f7336c04f3e",
      "activityType": "Broadcast",
      "last_opened_at": "2020-06-16T18:25:55Z"
    },
  }
]
```

### fetchInboxMessage
This call fetches a single inbox message based on the `message_uid` supplied. This is ideal for cases when a push message is linked to an inbox message. It returns a promise, which contains the inbox message on success, or an error message on failure. Note that the `message_uid` is required to invoke this call.

```
{
    "collapse_key": "vibes-acee3b99-10c1-4dd5-b0e5-1589296ba3a2",
    "content": "Content here",
    "created_at": "Jun 16, 2020 6:26:52 PM",
    "expires_at": "Sep 14, 2020 12:00:00 AM",
    "message_uid": "a62b9c70-3b50-40c0-aaf5-9d55c0149e7c",
    "read": false,
    "subject": "Subject here"
    "apprefdata": {
      "personUid": "83497970-280e-4cc8-92c3-e699c3db0738",
      "activityUid": "acee3b99-10c1-4dd5-b0e5-1589296ba3a2",
      "vibesDeviceId": "32515f9b-f722-4914-9afc-c734790e5789",
      "flightUid": "f76cd0c9-6245-4ea1-ae36-0b5a13b8fba5",
      "deviceUid": "7e0d100e-c549-4d0d-a28f-3f7336c04f3e",
      "activityType": "Broadcast",
      "last_opened_at": "2020-06-16T18:25:55Z"
    }
  }
```

### expireInboxMessage
This call is used to mark a message for expiry. The call requires a `message_uid`, and an optional date of expiry. If the date is not supplied, the current date will be used, which will automatically mark the message as expired immediately. The promise returns with the updated json payload of the expired message, or an error message if there's a failure. Note that the `message_uid` is required to invoke this call.

### markInboxMessageAsRead
This call is used to mark a message as read. The call requires a `message_uid`. The promise returns with the updated json payload of showing the `read` field set to true, or an error message if there's a failure. Note that the `message_uid` is required to invoke this call.

### onInboxMessageOpen
This call generates an event showing that the inbox message has been opened. The call requires the full message that has been viewed to be passed as a stringified JSON. The promise returns with no data on success, or an error message on failure.
