//
//  NVPIPViewController.h
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NVPIPDisplayMode) {
  NVPIPDisplayModeExpanded,
  NVPIPDisplayModeCompact
};

@protocol NVPIPViewControllerDelegate;

@interface NVPIPViewController : UIViewController

@property (nonatomic, weak) id<NVPIPViewControllerDelegate> delegate;

- (UIEdgeInsets)edgeInsetsForDisplayModeCompact;

- (CGRect)frameForDisplayMode:(NVPIPDisplayMode)displayMode;

- (void)setDisplayMode:(NVPIPDisplayMode)displayMode animated:(BOOL)animated;

- (void)updateViewWithTranslationPercentage:(CGFloat)percentage;

- (BOOL)shouldReceivePoint:(CGPoint)point;

@end

@protocol NVPIPViewControllerDelegate <NSObject>

@optional
- (void)pipViewController:(NVPIPViewController *)viewController willChangeToDisplayMode:(NVPIPDisplayMode)displayMode;

@optional
- (void)pipViewController:(NVPIPViewController *)viewController didChangeToDisplayMode:(NVPIPDisplayMode)displayMode;

@optional
- (void)pipViewController:(NVPIPViewController *)viewController willStartTransitionToDisplayMode:(NVPIPDisplayMode)displayMode;

@end
