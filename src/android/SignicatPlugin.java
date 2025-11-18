package com.signicat.plugin;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;

import com.connectis.sdk.ConnectisSDK;
import com.connectis.sdk.ConnectisSDKConfiguration;
import com.connectis.sdk.AuthenticationResponseDelegate;
import com.connectis.sdk.AccessTokenDelegate;


public class SignicatPlugin extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext)
            throws JSONException {

        switch (action) {
            case "login":
                JSONObject configJson = args.getJSONObject(0);
                login(configJson, callbackContext);
                return true;
            case "getAccessToken":
                getAccessToken(callbackContext);
                return true;
            case "enableDeviceAuth":
                enableDeviceAuth(callbackContext);
                return true;
            case "disableDeviceAuth":
                disableDeviceAuth(callbackContext);
                return true;
            default:
                return false;
        }
    }

    private void login(JSONObject json, CallbackContext callbackContext) {
        Activity activity = cordova.getActivity();
        try {
            String issuer = json.getString("issuer");
            String clientId = json.getString("clientId");
            String redirectUri = json.getString("redirectUri");
            String loginFlow = json.optString("loginFlow", "WEB");
            boolean allowDeviceAuth = json.optBoolean("allowDeviceAuthentication", false);
            String brokerAppAcs = json.optString("brokerAppAcs", null);
            String brokerDigidAppAcs = json.optString("brokerDigidAppAcs", null);

            ConnectisSDKConfiguration.Builder builder = new ConnectisSDKConfiguration.Builder()
                    .issuer(issuer)
                    .clientId(clientId)
                    .redirectUri(redirectUri)
                    .loginFlow(ConnectisSDKConfiguration.LoginFlow.valueOf(loginFlow))
                    .allowDeviceAuthentication(allowDeviceAuth);

            if (brokerAppAcs != null) {
                builder.brokerAppAcs(brokerAppAcs);
            }
            if (brokerDigidAppAcs != null) {
                builder.brokerDigidAppAcs(brokerDigidAppAcs);
            }

            ConnectisSDKConfiguration config = builder.build();
            ConnectisSDK.initialize(activity.getApplication(), config);

            ConnectisSDK.login(activity, new AuthenticationResponseDelegate() {
                @Override
                public void onSuccess(com.connectis.sdk.AuthenticationResponse response) {
                    try {
                        JSONObject res = new JSONObject();
                        res.put("issuer", response.getIssuer());
                        res.put("accessToken", response.getAccessToken());
                        res.put("idToken", response.getIdToken());
                        res.put("refreshToken", response.getRefreshToken());
                        callbackContext.success(res);
                    } catch (JSONException e) {
                        callbackContext.error("JSON error: " + e.getMessage());
                    }
                }

                @Override
                public void onError(Exception e) {
                    callbackContext.error("Login error: " + e.getMessage());
                }
            });

        } catch (Exception e) {
            callbackContext.error("Login config error: " + e.getMessage());
        }
    }

    private void getAccessToken(CallbackContext callbackContext) {
        ConnectisSDK.getOpenIdAccessToken(new AccessTokenDelegate() {
            @Override
            public void onToken(String token) {
                callbackContext.success(token);
            }

            @Override
            public void onError(Exception e) {
                callbackContext.error("AccessToken error: " + e.getMessage());
            }
        });
    }

    private void enableDeviceAuth(CallbackContext callbackContext) {
        ConnectisSDK.enableDeviceAuthentication();
        callbackContext.success("deviceAuthEnabled");
    }

    private void disableDeviceAuth(CallbackContext callbackContext) {
        ConnectisSDK.disableDeviceAuthentication();
        callbackContext.success("deviceAuthDisabled");
    }
}
