import Foundation
import ConnectisSDK



@objc(SignicatPlugin)
class SignicatPlugin: CDVPlugin, AuthenticationResponseDelegate {

    private var currentCommand: CDVInvokedUrlCommand?


    @MainActor
    private func showAlert(title: String, message: String) {
        guard let vc = self.viewController else { return }

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }


    @objc(loginAppToApp:)
    @MainActor
    func loginAppToApp(command: CDVInvokedUrlCommand) {

        self.currentCommand = command
/*
        /*Demo app default configuration*/
        let issuer = "https://pkio.broker.ng-test.nl/broker/sp/oidc"
        let clientID = "PRlEjCDjGEzzLimcNOYWnmxY4IWqRHe3"
        let redirectURI = "https://pkio.broker.ng-test.nl/broker/app/redirect/response"
        let appToAppScopes = "openid idp_scoping:https://was-preprod1.digid.nl/saml/idp/metadata_app"
        let brokerDigidAppAcs = "https://pkio.broker.ng-test.nl/broker/authn/digid/digid-app-acs"
        
        /*APalma Signicat SDK - OIDC Client configuration */
        let issuer = "https://preprodbroker.salland.nl/auth/open"
        let clientID = "sandbox-victorious-chess-790"
        let redirectURI = "https://salland-dev.outsystems.app/Adriano_Sandbox/Redirect"
        let appToAppScopes = "openid profile"
        let brokerDigidAppAcs = "https://preprodbroker.salland.nl/broker/authn/digid/acs"

*/
        guard command.arguments.count >= 5,
            let issuer = command.arguments[0] as? String,
            let clientID = command.arguments[1] as? String,
            let redirectURI = command.arguments[2] as? String,
            let appToAppScopes = command.arguments[3] as? String,
            let brokerDigidAppAcs = command.arguments[4] as? String
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
            loginFlow: LoginFlow.APP_TO_APP
        )


        ConnectisSDK.logIn(
            sdkConfiguration: configuration,
            caller: self.viewController,
            delegate: self,
            allowDeviceAuthentication: ConnectisSDK.isDeviceAuthenticationEnabled()
        )
    }


    func handleResponse(authenticationResponse: AuthenticationResponse) {

        guard let command = currentCommand else { return }


        guard let nameId = authenticationResponse.nameIdentifier else {

            if !authenticationResponse.isSuccess {
                let errorMessage = authenticationResponse.error?.localizedDescription ?? "Unknown authentication error"

                let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: "Authentication error: \(errorMessage)"
                )

                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                self.currentCommand = nil
                return
            }

            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Authentication error"
            )

            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            self.currentCommand = nil
            return
        }

        let result: [String: Any] = [
            "nameIdentifier": nameId,
            "isSuccess": authenticationResponse.isSuccess
        ]

        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: result
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


}


