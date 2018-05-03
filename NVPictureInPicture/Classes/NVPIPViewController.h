//
//  NVPIPViewController.h
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import <UIKit/UIKit.h>

@interface NVPIPViewController : UIViewController

- (UIEdgeInsets)edgeInsetsForDisplayModeCompact;

- (BOOL)shouldReceivePoint:(CGPoint)point;

@end
