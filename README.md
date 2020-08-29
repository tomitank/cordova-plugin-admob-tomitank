# Cordova AdMob Plugin

Created for iOS 14 AppTrackingTransparency.

This plugin use cordova-plugin-admob-sdk-tomitank

Based on https://github.com/ratson/cordova-plugin-admob-free

Usage:
-------------------------------------------------------
```
admob.getTrackingStatus().then(function(result) {
    alert(status);
});

admob.trackingStatusForm().then(function(result) {
    alert(status);
    // load + show ads..
    // admob.banner.prepare();
    // etc..
});
```

Result:
-------------------------------------------------------
This plugin return the AppTrackingTransparency status as string. So you can write extra notification for user.
Info: https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus

Support:
-------------------------------------------------------
If you want to support please write here: tanky.hu@gmail.com

ENJOY!
