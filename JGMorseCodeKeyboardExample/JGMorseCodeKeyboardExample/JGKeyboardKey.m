//
//  JGKeyboardKey.m
//  JGMorseCodeKeyboardExample
//
//  Created by Jaden Geller on 2/24/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGKeyboardKey.h"
#import <QuartzCore/QuartzCore.h>

@implementation JGKeyboardKey

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = NO;
        self.clipsToBounds = NO;
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.layer.shadowColor = [UIColor colorWithWhite:.47 alpha:1].CGColor;
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 0;
        self.layer.shadowOffset = CGSizeMake(0, 1);
    }
    return self;
}

-(void)layoutSubviews{
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

+(JGKeyboardKey*)lightKey{
    return [[JGKeyboardKey alloc]init];
}

+(JGKeyboardKey*)darkKey{
    JGKeyboardKey *key = [[JGKeyboardKey alloc]init];
    key.backgroundColor = [UIColor colorWithRed:170/255.0 green:180/255.0 blue:190/255.0 alpha:1];
    return key;
}

@end
