# Cordova AdMob Plugin

Created for iOS 14 AppTrackingTransparency.

This plugin use https://github.com/tomitank/cordova-admob-sdk-tomitank

Based on https://github.com/ratson/cordova-plugin-admob-free

Usage:
-------------------------------------------------------
```
admob.getTrackingStatus().then(function(result) {

    alert(status);

    admob.trackingStatusForm().then(function(result) {
        alert(status);
        // load + show ads..
        // admob.banner.prepare();
        // etc..
    });
});
```

- all others functions same as in https://github.com/ratson/cordova-plugin-admob-free

Result:
-------------------------------------------------------
This plugin return the AppTrackingTransparency status name. So you can write extra notification for user.
Info: https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus

Support:
-------------------------------------------------------
If you want to support please write here: tanky.hu@gmail.com

ENJOY!
