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

    func sendError(code: String, message: String, callbackId: String) {
        let errorObj: [String: Any] = [
            "code": code,
            "message": message
        ]

        // Convert to JSON string safely
        var jsonString = "{}"
        if JSONSerialization.isValidJSONObject(errorObj),
        let data = try? JSONSerialization.data(withJSONObject: errorObj, options: []) {
            jsonString = String(data: data, encoding: .utf8) ?? "{}"
        }

        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: jsonString
        )

        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    /**
    * Requests an OpenID Connect access token from the Signicat Identity Broker.
    *
    * On iOS the Mobile SDK exposes an API that returns a valid OpenID access
    * token once the user has previously authenticated. This access token
    * represents an OAuth2 authorization credential that you can use to call
    * backend services on behalf of the authenticated user. Treat this token
    * as a secret and never expose it to untrusted components.
    *
    */

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
        sendError(code:"E_ACCESS_TOKEN_EXCEPTION", message:errorMessage, callbackId: self.accessTokenCallbackId)
    }



    /**
    * Initiates the Signicat Identity Broker authentication flow.
    *
    * On iOS the Mobile SDK’s `login` method takes a configuration object
    * containing issuer, client ID, redirect URI and optional scopes.
    * It opens a browser or app-to-app flow depending on configuration,
    * and calls back into delegate methods when complete.
    *
    * The SDK supports:
    *   • A WEB login flow — browser-based authentication with universal links.
    *   • An APP_TO_APP flow — universal linking to an external identity app (Digid).
    *
    * The results are sent asynchronously:
    *   • On success, `handleResponse(...)` receives an AuthenticationResponse.
    *   • On cancel, `onCancel()` is invoked.
    *   • SDK errors are returned via an error handler.
    *
    */

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
            sendError(code:"E_LOGIN_INVALID_ARGS", message:"Missing or invalid parameters", callbackId: command.callbackId)
            return
        }

        let configuration: ConnectisSDKConfiguration
        do {
            configuration = ConnectisSDKConfiguration(
                issuer: issuer,
                clientID: clientID,
                redirectURI: redirectURI,
                scopes: appToAppScopes,
                brokerDigidAppAcs: brokerDigidAppAcs,
                loginFlow: isAppToApp ? LoginFlow.APP_TO_APP : LoginFlow.WEB
            )
        } catch {
            sendError(code:"E_LOGIN_CONFIG", message:"Invalid login configuration: \(error.localizedDescription)", callbackId: command.callbackId)
            return
        }


        ConnectisSDK.logIn(
            sdkConfiguration: configuration,
            caller: self.viewController,
            delegate: self,
            allowDeviceAuthentication: false//ConnectisSDK.isDeviceAuthenticationEnabled()
        )
    }


    func handleResponse(authenticationResponse: AuthenticationResponse) {
        NSLog("loginAppToApp handleResponse");
        guard let command = currentCommand else { return }

        do{
            // Manually build JSON dictionary
            var json: [String: Any] = [
                "isSuccess": authenticationResponse.isSuccess
            ]

            if let error = authenticationResponse.error {
                json["error"] = error
            } else {
                json["error"] = NSNull()
            }

            if let nameId = authenticationResponse.nameIdentifier {
                json["nameIdentifier"] = nameId
            } else {
                json["nameIdentifier"] = NSNull()
            }

            // Convert attributes
            var attributesJson: [[String: Any]] = []
            for attr in authenticationResponse.attributes ?? [] {
                attributesJson.append([
                    "name": attr.name,
                    "value": attr.value
                ])
            }
            json["attributes"] = attributesJson

            // Convert to JSON string safely
            var jsonString = "{}"
            if JSONSerialization.isValidJSONObject(json),
            let data = try? JSONSerialization.data(withJSONObject: json, options: []) {
                jsonString = String(data: data, encoding: .utf8) ?? "{}"
            }

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: jsonString
            )

            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            self.currentCommand = nil
            
        } catch {
            sendError(code:"E_HANDLE_RESPONSE_EXCEPTION", message:"Error handling login response: \(error)", callbackId: command.callbackId)
            return
        }
        
    }



    func onCancel() {
        guard let command = currentCommand else { return }

        sendError(code:"E_LOGIN_CANCELED", message:"User canceled login", callbackId: command.callbackId)

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

