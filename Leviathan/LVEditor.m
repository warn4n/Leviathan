//
//  LVEditorViewController.m
//  Leviathan
//
//  Created by Steven Degutis on 10/17/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "LVEditor.h"

@interface LVEditor ()

@property IBOutlet LVTextView* textView;

@end

@implementation LVEditor

- (NSString*) nibName {
    return @"Editor";
}

- (void) startEditingFile:(LVFile*)file {
    self.file = file;
    self.title = file.shortName;
    self.textView.file = file;
    
    [[self.textView layoutManager] replaceTextStorage:file.textStorage];
    [self.file highlight];
}

- (void) makeFirstResponder {
    [[self.view window] makeFirstResponder: self.textView];
}

- (void) textViewWasFocused:(NSTextView*)view {
    [self.delegate editorWasSelected:self];
}

- (void)textDidChange:(NSNotification *)notification {
    [self.file highlight];
}

@end
