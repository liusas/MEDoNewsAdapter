//
//  MobiDoNewsFeedCustomEvent.m
//  MEDoNewsAdapter
//
//  Created by 刘峰 on 2020/10/26.
//

#import "MobiDoNewsFeedCustomEvent.h"
#import <DNAdSDK/DNExpressFeedAd.h>
#import "MEDoNewsAdapter.h"

@interface MobiDoNewsFeedCustomEvent ()<DNExpressFeedAdDelegate>

/// 原生模板广告
@property (strong, nonatomic) NSMutableArray<__kindof DNExpressFeedAd *> *expressAdViews;

/// 原生广告管理类
@property (strong, nonatomic) DNExpressFeedAd *expressFeed;

@end

@implementation MobiDoNewsFeedCustomEvent

- (void)requestFeedWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    CGFloat width = [[info objectForKey:@"width"] floatValue];
    CGFloat height = [[info objectForKey:@"height"] floatValue];
    NSInteger count = [[info objectForKey:@"count"] intValue];
    
    if (adUnitId == nil) {
        NSError *error =
        [NSError errorWithDomain:MobiFeedAdsSDKDomain
                            code:MobiFeedAdErrorInvalidPosid
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad Unit ID cannot be nil."}];
        [self.delegate nativeExpressAdFailToLoadForCustomEvent:self error:error];
        return;
    }
    
    UIViewController *vc = [MEDoNewsAdapter topVC];
    
    if (!vc) {
        NSError *error =
        [NSError errorWithDomain:MobiFeedAdsSDKDomain
                            code:MobiFeedAdErrorNoRootVC
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad root view controller cannot be nil."}];
        [self.delegate nativeExpressAdFailToLoadForCustomEvent:self error:error];
        return;
    }
    
    self.expressAdViews = [NSMutableArray array];
    
    DNExpressFeedAd *expressAd = [DNExpressFeedAd.alloc initWithPlaceId:adUnitId adSize:CGSizeMake(width, height)];
    expressAd.controller = vc;
    expressAd.delegate = self;
    _expressFeed = expressAd; //需要全局持有实例否则实例被销毁将无法正常展示广告
    [expressAd loadAdWithCount:count];
}

/// 在回传信息流广告之前,
/// 需要判断这个广告是否还有效,需要在此处返回广告有效性(是否可以直接展示)
- (BOOL)hasAdAvailable {
    return YES;
}

/// 子类重写次方法,决定由谁处理展现和点击上报
/// 默认return YES;由上层adapter处理展现和点击上报,
/// 若return NO;则由子类实现trackImpression和trackClick方法,实现上报,但要保证每个广告只上报一次
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return YES;
}

/// 这个方法存在的意义是聚合广告,因为聚合广告可能会出现两个广告单元用同一个广告平台加载广告
/// 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
/// 当然广告失效后需要回调`[-rewardedVideoDidExpireForCustomEvent:]([MPRewardedVideoCustomEventDelegate rewardedVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
/// 并且我们要重写这个方法,让这个Custom event类能释放掉
/// 默认这个方法不会做任何事情
- (void)handleAdPlayedForCustomEventNetwork {
    [self.delegate nativeExpressAdDidExpireForCustomEvent:self];
}

/// 在激励视频系统不再需要这个custom event类时,会调用这个方法,目的是让custom event能够成功释放掉,如果能保证custom event不会造成内存泄漏,则这个方法不用重写
- (void)handleCustomEventInvalidated {
    
}

// MARK: - DNExpressFeedAdDelegate
/// 拉取原生模板广告成功
/// @param expressFeedAd expressFeedAd对象本身
/// @param views 模版广告视图数组
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd loadSuccessWithViews:(NSArray<DNExpressFeedAdView *> *)views {
    [self.expressAdViews removeAllObjects];//【重要】不能保存太多view，需要在合适的时机手动释放不用的，否则内存会过大
    
    [self.expressAdViews addObjectsFromArray:views];
    [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        DNExpressFeedAdView *expressView = (DNExpressFeedAdView *)obj;
        [expressView render];
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdSuccessToLoadForCustomEvent:views:)]) {
        [self.delegate nativeExpressAdSuccessToLoadForCustomEvent:self views:self.expressAdViews];
    }
}

/// 拉取原生模板广告失败
/// @param expressFeedAd expressFeedAd对象本身
/// @param error 错误信息
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd loadFailureWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdFailToLoadForCustomEvent:error:)]) {
        [self.delegate nativeExpressAdFailToLoadForCustomEvent:self error:error];
    }
}

/// 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
/// @param expressFeedAd expressFeedAd对象本身
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd renderSuccessForView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderSuccessForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewRenderSuccessForCustomEvent:view];
    }
}

/// 原生模板广告渲染失败
/// @param expressFeedAd expressFeedAd对象本身
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd renderFailureForView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderFailForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewRenderFailForCustomEvent:view];
    }
}

/// 原生模板广告曝光回调
/// @param expressFeedAd expressFeedAd对象本身
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd exposureForView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewExposureForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewExposureForCustomEvent:view];
    }
}

/// 原生模板广告点击回调
/// @param expressFeedAd expressFeedAd对象本身
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd didClickedForView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewClickedForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewClickedForCustomEvent:view];
    }
}

/// 原生模板广告被关闭
/// @param expressFeedAd expressFeedAd对象本身
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd didClosedForView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewClosedForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewClosedForCustomEvent:view];
    }
}

/// 即将打开广告落地页
/// @param expressFeedAd expressFeedAd对象本身
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd willShowDetailsForView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewWillPresentScreenForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewWillPresentScreenForCustomEvent:view];
    }
}

/// 关闭广告落地页
/// @param expressFeedAd expressFeedAd对象本身
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd didCloseDetailsForView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewWillDissmissScreenForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewWillDissmissScreenForCustomEvent:view];
    }
}

/// 播放器状态发生变化时回调
/// @param expressFeedAd expressFeedAd对象本身
/// @param status 当前播放器状态
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd playerDidChangedStatus:(DNExpressPlayerStatus)status forView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewForCustomEvent:playerStatusChanged:)]) {
        [self.delegate nativeExpressAdViewForCustomEvent:view playerStatusChanged:MobiMediaPlayerStatusStoped];
    }
}

/// 视频广告播放完毕
/// @param expressFeedAd expressFeedAd对象本身
/// @param view 模板View
- (void)expressFeedAd:(DNExpressFeedAd *)expressFeedAd playerDidPlayFinishForView:(DNExpressFeedAdView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewForCustomEvent:playerStatusChanged:)]) {
        [self.delegate nativeExpressAdViewForCustomEvent:view playerStatusChanged:MobiMediaPlayerStatusStoped];
    }
}


@end
