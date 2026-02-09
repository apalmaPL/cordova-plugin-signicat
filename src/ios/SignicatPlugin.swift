import Foundation
import ConnectisSDK
import UIKit



@objc(SignicatPlugin)
class SignicatPlugin: CDVPlugin, AuthenticationResponseDelegate, AccessTokenDelegate  {

    private var currentCommand: CDVInvokedUrlCommand?
    private var accessTokenCallbackId: String?

    
    override func pluginInitialize() {
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(continueUserActivityHandler(_:)),
          name: Notification.Name(rawValue: "UIApplicationContinueUserActivity"),
          object: nil
        )
    }

    @objc(continueUserActivityHandler:) func continueUserActivityHandler(_ notification: NSNotification) {
        let userActivity = notification.object as! NSUserActivity
        if ConnectisSDK.continueLogin(userActivity: userActivity) {
            NSLog("[Signicat] continueLogin handled the URL")
        }
    }

    @objc(getAccessToken:)
    @MainActor
    func getAccessToken(command: CDVInvokedUrlCommand) {

        self.accessTokenCallbackId = command.callbackId

        ConnectisSDK.useAccessToken(
            caller: self.viewController,
            delegate: self
        )

    }

    func handleAccessToken(accessToken: Token) {

        let result = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: accessToken.getValue()
        )
        self.commandDelegate.send(
            result,
            callbackId: self.accessTokenCallbackId
        )

    }

    func onError(errorMessage: String) {

        let result = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: errorMessage
        )
        self.commandDelegate.send(
            result,
            callbackId: self.accessTokenCallbackId
        )

    }


    @objc(loginAppToApp:)
    @MainActor
    func loginAppToApp(command: CDVInvokedUrlCommand) {

        NSLog("loginAppToApp Started");

        self.currentCommand = command

        guard command.arguments.count >= 5,
            let issuer = command.arguments[0] as? String,
            let clientID = command.arguments[1] as? String,
            let redirectURI = command.arguments[2] as? String,
            let appToAppScopes = command.arguments[3] as? String,
            let brokerDigidAppAcs = command.arguments[4] as? String,
            let isAppToApp = command.arguments[5] as? Bool
        else {
            let result = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Missing or invalid parameters"
            )
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }




        let configuration = ConnectisSDKConfiguration(
            issuer: issuer,
            clientID: clientID,
            redirectURI: redirectURI,
            scopes: appToAppScopes,
            brokerDigidAppAcs: brokerDigidAppAcs,
            loginFlow: isAppToApp ? LoginFlow.APP_TO_APP : LoginFlow.WEB
        )


        ConnectisSDK.logIn(
            sdkConfiguration: configuration,
            caller: self.viewController,
            delegate: self,
            allowDeviceAuthentication: false//ConnectisSDK.isDeviceAuthenticationEnabled()
        )
    }


    func handleResponse(authenticationResponse: AuthenticationResponse) {


        guard let command = currentCommand else { return }


        let responseStr = String(describing: authenticationResponse)


        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: responseStr
        )

        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        self.currentCommand = nil
    }


    func onCancel() {

        guard let command = currentCommand else { return }

        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: "Authentication was canceled!"
        )

        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        self.currentCommand = nil
    }


    func showMessage(messageIn: String){

        let toastController: UIAlertController =
            UIAlertController(
            title: "WOOOOW!",
            message: messageIn,
            preferredStyle: .alert
            )

        toastController.addAction(UIAlertAction(
            title: "OK", 
            style: .default, 
            handler: { _ in 
                print("OK tap") 
            }))

        self.viewController?.present(
            toastController,
            animated: true,
            completion: nil
        )

    }

}

