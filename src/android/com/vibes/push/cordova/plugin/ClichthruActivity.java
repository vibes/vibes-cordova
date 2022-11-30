package com.vibes.push.cordova.plugin;

import com.vibes.vibes.Vibes;
import com.vibes.vibes.PushPayloadParser;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.os.Bundle;
import java.util.HashMap;
import android.os.Build;

import static com.vibes.push.cordova.plugin.VibesPlugin.TAG;

public class ClichthruActivity extends Activity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          Log.d(TAG, "Checking if Vibes push message exists in intent");
          HashMap<String, String> pushMap  = (HashMap<String, String>) getIntent().getSerializableExtra(Vibes.VIBES_REMOTE_MESSAGE_DATA);
          if(pushMap !=null){
            Log.d(TAG, "Vibes push payload found. Attempting to emit to Javascript");
            //this is for tracking which push messages have been opened by the user
            Context context = this.getApplicationContext();
            String packageName = context.getPackageName();
            Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
            String className = launchIntent.getComponent().getClassName();
            Vibes.getInstance().onPushMessageOpened(pushMap, context);
            try {
                //Now emit event to the main activity
                Intent mainActivityIntent = new Intent(context, Class.forName(className));
                mainActivityIntent.putExtra(Vibes.VIBES_REMOTE_MESSAGE_DATA, pushMap);
                mainActivityIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
                
                Bundle extras = mainActivityIntent.getExtras();
                VibesPlugin.notifyCallback(extras, context);

                mainActivityIntent.putExtras(extras);
                context.startActivity(mainActivityIntent);
              } catch (ClassNotFoundException e) {
                //ignore. this should not happen            
            }
          }else{
            Log.d(TAG, "No push received");
          }
        }
        
    }
}