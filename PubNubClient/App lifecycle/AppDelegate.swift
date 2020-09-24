//
//  AppDelegate.swift
//  PubNubClient
//
//  Created by Robert Ryan on 8/26/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import UIKit
import UserNotifications
import PubNub
import os.log

private let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "AppDelegate")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var pubnub = PubNubEventManager.pubnub

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /*
         STEP 1: Ask user for permission to receive push; register with APNs if allowed
         */
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    // You might want to remove this
                    /// or handle errors differently in production
                    assert(error == nil)
                    if granted {
                        DispatchQueue.main.async {
                            os_log(.debug, log: log, "getNotificationSettings: Permissions granted")
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }

            case .authorized, .provisional:
                DispatchQueue.main.async {
                    os_log(.debug, log: log, "getNotificationSettings: Permissions already granted")
                    UIApplication.shared.registerForRemoteNotifications()
                }

            case .denied:
                os_log(.debug, log: log, "getNotificationSettings: We can't use notifications because the user has denied permissions")

            @unknown default:
                os_log(.error, log: log, "getNotificationSettings: Unknown error")
            }
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        /*
         STEP 2: Receive device push token from APNs
         */
        os_log(.debug, log: log, "Received device push token from APNs: %{public}@", deviceToken.hexEncodedString)

        /*
         STEP 3: Is the new device token different than the old device token
         */
        let defaults = UserDefaults.standard
        let oldDeviceToken = defaults.data(forKey: "DeviceToken")

        // if token is different from previous token,
        // then store locally and associate for push on channels with new token
        if oldDeviceToken != deviceToken {
            defaults.set(deviceToken, forKey: "DeviceToken")
            defaults.synchronize()

            if oldDeviceToken != nil {
                pubnub.removeAllPushChannelRegistrations(for: oldDeviceToken!) { result in
                    switch result {
                    case .success(_):
                        os_log(.debug, log: log, "Successful Push Deletion Response")

                    case let .failure(error):
                        os_log(.error, log: log, "Failed Push Deletion Response: %{public}@", error.localizedDescription)
                    }
                }
            }

            /*
             STEP 4: associate push notifications with channels for PubNub
             */

//            pubnub.managePushChannelRegistrations(byRemoving: [], thenAdding: ["conv-1", "alerts.system"], for: deviceToken) { result in
            pubnub.managePushChannelRegistrations(byRemoving: [], thenAdding: ["conv-1"], for: deviceToken) { result in

//            pubnub.modifyAPNSDevicesOnChannels(
//                byRemoving: [],
//                thenAdding: ["conv-1", "alerts.system"],
//                device: deviceToken,
//                on: "com.imidastouch.ios.dev",
//                environment: .
//            ) { result in
                switch result {
                case .success(_):
                    os_log(.debug, log: log, "managePushChannelRegistrations success")

                case let .failure(error):
                    os_log(.error, log: log, "managePushChannelRegistrations failure: %{public}@", error.localizedDescription)
                }
            }
        } else {
            pubnub.listPushChannelRegistrations(for: deviceToken) { result in
                switch result {
                case let .failure(error):
                    os_log(.error, log: log, "listPushChannelRegistrations error: %{public}@", error.localizedDescription)

                case let .success(response):
                    os_log(.debug, log: log, "listPushChannelRegistrations success:")
                    for string in response {
                        os_log(.debug, log: log, "  %{public}@", string)
                    }
                }
            }
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        os_log(.error, log: log, "didFailToRegisterForRemoteNotificationsWithError: %{public}@", error.localizedDescription)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        /*
         STEP 5: provide a means to receive push notifications
         */

        os_log(.debug, log: log, "didReceiveRemoteNotification")

        guard let aps = userInfo["aps"] as? [String: AnyObject] else {
            completionHandler(.failed)
            return
        }

        completionHandler(.noData)
        // you might just do nothing if you do not want to display anything
        // there techniques for displaying silent push Notifications
        // but leaving that to Apple docs for those details
    }
}

// MARK: UISceneSession Lifecycle

extension AppDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// MARK: - UNUserNotificationCenterDelegate

@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    //Called to let your app know which action was selected by the user for a given notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        os_log(.debug, log: log, "userNotificationCenter didReceive")
        completionHandler()
    }

    //Called when a notification is delivered to a foreground app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        os_log(.debug, log: log, "userNotificationCenter willPresent")
        completionHandler([.alert, .badge, .sound])
    }
}
