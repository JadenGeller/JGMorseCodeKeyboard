//
//  JGMorseCodeKeyboard.h
//  JGMorseCodeKeyboardExample
//
//  Created by Jaden Geller on 2/24/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JGMorseCodeKeyboard : UIView <UIInputViewAudioFeedback>

@property (nonatomic) id<UITextInput, UIKeyInput> input;

+(JGMorseCodeKeyboard*)keyboardWithInput:(id<UITextInput, UIKeyInput>)input;

@end
