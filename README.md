# Cordova AdMob Plugin

Created for iOS 14 AppTrackingTransparency.

This plugin use cocoapods for iOS dependencies!

Usage:
-------------------------------------------------------
Use with User Messaging Platform SDK (recommended)
```
admob.userMessagingPlatform().then(function(result) {
    alert(result);
}).catch(function(error) {
    alert(error);
}).then(function() { // load ads in every case..
    // load + show ads..
});

OR use directly with iOS 14 AppTrackingTransparency module:
```
admob.getTrackingStatus().then(function(result) {

    alert(result);

    admob.trackingStatusForm().then(function(result) {
        alert(result);
        // load + show ads..
    });
});
```

- all others functions same as in https://github.com/ratson/cordova-plugin-admob-free

Result:
-------------------------------------------------------
User Messaging Platform:
Error callback: umpError, formError
Success callback: noSharedInstance, formStatusNotAvailable, obtained, notObtained, keepTheForm
AppTrackingTransparency:
This plugin return the AppTrackingTransparency status name. So you can write extra notification for user.
Info: https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus

Support:
-------------------------------------------------------
If you want to support please write here: tanky.hu@gmail.com

ENJOY!
