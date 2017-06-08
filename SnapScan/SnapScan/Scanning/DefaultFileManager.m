//
//  DefaultFileManager.m
//  SnapScan
//
//  Created by Bryan Fox on 6/7/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import "DefaultFileManager.h"
#import "DLog.h"

@implementation DefaultFileManager

- (NSString *)imageDirectoryName {
    // Refers to saved user data on disk
    return @"img";
}

- (NSString *)pdfDirectoryName {
    // Refers to saved user data on disk
    return @"pdf";
}

- (NSURL *)userDocumentsURLForSubdirectory:(NSString *)subdirectory {
    NSArray *dirPaths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docsDir = [dirPaths firstObject];
    return [docsDir URLByAppendingPathComponent:subdirectory];
}

- (BOOL)createDirectoryAtPathURL:(NSURL *)url {
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:url
                                            withIntermediateDirectories:YES
                                                             attributes:nil
                                                                  error:&error];
//    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path
//                                             withIntermediateDirectories:YES
//                                                              attributes:nil
//                                                                   error:&error];
    if (!success) {
        DLog(@"Error during directory creation: %@", error);
    }

    return success;
}

@end
