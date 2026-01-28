import ConnectisSDK


@UIApplicationMain
class MyCustomAppDelegate: AppDelegate {

    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        NSLog("APPDELEGATE!");
        // Get URL components from the incoming user activity
        return ConnectisSDK.continueLogin(userActivity: userActivity)
    }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        NSLog("APPDELEGATE2!");
        return true
    }

}
