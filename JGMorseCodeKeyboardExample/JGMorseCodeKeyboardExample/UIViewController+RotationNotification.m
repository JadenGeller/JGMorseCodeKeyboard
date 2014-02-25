//
//  UIViewController+RotationNotification.m
//  JGMorseCodeKeyboardExample
//
//  Created by Jaden Geller on 2/24/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "UIViewController+RotationNotification.h"

NSString * const UIViewControllerRotationNotification = @"willAnimateRotationToInterfaceOrientation";

@implementation UIViewController (RotationNotification)

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [[NSNotificationCenter defaultCenter] postNotificationName:UIViewControllerRotationNotification object:@(toInterfaceOrientation)];
}

@end
