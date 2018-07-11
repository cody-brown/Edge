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
        Ui.requestUpdate();
    }

}