package com.vibes.push.cordova.plugin;

import com.vibes.vibes.NotificationFactory;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import static com.vibes.push.cordova.plugin.VibesPlugin.TAG;

/**
 * This implementation of {@link NotificationFactory} associates every push clickthru with the <code>ClickthruActivity</code> class, 
 * otherwise push messages with a deeplink will never be resolvable to <code>ClickthruActivity</code>
 */
public class VibesCordovaNotificationFactory extends NotificationFactory{

    public VibesCordovaNotificationFactory(Context context) {
        super(context);
    }

    protected Class<? extends Activity> getActivity(Context context, Intent intent) {
        intent.setData(null);
        Class activityClass = super.getActivity(context,intent);
        Log.d(TAG, "Clickthru events will be channeled to the activity="+ activityClass);
        return activityClass;
    }
    
}
