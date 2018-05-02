//
//  NVPIPViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPIPViewController.h"

@implementation NVPIPViewController

- (BOOL)shouldReceivePoint:(CGPoint)point {
  return CGRectContainsPoint(self.view.frame, point);
}

@end
