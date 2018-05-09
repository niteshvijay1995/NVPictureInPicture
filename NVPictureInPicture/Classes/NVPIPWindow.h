//
//  NVPIPWindow.h
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import <UIKit/UIKit.h>

@protocol NVPIPWindowDelegate;

@interface NVPIPWindow : UIWindow

@property (nonatomic, weak) id<NVPIPWindowDelegate> NVDelegate;

- (instancetype)initWithFrame:(CGRect)frame
                  windowLevel:(CGFloat)windowLevel;

@end

@protocol NVPIPWindowDelegate <NSObject>

- (BOOL)isEventPoint:(CGPoint)point;

@end
