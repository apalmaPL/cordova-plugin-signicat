package com.signicat.plugin;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

import com.connectis.sdk.ConnectisSDK;
import com.connectis.sdk.api.configuration.ConnectisSDKConfiguration;
import com.connectis.sdk.api.authentication.AuthenticationResponse;
import com.connectis.sdk.api.authentication.AuthenticationResponseDelegate;
import com.connectis.sdk.api.authentication.ErrorResponseDelegate;
import com.connectis.sdk.internal.authentication.login.LoginFlow;

public class SignicatPlugin extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if ("loginAppToApp".equals(action)) {
            login(args, callbackContext);
            return true;
        }
        return false;
    }

    private void login(JSONArray args, CallbackContext callbackContext) {

        final String issuer;
        final String clientId;
        final String redirectUri;
        final String scopes;
        final String brokerDigidAppAcs;

        try {
            issuer = args.getString(0);
            clientId = args.getString(1);
            redirectUri = args.getString(2);
            scopes = args.getString(3);
            brokerDigidAppAcs = args.getString(4);
        } catch (JSONException e) {
            callbackContext.error("Invalid args: " + e.getMessage());
            return;
        }

        final boolean allowDeviceAuthentication = false;

        cordova.getActivity().runOnUiThread(() -> {
          try {
            ConnectisSDKConfiguration configuration = new ConnectisSDKConfiguration(
                issuer,
                clientId,
                redirectUri,
                scopes,
                null,
                brokerDigidAppAcs,
                LoginFlow.APP_TO_APP
            );
        
            AuthenticationResponseDelegate delegate = new AuthenticationResponseDelegate() {
              @Override
              public void handleResponse(AuthenticationResponse response) {
                callbackContext.success("Signicat login successful");
              }
        
              @Override
              public void onCancel() {
                callbackContext.error("Signicat login cancelled");
              }
            };
        
            ErrorResponseDelegate errorDelegate = new ErrorResponseDelegate() {
              @Override
              public void handleError(Exception e) {
                callbackContext.error(e.getMessage());
              }
            };
        
            ConnectisSDK.Companion.login(
                configuration,
                cordova.getActivity(),
                delegate,
                errorDelegate,
                allowDeviceAuthentication
            );
          } catch (Exception e) {
            callbackContext.error("Login config error: " + e.getMessage());
          }
        });

    }
}

