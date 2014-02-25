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

BOOL const JGKeyboardDit = YES;
BOOL const JGKeyboardDah = NO;

CGFloat const JGKeyboardBoundsHeightPortrait = 130;
CGFloat const JGKeyboardBoundsHeightLandscape = 80;

// portrait
CGFloat const JGKeyboardLayoutKeyHeightToKeyboardHeightRatio = .52;
CGFloat const JGKeyboardLayoutSpecialKeyWidthToHeightRatio = 1.2;

//landscape
CGFloat const JGKeyboardLayoutKeyWidthToKeyboardWidthRatio = .28;
CGFloat const JGKeyboardLayoutSpaceHeightToKeyboardHeightRatio = .4;

//both
CGFloat const JGKeyboardLayoutSideSpacing = 6;
CGFloat const JGKeyboardLayoutTopSpacing = 10;
CGFloat const JGKeyboardLayoutBottomSpacing = 6;
CGFloat const JGKeyboardLayoutHorizontalKeySpacing = 6;
CGFloat const JGKeyboardLayoutVerticalKeySpacing = 8;

CGFloat const JGKeyboardDeleteRepeatInitialLetterDelay = .5;
CGFloat const JGKeyboardDeleteRepeatLetterDelay = .1;
CGFloat const JGKeyboardDeleteRepeatWordDelay = .35;
CGFloat const JGKeyboardDeleteRepeatLetterWordTransitionDelay = 2.5;

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

@property (nonatomic) NSTimer *deleteTransitionTimer;
@property (nonatomic) NSTimer *deleteBlockTimer;

@property (nonatomic) NSMutableArray *inputBuffer;

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
    kb.textInput = input;
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
        _dit = [JGKeyboardKey lightKey];
        _dit.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_delete addTarget:self action:@selector(ditPress) forControlEvents:UIControlEventTouchDown];
        [_delete addTarget:self action:@selector(ditRelease) forControlEvents:UIControlEventTouchUpInside];
        [_delete addTarget:self action:@selector(ditCancel) forControlEvents:UIControlEventTouchDragOutside];

    }
    return _dit;
}

-(JGKeyboardKey*)dah{
    if (!_dah) {
        _dah = [JGKeyboardKey lightKey];
        _dah.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_delete addTarget:self action:@selector(dahPress) forControlEvents:UIControlEventTouchDown];
        [_delete addTarget:self action:@selector(dahRelease) forControlEvents:UIControlEventTouchUpInside];
        [_delete addTarget:self action:@selector(dahCancel) forControlEvents:UIControlEventTouchDragOutside];

    }
    return _dah;
}

-(JGKeyboardKey*)shift{
    if (!_shift) {
        _shift = [JGKeyboardKey darkKey];
        _shift.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_shift addTarget:self action:@selector(shiftPress) forControlEvents:UIControlEventTouchDown];
        [_shift addTarget:self action:@selector(shiftDoublePress) forControlEvents:UIControlEventTouchDownRepeat];

    }
    return _shift;
}

-(JGKeyboardKey*)space{
    if (!_space) {
        _space = [JGKeyboardKey lightKey];
        _space.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_space addTarget:self action:@selector(spacePress) forControlEvents:UIControlEventTouchUpInside];
    }
    return _space;
}

-(JGKeyboardKey*)delete{
    if (!_delete) {
        _delete = [JGKeyboardKey darkKey];
        _delete.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_delete addTarget:self action:@selector(deletePress) forControlEvents:UIControlEventTouchDown];
        [_delete addTarget:self action:@selector(deleteRelease) forControlEvents:UIControlEventTouchUpInside];
        [_delete addTarget:self action:@selector(deleteRelease) forControlEvents:UIControlEventTouchDragOutside];
    }
    return _delete;
}

-(NSMutableArray*)inputBuffer{
    if (!_inputBuffer) {
        _inputBuffer = [NSMutableArray array];
    }
    return _inputBuffer;
}

-(void)ditPress{
    [self click];
    
}

-(void)ditRelease{
    [self.inputBuffer addObject:@(JGKeyboardDit)];
}

-(void)ditCancel{
    
}

-(void)dahPress{
    [self click];
}

-(void)dahRelease{
    [self.inputBuffer addObject:@(JGKeyboardDah)];
}

-(void)dahCancel{
    
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
    [self deleteCharacter];
    
    self.deleteBlockTimer = [NSTimer scheduledTimerWithTimeInterval:JGKeyboardDeleteRepeatInitialLetterDelay target:self selector:@selector(deletePressRepeat) userInfo:nil repeats:NO];
    self.deleteTransitionTimer = [NSTimer scheduledTimerWithTimeInterval:JGKeyboardDeleteRepeatLetterWordTransitionDelay target:self selector:@selector(deleteTypeTransition) userInfo:nil repeats:NO];
}

-(void)deleteRelease{
    [self.deleteTransitionTimer invalidate];
    [self.deleteBlockTimer invalidate];

    self.deleteTransitionTimer = nil;
    self.deleteBlockTimer = nil;
}

-(void)deletePressRepeat{
    [self deleteCharacter];
    
    self.deleteBlockTimer = [NSTimer scheduledTimerWithTimeInterval:JGKeyboardDeleteRepeatLetterDelay target:self selector:@selector(deleteCharacter) userInfo:nil repeats:YES];
}

-(void)deleteTypeTransition{
    [self.deleteBlockTimer invalidate];
    [self deleteWord];
    
    self.deleteBlockTimer = [NSTimer scheduledTimerWithTimeInterval:JGKeyboardDeleteRepeatWordDelay target:self selector:@selector(deleteWord) userInfo:nil repeats:YES];
}

-(BOOL)whitespacePrecedesCursor{
    return ([[self textBeforeCursor] rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound);
}

-(NSString*)textBeforeCursor{
    UITextPosition *cursorPosition = self.textInput.selectedTextRange.start;
    UITextPosition *precedingPosition = [self.textInput positionFromPosition:cursorPosition offset:-1];
    UITextRange *range = [self.textInput textRangeFromPosition:precedingPosition toPosition:cursorPosition];
    return [self.textInput textInRange:range];
    
}

-(void)deleteCharacter{
    [self click];
    [self.textInput deleteBackward];
}

-(void)deleteWord{
    [self click];

    BOOL deleteOnlyCharacters = NO;  // after some point, stop considering whitespace as part of word
    NSInteger charactersDeleted = 0; // only stop after >= 4 characters are deleted
    
    while (!deleteOnlyCharacters || ![self whitespacePrecedesCursor]){
        deleteOnlyCharacters |= (![self whitespacePrecedesCursor] && charactersDeleted >= 4);
        [self.textInput deleteBackward];
        charactersDeleted++;
    }
}

-(void)shiftPress{
    [self click];
    [self toggleShift];
    
}

-(void)shiftDoublePress{
    [self toggleCapsLock];
}

-(void)spacePress{
    [self.textInput insertText:@" "];
    [self click];
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
    
    [self addSubview:self.dit];
    [self addSubview:self.dah];
    
    [self addSubview:self.shift];
    [self addSubview:self.space];
    [self addSubview:self.delete];
    
    self.isPortrait = YES; // change in future
    self.bounds = CGRectMake(0, 0, 1, JGKeyboardBoundsHeightPortrait);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willAnimateRotationToInterfaceOrientation:) name:UIViewControllerRotationNotification object:nil];
    
    [self setNeedsUpdateConstraints];
}

-(void)willAnimateRotationToInterfaceOrientation:(NSNotification*)notification{
    self.isPortrait = UIInterfaceOrientationIsPortrait([notification.object integerValue]);
    
    self.bounds = CGRectMake(0, 0, 1, self.isPortrait ? JGKeyboardBoundsHeightPortrait : JGKeyboardBoundsHeightLandscape);
    
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
        
        // Horizontal spacing
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-side-[dit]-hgap-[shift]-hgap-[delete(==shift)]-hgap-[dah]-side-|" options:0 metrics:self.constantBindings views:self.viewBindings]];
        
        // Horizontal equivalence for space
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.space attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.shift attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.space attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.delete attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
        
        // Width of dit and dah
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dit attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:JGKeyboardLayoutKeyWidthToKeyboardWidthRatio constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dah attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:JGKeyboardLayoutKeyWidthToKeyboardWidthRatio constant:0]];
        
        // Vertical spacing for shift and space
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[shift]-vgap-[space]-bottom-|" options:0 metrics:self.constantBindings views:self.viewBindings]];
        
        // Top equivalences for dit, delete, and dah
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dit attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.shift attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.delete attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.shift attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dah attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.shift attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        
        // Bottom equivalency for delete
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.delete attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.shift attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
        
        // Bottom constraints for dit and dah
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dit attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-JGKeyboardLayoutBottomSpacing]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.dah attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-JGKeyboardLayoutBottomSpacing]];
        
        // Height for space
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.space attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:JGKeyboardLayoutSpaceHeightToKeyboardHeightRatio constant:0]];
        
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
