using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Application.Storage;
using Toybox.ActivityMonitor;
using Toybox.Lang;

class KMGoalView extends WatchUi.View {

    // Current page (0 = overview, 1 = pace details, 2 = settings info)
    var currentPage = 0;
    const MAX_PAGES = 3;

    // Screen dimensions (cached in onLayout)
    var screenWidth = 0;
    var screenHeight = 0;
    var centerX = 0;
    var centerY = 0;

    // Colors (loaded from settings)
    var accentColor = Graphics.COLOR_BLUE;
    var behindColor = Graphics.COLOR_RED;
    var aheadColor = Graphics.COLOR_GREEN;

    // Unit label and conversion (loaded from settings)
    // 0 = km, 1 = miles. Accumulated data is always in km internally.
    var unitLabel = "km";
    var unitLabelLong = "kilometers";
    var unitConversion = 1.0;

    // Pre-allocated constant arrays (avoid creating in hot path)
    hidden const DAYS_IN_MONTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    function initialize() {
        View.initialize();
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
    }

    function onShow() {
        loadColors();
        loadUnits();
    }

    // Color index mapping: 0=blue, 1=green, 2=orange, 3=red, 4=purple, 5=cyan, 6=yellow, 7=white
    hidden const COLOR_MAP = [
        Graphics.COLOR_BLUE,    // 0
        Graphics.COLOR_GREEN,   // 1
        Graphics.COLOR_ORANGE,  // 2
        Graphics.COLOR_RED,     // 3
        Graphics.COLOR_PURPLE,  // 4
        0x00FFFF,               // 5 = cyan
        Graphics.COLOR_YELLOW,  // 6
        Graphics.COLOR_WHITE    // 7
    ];

    function loadColors() {
        accentColor = getColorFromSetting("accentColor", 0);
        behindColor = getColorFromSetting("behindColor", 3);
        aheadColor = getColorFromSetting("aheadColor", 1);
    }

    function loadUnits() {
        var units = getPropertyNum("units", 0);
        if (units == 1) {
            unitLabel = "mi";
            unitLabelLong = "miles";
            unitConversion = 0.621371;
        } else {
            unitLabel = "km";
            unitLabelLong = "kilometers";
            unitConversion = 1.0;
        }
    }

    function getColorFromSetting(propertyName, defaultIndex) {
        var idx = getPropertyNum(propertyName, defaultIndex);
        if (idx >= 0 && idx < COLOR_MAP.size()) {
            return COLOR_MAP[idx];
        }
        return COLOR_MAP[0];
    }

    function onUpdate(dc) {
        // Ensure dimensions are set
        if (screenWidth == 0) {
            screenWidth = dc.getWidth();
            screenHeight = dc.getHeight();
            centerX = screenWidth / 2;
            centerY = screenHeight / 2;
        }

        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Reload units each update (in case settings changed)
        loadUnits();

        // Get settings
        var goalType = getPropertyNum("goalType", 0);
        var goal = getPropertyNum("goal", 2026);
        var startingDist = getPropertyNum("startingDist", 0);

        // Get current date info
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var year = info.year;
        var month = info.month;
        var day = info.day;

        // Update accumulated distance tracking
        var isYearly = goalType == 0;
        updateAccumulation(year, month, day, isYearly);

        // Calculate days in period and remaining
        var daysInPeriod;
        var currentDayOfPeriod;

        if (isYearly) {
            daysInPeriod = isLeapYear(year) ? 366 : 365;
            currentDayOfPeriod = getDayOfYear(year, month, day);
        } else {
            daysInPeriod = getDaysInMonth(year, month);
            currentDayOfPeriod = day;
        }

        var daysRemaining = daysInPeriod - currentDayOfPeriod;

        // Total distance: starting + accumulated + today
        // startingDist and goal are in user's chosen unit
        // accumulated and today are in km, convert to user unit
        var trackedDist = (getAccumulatedKm() + getTodayKm()) * unitConversion;
        var completed = startingDist.toFloat() + trackedDist;
        var remaining = goal.toFloat() - completed;
        if (remaining < 0) { remaining = 0.0; }

        var progress = 0.0;
        if (goal > 0) {
            progress = (completed / goal.toFloat()) * 100.0;
        }

        var startOfPeriodPace = goal.toFloat() / daysInPeriod.toFloat();
        var requiredPace = 0.0;
        if (daysRemaining > 0) {
            requiredPace = remaining / daysRemaining.toFloat();
        }

        var requiredPerWeek = requiredPace * 7.0;
        var requiredPerMonth = requiredPace * 30.44;

        var isComplete = completed >= goal;
        var isAhead = requiredPace <= startOfPeriodPace;

        var statusColor = isComplete ? aheadColor : (isAhead ? aheadColor : behindColor);

        // Draw based on current page
        if (currentPage == 0) {
            drawOverviewPage(dc, goal, completed, remaining, progress, statusColor);
        } else if (currentPage == 1) {
            drawPacePage(dc, requiredPace, requiredPerWeek, requiredPerMonth, daysRemaining, isYearly);
        } else {
            drawSettingsPage(dc, goal, goalType);
        }

        // Draw page indicators
        drawPageIndicators(dc);
    }

    function drawOverviewPage(dc, goal, completed, remaining, progress, statusColor) {
        var topMargin = (screenHeight * 0.12).toNumber();
        var arcMargin = (screenWidth * 0.12).toNumber();
        var arcRadius = (screenWidth / 2) - arcMargin;
        var arcWidth = (screenWidth * 0.035).toNumber();
        if (arcWidth < 4) { arcWidth = 4; }
        if (arcWidth > 10) { arcWidth = 10; }

        // Title - just the goal amount
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, topMargin, Graphics.FONT_XTINY,
            Lang.format("$1$ $2$", [formatNumber(goal), unitLabel]),
            Graphics.TEXT_JUSTIFY_CENTER);

        // Progress arc - background track
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(arcWidth);
        dc.drawArc(centerX, centerY, arcRadius, Graphics.ARC_COUNTER_CLOCKWISE, 135, 45);

        // Progress arc - filled portion
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        if (progress > 0.0) {
            var cappedProgress = progress;
            if (cappedProgress > 100.0) { cappedProgress = 100.0; }
            var endAngle = 135.0 + ((cappedProgress / 100.0) * 270.0);
            if (endAngle >= 360.0) { endAngle = endAngle - 360.0; }
            dc.drawArc(centerX, centerY, arcRadius, Graphics.ARC_COUNTER_CLOCKWISE, 135, endAngle.toNumber());
        }
        dc.setPenWidth(1);

        // Center content: completed + label + remaining (all inside arc)
        var numFont = Graphics.FONT_NUMBER_MEDIUM;
        if (completed >= 1000) {
            numFont = Graphics.FONT_NUMBER_MILD;
        }
        var numHeight = dc.getFontHeight(numFont);
        var xtinyHeight = dc.getFontHeight(Graphics.FONT_XTINY);

        // Vertical stack: [number] [done label] [remaining amount] [remaining label]
        var totalHeight = numHeight + (xtinyHeight * 3);
        var startY = centerY - (totalHeight / 2) - 5;

        // Completed distance (large number)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, startY, numFont, formatDistance(completed), Graphics.TEXT_JUSTIFY_CENTER);

        // "km done" / "mi done" label
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, startY + numHeight - 5, Graphics.FONT_XTINY,
            Lang.format("$1$ done", [unitLabel]),
            Graphics.TEXT_JUSTIFY_CENTER);

        // Remaining (inside arc, two compact lines)
        var remainingY = startY + numHeight + xtinyHeight + 2;
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, remainingY, Graphics.FONT_XTINY,
            Lang.format("$1$ $2$", [formatDistance(remaining), unitLabel]),
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, remainingY + xtinyHeight - 2, Graphics.FONT_XTINY,
            "remaining",
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawPacePage(dc, requiredPace, requiredPerWeek, requiredPerMonth, daysRemaining, isYearly) {
        var topMargin = (screenHeight * 0.10).toNumber();
        var fontTinyHeight = dc.getFontHeight(Graphics.FONT_TINY);
        var fontXtinyHeight = dc.getFontHeight(Graphics.FONT_XTINY);
        var fontSmallHeight = dc.getFontHeight(Graphics.FONT_SMALL);

        // Title
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, topMargin, Graphics.FONT_TINY, "AVG REQUIRED", Graphics.TEXT_JUSTIFY_CENTER);

        // Subtitle - days left
        var subtitleY = topMargin + fontTinyHeight - 2;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, subtitleY, Graphics.FONT_XTINY,
            Lang.format("$1$ days left", [daysRemaining]),
            Graphics.TEXT_JUSTIFY_CENTER);

        // Pace items - single line each
        var contentStartY = subtitleY + fontXtinyHeight + 10;
        var lineSpacing = fontSmallHeight + 4;
        var u = unitLabel;

        // per day
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, contentStartY, Graphics.FONT_SMALL,
            Lang.format("$1$/day - $2$", [u, requiredPace.format("%.2f")]),
            Graphics.TEXT_JUSTIFY_CENTER);

        // per week
        dc.drawText(centerX, contentStartY + lineSpacing, Graphics.FONT_SMALL,
            Lang.format("$1$/week - $2$", [u, requiredPerWeek.format("%.1f")]),
            Graphics.TEXT_JUSTIFY_CENTER);

        // per month (only for yearly goal)
        if (isYearly) {
            dc.drawText(centerX, contentStartY + (lineSpacing * 2), Graphics.FONT_SMALL,
                Lang.format("$1$/month - $2$", [u, requiredPerMonth.format("%.1f")]),
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawSettingsPage(dc, goal, goalType) {
        var topMargin = (screenHeight * 0.12).toNumber();
        var fontTinyHeight = dc.getFontHeight(Graphics.FONT_TINY);
        var fontSmallHeight = dc.getFontHeight(Graphics.FONT_SMALL);
        var fontXtinyHeight = dc.getFontHeight(Graphics.FONT_XTINY);

        // Title
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, topMargin, Graphics.FONT_TINY, "SETTINGS", Graphics.TEXT_JUSTIFY_CENTER);

        // "Current Goal" label
        var labelY = topMargin + fontTinyHeight + 5;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, labelY, Graphics.FONT_SMALL, "Current Goal", Graphics.TEXT_JUSTIFY_CENTER);

        // Goal number
        var goalY = labelY + fontSmallHeight + 2;
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        var goalFont = Graphics.FONT_NUMBER_MEDIUM;
        var goalFontHeight = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM);
        if (goal >= 10000) {
            goalFont = Graphics.FONT_NUMBER_MILD;
            goalFontHeight = dc.getFontHeight(Graphics.FONT_NUMBER_MILD);
        }
        dc.drawText(centerX, goalY, goalFont, formatNumber(goal), Graphics.TEXT_JUSTIFY_CENTER);

        // unit label (kilometers / miles)
        var kmLabelY = goalY + goalFontHeight - 5;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, kmLabelY, Graphics.FONT_XTINY, unitLabelLong, Graphics.TEXT_JUSTIFY_CENTER);

        // Goal type
        var typeY = kmLabelY + fontXtinyHeight + 5;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var typeText = (goalType == 0) ? "Yearly Goal" : "Monthly Goal";
        dc.drawText(centerX, typeY, Graphics.FONT_TINY, typeText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawPageIndicators(dc) {
        var dotY = screenHeight - (screenHeight * 0.04).toNumber();
        var dotSpacing = (screenWidth * 0.04).toNumber();
        if (dotSpacing < 6) { dotSpacing = 6; }
        var dotRadius = (screenWidth * 0.01).toNumber();
        if (dotRadius < 2) { dotRadius = 2; }
        if (dotRadius > 3) { dotRadius = 3; }

        var startX = centerX - ((MAX_PAGES - 1) * dotSpacing / 2);

        for (var i = 0; i < MAX_PAGES; i++) {
            var dotX = startX + (i * dotSpacing);
            if (i == currentPage) {
                dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(dotX, dotY, dotRadius);
        }
    }

    // Format number with comma separator for thousands
    function formatNumber(num) {
        if (num >= 1000) {
            var thousands = (num / 1000).toNumber();
            var remainder = num - (thousands * 1000);
            return Lang.format("$1$,$2$", [thousands, remainder.format("%03d")]);
        }
        return num.format("%d");
    }

    // Format distance appropriately based on size
    function formatDistance(dist) {
        if (dist >= 1000) {
            return dist.format("%.0f");
        }
        return dist.format("%.1f");
    }

    // Read a numeric property with default
    function getPropertyNum(key, defaultVal) {
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

    // Update daily distance accumulation in Storage.
    // Tracks today's distance via ActivityMonitor, accumulates previous days.
    // Resets when the goal period (year or month) changes.
    function updateAccumulation(year, month, day, isYearly) {
        var storedYear = Storage.getValue("lastYear");
        var storedMonth = Storage.getValue("lastMonth");
        var storedDay = Storage.getValue("lastDay");
        var accKm = Storage.getValue("accKm");
        var lastDayDist = Storage.getValue("lastDayDist");

        if (accKm == null) { accKm = 0.0; }
        if (lastDayDist == null) { lastDayDist = 0; }

        // Check for period rollover (new year or new month)
        var periodReset = false;
        if (isYearly && storedYear != null && storedYear < year) {
            periodReset = true;
        }
        if (!isYearly && storedMonth != null &&
            (storedYear != null && (storedYear < year || storedMonth < month))) {
            periodReset = true;
        }

        if (periodReset) {
            accKm = 0.0;
            lastDayDist = 0;
        } else if (storedDay != null && storedDay != day) {
            // New day - add previous day's final distance to accumulated
            accKm = accKm + (lastDayDist.toFloat() / 100000.0);
            lastDayDist = 0;
        }

        // Get today's live distance from ActivityMonitor
        var todayDist = 0;
        if (Toybox has :ActivityMonitor && ActivityMonitor has :getInfo) {
            var monitorInfo = ActivityMonitor.getInfo();
            if (monitorInfo != null && monitorInfo has :distance && monitorInfo.distance != null) {
                todayDist = monitorInfo.distance;
            }
        }

        // Persist to Storage
        Storage.setValue("accKm", accKm);
        Storage.setValue("lastYear", year);
        Storage.setValue("lastMonth", month);
        Storage.setValue("lastDay", day);
        Storage.setValue("lastDayDist", todayDist);
    }

    // Get accumulated km from previous days (from Storage)
    function getAccumulatedKm() {
        var accKm = Storage.getValue("accKm");
        if (accKm == null) { return 0.0; }
        return accKm.toFloat();
    }

    // Get today's live distance in km
    function getTodayKm() {
        if (Toybox has :ActivityMonitor && ActivityMonitor has :getInfo) {
            var monitorInfo = ActivityMonitor.getInfo();
            if (monitorInfo != null && monitorInfo has :distance && monitorInfo.distance != null) {
                return monitorInfo.distance.toFloat() / 100000.0;
            }
        }
        return 0.0;
    }

    // Helper: Check if leap year
    function isLeapYear(year) {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }

    // Helper: Get day of year
    function getDayOfYear(year, month, day) {
        var totalDays = day;
        for (var i = 0; i < month - 1; i++) {
            totalDays += DAYS_IN_MONTHS[i];
        }
        if (isLeapYear(year) && month > 2) {
            totalDays += 1;
        }
        return totalDays;
    }

    // Helper: Get days in month
    function getDaysInMonth(year, month) {
        if (isLeapYear(year) && month == 2) {
            return 29;
        }
        return DAYS_IN_MONTHS[month - 1];
    }

    // Navigate to next page
    function nextPage() {
        currentPage = (currentPage + 1) % MAX_PAGES;
        WatchUi.requestUpdate();
    }

    // Navigate to previous page
    function previousPage() {
        currentPage = currentPage - 1;
        if (currentPage < 0) {
            currentPage = MAX_PAGES - 1;
        }
        WatchUi.requestUpdate();
    }
}
