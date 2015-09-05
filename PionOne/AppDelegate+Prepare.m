//
//  AppDelegate+Prepare.m
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "AppDelegate+Prepare.h"
#import "PionOneUserDefaults.h"

@implementation AppDelegate (Prepare)
- (void)prepareManagedObjectContext {
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PionOne"];
    self.managedDocument = [[UIManagedDocument alloc] initWithFileURL:storeURL];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]];
    if (fileExists) {
        [self.managedDocument openWithCompletionHandler:^(BOOL success) {
            if (success) {
                [self documentIsReady];
            }
            if (!success) NSLog(@"Could not open documnet at %@", storeURL);
        }];
    } else {
        [self.managedDocument saveToURL:storeURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                [self documentIsReady];
            }
            if (!success) NSLog(@"Could not open documnet at %@", storeURL);
        }];
    }
    
}
- (void)documentIsReady {
    if (self.managedDocument.documentState == UIDocumentStateNormal) {
        self.managedObjectContext2 = self.managedDocument.managedObjectContext;
    }
}

- (BOOL)isUserExist {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userkey = [userDefaults stringForKey:kPionOneUserToken];
    if ([userkey length] > 10) { //the key length must bigger than 10, I diden't check what is the exactly value.
        return YES;
    }
    return NO;
}

@end
