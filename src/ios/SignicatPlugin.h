#import "Foundation/Foundation.h"
#import "Cordova/CDV.h"

@interface SignicatPlugin : CDVPlugin

- (void)login:(CDVInvokedUrlCommand*)command;
- (void)getAccessToken:(CDVInvokedUrlCommand*)command;
- (void)enableDeviceAuth:(CDVInvokedUrlCommand*)command;
- (void)disableDeviceAuth:(CDVInvokedUrlCommand*)command;

@end
