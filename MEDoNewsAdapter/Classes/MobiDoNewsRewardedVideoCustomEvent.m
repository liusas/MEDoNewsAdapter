//
//  MobiDoNewsRewardedVideoCustomEvent.m
//  MEDoNewsAdapter
//
//  Created by 刘峰 on 2020/10/26.
//

#import "MobiDoNewsRewardedVideoCustomEvent.h"
#import <DNAdSDK/DNRewardedVideoAd.h>

@interface MobiDoNewsRewardedVideoCustomEvent () <DNRewardedVideoAdDelegate>
@property(nonatomic, copy) NSString *posid;
/// 激励视频广告管理
@property (nonatomic, strong) DNRewardedVideoAd *rewardedVideoAd;

/// 用来弹出广告的 viewcontroller
@property (nonatomic, strong) UIViewController *rootVC;

@end

@implementation MobiDoNewsRewardedVideoCustomEvent

- (void)requestRewardedVideoWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    if (adUnitId == nil) {
        NSError *error =
        [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain
                            code:MobiRewardedVideoAdErrorInvalidPosid
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad Unit ID cannot be nil."}];
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
        return;
    }
    
    DNRewardedVideoAd *rewardedVideo = [DNRewardedVideoAd.alloc initWithPlaceId:adUnitId];
    rewardedVideo.delegate = self;
    _rewardedVideoAd = rewardedVideo; //需要全局持有实例否则实例被销毁将无法正常展示广告
    [rewardedVideo loadAD];
}

/// 上层调用`presentRewardedVideoFromViewController`展示广告之前,
/// 需要判断这个广告是否还有效,需要在此处返回广告有效性(是否可以直接展示)
- (BOOL)hasAdAvailable {
    return self.rewardedVideoAd.isAdValid;
}

/// 展示激励视频广告
/// 一般在广告加载成功后调用,需要重写这个类,实现弹出激励视频广告
/// 注意,如果重写的`enableAutomaticImpressionAndClickTracking`方法返回NO,
/// 那么需要自行实现`trackImpression`方法进行数据上报,否则不用处理,交由上层的adapter处理即可
/// @param viewController 弹出激励视频广告的类
- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController {
    if (viewController != nil) {
        self.rootVC = viewController;
    }
    
    if (self.rewardedVideoAd.isAdValid == YES) {
        [self.rewardedVideoAd rewardedVideoShowInController:viewController];
        return;
    }
    
    // We will send the error if the rewarded ad has already been presented.
    NSError *error = [NSError
                      errorWithDomain:MobiRewardedVideoAdsSDKDomain
                      code:MobiRewardedVideoAdErrorNoAdReady
                      userInfo:@{NSLocalizedDescriptionKey : @"Rewarded ad is not ready to be presented."}];
    [self.delegate rewardedVideoDidFailToPlayForCustomEvent:self error:error];
}

/// 子类重写次方法,决定由谁处理展现和点击上报
/// 默认return YES;由上层adapter处理展现和点击上报,
/// 若return NO;则由子类实现trackImpression和trackClick方法,实现上报,但要保证每个广告只上报一次
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return YES;
}

 /** MoPub's API includes this method because it's technically possible for two MoPub custom events or
  adapters to wrap the same SDK and therefore both claim ownership of the same cached ad. The
  method will be called if 1) this custom event has already invoked
  rewardedVideoDidLoadAdForCustomEvent: on the delegate, and 2) some other custom event plays a
  rewarded video ad. It's a way of forcing this custom event to double-check that its ad is
  definitely still available and is not the one that just played. If the ad is still available, no
  action is necessary. If it's not, this custom event should call
  rewardedVideoDidExpireForCustomEvent: to let the MoPub SDK know that it's no longer ready to play
  and needs to load another ad. That event will be passed on to the publisher app, which can then
  trigger another load.
  */
- (void)handleAdPlayedForCustomEventNetwork {
    if (!self.rewardedVideoAd.adValid) {
        [self.delegate rewardedVideoDidExpireForCustomEvent:self];
    }
}

/// 在激励视频系统不再需要这个custom event类时,会调用这个方法,目的是让custom event能够成功释放掉,如果能保证custom event不会造成内存泄漏,则这个方法不用重写
- (void)handleCustomEventInvalidated {
    
}

// MARK: - DNRewardedVideoAdDelegate
/// 广告数据加载成功回调
/// @param rewardedVideoAd rewardedVideoAd对象本身
- (void)rewardVideoAdDidLoad:(DNRewardedVideoAd *)rewardedVideoAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidLoadAdForCustomEvent:)]) {
        [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
    }
}

/// 视频广告各种错误信息回调
/// @param rewardedVideoAd rewardedVideoAd对象本身
/// @param error 错误信息
- (void)rewardVideoAd:(DNRewardedVideoAd *)rewardedVideoAd didFaildWithError:(NSError *)error {
    self.rootVC = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidFailToLoadAdForCustomEvent:error:)]) {
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
    }
}
 
/// 视频数据下载成功回调，已经下载过的视频会直接回调
/// @param rewardedVideoAd rewardedVideoAd对象本身
- (void)rewardVideoAdVideoDidLoad:(DNRewardedVideoAd *)rewardedVideoAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoAdVideoDidLoadForCustomEvent:)]) {
        [self.delegate rewardedVideoAdVideoDidLoadForCustomEvent:self];
    }
}

/// 视频播放页即将展示回调
/// @param rewardedVideoAd rewardedVideoAd对象本身
- (void)rewardVideoAdWillVisible:(DNRewardedVideoAd *)rewardedVideoAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoWillAppearForCustomEvent:)]) {
        [self.delegate rewardedVideoWillAppearForCustomEvent:self];
    }
}

/// 视频广告曝光回调
/// @param rewardedVideoAd rewardedVideoAd对象本身
- (void)rewardVideoAdDidExposed:(DNRewardedVideoAd *)rewardedVideoAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidAppearForCustomEvent:)]) {
        [self.delegate rewardedVideoDidAppearForCustomEvent:self];
    }
}

/// 视频播放页关闭回调
/// @param rewardedVideoAd rewardedVideoAd对象本身
- (void)rewardVideoAdDidClose:(DNRewardedVideoAd *)rewardedVideoAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoWillDisappearForCustomEvent:)]) {
        [self.delegate rewardedVideoWillDisappearForCustomEvent:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidDisappearForCustomEvent:)]) {
        [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
    }
    self.rootVC = nil;
}

/// 视频广告信息点击回调
/// @param rewardedVideoAd rewardedVideoAd对象本身
- (void)rewardVideoAdDidClicked:(DNRewardedVideoAd *)rewardedVideoAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidReceiveTapEventForCustomEvent:)]) {
        [self.delegate rewardedVideoDidReceiveTapEventForCustomEvent:self];
    }
}

/// 视频广告播放达到激励条件回调
/// @param rewardedVideoAd rewardedVideoAd对象本身
- (void)rewardVideoAdDidRewardEffective:(DNRewardedVideoAd *)rewardedVideoAd {
    MobiRewardedVideoReward *reward = [[MobiRewardedVideoReward alloc] initWithCurrencyAmount:@(kMobiRewardedVideoRewardCurrencyAmountUnspecified)];
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidReceiveTapEventForCustomEvent:)]) {
        [self.delegate rewardedVideoShouldRewardUserForCustomEvent:self reward:reward];
    }
}

/// 视频广告视频播放完成
/// @param rewardedVideoAd rewardedVideoAd对象本身
- (void)rewardVideoAdDidPlayFinish:(DNRewardedVideoAd *)rewardedVideoAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoAdDidPlayFinishForCustomEvent:didFailWithError:)]) {
        [self.delegate rewardedVideoAdDidPlayFinishForCustomEvent:self didFailWithError:nil];
    }
}

@end
