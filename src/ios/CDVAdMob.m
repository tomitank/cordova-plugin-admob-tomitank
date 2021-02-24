#import "CDVAdMob.h"

@interface CDVAdMob()

- (void) resizeViews;
- (void) __createBanner;
- (void) __showAd:(BOOL)show;
- (BOOL) __showInterstitial:(BOOL)show;
- (void) __setOptions:(NSDictionary*) options;
- (void) __loadForm:(CDVInvokedUrlCommand*)command;

- (GADRequest*) __buildAdRequest;
- (NSString *)  __getAdMobDeviceId;
- (NSString*)   __md5: (NSString*) string;
- (GADAdSize)   __AdSizeFromString:(NSString *)string;

- (void) deviceOrientationChange:(NSNotification *)notification;
- (void) fireEvent:(NSString *)obj event:(NSString *)eventName withData:(NSString *)jsonStr;

@end

@implementation CDVAdMob

@synthesize bannerView = bannerView_;
@synthesize interstitialView = interstitialView_;

@synthesize publisherId, interstitialAdId, adSize;
@synthesize bannerAtTop, bannerOverlap, offsetTopBar;
@synthesize isTesting, adExtras;

@synthesize bannerIsVisible, bannerIsInitialized;
@synthesize bannerShow, autoShow, autoShowBanner, autoShowInterstitial;

@synthesize forChild;

#define DEFAULT_BANNER_ID       @"ca-app-pub-3940256099942544/2934735716"
#define DEFAULT_INTERSTITIAL_ID @"ca-app-pub-3940256099942544/4411468910"

#define OPT_INTERSTITIAL_ADID   @"interstitialAdId"
#define OPT_OFFSET_TOPBAR       @"offsetTopBar"
#define OPT_BANNER_AT_TOP       @"bannerAtTop"
#define OPT_PUBLISHER_ID        @"publisherId"
#define OPT_IS_TESTING          @"isTesting"
#define OPT_AD_EXTRAS           @"adExtras"
#define OPT_AUTO_SHOW           @"autoShow"
#define OPT_FORCHILD            @"forChild"
#define OPT_OVERLAP             @"overlap"
#define OPT_AD_SIZE             @"adSize"

#pragma mark Cordova JS bridge

- (void) pluginInitialize {
    [super pluginInitialize];
    if (self) {
        // These notifications are required for re-placing the ad on orientation
        // changes. Start listening for notifications here since we need to
        // translate the Smart Banner constants according to the orientation.
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(deviceOrientationChange:)
         name:UIDeviceOrientationDidChangeNotification
         object:nil];
    }

    bannerShow = true;
    publisherId = DEFAULT_BANNER_ID;
    interstitialAdId = DEFAULT_INTERSTITIAL_ID;
    adSize = [self __AdSizeFromString:@"SMART_BANNER"];

    bannerAtTop = false;
    bannerOverlap = false;
    offsetTopBar = false;
    isTesting = false;

    autoShow = true;
    autoShowBanner = true;
    autoShowInterstitial = false;

    bannerIsInitialized = false;
    bannerIsVisible = false;

    forChild = nil;

    srand((unsigned int)time(NULL));

    [self initializeSafeAreaBackgroundView];
}

- (void) setOptions:(CDVInvokedUrlCommand *)command {
    NSLog(@"setOptions");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];

        [self __setOptions:options];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// iOS 14 AppTrackingTransparency (Recommended: UMP is buggy! 2020.09.22) (added by tomitank)
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

 #pragma mark AppTrackingTransparency implementation

- (void) getTrackingStatus:(CDVInvokedUrlCommand *)command {
    NSLog(@"getTrackingStatus");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;

    if (@available(iOS 14.0, *)) {

        if ([ATTrackingManager trackingAuthorizationStatus] == ATTrackingManagerAuthorizationStatusNotDetermined) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"notDetermined"];
        } else if ([ATTrackingManager trackingAuthorizationStatus] == ATTrackingManagerAuthorizationStatusRestricted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"restricted"];
        } else if ([ATTrackingManager trackingAuthorizationStatus] == ATTrackingManagerAuthorizationStatusDenied)  {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"denied"];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"authorized"];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"authorized"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) trackingStatusForm:(CDVInvokedUrlCommand *)command {
    NSLog(@"trackingStatusForm");

    if (@available(iOS 14.0, *)) {

        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            [self getTrackingStatus:command]; // return with status string instead of "status" variable..
        }];

    } else {

        [self getTrackingStatus:command]; // return with authorized string..
    }
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// User Messaging Platform SDK (added by tomitank)
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

 #pragma mark UserMessagingPlatform implementation

- (void) userMessagingPlatform:(CDVInvokedUrlCommand *)command {

    // Create a UMPRequestParameters object.
    UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
    // Set tag for under age of consent. Here NO means users are not under age.
    parameters.tagForUnderAgeOfConsent = NO;
    // Request an update to the consent information.

    if (!UMPConsentInformation.sharedInstance) {
        NSLog(@"No shared instance");

        CDVPluginResult *pluginResult;
        NSString *callbackId = command.callbackId;

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"noSharedInstance"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }

    [UMPConsentInformation.sharedInstance requestConsentInfoUpdateWithParameters:parameters completionHandler:^(NSError* _Nullable error) {
        NSLog(@"sharedInstance");

        CDVPluginResult *pluginResult;
        NSString *callbackId = command.callbackId;

        // The consent information has updated.
        if (error) {
            // Handle the error.
            NSLog(@"UMP error %@", error);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"umpError"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        } else {
            // The consent information state was updated.
            // You are now ready to see if a form is available.
            NSLog(@"Proceed to form..");
            UMPFormStatus formStatus = UMPConsentInformation.sharedInstance.formStatus;
            if (formStatus == UMPFormStatusAvailable) {
                NSLog(@"Loading form..");
                [self __loadForm:command];
            } else {
                NSLog(@"Form status is not available");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"formStatusNotAvailable"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            }
        }
    }];
}

- (void) __loadForm:(CDVInvokedUrlCommand *)command {

    [UMPConsentForm loadWithCompletionHandler:^(UMPConsentForm *form, NSError *loadError) {

        CDVPluginResult *pluginResult;
        NSString *callbackId = command.callbackId;

        if (loadError) {
            // Handle the error.
            NSLog(@"Form error %@", loadError);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"formError"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        } else {
            // Present the form. You can also hold on to the reference to present later.
            NSLog(@"Presenting form..");
            if (UMPConsentInformation.sharedInstance.consentStatus == UMPConsentStatusRequired) {
                    [form presentFromViewController:self.viewController completionHandler:^(NSError *_Nullable dismissError) {

                        CDVPluginResult *pluginResult;
                        NSString *callbackId = command.callbackId;

                        if (UMPConsentInformation.sharedInstance.consentStatus == UMPConsentStatusObtained) {
                            // App can start requesting ads.
                            NSLog(@"Obtained");
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"obtained"];
                        } else {
                            NSLog(@"Not obtained");
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"notObtained"];
                        }
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                    }];
            } else {
                // Keep the form available for changes to user consent.
                NSLog(@"Keep the form available for changes to user consent.");
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"keepTheForm"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            }
        }
    }];
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Banner public functions
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

// The javascript from the AdMob plugin calls this when createBannerView is

// invoked. This method parses the arguments passed in.

- (void) createBannerView:(CDVInvokedUrlCommand *)command {
    NSLog(@"createBannerView");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
        autoShowBanner = autoShow;
    }

    if(!self.bannerView) {
        [self __createBanner];
    }

    if(autoShowBanner) {
        bannerShow = autoShowBanner;
        [self __showAd:YES];
    }

    NSString *callbackString = self.publisherId;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:callbackString];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) destroyBannerView:(CDVInvokedUrlCommand *)command {
    NSLog(@"destroyBannerView");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;

    if(self.bannerView) {
        [self.bannerView setDelegate:nil];
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
        [self resizeViews];
    }

    // Call the success callback that was passed in through the javascript.
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) showAd:(CDVInvokedUrlCommand *)command {
    NSLog(@"showAd");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;

    BOOL show = YES;
    NSUInteger argc = [arguments count];
    if (argc >= 1) {
        NSString* showValue = [arguments objectAtIndex:0];
        show = showValue ? [showValue boolValue] : YES;
    }

    bannerShow = show;

    if(!self.bannerView) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"bannerView is null, call createBannerView first."];
    } else {
        [self __showAd:show];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) requestAd:(CDVInvokedUrlCommand *)command {
    NSLog(@"requestAd");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }

    if(!self.bannerView) {
        [self __createBanner];
    } else {
        [self.bannerView loadRequest:[self __buildAdRequest]];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Banner private functions
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

- (void) __createBanner {
    NSLog(@"__createBanner");

    // set background color to black
    //self.webView.superview.backgroundColor = [UIColor blackColor];
    //self.webView.superview.tintColor = [UIColor whiteColor];

    if (!self.bannerView) {
        self.bannerView = [[GADBannerView alloc] initWithAdSize:adSize];
        self.bannerView.adUnitID = [self publisherId];
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self.viewController;
        self.bannerIsInitialized = YES;
        self.bannerIsVisible = NO;
        [self resizeViews];
        [self.bannerView loadRequest:[self __buildAdRequest]];
    }
}

- (void) __showAd:(BOOL)show {
    //NSLog(@"Show Ad: %d", show);

    if (!self.bannerIsInitialized) {
        [self __createBanner];
    }

    if (show == self.bannerIsVisible) { // same state, nothing to do
        //NSLog(@"already show: %d", show);
        [self resizeViews];
    } else if (show) {
        //NSLog(@"show now: %d", show);
        UIView* parentView = self.bannerOverlap ? self.webView : [self.webView superview];
        [parentView addSubview:self.bannerView];
        [parentView bringSubviewToFront:self.bannerView];
        [self resizeViews];
        self.bannerIsVisible = YES;
    } else {
        [self.bannerView removeFromSuperview];
        [self resizeViews];
        self.bannerIsVisible = NO;
    }
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Interstitial public functions
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

- (void) prepareInterstitial:(CDVInvokedUrlCommand *)command {
    NSLog(@"prepareInterstitial");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
        autoShowInterstitial = autoShow;
    }

    [self __cycleInterstitial];

    if (self.interstitialView) {
        NSString *callbackString = self.interstitialAdId;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:callbackString];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to load interstitial ad."];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) showInterstitialAd:(CDVInvokedUrlCommand *)command {
    NSLog(@"showInterstitial");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;

    BOOL showed = [self __showInterstitial:YES];
    if (showed) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"interstitial not ready yet."];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) isInterstitialReady:(CDVInvokedUrlCommand *)command {
    NSLog(@"isInterstitialReady");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;

    if (self.interstitialView && [self.interstitialView canPresentFromRootViewController]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:false];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Interstitial private functions
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

- (void) __cycleInterstitial {
    NSLog(@"__cycleInterstitial");

    // Clean up the old interstitial...
    if (self.interstitialView) {
        self.interstitialView.fullScreenContentDelegate = nil;
        self.interstitialView = nil;
    }

    // and create a new interstitial. We set the delegate so that we can be notified..
    [GADInterstitialAd loadWithAdUnitID:self.interstitialAdId request:[self __buildAdRequest] completionHandler:^(GADInterstitialAd *ad, NSError *error) {
        if (error) {
            NSLog(@"Failed to load interstitial ad with error: %@", [error localizedDescription]);
        }
        self.interstitialView = ad;
        self.interstitialView.fullScreenContentDelegate = self;
    }];
}

- (BOOL) __showInterstitial:(BOOL)show {
    NSLog(@"__showInterstitial");

    if (!self.interstitialView) {
        [self __cycleInterstitial];
    }

    if (self.interstitialView && [self.interstitialView canPresentFromRootViewController]) {
        [self.interstitialView presentFromRootViewController:self.viewController];
        return true;
    } else {
        NSLog(@"Ad wasn't ready");
        return false;
    }
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Cordova events
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

- (void) fireEvent:(NSString *)obj event:(NSString *)eventName withData:(NSString *)jsonStr {
    NSString* js;
    if(obj && [obj isEqualToString:@"window"]) {
        js = [NSString stringWithFormat:@"var evt=document.createEvent(\"UIEvents\");evt.initUIEvent(\"%@\",true,false,window,0);window.dispatchEvent(evt);", eventName];
    } else if(jsonStr && [jsonStr length] > 0) {
        js = [NSString stringWithFormat:@"javascript:cordova.fireDocumentEvent('%@',%@);", eventName, jsonStr];
    } else {
        js = [NSString stringWithFormat:@"javascript:cordova.fireDocumentEvent('%@');", eventName];
    }
    [self.commandDelegate evalJs:js];
}

#pragma mark GADBannerViewDelegate implementation

- (void) bannerView:(GADBannerView *)view didFailToReceiveAdWithError:(NSError *)error {
    NSString* jsonData = [NSString stringWithFormat:@"{ 'error': '%@', 'adType':'banner' }", [error localizedFailureReason]];
    [self fireEvent:@"" event:@"admob.banner.events.LOAD_FAIL" withData:jsonData];
    [self fireEvent:@"" event:@"onFailedToReceiveAd" withData:jsonData];
}

- (void) bannerViewDidReceiveAd:(GADBannerView *)bannerView {
    if(self.bannerShow) {
        [self __showAd:YES];
    }
    NSString* jsonData = [NSString stringWithFormat:@"{ 'bannerHeight': '%d' }", (int)self.bannerView.frame.size.height];
    [self fireEvent:@"" event:@"admob.banner.events.LOAD" withData:jsonData];
    [self fireEvent:@"" event:@"onReceiveAd" withData:nil];
}
/* NOT USED!
- (void) bannerViewWillDismissScreen:(GADBannerView *)bannerView {
    [self fireEvent:@"" event:@"admob.banner.events.EXIT_APP" withData:nil];
    [self fireEvent:@"" event:@"onLeaveToAd" withData:nil];
}
*/
- (void) bannerViewWillPresentScreen:(GADBannerView *)bannerView {
    [self fireEvent:@"" event:@"admob.banner.events.OPEN" withData:nil];
    [self fireEvent:@"" event:@"onPresentAd" withData:nil];
}

- (void) bannerViewDidDismissScreen:(GADBannerView *)bannerView {
    [self fireEvent:@"" event:@"admob.banner.events.CLOSE" withData:nil];
    [self fireEvent:@"" event:@"onDismissAd" withData:nil];
}

#pragma mark GADFullScreenContentDelegate implementation

- (void) interstitial:(GADInterstitialAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    NSString* jsonData = [NSString stringWithFormat:@"{ 'error': '%@', 'adType':'interstitial' }", [error localizedFailureReason]];
    [self fireEvent:@"" event:@"admob.interstitial.events.LOAD_FAIL" withData:jsonData];
    [self fireEvent:@"" event:@"onFailedToReceiveAd" withData:jsonData];
}

- (void) interstitialDidReceiveAd:(GADInterstitialAd *)interstitial {
    [self fireEvent:@"" event:@"admob.interstitial.events.LOAD" withData:nil];
    [self fireEvent:@"" event:@"onReceiveInterstitialAd" withData:nil];
    if (self.interstitialView) {
        if(self.autoShowInterstitial) {
            [self __showInterstitial:YES];
        }
    }
}

- (void) interstitialWillPresentScreen:(GADInterstitialAd *)interstitial {
    [self fireEvent:@"" event:@"admob.interstitial.events.OPEN" withData:nil];
    [self fireEvent:@"" event:@"onPresentInterstitialAd" withData:nil];
}

- (void) interstitialDidDismissScreen:(GADInterstitialAd *)interstitial {
    [self fireEvent:@"" event:@"admob.interstitial.events.CLOSE" withData:nil];
    [self fireEvent:@"" event:@"onDismissInterstitialAd" withData:nil];
    if (self.interstitialView) {
        self.interstitialView.fullScreenContentDelegate = nil;
        self.interstitialView = nil;
        [self resizeViews];
    }
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// __buildAdRequest
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

- (GADRequest*) __buildAdRequest {
    GADRequest *request = [GADRequest request];

    if (self.isTesting) {
        NSString* deviceId = [self __getAdMobDeviceId];
        request.testDevices = @[ kGADSimulatorID, deviceId, [deviceId lowercaseString] ];
        NSLog(@"request.testDevices: %@", deviceId);
    }

    if (self.adExtras) {
        GADExtras *extras = [[GADExtras alloc] init];
        NSMutableDictionary *modifiedExtrasDict =
        [[NSMutableDictionary alloc] initWithDictionary:self.adExtras];
        [modifiedExtrasDict removeObjectForKey:@"cordova"];
        [modifiedExtrasDict setValue:@"1" forKey:@"cordova"];
        extras.additionalParameters = modifiedExtrasDict;
        [request registerAdNetworkExtras:extras];
    }

    if (self.forChild != nil) {
        if ([self.forChild caseInsensitiveCompare:@"yes"] == NSOrderedSame) {
            [request tagForChildDirectedTreatment:YES];
        } else if ([self.forChild caseInsensitiveCompare:@"no"] == NSOrderedSame) {
            [request tagForChildDirectedTreatment:NO];
        }
    }
    return request;
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Options & veiw change & rest functions
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

- (GADAdSize)__AdSizeFromString:(NSString *)string {
    if ([string isEqualToString:@"BANNER"]) {
        return kGADAdSizeBanner;
    } else if ([string isEqualToString:@"IAB_MRECT"]) {
        return kGADAdSizeMediumRectangle;
    } else if ([string isEqualToString:@"IAB_BANNER"]) {
        return kGADAdSizeFullBanner;
    } else if ([string isEqualToString:@"IAB_LEADERBOARD"]) {
        return kGADAdSizeLeaderboard;
    } else if ([string isEqualToString:@"LARGE_BANNER"]) {
        return kGADAdSizeLargeBanner;
    } else if ([string isEqualToString:@"FLUID"]) {
        return kGADAdSizeFluid;
    } else if ([string isEqualToString:@"SMART_BANNER"]) {
        CGRect pr = self.webView.superview.bounds;
        if(pr.size.width > pr.size.height) {
            return kGADAdSizeSmartBannerLandscape;
        }
        else {
            return kGADAdSizeSmartBannerPortrait;
        }
    } else if ([string isEqualToString:@"ADAPTIVE_BANNER"]) {
        CGRect pr = self.webView.superview.bounds;
        GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(pr.size.width);
    } else {
        return kGADAdSizeInvalid;
    }
}

- (NSString*) __getAdMobDeviceId {
    NSUUID* adid = [[ASIdentifierManager sharedManager] advertisingIdentifier];
    return [self __md5:adid.UUIDString];
}

- (NSString*) __md5:(NSString *) s {
    const char *cstr = [s UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);

    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark Ad Banner logic

- (void) __setOptions:(NSDictionary*) options {
    if ((NSNull *)options == [NSNull null]) return;

    NSString* str = nil;

    str = [options objectForKey:OPT_PUBLISHER_ID];
    if (str && [str length] > 0) {
        publisherId = str;
    }

    str = [options objectForKey:OPT_INTERSTITIAL_ADID];
    if (str && [str length] > 0) {
        interstitialAdId = str;
    }

    str = [options objectForKey:OPT_AD_SIZE];
    if (str) {
        adSize = [self __AdSizeFromString:str];
    }

    str = [options objectForKey:OPT_BANNER_AT_TOP];
    if (str) {
        bannerAtTop = [str boolValue];
    }

    str = [options objectForKey:OPT_OVERLAP];
    if (str) {
        bannerOverlap = [str boolValue];
    }

    str = [options objectForKey:OPT_OFFSET_TOPBAR];
    if (str) {
        offsetTopBar = [str boolValue];
    }

    str = [options objectForKey:OPT_IS_TESTING];
    if (str) {
        isTesting = [str boolValue];
    }

    NSDictionary* dict = [options objectForKey:OPT_AD_EXTRAS];
    if (dict) {
        adExtras = dict;
    }

    str = [options objectForKey:OPT_AUTO_SHOW];
    if (str) {
        autoShow = [str boolValue];
    }

    str = [options objectForKey:OPT_FORCHILD];
    if (str && [str length] > 0) {
        forChild = str;
    } else if (str && [str length] == 0) {
        forChild = nil;
    }
}

- (void) deviceOrientationChange:(NSNotification *)notification {
    [self resizeViews];
}

- (void) initializeSafeAreaBackgroundView
{
    if (@available(iOS 11.0, *)) {

        UIView* parentView = self.bannerOverlap ? self.webView : [self.webView superview];
        CGRect pr = self.webView.superview.bounds;

        CGRect safeAreaFrame = CGRectMake(0, 0, 0, 0);

        safeAreaFrame.origin.y = pr.size.height - parentView.safeAreaInsets.bottom;
        safeAreaFrame.size.width = pr.size.width;
        safeAreaFrame.size.height = parentView.safeAreaInsets.bottom;

        _safeAreaBackgroundView = [[UIView alloc] initWithFrame:safeAreaFrame];
        _safeAreaBackgroundView.backgroundColor = [UIColor blackColor];
        _safeAreaBackgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth  | UIViewAutoresizingFlexibleBottomMargin);
        _safeAreaBackgroundView.autoresizesSubviews = YES;
        _safeAreaBackgroundView.hidden = true;

        [self.webView.superview addSubview:_safeAreaBackgroundView];
    }
}

- (void) resizeViews {
    // Frame of the main container view that holds the Cordova webview.
    CGRect pr = self.webView.superview.bounds, wf = pr;
    //NSLog(@"super view: %d x %d", (int)pr.size.width, (int)pr.size.height);

    // iOS7 Hack, handle the Statusbar
    //BOOL isIOS7 = ([[UIDevice currentDevice].systemVersion floatValue] >= 7);
    //CGRect sf = [[UIApplication sharedApplication] statusBarFrame];
    //CGFloat top = isIOS7 ? MIN(sf.size.height, sf.size.width) : 0.0;
    float top = 0.0;

    //if(!self.offsetTopBar) top = 0.0;

    wf.origin.y = top;
    wf.size.height = pr.size.height - top;

    if (self.bannerView) {
        if (pr.size.width > pr.size.height ) {
            if(GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerPortrait)) {
                self.bannerView.adSize = kGADAdSizeSmartBannerLandscape;
            }
        } else {
            if(GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerLandscape)) {
                self.bannerView.adSize = kGADAdSizeSmartBannerPortrait;
            }
        }

        CGRect bf = self.bannerView.frame;

        // if the ad is not showing or the ad is hidden, we don't want to resize anything.
        UIView* parentView = self.bannerOverlap ? self.webView : [self.webView superview];
        BOOL adIsShowing = ([self.bannerView isDescendantOfView:parentView]) && (!self.bannerView.hidden);

        if (adIsShowing) {
            //NSLog( @"banner visible" );
            if (bannerAtTop) {
                if(bannerOverlap) {
                    wf.origin.y = top;
                    bf.origin.y = 0; // banner is subview of webview

                    if (@available(iOS 11.0, *)) {
                        bf.origin.y = parentView.safeAreaInsets.top;
                        bf.size.width = wf.size.width - parentView.safeAreaInsets.left - parentView.safeAreaInsets.right;
                    }
                } else {
                    bf.origin.y = top;
                    wf.origin.y = bf.origin.y + bf.size.height;

                    if (@available(iOS 11.0, *)) {
                        bf.origin.y += parentView.safeAreaInsets.top;
                        wf.origin.y += parentView.safeAreaInsets.top;
                        bf.size.width = wf.size.width - parentView.safeAreaInsets.left - parentView.safeAreaInsets.right;
                        wf.size.height -= parentView.safeAreaInsets.top;

                        // if safeAreBackground was turned turned off, turn it back on
                        _safeAreaBackgroundView.hidden = false;

                        CGRect saf = _safeAreaBackgroundView.frame;
                        saf.origin.y = top;
                        saf.size.width = pr.size.width;
                        saf.size.height = parentView.safeAreaInsets.top;

                        _safeAreaBackgroundView.frame = saf;
                        _safeAreaBackgroundView.bounds = saf;
                    }
                }

            } else {
                // move webview to top
                wf.origin.y = top;

                if (bannerOverlap) {
                    bf.origin.y = wf.size.height - bf.size.height; // banner is subview of webview

                    if (@available(iOS 11.0, *)) {
                        bf.origin.y -= parentView.safeAreaInsets.bottom;
                        bf.size.width = wf.size.width - parentView.safeAreaInsets.left - parentView.safeAreaInsets.right;
                    }
                } else {
                    bf.origin.y = pr.size.height - bf.size.height;

                    if (@available(iOS 11.0, *)) {
                        bf.origin.y -= parentView.safeAreaInsets.bottom;
                        bf.size.width = wf.size.width - parentView.safeAreaInsets.left - parentView.safeAreaInsets.right;
                        wf.size.height -= parentView.safeAreaInsets.bottom;

                        // if safeAreBackground was turned turned off, turn it back on
                        _safeAreaBackgroundView.hidden = false;

                        CGRect saf = _safeAreaBackgroundView.frame;
                        saf.origin.y = pr.size.height - parentView.safeAreaInsets.bottom;
                        saf.size.width = pr.size.width;
                        saf.size.height = parentView.safeAreaInsets.bottom;

                        _safeAreaBackgroundView.frame = saf;
                        _safeAreaBackgroundView.bounds = saf;
                    }
                }
            }

            if(!bannerOverlap) wf.size.height -= bf.size.height;

            bf.origin.x = (pr.size.width - bf.size.width) * 0.5f;

            self.bannerView.frame = bf;

            //NSLog(@"x,y,w,h = %d,%d,%d,%d", (int) bf.origin.x, (int) bf.origin.y, (int) bf.size.width, (int) bf.size.height );
        } else {
            // Hide safe area background if visibile and banner ad does not exist
            _safeAreaBackgroundView.hidden = true;
        }
    } else {
        // Hide safe area background if visibile and banner ad does not exist
        _safeAreaBackgroundView.hidden = true;
    }

    self.webView.frame = wf;

    //NSLog(@"superview: %d x %d, webview: %d x %d", (int) pr.size.width, (int) pr.size.height, (int) wf.size.width, (int) wf.size.height );
}

#pragma mark Cleanup

- (void) dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIDeviceOrientationDidChangeNotification
     object:nil];

    self.bannerView = nil;
    self.interstitialView = nil;

    bannerView_.delegate = nil;
    interstitialView_.fullScreenContentDelegate = nil;

    bannerView_ = nil;
    interstitialView_ = nil;
}

@end
