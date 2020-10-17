# Cordova AdMob Plugin

Created for iOS 14 AppTrackingTransparency.

This plugin use cocoapods for iOS dependencies!

Usage:
-------------------------------------------------------
Use directly with iOS 14 AppTrackingTransparency module (recommended)
```
admob.interstitial.config({ id: admobid.interstitial, isTesting: false, autoShow: false });

admob.banner.config({ id: admobid.banner, overlap: true, isTesting: false, autoShow: true });

admob.getTrackingStatus().then(function(status) { // get status..

    if (status === 'notDetermined') { // not determined..

        navigator.notification.confirm(LANGUAGE.tracking_info_msg, function() { // open a native popup for infos..

            admob.trackingStatusForm().then(function(status) { // iOS tracking form..
                if (status === 'authorized' || status === 'restricted') {
                    // show ads..

                }

                if (status === 'restricted' || status === 'denied') {
                    // not authorized show a motivation popup.. (optional)

                    // navigator.notification.confirm..
                }
            });

        }, LANGUAGE.tracking_info, [LANGUAGE.okay]);

    } else { // determined..

        // show ads..

        if (status === 'authorized' || status === 'restricted') {
            // show ads..

        }

        if (status === 'restricted' || status === 'denied') {
            // not authorized show a motivation popup.. (optional)

            // navigator.notification.confirm..
        }
    }
});
```
OR Use with User Messaging Platform SDK (not recommended - 2020.09.22)
```
admob.userMessagingPlatform().then(function(result) {
    alert(result);
}).catch(function(error) {
    alert(error);
}).then(function() { // load ads in every case..
    // load + show ads..
});
```

Difference against the admob-free plugin:
-------------------------------------------------------
All prepare() functions return the ad id!
```
admob.banner.prepare().then(function(ad_id) {});
admob.rewardvideo.prepare().then(function(ad_id) {});
admob.interstitial.prepare().then(function(ad_id) {});
```

- all others functions same as in https://github.com/ratson/cordova-plugin-admob-free

Result:
-------------------------------------------------------
1. AppTrackingTransparency:
This plugin return the AppTrackingTransparency status name. So you can write extra notification for user.
Info: https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus
2. User Messaging Platform:
Error callback: umpError, formError
Success callback: noSharedInstance, formStatusNotAvailable, obtained, notObtained, keepTheForm

Support:
-------------------------------------------------------
If you want to support please write here: tanky.hu@gmail.com

ENJOY!
