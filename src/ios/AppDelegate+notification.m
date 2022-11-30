//
//  AppDelegate+notification.m
//  VibesPlugin
//
//  Created by Moin' Victor on 26/02/2020.
//

#import "AppDelegate+notification.h"
#import <objc/runtime.h>

NSString *const pushPluginApplicationDidBecomeActiveNotification = @"pushPluginApplicationDidBecomeActiveNotification";
NSString *const pushPluginApplicationDidRegisterForRemoteNotificationsWithDeviceToken = @"UIApplicationDidRegisterForRemoteNotificationsWithDeviceToken";
NSString *const pushPluginApplicationDidFailToRegisterForRemoteNotificationsWithError = @"UIApplicationDidFailToRegisterForRemoteNotificationsWithError";
NSString *const pushPluginApplicationDidReceiveRemoteNotification = @"UIApplicationDidReceiveRemoteNotification";
@implementation AppDelegate (notification)

// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        // Swizzle VibesPlugin.init
        SEL originalSelector = @selector(init);
        SEL swizzledSelector = @selector(vibesPluginSwizzledInit);

        Method original = class_getInstanceMethod(class, originalSelector);
        Method swizzled = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzled),
                        method_getTypeEncoding(swizzled));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(original),
                                method_getTypeEncoding(original));
        } else {
            method_exchangeImplementations(original, swizzled);
        }

        // Swizzle application:didFinishLaunchingWithOptions
        SEL originalDidFinishSelector = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledDidFinishSelector = @selector(application:swizzledDidFinishLaunchingWithOptions:);
        
        Method originalDidFinish = class_getInstanceMethod(self, originalDidFinishSelector);
        Method swizzledDidFinish = class_getInstanceMethod(self, swizzledDidFinishSelector);
        
        BOOL didAddDidFinishMethod =
        class_addMethod(class,
                        originalDidFinishSelector,
                        method_getImplementation(swizzledDidFinish),
                        method_getTypeEncoding(swizzledDidFinish));

        if (didAddDidFinishMethod) {
            class_replaceMethod(class,
                                swizzledDidFinishSelector,
                                method_getImplementation(originalDidFinish),
                                method_getTypeEncoding(originalDidFinish));
        } else {
            method_exchangeImplementations(originalDidFinish, swizzledDidFinish);
        }
    });
}

- (AppDelegate *)vibesPluginSwizzledInit
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(pushPluginOnApplicationDidBecomeActive:)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];

    // This actually calls the original init method over in AppDelegate. Equivilent to calling super
    // on an overrided method, this is not recursive, although it appears that way. neat huh?
    return [self vibesPluginSwizzledInit];
}

- (BOOL)application:(UIApplication*)application swizzledDidFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    // we check if we have launch options
    if (launchOptions != nil) {
        // check if app is opened from a push notification when the app is closed
        NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo != nil) {
            NSLog(@"opened from a push notification when the app is closed: userInfo->%@", [userInfo objectForKey:@"aps"]);
            
            // the 7.5 sec delay set below is required so we dispatch after Cordova has init
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // notify the plugin that we lauched with notification
                [[NSNotificationCenter defaultCenter] postNotificationName: pushPluginApplicationDidReceiveRemoteNotification object:userInfo userInfo:nil];
            });
            
        } else {
            // opened app without a push notification.
            NSLog(@"opened app without a push notification");
        }
    } else {
        NSLog(@"opened with no launchOptions");
    }
    
    [self application:application swizzledDidFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:deviceToken forKey:@"token"];
    [[NSNotificationCenter defaultCenter] postNotificationName:
    pushPluginApplicationDidRegisterForRemoteNotificationsWithDeviceToken object:nil userInfo:userInfo];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
    [[NSNotificationCenter defaultCenter] postNotificationName:
                           pushPluginApplicationDidFailToRegisterForRemoteNotificationsWithError object:nil userInfo:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    NSLog(@"didReceiveRemoteNotification:fetchCompletionHandler: %@", userInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName: pushPluginApplicationDidReceiveRemoteNotification object:userInfo userInfo:nil];
    //Success
    handler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)checkUserHasRemoteNotificationsEnabledWithCompletionHandler:(nonnull void (^)(BOOL))completionHandler
{
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {

        switch (settings.authorizationStatus)
        {
            case UNAuthorizationStatusDenied:
            case UNAuthorizationStatusNotDetermined:
            case UNAuthorizationStatusProvisional:
                completionHandler(NO);
                break;
            case UNAuthorizationStatusAuthorized:
                completionHandler(YES);
                break;
        }
    }];
}

- (void)pushPluginOnApplicationDidBecomeActive:(NSNotification *)notification {

    NSLog(@"active");

    NSString *firstLaunchKey = @"firstLaunchKey";
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"vibes-plugin-push"];
    if (![defaults boolForKey:firstLaunchKey]) {
        NSLog(@"application first launch: remove badge icon number");
        [defaults setBool:YES forKey:firstLaunchKey];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: -1];
    }

    UIApplication *application = notification.object;
    [application setApplicationIconBadgeNumber: -1];

    [[NSNotificationCenter defaultCenter] postNotificationName:pushPluginApplicationDidBecomeActiveNotification object:nil];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    NSLog(@"userNotificationCenter:willPresentNotification:withCompletionHandler Handle push from foreground" );
    NSDictionary *userInfo = notification.request.content.userInfo;
    [[NSNotificationCenter defaultCenter] postNotificationName:
                           pushPluginApplicationDidReceiveRemoteNotification object:userInfo userInfo:nil];

    completionHandler(UNNotificationPresentationOptionAlert + UNNotificationPresentationOptionBadge + UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler
{
    NSLog(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler" );
    NSLog(@"Push Plugin didReceiveNotificationResponse:withCompletionHandler actionIdentifier %@, notification: %@", response.actionIdentifier,
          response.notification.request.content.userInfo);
    NSMutableDictionary *userInfo = [response.notification.request.content.userInfo mutableCopy];
    NSLog(@"Vibes Push Plugin userInfo %@", userInfo);

    switch ([UIApplication sharedApplication].applicationState) {
        case UIApplicationStateActive:
        {
            completionHandler();
            break;
        }
        case UIApplicationStateInactive:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:
                                  pushPluginApplicationDidReceiveRemoteNotification object:userInfo userInfo:nil];
            completionHandler();
            break;
        }
        case UIApplicationStateBackground:
        {

            // do in main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:
                                       pushPluginApplicationDidReceiveRemoteNotification object:userInfo userInfo:nil];
                 completionHandler();
            });
        }
    }
}

@end
