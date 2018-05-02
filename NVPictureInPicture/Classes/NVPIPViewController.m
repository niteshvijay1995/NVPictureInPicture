//
//  NVPIPViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPIPViewController.h"

@interface NVPIPViewController()

@property (nonatomic) UIPanGestureRecognizer *panGesture;

@end

@implementation NVPIPViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDidFire:)];
  [self.view addGestureRecognizer:self.panGesture];
}

- (void)panDidFire:(UIGestureRecognizer *)gestureRecognizer {
  
}

- (BOOL)shouldReceivePoint:(CGPoint)point {
  return CGRectContainsPoint(self.view.frame, point);
}

@end
