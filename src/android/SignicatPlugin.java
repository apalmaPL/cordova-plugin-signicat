package com.signicat.plugin;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;

import com.connectis.sdk.ConnectisSDK;
import com.connectis.sdk.api.configuration.ConnectisSDKConfiguration;
import com.connectis.sdk.api.authentication.AccessTokenDelegate;
import com.connectis.sdk.api.authentication.AuthenticationResponseDelegate;
import com.connectis.sdk.api.authentication.DeviceAuthenticationResponseDelegate;
import com.connectis.sdk.api.authentication.ErrorResponseDelegate;
import com.connectis.sdk.internal.authentication.device.authentication.DeviceAuthenticationService;
import com.connectis.sdk.internal.authentication.device.authentication.DeviceAuthenticationUtils;
import com.connectis.sdk.internal.authentication.login.LoginService;
import com.connectis.sdk.internal.authentication.login.LoginServiceParameters;
import com.connectis.sdk.internal.authentication.token.AccessTokenService;


public class SignicatPlugin extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        switch (action) {
            case "login":
                login(args, callbackContext);
                return true;
            default:
                return false;
        }
    }

    private void login(JSONArray args, CallbackContext callbackContext) {

        try {
            Activity activity = cordova.getActivity();

            String issuer = args.getString(0);
            String clientId = args.getString(1);
            String redirectUri = args.getString(2);
            String scopes = args.getString(3);
            String brokerDigidAppAcs = args.getString(4);
            boolean allowDeviceAuthentication = false;
            LoginFlow loginFlow = LoginFlow.APP_TO_APP;


            ConnectisSDKConfiguration configuration = new ConnectisSDKConfiguration(
                issuer,
                clientId,
                redirectUri,
                scopes,
                brokerDigidAppAcs,
                loginFlow
            );

            AuthenticationResponseDelegate delegate = new AuthenticationResponseDelegate() {

                @Override
                public void onSuccess() {
                    callbackContext.success("Signicat login successful");
                }

                @Override
                public void onCancel() {
                    callbackContext.error("Signicat login cancelled");
                }
            }

            activity.runOnUiThread(() -> {
                ConnectisSDK.login(
                    configuration,
                    activity,
                    delegate,
                    null,
                    allowDeviceAuthentication 
                );
            });
                

        } catch (Exception e) {
            callbackContext.error("Login config error: " + e.getMessage());
        }
    }


}
