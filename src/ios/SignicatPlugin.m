#import "Cordova/CDV.h"
#import "SignicatPlugin.h"
#import <ConnectisSDK/ConnectisSDK.h>
#import <ConnectisSDK/ConnectisSDK-Swift.h>



@implementation SignicatPlugin

- (void)login:(CDVInvokedUrlCommand*)command {
    NSDictionary *config = [command.arguments objectAtIndex:0];
    NSString *issuer = config[@"issuer"];
    NSString *clientId = config[@"clientId"];
    NSString *redirectUri = config[@"redirectUri"];
    NSString *loginFlow = config[@"loginFlow"] ?: @"WEB";
    BOOL allowDeviceAuth = [config[@"allowDeviceAuthentication"] boolValue];
    NSString *brokerAppAcs = config[@"brokerAppAcs"];
    NSString *brokerDigidAppAcs = config[@"brokerDigidAppAcs"];

    ConnectisSDKConfiguration *cfg;

}


@end

