using Toybox.Application;
using Toybox.WatchUi;

class KMGoalApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Return the initial view of the application
    function getInitialView() {
        var view = new KMGoalView();
        var delegate = new KMGoalDelegate();
        delegate.setView(view);
        return [view, delegate];
    }

    // Return the glance view for the widget carousel (SDK 3.2+)
    function getGlanceView() {
        if (WatchUi has :GlanceView) {
            return [new KMGoalGlanceView()];
        }
        return null;
    }

    // Handle settings changes from Garmin Connect app
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}
