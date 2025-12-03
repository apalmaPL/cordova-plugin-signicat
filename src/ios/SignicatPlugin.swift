import Foundation
import ConnectisSDK

@objc(SignicatPlugin)
class SignicatPlugin: CDVPlugin {


    @objc(login:)
    func login(command: CDVInvokedUrlCommand) {
        
    }

    private func enableDeviceAuthentication() {
        ConnectisSDK.enableDeviceAuthentication(delegate: self)
    }
}

