using Toybox.WatchUi;

class KMGoalDelegate extends WatchUi.BehaviorDelegate {

    hidden var view = null;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function setView(v) {
        view = v;
    }

    // Handle next page (swipe up or select button)
    function onNextPage() {
        if (view != null) {
            view.nextPage();
        }
        return true;
    }

    // Handle previous page (swipe down)
    function onPreviousPage() {
        if (view != null) {
            view.previousPage();
        }
        return true;
    }

    // Handle select/enter button
    function onSelect() {
        return onNextPage();
    }

    // Handle back button - exit widget
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    // Handle tap
    function onTap(clickEvent) {
        return onNextPage();
    }

    // Handle swipe
    function onSwipe(swipeEvent) {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_UP || direction == WatchUi.SWIPE_LEFT) {
            return onNextPage();
        } else if (direction == WatchUi.SWIPE_DOWN || direction == WatchUi.SWIPE_RIGHT) {
            return onPreviousPage();
        }
        return false;
    }
}
