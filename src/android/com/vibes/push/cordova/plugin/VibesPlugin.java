
package com.vibes.push.cordova.plugin;

import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.util.Set;
import java.util.Map;
import java.lang.reflect.InvocationTargetException;

import android.app.Application;
import android.content.Context;
import android.content.Context;
import android.util.Log;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.Context;
import android.content.Intent;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.vibes.vibes.Vibes;
import com.vibes.vibes.VibesConfig;
import com.vibes.vibes.VibesListener;
import com.vibes.vibes.Credential;
import com.vibes.vibes.Person;

import com.vibes.push.cordova.plugin.FMS;

/**
 * Entry point into the cordova plugin.
 */
public class VibesPlugin extends CordovaPlugin {
    private static final String TAG = "c.v.pcp.VibesPlugin";
    public static final String REGISTERED = "REGISTERED";
    public static final String DEVICE_ID = "VibesPlugin.DEVICE_ID";
    public static final String VIBES_APPID_KEY = "vibes_app_id";
    public static final String VIBES_APIURL_KEY = "vibes_api_url";
    private String[] actions = {"registerDevice", "unregisterDevice", "registerPush", "unregisterPush", "associatePerson", "getVibesDeviceInfo", "getPerson", "onNotificationOpened"};

    private static CallbackContext notificationCallbackContext;
    private static ArrayList<Bundle> notificationStack = null;

    /**
     * Gets the application context from cordova's main activity.
     *
     * @return the application context
     */
    private Context getApplicationContext() {
        return this.cordova.getActivity().getApplicationContext();
    }

    @Override
    public void pluginInitialize() {
        Log.d(TAG, "Initialing the Vibes Push SDK and registering your device");
        Bundle extras = this.cordova.getActivity().getIntent().getExtras();
        this.initializeSDK();
        this.registerDeviceAtStartup();
        if (extras != null && extras.size() > 1) {
            if (VibesPlugin.notificationStack == null) {
                VibesPlugin.notificationStack = new ArrayList<Bundle>();
            }
            if (extras.containsKey(Vibes.VIBES_REMOTE_MESSAGE_DATA)) {
                notificationStack.add(extras);
            }
        }
    }

    public boolean execute(String action, JSONArray args, final CallbackContext callback) throws JSONException {
        Log.i(TAG, String.format("Plugin called with the action [%s] and arguments [%s]", action, args));
        Context context = getApplicationContext();

        //check if method invoked is one of the supported methods.
        List<String> list = Arrays.asList(actions);
        if (!list.contains(action)) {
            callback.error("\"" + action + "\" is not a recognized action.");
            return false;
        }
        if (action.equals("registerDevice")) {
            VibesListener<Credential> listener = getRegisterDeviceListener(callback);
            this.registerDevice(listener);
        } else if (action.equals("unregisterDevice")) {
            this.unregisterDevice(callback);
        } else if (action.equals("registerPush")) {
            SharedPrefsManager prefsManager = new SharedPrefsManager(context);
            String pushToken = prefsManager.getStringData(FMS.TOKEN_KEY);
            if (pushToken == null) {
                callback.error("No push token available for registration yet");
            } else {
                VibesListener<Void> listener = new VibesListener<Void>() {
                    public void onSuccess(Void credential) {
                        callback.success();
                    }

                    public void onFailure(String errorText) {
                        callback.error(errorText);
                    }
                };
                registerPush(pushToken, listener);
            }
        } else if (action.equals("unregisterPush")) {
            this.unregisterPush(callback);
        } else if (action.equals("getVibesDeviceInfo")) {
            getVibesDeviceInfo(callback);
        } else if (action.equals("getPerson")) {
            VibesListener<Person> listener = new VibesListener<Person>() {
                public void onSuccess(Person person) {
                    String jsonString = null;
                    try {
                        JSONObject json = new JSONObject();
                        json.put("person_key", person.getPersonKey());
                        json.put("mdn", person.getMdn());
                        json.put("external_person_id", person.getExternalPersonId());
                        jsonString = json.toString();
                    } catch (JSONException ex) {
                        Log.e(TAG, "Error serializing person to json");
                    }
                    callback.success(jsonString);
                }

                public void onFailure(String errorText) {
                    callback.error(errorText);
                }
            };
            getPerson(listener);
        } else if (action.equals("associatePerson")) {
            String externalPersonId = args.getString(0);
            Log.d(TAG, "Associating Person --> " + externalPersonId);
            VibesListener<Void> listener = new VibesListener<Void>() {
                public void onSuccess(Void value) {
                    callback.success();
                }

                public void onFailure(String errorText) {
                    callback.error(errorText);
                }
            };
            associatePerson(externalPersonId, listener);
        } else if (action.equals("onNotificationOpened")) {
            this.onNotificationOpened(callback);
        }
        return true;
    }

    /**
     * Uses the values passed from preferences into the vibes_app_id and vibes_api_url to initialize the SDK.
     * Crashes the app with appropriate message if those 2 values are not supplied.
     */
    private void initializeSDK() {
        String appId = null;
        String apiUrl = null;
        try {
            ApplicationInfo ai = getApplicationContext().getPackageManager()
                    .getApplicationInfo(getApplicationContext().getPackageName(), PackageManager.GET_META_DATA);
            Bundle bundle = ai.metaData;
            appId = bundle.getString(VIBES_APPID_KEY);
            apiUrl = bundle.getString(VIBES_APIURL_KEY);
            Log.d(TAG, "Vibes parameters are : appId=[" + appId + "], appUrl=[" + apiUrl + "]");

        } catch (PackageManager.NameNotFoundException ex) {

        }
        if (appId == null || appId.isEmpty()) {
            throw new IllegalStateException("No appId provided in manifest under meta-data name [" + VIBES_APPID_KEY + "]");
        }
        if (apiUrl == null || apiUrl.isEmpty()) {
            throw new IllegalStateException("No url provided in manifest under meta-data name [" + VIBES_APIURL_KEY + "]");
        }
        VibesConfig config = new VibesConfig.Builder().setApiUrl(apiUrl).setAppId(appId).build();
        Vibes.initialize(getApplicationContext(), config);
    }

    private void registerDeviceAtStartup() {
        VibesListener<Credential> listener = getRegisterDeviceListener(null);
        this.registerDevice(listener);
    }

    private VibesListener<Credential> getRegisterDeviceListener(final CallbackContext callback) {
        return new VibesListener<Credential>() {
            public void onSuccess(Credential credential) {
                SharedPrefsManager prefsManager = new SharedPrefsManager(VibesPlugin.this.getApplicationContext());
                prefsManager.saveBoolean(VibesPlugin.REGISTERED, true);
                String deviceId = credential.getDeviceID();
                prefsManager.saveData(VibesPlugin.DEVICE_ID, deviceId);
                Log.d(TAG, "Device id obtained is --> " + deviceId);
                String pushToken = prefsManager.getStringData(FMS.TOKEN_KEY);
                if (pushToken == null) {
                    Log.d(TAG, "Token not yet available. Skipping registerPush");
                } else {
                    Log.d(TAG, "Token found after registering device. Attempting to register push token");
                    registerPush(pushToken);
                }
                String jsonString = null;
                try {
                    JSONObject json = new JSONObject();
                    json.put("device_id", credential.getDeviceID());
                    jsonString = json.toString();
                    if (callback != null) {
                        callback.success(jsonString);
                    }
                } catch (JSONException ex) {
                    Log.e(TAG, "Error serializing credential to json");
                    if (callback != null) {
                        callback.error("Error serializing credential to json");
                    }
                }
            }

            public void onFailure(String errorText) {
                Log.e(TAG, "Failure registering device with Vibes Push SDK: " + errorText);
                if (callback != null) {
                    callback.error(errorText);
                }
            }
        };
    }

    private void registerDevice(VibesListener<Credential> listener) {
        Vibes.getInstance().registerDevice(listener);
    }

    private void unregisterDevice(final CallbackContext callback) {
        VibesListener<Void> listener = new VibesListener<Void>() {
            public void onSuccess(Void credential) {
                Log.d(TAG, "Unregister device successful");
                SharedPrefsManager prefsManager = new SharedPrefsManager(getApplicationContext());
                prefsManager.updateData(VibesPlugin.DEVICE_ID, null);
                prefsManager.updateBoolean(VibesPlugin.REGISTERED, false);

                callback.success();
            }

            public void onFailure(String errorText) {
                Log.d(TAG, "Unregister device failed");
                callback.error(errorText);
            }
        };
        Vibes.getInstance().unregisterDevice(listener);
    }

    /**
     * Registers a push token with the Vibes SDK, where the caller is not interested in success or failure callback.
     *
     * @param pushToken the callback to be notified of either success or failure.
     */
    public static void registerPush(String pushToken) {
        VibesListener<Void> listener = new VibesListener<Void>() {
            public void onSuccess(Void credential) {
                Log.d(TAG, "Push token registration success");
            }

            public void onFailure(String errorText) {
                Log.d(TAG, "Failure registering token with Vibes Push SDK: " + errorText);
            }
        };
        registerPush(pushToken, listener);
    }

    /**
     * Registers a push token with the Vibes SDK, with the supplied listener to handle success/failure callbacks.
     *
     * @param pushToken token to register with Vibes SDK
     * @param listener  the callback to be notified of either success or failure.
     */
    public static void registerPush(String pushToken, VibesListener<Void> listener) {
        Vibes.getInstance().registerPush(pushToken, listener);
    }

    private void unregisterPush(final CallbackContext callback) {
        VibesListener<Void> listener = new VibesListener<Void>() {
            public void onSuccess(Void credential) {
                Log.d(TAG, "Unregister push successful");
                callback.success();
            }

            public void onFailure(String errorText) {
                Log.d(TAG, "Unregister push failed");
                callback.error(errorText);
            }
        };
        Vibes.getInstance().unregisterPush(listener);
    }

    private void getVibesDeviceInfo(final CallbackContext callback) {
        SharedPrefsManager prefsManager = new SharedPrefsManager(getApplicationContext());
        String pushToken = prefsManager.getStringData(FMS.TOKEN_KEY);
        String deviceId = prefsManager.getStringData(VibesPlugin.DEVICE_ID);
        String jsonString = null;
        try {
            JSONObject json = new JSONObject();
            json.put("device_id", deviceId);
            json.put("push_token", pushToken);
            jsonString = json.toString();
            callback.success(jsonString);
        } catch (JSONException ex) {
            Log.e(TAG, "Error serializing device info to json");
            callback.error("Error serializing device info to json");
        }
    }

    private void getPerson(VibesListener<Person> listener) {
        Vibes.getInstance().getPerson(listener);
    }

    private void associatePerson(String externalPersonId, VibesListener<Void> listener) {
        Vibes.getInstance().associatePerson(externalPersonId, listener);
    }

    /**
     * Callback that notifies the app when a push notification is received with the payload in the notification.
     * On first attempt, the callback is stored in static variable and all previously received notification stored 
     * in the stack prior to registering for this callback are sent.
     * 
     * Subsequently, each new notification is immediately sent to the app.
     */
    private void onNotificationOpened(final CallbackContext callbackContext) {
        VibesPlugin.notificationCallbackContext = callbackContext;
        if (VibesPlugin.notificationStack != null) {
            for (Bundle bundle : VibesPlugin.notificationStack) {
                VibesPlugin.notifyCallback(bundle, this.cordova.getActivity().getApplicationContext());
            }
            VibesPlugin.notificationStack.clear();
        }
    }

    /**
     * Performs the actual sending of notification payload through the static notificationCallbackContext 
     */
    public static void notifyCallback(Bundle bundle, Context context) {
        Log.d(TAG, "notifyCallback invoked. Attempting to read and send notification payload");
        if (!VibesPlugin.hasNotificationsCallback()) {
            String packageName = context.getPackageName();
            if (VibesPlugin.notificationStack == null) {
                VibesPlugin.notificationStack = new ArrayList<Bundle>();
            }
            notificationStack.add(bundle);

            return;
        }
        VibesPlugin.notifyCallback((Map<String, String>) bundle.get(Vibes.VIBES_REMOTE_MESSAGE_DATA));
    }

    public static void notifyCallback(Map<String, String> data) {
        final CallbackContext callbackContext = VibesPlugin.notificationCallbackContext;

        if (callbackContext != null && data != null) {
            String jsonString = null;

            JSONObject json = new JSONObject(data);
            jsonString = json.toString();
            jsonString = jsonString.replaceAll("\\\\", "");
            PluginResult pluginresult = new PluginResult(PluginResult.Status.OK, jsonString);
            pluginresult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginresult);
        }
    }

    private static boolean hasNotificationsCallback() {
        return VibesPlugin.notificationCallbackContext != null;
    }
}
