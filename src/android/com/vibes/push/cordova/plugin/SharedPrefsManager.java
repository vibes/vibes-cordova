package com.vibes.push.cordova.plugin;

import android.content.Context;
import android.content.SharedPreferences;

public class SharedPrefsManager implements PrefsManager {
    private static final String VIBES_PREFS_KEY = "VIBES_PREFS_KEY";
    private SharedPreferences sharedPreferences;
    private SharedPreferences.Editor editor;

    public SharedPrefsManager(Context context) {
        sharedPreferences = context.getSharedPreferences(VIBES_PREFS_KEY, Context.MODE_PRIVATE);
    }
    @Override
    public void saveData(String key, String value) {
        editor = sharedPreferences.edit();
        editor.putString(key, value);
        editor.apply();
    }

    @Override
    public void saveBoolean(String key, Boolean value) {
        editor = sharedPreferences.edit();
        editor.putBoolean(key, value);
        editor.apply();
    }

    @Override
    public void updateData(String key, String value) {
        editor = sharedPreferences.edit();
        editor.putString(key, value);
        editor.apply();
    }

    @Override
    public void updateBoolean(String key, Boolean value) {
        editor = sharedPreferences.edit();
        editor.putBoolean(key, value);
        editor.apply();
    }

    @Override
    public String getStringData(String key) {
        return sharedPreferences.getString(key, null);
    }

    @Override
    public int getIntData(String key) {
        return sharedPreferences.getInt(key, 0);
    }

    @Override
    public boolean getBooleanData(String key) {
        return sharedPreferences.getBoolean(key, false);
    }
}
