//
//  NVPIPViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPIPViewController.h"

static const CGSize defaultSizeInCompactMode = {100, 150};

typedef NS_ENUM(NSInteger, NVPIPDisplayMode) {
  NVPIPDisplayModeExpanded,
  NVPIPDisplayModeCompact
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
  self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  [self.view addGestureRecognizer:self.panGesture];
}

- (CGSize)sizeInDisplayModeCompact {
  return defaultSizeInCompactMode;
}

- (void)handlePan:(UIGestureRecognizer *)gestureRecognizer {
  if (self.displayMode == NVPIPDisplayModeExpanded) {
    [self handlePanForDisplayModeExpanded:(UIPanGestureRecognizer *)gestureRecognizer];
  } else if (self.displayMode == NVPIPDisplayModeCompact) {
    [self handlePanForDisplayModeCompact:(UIPanGestureRecognizer *)gestureRecognizer];
  }
}

- (void)handlePanForDisplayModeExpanded:(UIPanGestureRecognizer *)gestureRecognizer {
  
}

- (void)handlePanForDisplayModeCompact:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    [self.panGesture setTranslation:CGPointZero inView:self.view];
    CGPoint center = self.view.center;
    center.x += translation.x;
    center.y += translation.y;
    self.view.center = center;
  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
             || gestureRecognizer.state == UIGestureRecognizerStateCancelled
             || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
    return;
  }
}

- (BOOL)shouldReceivePoint:(CGPoint)point {
  return CGRectContainsPoint(self.view.frame, point);
}

@end
