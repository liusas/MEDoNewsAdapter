//
//  MEDoNewsAdapter.m
//  MEDoNewsAdapter
//
//  Created by 刘峰 on 2020/10/26.
//

#import "MEDoNewsAdapter.h"
#import <DNAdSDK/DNAdSDK.h>

// Initialization configuration keys
static NSString * const kDoNewsAppID = @"appid";

// Errors
static NSString * const kAdapterErrorDomain = @"com.mobipub.mobipub-ios-sdk.mobipub-donews-adapter";

typedef NS_ENUM(NSInteger, DoNewsAdapterErrorCode) {
    DoNewsAdapterErrorCodeMissingAppId,
};

@implementation MEDoNewsAdapter

#pragma mark - Caching

+ (void)updateInitializationParameters:(NSDictionary *)parameters {
    // These should correspond to the required parameters checked in
    // `initializeNetworkWithConfiguration:complete:`
    NSString * appId = parameters[kDoNewsAppID];
    
    if (appId != nil) {
        NSDictionary * configuration = @{ kDoNewsAppID: appId };
        [MEDoNewsAdapter setCachedInitializationParameters:configuration];
    }
}

#pragma mark - MPAdapterConfiguration

- (NSString *)adapterVersion {
    return @"1.0.0";
}

- (NSString *)biddingToken {
    return nil;
}

- (NSString *)mobiNetworkName {
    return @"donews";
}

- (NSString *)networkSdkVersion {
    return @"5.6";
}

#pragma mark - MobiPub ad type
- (Class)getSplashCustomEvent {
    return NSClassFromString(@"MobiDoNewsSplashCustomEvent");
}

- (Class)getBannerCustomEvent {
    return NSClassFromString(@"MobiDoNewsBannerCustomEvent");
}

- (Class)getFeedCustomEvent {
    return NSClassFromString(@"MobiDoNewsFeedCustomEvent");
}

- (Class)getInterstitialCustomEvent {
    return NSClassFromString(@"MobiDoNewsInterstitialCustomEvent");
}

- (Class)getRewardedVideoCustomEvent {
    return NSClassFromString(@"MobiDoNewsRewardedVideoCustomEvent");
}

- (Class)getFullscreenCustomEvent {
    return NSClassFromString(@"MobiDoNewsFullscreenCustomEvent");
}

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *,id> *)configuration complete:(void (^)(NSError * _Nullable))complete {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *appid = configuration[kDoNewsAppID];
        
        DNAdKitManager *mgr = DNAdKitManager.sharedManager;
        mgr.showDebugLog = YES;
        /// 调用这句可检测联盟SDK引用状况，可用来判断大部分不走代理，无回调问题
        [mgr printAllSDKVersionInfo];
        [mgr startService];
        
        if (complete != nil) {
            complete(nil);
        }
    });
}

// MoPub collects GDPR consent on behalf of Google
+ (NSString *)npaString
{
//    return !MobiPub.sharedInstance.canCollectPersonalInfo ? @"1" : @"";
    return @"";
}

/// 获取顶层VC
+ (UIViewController *)topVC {
    UIWindow *rootWindow = [UIApplication sharedApplication].keyWindow;
    if (![[UIApplication sharedApplication].windows containsObject:rootWindow]
        && [UIApplication sharedApplication].windows.count > 0) {
        rootWindow = [UIApplication sharedApplication].windows[0];
    }
    UIViewController *topVC = rootWindow.rootViewController;
    // 未读到keyWindow的rootViewController，则读UIApplicationDelegate的window，但该window不一定存在
    if (nil == topVC && [[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        topVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

@end
