using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Properties;
using Toybox.Application.Storage;
using Toybox.ActivityMonitor;
using Toybox.Lang;

// Glance view shown in the widget carousel on SDK 3.2+ devices.
// Must be extremely lightweight (3-16 KB memory budget).
// Reads accumulated distance from Storage (written by main view).
(:glance)
class KMGoalGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc) {
        var goal = getGoalValue();
        var units = getPropertyNum("units", 0);
        var conv = (units == 1) ? 0.621371 : 1.0;
        var uLabel = (units == 1) ? "mi" : "km";
        var completed = getPropertyNum("startingDist", 0).toFloat() + ((getAccumulatedKm() + getTodayKm()) * conv);
        var pct = 0;
        if (goal > 0) {
            pct = ((completed / goal.toFloat()) * 100).toNumber();
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var h = dc.getHeight();
        var fontH = dc.getFontHeight(Graphics.FONT_GLANCE);
        var totalH = fontH * 2;
        var startY = (h - totalH) / 2;

        // Line 1: "KM Goal  6%"
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, startY, Graphics.FONT_GLANCE,
            Lang.format("KM Goal  $1$%", [pct]),
            Graphics.TEXT_JUSTIFY_LEFT);

        // Line 2: "132 / 2,026 km"
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, startY + fontH,
            Graphics.FONT_GLANCE,
            Lang.format("$1$ / $2$ $3$", [formatGlanceNum(completed), formatGlanceNum(goal.toFloat()), uLabel]),
            Graphics.TEXT_JUSTIFY_LEFT);
    }

    hidden function getGoalValue() {
        return getPropertyNum("goal", 2026);
    }

    hidden function getPropertyNum(key, defaultVal) {
        try {
            if (Properties has :getValue) {
                var val = Properties.getValue(key);
                if (val != null && val instanceof Number) {
                    return val;
                }
            }
        } catch (e) {
            // use default
        }
        return defaultVal;
    }

    hidden function getAccumulatedKm() {
        var accKm = Storage.getValue("accKm");
        if (accKm == null) { return 0.0; }
        return accKm.toFloat();
    }

    hidden function getTodayKm() {
        var todayKm = 0.0;
        if (Toybox has :ActivityMonitor && ActivityMonitor has :getInfo) {
            var monitorInfo = ActivityMonitor.getInfo();
            if (monitorInfo != null && monitorInfo has :distance && monitorInfo.distance != null) {
                todayKm = monitorInfo.distance.toFloat() / 100000.0;
            }
        }
        // Use stored value as floor to protect against sync resets
        var storedDist = Storage.getValue("lastDayDist");
        if (storedDist != null) {
            var storedKm = storedDist.toFloat() / 100000.0;
            if (storedKm > todayKm) {
                todayKm = storedKm;
            }
        }
        return todayKm;
    }

    hidden function formatGlanceNum(num) {
        if (num >= 1000.0) {
            var whole = num.toNumber();
            var thousands = (whole / 1000).toNumber();
            var remainder = whole - (thousands * 1000);
            return Lang.format("$1$,$2$", [thousands, remainder.format("%03d")]);
        }
        if (num < 1.0) {
            return num.format("%.0f");
        }
        return num.format("%.1f");
    }
}
