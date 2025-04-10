import UIKit
import Flutter
import UserNotifications
import CleverTapSDK
import CleverTapGeofence
import CoreLocation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
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
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
}
