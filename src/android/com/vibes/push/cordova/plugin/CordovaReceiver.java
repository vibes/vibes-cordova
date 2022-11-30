package com.vibes.push.cordova.plugin;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.vibes.vibes.PushPayloadParser;
import com.vibes.vibes.Vibes;
import com.vibes.vibes.VibesReceiver;

import android.util.Log;

import static com.vibes.push.cordova.plugin.VibesPlugin.TAG;

/**
 * Overrides the default VibesReceiver behaviour to open the app when hidden.
 */
public class CordovaReceiver extends VibesReceiver {
    
    @Override
    protected void onPushOpened(Context context, PushPayloadParser pushModel) {
        super.onPushOpened(context,pushModel);
        String packageName = context.getPackageName();
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
        String className = launchIntent.getComponent().getClassName();
        Log.d(TAG, "CordovaReceiver.onPushOpened invoked. Opening ["+className+"]");
        try {
            Intent mainActivityIntent = new Intent(context, Class.forName(className));
            mainActivityIntent.putExtra(Vibes.VIBES_REMOTE_MESSAGE_DATA, pushModel.getMap());
            mainActivityIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
            
            Bundle extras = mainActivityIntent.getExtras();
            VibesPlugin.notifyCallback(extras, context);

            mainActivityIntent.putExtras(extras);
            context.startActivity(mainActivityIntent);
        } catch (ClassNotFoundException e) {
            //ignore. this should not happen            
        }
        
    }

}