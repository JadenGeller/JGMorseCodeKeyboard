//
//  JGMorseCodeKeyboard.m
//  JGMorseCodeKeyboardExample
//
//  Created by Jaden Geller on 2/24/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGMorseCodeKeyboard.h"
#import "JGKeyboardKey.h"
#import "UIViewController+RotationNotification.h"

CGFloat const JGKeyboardLayoutSideSpacing = 6;
CGFloat const JGKeyboardLayoutTopSpacing = 10;
CGFloat const JGKeyboardLayoutBottomSpacing = 6;
CGFloat const JGKeyboardLayoutHorizontalKeySpacing = 6;
CGFloat const JGKeyboardLayoutVerticalKeySpacing = 8;
CGFloat const JGKeyboardLayoutKeyHeightToKeyboardHeightRatio = .52;
CGFloat const JGKeyboardLayoutSpecialKeyWidthToHeightRatio = 1.2;

@interface JGMorseCodeKeyboard ()

@property (nonatomic) NSArray *portraitConstraints;
@property (nonatomic) NSArray *landscapeConstraints;

@property (nonatomic) JGKeyboardKey *shift;
@property (nonatomic) JGKeyboardKey *delete;
@property (nonatomic) JGKeyboardKey *space;

@property (nonatomic) JGKeyboardKey *dit;
@property (nonatomic) JGKeyboardKey *dah;

@property (nonatomic) BOOL isPortrait;

@property (nonatomic, readonly) NSDictionary *viewBindings;
@property (nonatomic, readonly) NSDictionary *constantBindings;

@property (nonatomic, readonly) BOOL shouldCapitalize;
@property (nonatomic) BOOL shiftEnabled;
@property (nonatomic) BOOL capsLockEnabled;

@end

@implementation JGMorseCodeKeyboard

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

+(JGMorseCodeKeyboard*)keyboardWithInput:(id<UITextInput,UIKeyInput>)input{
    JGMorseCodeKeyboard *kb = [[JGMorseCodeKeyboard alloc] init];
    kb.input = input;
    return kb;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(JGKeyboardKey*)dit{
    if (!_dit) {
        _dit = [[JGKeyboardKey alloc]init];
        _dit.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _dit;
}

-(JGKeyboardKey*)dah{
    if (!_dah) {
        _dah = [[JGKeyboardKey alloc]init];
        _dah.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _dah;
}

-(JGKeyboardKey*)shift{
    if (!_shift) {
        _shift = [[JGKeyboardKey alloc]init];
        _shift.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_shift addTarget:self action:@selector(shiftPress) forControlEvents:UIControlEventTouchDown];
        [_shift addTarget:self action:@selector(shiftDoublePress) forControlEvents:UIControlEventTouchDownRepeat];

    }
    return _shift;
}

-(JGKeyboardKey*)space{
    if (!_space) {
        _space = [[JGKeyboardKey alloc]init];
        _space.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_space addTarget:self action:@selector(spacePress) forControlEvents:UIControlEventTouchUpInside];
    }
    return _space;
}

-(JGKeyboardKey*)delete{
    if (!_delete) {
        _delete = [[JGKeyboardKey alloc]init];
        _delete.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_delete addTarget:self action:@selector(deletePress) forControlEvents:UIControlEventTouchDown];
    }
    return _delete;
}

-(BOOL)shouldCapitalize{
    return self.shiftEnabled | self.capsLockEnabled;
}

-(void)toggleShift{
    if (self.capsLockEnabled) self.capsLockEnabled = NO;
    else _shiftEnabled = !_shiftEnabled;
}

-(void)toggleCapsLock{
    _shiftEnabled = NO;
    _capsLockEnabled = !_capsLockEnabled;
}

-(void)deletePress{
    [self.input deleteBackward];
}

-(void)shiftPress{
    [self toggleShift];
}

-(void)shiftDoublePress{
    [self toggleCapsLock];
}

-(void)spacePress{
    [self.input insertText:@" "];
}

-(NSDictionary*)viewBindings{
    return @{@"dit" : self.dit, @"dah" : self.dah, @"shift" : self.shift, @"delete" : self.delete, @"space" : self.space};

}

-(NSDictionary*)constantBindings{
    return @{@"side" : @(JGKeyboardLayoutSideSpacing), @"vgap" : @(JGKeyboardLayoutVerticalKeySpacing), @"hgap" : @(JGKeyboardLayoutHorizontalKeySpacing), @"top" : @(JGKeyboardLayoutTopSpacing), @"bottom" : @(JGKeyboardLayoutBottomSpacing)};
}

-(void)setup{
    self.backgroundColor = [UIColor colorWithWhite:.78 alpha:1];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.bounds = CGRectMake(0, 0, 1, 130);
    
    [self addSubview:self.dit];
    [self addSubview:self.dah];
    
    [self addSubview:self.shift];
    [self addSubview:self.space];
    [self addSubview:self.delete];
    
    self.isPortrait = YES; // change in future
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willAnimateRotationToInterfaceOrientation:) name:UIViewControllerRotationNotification object:nil];
    
    [self setNeedsUpdateConstraints];
}

-(void)willAnimateRotationToInterfaceOrientation:(NSNotification*)notification{
    self.isPortrait = UIInterfaceOrientationIsPortrait([notification.object integerValue]);
    [self setNeedsUpdateConstraints];
}

-(void)updateConstraints{
    [super updateConstraints];
    
    [self removeConstraints:self.landscapeConstraints];
    [self removeConstraints:self.portraitConstraints];
    [self addConstraints:self.isPortrait ? self.portraitConstraints : self.landscapeConstraints];

}

-(NSArray*)portraitConstraints{
    if (!_portraitConstraints) {
        NSMutableArray *constraints = [NSMutableArray array];
        
        // Horizontal spacing for dit and dah
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-side-[dit]-hgap-[dah(==dit)]-side-|" options:0 metrics:self.constantBindings views:self.viewBindings]];
        
        // Horizontal spacing for shift, delete, and space
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-side-[shift]-hgap-[space]-hgap-[delete(==shift)]-side-|" options:0 metrics:self.constantBindings views:self.viewBindings]];
        
        // Width of special buttons
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.shift attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.shift attribute:NSLayoutAttributeHeight multiplier:JGKeyboardLayoutSpecialKeyWidthToHeightRatio constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.delete attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.delete attribute:NSLayoutAttributeHeight multiplier:JGKeyboardLayoutSpecialKeyWidthToHeightRatio constant:0]];
        
        // Vertical spacing for dit and shift
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[dit]-vgap-[shift]-bottom-|" options:0 metrics:self.constantBindings views:self.viewBindings]];
        
        // Top equivalencies
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dah attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.dit attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.shift attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.delete attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.space attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.delete attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        
        // Bottom equivalencies
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dah attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.dit attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.shift attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.delete attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.space attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.delete attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
        
        
        // Height for dit and dah
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dit attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:JGKeyboardLayoutKeyHeightToKeyboardHeightRatio constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dah attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:JGKeyboardLayoutKeyHeightToKeyboardHeightRatio constant:0]];
        
        _portraitConstraints = constraints;

    }
    return _portraitConstraints;
}

-(NSArray*)landscapeConstraints{
    if (!_landscapeConstraints) {
        NSMutableArray *constraints = [NSMutableArray array];
        
        _landscapeConstraints = constraints;
    }
    
    return _landscapeConstraints;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
}

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

- (void)click {
    [[UIDevice currentDevice] playInputClick];
}

@end
