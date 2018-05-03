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

@interface NVPIPViewController : UIViewController

- (UIEdgeInsets)edgeInsetsForDisplayModeCompact;

- (CGRect)frameForDisplayMode:(NVPIPDisplayMode)displayMode;

- (BOOL)shouldReceivePoint:(CGPoint)point;

@end
