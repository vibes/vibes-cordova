package com.vibes.push.cordova.plugin;

import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.vibes.vibes.PushPayloadParser;
import com.vibes.vibes.Vibes;
import com.vibes.vibes.VibesListener;

import android.util.Log;

import java.util.Map;

/**
 * Component for receiving notifications of Firebase token changes, as well as passing push messages received to the Vibes SDK to interpret.
 */
public class FMS extends FirebaseMessagingService {
    private static final String TAG = "c.v.pcp.FMS";
    public static final String TOKEN_KEY = "c.v.a.PushToken";

    /**
     * @see FMS#onMessageReceived(RemoteMessage)
     */
    @Override
    public void onMessageReceived(RemoteMessage message) {
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
            VibesPlugin.registerPush(pushToken);
        } else {
            Log.d(TAG, "Skipping token registration as device is not registered yet ");
        }
    }

    public PushPayloadParser createPushPayloadParser(Map<String, String> map) {
        return new PushPayloadParser(map);
    }
}
