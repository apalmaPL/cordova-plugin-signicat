import Foundation
import ConnectisSDK

@objc(SignicatPlugin)
class SignicatPlugin: CDVPlugin {

    private var callbackId: String?

    @objc(login:)
    func login(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId

        guard let config = command.arguments.first as? [String: Any] else {
            sendError("Invalid config", command.callbackId)
            return
        }
        // Extract parameters
        let issuer = config["issuer"] as? String ?? ""
        let clientId = config["clientId"] as? String ?? ""
        let redirectUri = config["redirectUri"] as? String ?? ""
        let scopes = config["scopes"] as? String
        let brokerAppAcs = config["brokerAppAcs"] as? String
        let brokerDigidAppAcs = config["brokerDigidAppAcs"] as? String
        let loginFlowStr = config["loginFlow"] as? String ?? "WEB"
        let loginFlow: LoginFlow = (loginFlowStr == "APP_TO_APP") ? .appToApp : .web
        let allowDeviceAuth = config["allowDeviceAuthentication"] as? Bool ?? false

        // Build SDK configuration
        var sdkConfig = ConnectisSDKConfiguration(
            issuer: issuer,
            clientID: clientId,
            redirectURI: redirectUri,
            scopes: scopes,
            brokerAppAcs: brokerAppAcs,
            brokerDigidAppAcs: brokerDigidAppAcs,
            loginFlow: loginFlow
        )
        sdkConfig.allowDeviceAuthentication = allowDeviceAuth

        // Call login
        ConnectisSDK.logIn(
            sdkConfiguration: sdkConfig,
            caller: self.viewController,
            delegate: self,
            allowDeviceAuthentication: allowDeviceAuth,
            errorResponseDelegate: self
        )
    }

    @objc(enableDeviceAuth:)
    func enableDeviceAuth(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        ConnectisSDK.enableDeviceAuthentication()
        sendOK("deviceAuthEnabled")
    }

    @objc(disableDeviceAuth:)
    func disableDeviceAuth(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        ConnectisSDK.disableDeviceAuthentication()
        sendOK("deviceAuthDisabled")
    }

    @objc(getAccessToken:)
    func getAccessToken(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        ConnectisSDK.getOpenIdAccessToken { token, error in
            if let t = token {
                self.sendOK(t)
            } else {
                self.sendError(error?.localizedDescription ?? "Unknown error", command.callbackId)
            }
        }
    }

    // MARK: - Helper for Cordova
    private func sendOK(_ message: Any) {
        guard let cb = callbackId else { return }
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: message)
        commandDelegate.send(result, callbackId: cb)
    }

    private func sendError(_ msg: String, _ callbackId: String) {
        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg)
        commandDelegate.send(result, callbackId: callbackId)
    }
}

// MARK: - Delegates
extension SignicatPlugin: AuthenticationResponseDelegate {
    func authenticationSucceeded(response: ConnectisAuthenticationResponse) {
        var res: [String: Any] = [:]
        res["issuer"] = response.issuer
        res["accessToken"] = response.accessToken
        res["idToken"] = response.idToken
        res["refreshToken"] = response.refreshToken
        sendOK(res)
    }
}

extension SignicatPlugin: ErrorResponseDelegate {
    func authenticationFailed(error: Error) {
        sendError(error.localizedDescription, self.callbackId ?? "")
    }
}
