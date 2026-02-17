package com.signicat.plugin;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import com.google.gson.Gson;

import com.connectis.sdk.ConnectisSDK;
import com.connectis.sdk.api.configuration.ConnectisSDKConfiguration;
import com.connectis.sdk.api.authentication.AuthenticationResponse;
import com.connectis.sdk.api.authentication.AuthenticationResponseDelegate;
import com.connectis.sdk.api.authentication.ErrorResponseDelegate;
import com.connectis.sdk.internal.authentication.login.LoginFlow;
import com.connectis.sdk.api.authentication.AccessTokenDelegate;
import com.connectis.sdk.api.authentication.Token;
import org.jetbrains.annotations.NotNull;


public class SignicatPlugin extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if ("loginAppToApp".equals(action)) {
            login(args, callbackContext);
            return true;
        }

        if ("getAccessToken".equals(action)) {
            getAccessToken(callbackContext);
            return true;
        }

        return false;
    }

    private void getAccessToken(final CallbackContext callbackContext) {    

        ConnectisSDK.Companion.useAccessToken(
            cordova.getActivity(),
            new AccessTokenDelegate() {
                @Override
                public void handleAccessToken(@NotNull Token accessToken) {
                    callbackContext.success(accessToken.getValue());
                }

                @Override
                public void onError(@NotNull String exception) {
                    sendError(callbackContext, "E_ACCESS_TOKEN_EXCEPTION", exception);
                }
            }
        );

    }


    private void login(JSONArray args, CallbackContext callbackContext) {

        final String issuer;
        final String clientId;
        final String redirectUri;
        final String scopes;
        final String brokerDigidAppAcs;
        final boolean isAppToApp;

        try {
            issuer = args.getString(0);
            clientId = args.getString(1);
            redirectUri = args.getString(2);
            scopes = args.getString(3);
            brokerDigidAppAcs = args.getString(4);
            isAppToApp = args.optBoolean(5, false);

        } catch (JSONException e) {
            sendError(callbackContext, "E_LOGIN_INVALID_ARGS", e.getMessage());
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
                (isAppToApp) ? LoginFlow.APP_TO_APP : LoginFlow.WEB
            );
        
            AuthenticationResponseDelegate delegate = new AuthenticationResponseDelegate() {
              @Override
              public void handleResponse(AuthenticationResponse response) {
                Gson gson = new Gson();
                String responseJSON = gson.toJson(response);
                callbackContext.success(responseJSON);
              }
        
              @Override
              public void onCancel() {
                sendError(callbackContext, "E_LOGIN_CANCELED", "User canceled Signicat login");
              }
            };
        
            ErrorResponseDelegate errorDelegate = new ErrorResponseDelegate() {
              @Override
              public void handleError(Exception e) {
                sendError(callbackContext, "E_LOGIN_SDK_ERROR", e.getMessage());
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
            sendError(callbackContext, "E_LOGIN_EXCEPTION", e.getMessage());
          }
        });

    }

    
    private void sendError(CallbackContext ctx, String code, String message) {
        try {
            JSONObject errorJson = new JSONObject();
            errorJson.put("code", code);
            errorJson.put("message", message);
            ctx.error(errorJson.toString());
        } catch (JSONException ignored) {
            ctx.error("{\"code\":\"" + code + "\",\"message\":\"" + message + "\"}");
        }
    }
}

