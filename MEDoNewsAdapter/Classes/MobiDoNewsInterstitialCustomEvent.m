//
//  MobiDoNewsInterstitialCustomEvent.m
//  MEDoNewsAdapter
//
//  Created by 刘峰 on 2020/10/26.
//

#import "MobiDoNewsInterstitialCustomEvent.h"
#import <DNAdSDK/DNInterstitialAd.h>

@interface MobiDoNewsInterstitialCustomEvent ()<DNInterstitialAdDelegate>

/// 插屏广告管理
@property (nonatomic, strong) DNInterstitialAd *interstitialAd;

/// 用来弹出广告的 viewcontroller
@property (nonatomic, strong) UIViewController *rootVC;

@end

@implementation MobiDoNewsInterstitialCustomEvent

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    if (adUnitId == nil) {
        NSError *error =
        [NSError errorWithDomain:MobiInterstitialAdsSDKDomain
                            code:MobiInterstitialAdErrorInvalidPosid
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad Unit ID cannot be nil."}];
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    DNInterstitialAd *interstitial = [DNInterstitialAd.alloc initWithPlaceId:adUnitId];
    interstitial.delegate = self;
    _interstitialAd = interstitial; //需要全局持有实例否则实例被销毁将无法正常展示广告
    [interstitial loadAD];
}

/**
 * Called when the interstitial should be displayed.
 *
 * This message is sent sometime after an interstitial has been successfully loaded, as a result
 * of your code calling `-[MPInterstitialAdController showFromViewController:]`. Your implementation
 * of this method should present the interstitial ad from the specified view controller.
 *
 * If you decide to [opt out of automatic impression tracking](enableAutomaticImpressionAndClickTracking), you should place your
 * manual calls to [-trackImpression]([MPInterstitialCustomEventDelegate trackImpression]) in this method to ensure correct metrics.
 *
 * @param rootViewController The controller to use to present the interstitial modally.
 *
 */
- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController {
    if (rootViewController != nil) {
        self.rootVC = rootViewController;
    }
    
    if (self.interstitialAd) {
        [self.interstitialAd interstitialAdShowInController:rootViewController];
        return;
    }
    
    NSError *error =
    [NSError errorWithDomain:MobiInterstitialAdsSDKDomain
                        code:MobiInterstitialAdErrorNoAdsAvailable
                    userInfo:@{NSLocalizedDescriptionKey : @"Cannot present intersitial ads. Cause interstitial ad is invalid"}];
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
}

- (BOOL)hasAdAvailable
{
    if (self.interstitialAd) {
        return YES;
    }
    return NO;
}

/** @name Impression and Click Tracking */

/**
 * Override to opt out of automatic impression and click tracking.
 *
 * By default, the  MPInterstitialCustomEventDelegate will automatically record impressions and clicks in
 * response to the appropriate callbacks. You may override this behavior by implementing this method
 * to return `NO`.
 *
 * @warning **Important**: If you do this, you are responsible for calling the `[-trackImpression]([MPInterstitialCustomEventDelegate trackImpression])` and
 * `[-trackClick]([MPInterstitialCustomEventDelegate trackClick])` methods on the custom event delegate. Additionally, you should make sure that these
 * methods are only called **once** per ad.
 */
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return YES;
}

// MARK: - DNInterstitialAdDelegate
/// 当接收服务器返回的广告数据成功且预加载后调用该函数
/// @param interstitialAd interstitialAd对象本身
- (void)interstitialAdDidLoadSuccessForInterstitialAd:(DNInterstitialAd *)interstitialAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEvent:didLoadAd:)]) {
        [self.delegate interstitialCustomEvent:self didLoadAd:nil];
    }
}

/// 当接收服务器返回的广告数据失败后调用该函数
/// @param interstitialAd interstitialAd对象本身
/// @param error 错误信息
- (void)interstitialAdDidLoadFaildForInterstitialAd:(DNInterstitialAd *)interstitialAd error:(NSError *)error {
    self.rootVC = nil;
    
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEvent:didFailToLoadAdWithError:)]) {
            [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
        }
    }
}

/// 插屏广告即将展示回调该函数
/// @param interstitialAd interstitialAd对象本身
- (void)interstitialAdWillVisibleForInterstitialAd:(DNInterstitialAd *)interstitialAd {
    self.rootVC = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventWillAppear:)]) {
        [self.delegate interstitialCustomEventWillAppear:self];
    }
}

/// 插屏广告展示结束回调该函数
/// @param interstitialAd interstitialAd对象本身
- (void)interstitialAdDidClosedForInterstitialAd:(DNInterstitialAd *)interstitialAd {
    self.rootVC = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventWillDisappear:)]) {
        [self.delegate interstitialCustomEventWillDisappear:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidDisappear:)]) {
        [self.delegate interstitialCustomEventDidDisappear:self];
    }
}

/// 插屏广告曝光回调
/// @param interstitialAd interstitialAd对象本身
- (void)interstitialAdDidExposureForInterstitialAd:(DNInterstitialAd *)interstitialAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidAppear:)]) {
        [self.delegate interstitialCustomEventDidAppear:self];
    }
}

/// 插屏广告点击回调
/// @param interstitialAd interstitialAd对象本身
- (void)interstitialAdDidClickForInterstitialAd:(DNInterstitialAd *)interstitialAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidReceiveTapEvent:)]) {
        [self.delegate interstitialCustomEventDidReceiveTapEvent:self];
    }
}

/// 全屏广告页将要关闭
/// @param interstitialAd interstitialAd对象本身
- (void)interstitialAdDetailsDidClosedForInterstitialAd:(DNInterstitialAd *)interstitialAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidDismissModal:)]) {
        [self.delegate interstitialCustomEventDidDismissModal:self];
    }
}


@end
