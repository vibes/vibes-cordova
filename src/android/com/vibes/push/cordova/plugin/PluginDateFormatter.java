package com.vibes.push.cordova.plugin;

import android.support.annotation.NonNull;

import java.text.FieldPosition;
import java.text.ParsePosition;
import java.text.SimpleDateFormat;
import java.util.Date;
import com.vibes.vibes.Vibes;

import static com.vibes.push.cordova.plugin.VibesPlugin.TAG;

/**
 * Helper class for parsing and formatting dates in ISO format.
 */
class PluginDateFormatter {
    // PUSHSDK-337
    // In java 7 XXX is allowed in the pattern for ISO 8601 which seems to work on the latest
    // android phone. Nevertheless, when using yyyy-MM-dd'T'HH:mm:ss.SSSZ in an older phone, it
    // thows an exception "Date - unknown pattern character 'X'"
    private static SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
        @Override
        public StringBuffer format(@NonNull Date date, @NonNull StringBuffer toAppendTo, @NonNull FieldPosition pos) {
            StringBuffer rfcFormat = super.format(date, toAppendTo, pos);
            return rfcFormat.insert(rfcFormat.length() - 2, ":");
        }

        @Override
        public Date parse(@NonNull String text, @NonNull ParsePosition pos) {
            if (text.length() > 3) {
                text = text.substring(0, text.length() - 3) + text.substring(text.length() - 2);
            }
            return super.parse(text, pos);
        }
    };
    /**
     * Formats a Date in ISO format
     * @param date the date to format
     * @return the formatted string
     */
    public static String toISOString(Date date) {
        return PluginDateFormatter.simpleDateFormat.format(date);
    }

    /**
     * Parses an ISO date string to a Date object.
     * @param iso The string to parse
     * @return the generated Date
     */
    public static Date fromISOString(String iso) {
        try {
            return PluginDateFormatter.simpleDateFormat.parse(iso);
        } catch (Exception e) {
            Vibes.getCurrentLogger().log(e);
        }
        return null;
    }
}
