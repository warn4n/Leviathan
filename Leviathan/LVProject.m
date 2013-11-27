//
//  LVProject.m
//  Leviathan
//
//  Created by Steven Degutis on 10/17/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "LVProject.h"

@implementation LVProject

+ (LVProject*) openProjectAtURL:(NSURL*)url {
    LVProject* p = [[LVProject alloc] init];
    p.projectURL = url;
    p.files = [NSMutableArray array];
    [p loadFiles];
    return p;
}

- (LVFile*) openNewFile {
    LVFile* file = [LVFile untitledFileInProject:self];
    [self.files addObject:file];
    return file;
}

- (void) loadFiles {
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    
    NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:self.projectURL
                                                  includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants
                                                                errorHandler:nil];
    
    for (NSURL *theURL in dirEnumerator) {
        NSNumber *isDirectory;
        [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        if ([isDirectory boolValue]) {
            if ([theURL isEqual: [self.projectURL URLByAppendingPathComponent:@"datomic"]]) {
                [dirEnumerator skipDescendants];
                continue;
            }
            if ([theURL isEqual: [self.projectURL URLByAppendingPathComponent:@"target"]]) {
                [dirEnumerator skipDescendants];
                continue;
            }
        }
        else {
            BOOL isClojure = [[theURL pathExtension] isEqualToString:@"clj"];
            
            if (isClojure) {
                LVFile* file = [LVFile untitledFileInProject:self];
                [file loadFromFileURL:theURL];
                [self.files addObject:file];
            }
        }
    }
}

@end
