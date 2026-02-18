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


/*********************************************************************************
 * The Android SDK is built with AndroidX. 
 * This means that you must have an AndroidX application to use the Android SDK.
 * The supported Android minimum version is Android 9 (API level 28). 
 * The supported Android target version is Android 16 (API level 36).
 * The SDK is made using Kotlin 1.9. If your app uses Kotlin, then we recommend that you use a language version that is the same (1.9) or newer.
 * The target phone's default browser must support cookies. If not, then a browser that supports cookies must be set as default. 
 * 
 * It includes the android-sdk-1.1.7.aar library.
 * 
**********************************************************************************/

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


    /**
     * Requests a valid OpenID access token from the Signicat Identity Broker.
     *
     * This method initiates an SDK call that returns an OAuth2/OpenID access token
     * previously obtained through a successful login. The token can be used to
     * authorize calls to backend APIs that require a valid access credential.
     *
     * The AccessTokenDelegate provides two callbacks:
     *   - handleAccessToken(Token accessToken): called when a valid token is available.
     *   - onError(String exception): called when there was a problem obtaining
     *     the token (e.g., expired session, internal error).
     *
     * Note: Treat the returned access token as a secret and keep it secure.
     */

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

    /**
     * Starts the authentication flow with the Signicat Identity Broker.
     *
     * This method uses ConnectisSDKConfiguration to launch either:
     *   - a WEB login flow using an external browser,
     *   - or an APP_TO_APP flow for DigID/App-to-app redirect authentication.
     *
     * After the user interacts with the broker (e.g., entering credentials,
     * choosing an ID provider), the result is returned through:
     *   - AuthenticationResponseDelegate.handleResponse(AuthenticationResponse):
     *     called with a response object when authentication completes.
     *   - AuthenticationResponseDelegate.onCancel():
     *     called if the user cancels the login.
     *
     * If an error occurs during the login process (e.g., network error,
     * invalid configuration), ErrorResponseDelegate.handleError(Exception e)
     * is triggered with details of the failure.
     *
     * The response includes information such as:
     *   - success status,
     *   - unique name identifier,
     *   - attributes returned by the identity provider (e.g., subject, amr).
     */

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

    /**
     * Sends a structured error object back to the Cordova JavaScript layer.
     *
     * This method wraps an error code and message into a JSON object,
     * then passes it to the Cordova CallbackContext as an error response. The
     * resulting JSON has the following structure:
     *
     * {
     *   "code": "<ERROR_CODE>",
     *   "message": "<Human readable message>"
     * }
     *
     * Using a consistent JSON error format allows the JavaScript side to reliably
     * detect, classify, and handle plugin errors such as argument validation issues,
     * SDK failures, login cancellations, or unexpected exceptions.
     *
     * @param ctx     The Cordova CallbackContext used to report the error.
     * @param code    A short, machine-readable error code (e.g. "E_LOGIN_CONFIG").
     * @param message A descriptive message providing additional context.
     */
    
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

