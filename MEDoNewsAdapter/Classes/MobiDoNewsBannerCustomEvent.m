//
//  MobiDoNewsBannerCustomEvent.m
//  MEDoNewsAdapter
//
//  Created by 刘峰 on 2020/10/26.
//

#import "MobiDoNewsBannerCustomEvent.h"
#import <DNAdSDK/DNBannerAdView.h>

@interface MobiDoNewsBannerCustomEvent ()<DNBannerAdViewDelegate>

/// banner广告
@property(nonatomic, strong) DNBannerAdView *bannerView;

@end

@implementation MobiDoNewsBannerCustomEvent

- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    CGFloat whRatio = [[info objectForKey:@"whRatio"] floatValue];
    NSTimeInterval interval = [[info objectForKey:@"interval"] floatValue];
    UIViewController *rootVC = [info objectForKey:@"rootVC"];
    
    
    if (adUnitId == nil) {
        NSError *error =
        [NSError errorWithDomain:MobiBannerAdsSDKDomain
                            code:MobiBannerAdErrorInvalidPosid
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad Unit ID cannot be nil."}];
        [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    if (!rootVC) {
        NSError *error =
        [NSError errorWithDomain:MobiBannerAdsSDKDomain
                            code:MobiBannerAdErrorNoRootVC
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad root view controller cannot be nil."}];
        [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    CGFloat bannerHeight = size.width/whRatio;
    DNBannerAdView *bannerView = [DNBannerAdView.alloc initWithFrame:(CGRect){CGPointZero, CGSizeMake(size.width, bannerHeight)} placeId:adUnitId];
    bannerView.controller = rootVC;
    bannerView.delegate = self;
    [bannerView loadAdAndShow];
    
    self.bannerView = bannerView;
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return YES;
}

//MARK: - DNBannerAdViewDelegate
/// 即将开始加载banner广告
/// @param bannerView bannerView对象本身
- (void)bannerAdWillLoadForBannerView:(DNBannerAdView *)bannerView {
    
}

/// bannerAdView加载成功时的回调
/// banner是可能有多条广告轮流展示的，所以banner每次展示了新的广告都会回调此方法
/// @param bannerView bannerView对象本身
- (void)bannerAdDidLoadSuccessForBannerView:(DNBannerAdView *)bannerView {
    // 回调到上层
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:didLoadAd:)]) {
        [self.delegate bannerCustomEvent:self didLoadAd:self.bannerView];
    }
}

/// bannerAdView加载失败时的回调
/// @param bannerView bannerView对象本身
- (void)bannerAdDidLoadFaildForBannerView:(DNBannerAdView *)bannerView error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:didFailToLoadAdWithError:)]) {
        [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
    }
}

/// bannerAdView曝光的回调
/// @param bannerView bannerView对象本身
- (void)bannerAdDidExposureForBannerView:(DNBannerAdView *)bannerView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:willVisible:)]) {
        [self.delegate bannerCustomEvent:self willVisible:bannerView];
    }
}

/// 点击banner广告的回调
/// @param bannerView bannerView对象本身
- (void)bannerAdDidClickForBannerView:(DNBannerAdView *)bannerView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:didClick:)]) {
        [self.delegate bannerCustomEvent:self didClick:bannerView];
    }
}

/// 落地页显示完成
/// @param bannerView bannerView对象本身
- (void)bannerAdDidShowDetailsForBannerView:(DNBannerAdView *)bannerView {
    
}

/// 落地页内点击返回
/// @param bannerView bannerView对象本身
- (void)bannerAdDetailsDidCloseForBannerView:(DNBannerAdView *)bannerView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEventWillLeaveApplication:)]) {
        [self.delegate bannerCustomEventWillLeaveApplication:self];
    }
}

/// 点击广告上的❌关闭广告(没有关闭按钮的不回调此方法)
/// @param bannerView bannerView对象本身
- (void)bannerAdDidClickCloseForBannerView:(DNBannerAdView *)bannerView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:willClose:)]) {
        [self.delegate bannerCustomEvent:self willClose:bannerView];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        bannerView.alpha = 0;
    } completion:^(BOOL finished) {
        [bannerView removeFromSuperview];
        if (self.bannerView == bannerView) {
            self.bannerView = nil;
        }
    }];
}

@end
