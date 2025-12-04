import Foundation
import ConnectisSDK


@objc(SignicatPlugin)
class SignicatPlugin: CDVPlugin, AuthenticationResponseDelegate {

    private var currentCommand: CDVInvokedUrlCommand?

    @objc(loginAppToApp:)
    func loginAppToApp(command: CDVInvokedUrlCommand) {

        self.currentCommand = command

        let issuer = "https://pkio.broker.ng-test.nl/broker/sp/oidc"
        let clientID = "PRlEjCDjGEzzLimcNOYWnmxY4IWqRHe3"
        let redirectURI = "https://pkio.broker.ng-test.nl/broker/app/redirect/response"
        let appToAppScopes = "openid idp_scoping:https://was-preprod1.digid.nl/saml/idp/metadata_app"
        let brokerDigidAppAcs = "https://pkio.broker.ng-test.nl/broker/authn/digid/digid-app-acs"

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
            "issuer": authenticationResponse.issuer ?? "",
            "accessToken": authenticationResponse.accessToken ?? "",
            "idToken": authenticationResponse.idToken ?? "",
            "refreshToken": authenticationResponse.refreshToken ?? "",
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
