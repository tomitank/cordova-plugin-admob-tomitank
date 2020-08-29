# Cordova AdMob Plugin

Created for iOS 14 AppTrackingTransparency.

This plugin use cordova-plugin-admob-sdk-tomitank

Based on https://github.com/ratson/cordova-plugin-admob-free

Usage:
-------------------------------------------------------
```
admob.banner.prepare().then(function(result) {
    alert(status);
});
```

Result:
-------------------------------------------------------
This plugin return the AppTrackingTransparency status as string. So you can write extra notification for user.
Info: https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus

Drawbacks & Bugs:
-------------------------------------------------------
- you need to call first "admob.banner.prepare()" otherwise it doesn't work (same as the original plugin)
  this call the  AppTrackingTransparency permission.

- for unknown reasons, if the user does not respond for too long, the application will freeze. if you know the solution please let me know.

ENJOY!
