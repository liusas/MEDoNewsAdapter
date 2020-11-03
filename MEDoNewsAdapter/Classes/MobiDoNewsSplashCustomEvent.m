//
//  MobiDoNewsSplashCustomEvent.m
//  MEDoNewsAdapter
//
//  Created by 刘峰 on 2020/10/26.
//

#import "MobiDoNewsSplashCustomEvent.h"
#import <DNAdSDK/DNAdSDK.h>

@interface MobiDoNewsSplashCustomEvent ()<DNSplashAdDelegate>

@property (nonatomic, strong) DNSplashAd *splash;
@property (nonatomic, strong) UIViewController *rootVC;

@end

@implementation MobiDoNewsSplashCustomEvent

- (void)requestSplashWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    UIView *bottomView = [info objectForKey:@"bottomView"];
    NSTimeInterval delay = [[info objectForKey:@"delay"] floatValue];
    
    if (adUnitId == nil) {
        NSError *error = [NSError splashErrorWithCode:MobiSplashAdErrorNoAdsAvailable localizedDescription:@"posid cannot be nil"];
        if ([self.delegate respondsToSelector:@selector(splashAdFailToPresentForCustomEvent:withError:)]) {
            [self.delegate splashAdFailToPresentForCustomEvent:self withError:error];
        }
        return;
    }
    
    UIViewController *vc = [self topVC];
    if (!vc) {
        return;
    }
    
    self.rootVC = vc;
    
    DNSplashAd.hiddenStatusBar = YES;
    DNSplashAd *splash = [DNSplashAd.alloc initWithPlaceId:adUnitId];
    splash.delegate = self;
    // splash.backgroundColor = UIColor.redColor;
    _splash = splash; //需要全局持有实例否则实例被销毁将无法正常展示广告
    CGRect frame = bottomView.frame;
    frame.size = (CGSize){UIScreen.mainScreen.bounds.size.width, 100.0}; /// 在frame中设置好bottomView的高就可以使用自定义高度，否则将使用默认100
    bottomView.frame = frame;
    [splash loadAdAndShowWithController:vc bottomView:bottomView];
}

- (void)presentSplashFromWindow:(UIWindow *)window {
}

- (BOOL)hasAdAvailable
{
    if (self.splash) {
        return YES;
    }
    return NO;
}

- (void)handleAdPlayedForCustomEventNetwork
{
    [self.delegate splashAdDidExpireForCustomEvent:self];
}

- (void)handleCustomEventInvalidated
{
}

/// 获取顶层VC
- (UIViewController *)topVC {
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

// MARK: - DNSplashAdDelegate
/// 开屏广告加载成功的回调
/// @param splashAd 产生该事件的 DNSplashAd 对象
- (void)splashAdDidLoadSuccess:(DNSplashAd *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdDidLoadForCustomEvent:)]) {
        [self.delegate splashAdDidLoadForCustomEvent:self];
    }
}

///  开屏广告加载失败的回调
/// @param splashAd 产生该事件的 DNSplashAd 对象
/// @param error Error对象
- (void)splashAdDidLoadFaild:(DNSplashAd *)splashAd withError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdFailToPresentForCustomEvent:withError:)]) {
        [self.delegate splashAdFailToPresentForCustomEvent:self withError:error];
    }
}

/// 开屏广告点击的回调
/// @param splashAd 产生该事件的 DNSplashAd 对象
- (void)splashAdClicked:(DNSplashAd *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdClickedForCustomEvent:)]) {
        [self.delegate splashAdClickedForCustomEvent:self];
    }
}

/// 开屏广告点击关闭按钮的回调
/// @param splashAd 产生该事件的 DNSplashAd 对象
- (void)splashAdDidClickCloseButton:(DNSplashAd *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdDidClickSkipForCustomEvent:)]) {
        [self.delegate splashAdDidClickSkipForCustomEvent:self];
    }
}

/// 关闭开屏广告的回调
/// @param splashAd DNSplashAd 对象
- (void)splashAdDidClose:(DNSplashAd *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdClosedForCustomEvent:)]) {
        [self.delegate splashAdClosedForCustomEvent:self];
    }
}

/// 广告将要消失的回调
/// @param splashAd 产生该事件的 DNSplashAd 对象
- (void)splashAdWillClose:(DNSplashAd *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdWillClosedForCustomEvent:)]) {
        [self.delegate splashAdWillClosedForCustomEvent:self];
    }
}

/// 开屏广告完成曝光的回调
/// @param splashAd splashAd 对象
- (void)splashAdExposured:(DNSplashAd *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdSuccessPresentScreenForCustomEvent:)]) {
        [self.delegate splashAdSuccessPresentScreenForCustomEvent:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdExposuredForCustomEvent:)]) {
        [self.delegate splashAdExposuredForCustomEvent:self];
    }
}

@end
