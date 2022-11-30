package com.vibes.push.cordova.plugin;

public interface PrefsManager {
    void saveData(String key, String value);
    void saveBoolean(String key, Boolean value);
    void updateData(String key, String value);
    void updateBoolean(String key, Boolean value);
    String getStringData(String key);
    int getIntData(String key);
    boolean getBooleanData(String key);
}