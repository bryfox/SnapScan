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
    if (nil == subdirectory) {
        // Else would throw NSInvalidArgumentException
        return nil;
    }
    NSArray *dirPaths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docsDir = [dirPaths firstObject];
    return [docsDir URLByAppendingPathComponent:subdirectory];
}

- (BOOL)createDirectoryAtURL:(NSURL *)url {
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:url
                                            withIntermediateDirectories:YES
                                                             attributes:nil
                                                                  error:&error];
    if (!success) {
        DLog(@"Error during directory creation: %@", error);
    }

    return success;
}

- (BOOL)deleteDocumentAtPath:(NSString *)path error:(NSError **)error {
    NSURL *url = [self userDocumentsURLForSubdirectory:path];
    return [[NSFileManager defaultManager] removeItemAtURL:url error:error];
}

- (NSInteger)pdfCount {
    NSError *error = nil;
    NSURL *dir = [self userDocumentsURLForSubdirectory:self.pdfDirectoryName];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:dir
                                                  includingPropertiesForKeys:nil
                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                       error:&error];
    return error ? -1: files.count;
}

@end
