//
//  AppDelegate+notification.h
//  VibesPlugin
//
//  Created by Moin' Victor on 26/02/2020.
//

#import "AppDelegate.h"
@import UserNotifications;

@interface AppDelegate (notification) <UNUserNotificationCenterDelegate>
- (void)application:(UIApplication *_Nonnull )application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *_Nullable)deviceToken;
- (void)application:(UIApplication *_Nonnull)application didFailToRegisterForRemoteNotificationsWithError:(NSError *_Nullable)error;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler;
- (void)pushPluginOnApplicationDidBecomeActive:(UIApplication *_Nonnull)application;
- (void)checkUserHasRemoteNotificationsEnabledWithCompletionHandler:(nonnull void (^)(BOOL))completionHandler;
@end
