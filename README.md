# Cordova AdMob Plugin

Created for iOS 14 AppTrackingTransparency. Based on https://github.com/ratson/cordova-plugin-admob-free

1.) use my plugin: (based on cordova-plugin-admob-free)
-------------------------------------------------------
https://www.npmjs.com/package/cordova-plugin-admob-tomitank

2.) Build & ENJOY!
 -------------------------------------------------------
`cordova build ios`

This plugin use cordova-plugin-admob-sdk-tomitank

Drawbacks & Bugs:
-------------------------------------------------------
- you need to call first "admob.banner.prepare()" otherwise it doesn't work (same as the original plugin)
  this call the  AppTrackingTransparency permission.

- for unknown reasons, if the user does not respond for too long, the application will freeze. if you know the solution please let me know.

Extra:
-------------------------------------------------------
my plugin return the AppTrackingTransparency status integer as string. so you can write extra notification for user.

Here is the possible values: https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus
authorized: 3
denied: 2

Usage:
-------------------------------------------------------
```
admob.banner.prepare().then(function(result) {
    alert(status);
});
```
