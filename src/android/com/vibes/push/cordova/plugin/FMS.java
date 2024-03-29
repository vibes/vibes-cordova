package com.vibes.push.cordova.plugin;

import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.vibes.vibes.PushPayloadParser;
import com.vibes.vibes.Vibes;
import com.vibes.vibes.VibesListener;
import com.vibes.push.cordova.plugin.VibesCordovaNotificationFactory;
import android.util.Log;

import java.util.Map;

import static com.vibes.push.cordova.plugin.VibesPlugin.TAG;

/**
 * Component for receiving notifications of Firebase token changes, as well as passing push messages received to the Vibes SDK to interpret.
 */
public class FMS extends FirebaseMessagingService {
    public static final String TOKEN_KEY = "c.v.a.PushToken";

    /**
     * @see FMS#onMessageReceived(RemoteMessage)
     */
    @Override
    public void onMessageReceived(RemoteMessage message) {
        Log.d(TAG, "Push message received. Atempting to render via Vibes SDK");
        Vibes.getInstance().setNotificationFactory(new VibesCordovaNotificationFactory(getApplicationContext()));
        Vibes.getInstance().handleNotification(getApplicationContext(), message.getData());
        PushPayloadParser pushModel = this.createPushPayloadParser(message.getData());
        if(pushModel.isSilentPush()){
            VibesPlugin.notifyCallback(pushModel.getMap());
        }
    }

    @Override
    public void onNewToken(String pushToken) {
        super.onNewToken(pushToken);
        Log.d(TAG, "Firebase token obtained as " + pushToken);
        SharedPrefsManager prefsManager = new SharedPrefsManager(this);
        prefsManager.saveData(TOKEN_KEY, pushToken);

        boolean registered = prefsManager.getBooleanData(VibesPlugin.REGISTERED);
        if (registered) {
            VibesPlugin.registerPush(pushToken, getRegisterPushListener(prefsManager));
        } else {
            Log.d(TAG, "Skipping token registration as device is not registered yet ");
        }
    }

    public PushPayloadParser createPushPayloadParser(Map<String, String> map) {
        return new PushPayloadParser(map);
    }

    private VibesListener<Void> getRegisterPushListener(final SharedPrefsManager prefsManager) {
        return new VibesListener<Void>() {
            public void onSuccess(Void credential) {
                prefsManager.saveBoolean(VibesPlugin.PUSH_REGISTERED, true);
                Log.d(TAG, "Push token registration successful");
            }

            public void onFailure(String errorText) {
                prefsManager.saveBoolean(VibesPlugin.PUSH_REGISTERED, false);
                Log.d(TAG, "Failure registering token with Vibes Push SDK: " + errorText);
                
            }
        };
    }
}
