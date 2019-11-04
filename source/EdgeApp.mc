using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class EdgeApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        if( Ui has :WatchFaceDelegate ) {
            return [new EdgeView(), new EdgeDelegate()];
        } else {
            return [new EdgeView()];
        }
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
        showSecondsSetting = App.getApp().getProperty("ShowSeconds");
        fgColor = App.getApp().getProperty("ForegroundColor");
        showMoveBars = App.getApp().getProperty("ShowMoveBars");
        leftBarInfo = App.getApp().getProperty("LeftBarInfo");
        rightBarInfo = App.getApp().getProperty("RightBarInfo");
        showHistoryPercentages = App.getApp().getProperty("ShowHistoryPercentages");
        dataFieldInfo = App.getApp().getProperty("DataFieldInfo");
        showDataFieldIcon = App.getApp().getProperty("ShowDataFieldIcon");

        Ui.requestUpdate();
    }

}