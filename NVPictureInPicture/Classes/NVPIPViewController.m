//
//  NVPIPViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPIPViewController.h"

static const CGSize defaultSizeInCompactMode = {100, 150};

typedef NS_ENUM(NSInteger, NVPIPDisplayMode) {
  NVPIPDisplayModeCompact,
  NVPIPDisplayModeExpanded
};

@interface NVPIPViewController()

@property (nonatomic) NVPIPDisplayMode displayMode;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) CGSize compactModeSize;
@property (nonatomic) CGSize expandedModeSize;

@end

@implementation NVPIPViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.compactModeSize = [self sizeInDisplayModeCompact];
  self.expandedModeSize = [UIScreen mainScreen].bounds.size;
  self.displayMode = NVPIPDisplayModeExpanded;
  self.view.frame = CGRectMake(0, 0, self.expandedModeSize.width, self.expandedModeSize.height);
  self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDidFire:)];
  [self.view addGestureRecognizer:self.panGesture];
}

- (CGSize)sizeInDisplayModeCompact {
  return defaultSizeInCompactMode;
}

- (void)panDidFire:(UIGestureRecognizer *)gestureRecognizer {
  
}

- (BOOL)shouldReceivePoint:(CGPoint)point {
  return CGRectContainsPoint(self.view.frame, point);
}

@end
