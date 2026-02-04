import Foundation
import ConnectisSDK
import UIKit


@objc(AppDelegate_Signicat)
extension CDVAppDelegate {

    @objc(application:continueUserActivity:restorationHandler:)
    public func application(_ application: UIApplication,
                                   continue userActivity: NSUserActivity,
                                   restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        NSLog("[Signicat] continueUserActivity triggered")

        if ConnectisSDK.continueLogin(userActivity: userActivity) {
            NSLog("[Signicat] continueLogin handled the URL")
            return true
        }

        return super.application(application,
                                 continue: userActivity,
                                 restorationHandler: restorationHandler)
    }

    @objc(application:openURL:options:)
    public func application(_ app: UIApplication,
                                   open url: URL,
                                   options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        NSLog("[Signicat] openURL: \(url.absoluteString)")

        return super.application(app, open: url, options: options)
    }
}




