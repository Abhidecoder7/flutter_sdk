//
//  NotificationService.swift
//  NotificationService
//
//  Created by Abhishek Vishwakarma on 13/03/25.
//


import UserNotifications
import CleverTapSDK
import CTNotificationService

class NotificationService: CTNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: request.content.userInfo)
        super.didReceive(request, withContentHandler: contentHandler)
        //    }
        //}
        //
        
        //  this is commented because of rich push handel
        //        if let bestAttemptContent = bestAttemptContent {
        //            // Modify the notification content here...
        //            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
        //
        //            contentHandler(bestAttemptContent)
        //
        //        }
        
        //        func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        //                // While running the Application add CleverTap Account ID and Account token in your .plist file
        //
        //                // call to record the Notification viewed
        //
        //            }
        //    }
        
        //    override func serviceExtensionTimeWillExpire() {
        //        // Called just before the extension will be terminated by the system.
        //        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        //        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
        //            contentHandler(bestAttemptContent)
        //        }
        //    }
        
    }
}
