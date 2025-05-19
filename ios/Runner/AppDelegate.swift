import UIKit
import Flutter
import UserNotifications
import CleverTapSDK
import CleverTapGeofence

import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
            
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
                // App launched from killed state by tapping push
                handlePushPayload(userInfo: remoteNotification)
            }
       
        // Initialize CleverTap
        CleverTap.autoIntegrate()
        CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize App Inbox (if needed)
        CleverTap.sharedInstance()?.initializeInbox { success in
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount() ?? 0
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount() ?? 0
            print("Inbox Message: \(messageCount) total, \(unreadCount) unread")
        }
        
        // Set up location manager for geofencing
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Request location permissions
        locationManager.requestAlwaysAuthorization()
        
        // Start CleverTap Geofence monitoring AFTER CleverTap is initialized
        CleverTapGeofence.monitor.start(didFinishLaunchingWithOptions: launchOptions)
        print("CleverTap Geofence Monitoring Started")
        
        // Register for push notifications
        registerForPush()
        
        // Register Push Notification Actions
            let action1 = UNNotificationAction(identifier: "action_1", title: "Back", options: [])
            let category = UNNotificationCategory(identifier: "CTNotification", actions: [action1], intentIdentifiers: [], options: [])
            UNUserNotificationCenter.current().setNotificationCategories([category])
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    func handlePushPayload(userInfo: [AnyHashable: Any]) {
        // Extract values from your payload
        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]
        let title = alert?["title"] as? String ?? "Notification"
        let body = alert?["body"] as? String ?? ""
        showAlert(title: title, message: body)
    }

    
    // MARK: - Push Notification Registration
    func registerForPush() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization status: \(status.rawValue)")
        
        // When authorization is granted, we can start geofence monitoring
        if status == .authorizedAlways {
            print("Always location permission granted - geofencing can work in background")
        } else if status == .authorizedWhenInUse {
            print("When in use location permission granted - geofencing limited to foreground")
            // You might want to prompt user for Always permission again with explanation
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region: \(region?.identifier ?? "unknown") with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    
    // Called when the app fails to register for remote (push) notifications
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("Failed to register for remote notifications: %@", error.localizedDescription)
      }
      // Called when the app successfully registers for remote notifications and receives a device token
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("Registered for remote notifications: %@", deviceToken.description)
      }
      // Called when the user taps on a push notification while the app is in the background or terminated
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                    didReceive response: UNNotificationResponse,
                    withCompletionHandler completionHandler: @escaping () -> Void) {
        // Logs the notification payload
        NSLog("Push notification tapped: %@", response.notification.request.content.userInfo)
        // Informs CleverTap that the notification was tapped (for engagement tracking)
        CleverTap.sharedInstance()?.handleNotification(withData: response.notification.request.content.userInfo)
        // Must call the completion handler
        completionHandler()
      }
      // Called when a push notification is received while the app is in the foreground
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                    willPresent notification: UNNotification,
                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Logs the notification payload received in foreground
        
        
                let userInfo = notification.request.content.userInfo
                let title = notification.request.content.title
                let body = notification.request.content.body
                // Show alert manually (optional)
                showAlert(title: title, message: body)
        
        
        
        NSLog("Push received while app is in foreground: %@", notification.request.content.userInfo)
        // Informs CleverTap that the notification was viewed (only works when app is in foreground)
        CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: notification.request.content.userInfo)
        // Tells iOS to present the notification with alert, sound, and badge even in foreground
        completionHandler([.badge, .sound, .alert])
      }
      // Called when a remote push notification is received in the background (silent push or content-available)
    override func application(_ application: UIApplication,
               didReceiveRemoteNotification userInfo: [AnyHashable : Any],
               fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

                // Show alert manually (optional)
        
        NSLog("Received background push notification: %@", userInfo)
        
        completionHandler(.noData)
        
        
      }
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                rootVC.present(alert, animated: true)
            }
        }
    }
    
}
