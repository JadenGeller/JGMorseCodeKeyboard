//
//  UITextView+Keyboard.m
//  JGMorseCodeKeyboardExample
//
//  Created by Jaden Geller on 2/24/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "UITextView+Keyboard.h"
#import "JGMorseCodeKeyboard.h"

@implementation UITextView (Keyboard)

-(UIView*)inputView{
    return [JGMorseCodeKeyboard keyboardWithInput:self];
}

@end
