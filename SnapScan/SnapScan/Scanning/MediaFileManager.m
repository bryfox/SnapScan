//
//  MediaFileManager.m
//  SnapScan
//
//  Created by Bryan Fox on 6/7/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import "MediaFileManager.h"
#import "DLog.h"

@interface MediaFileManager()
@property (readonly) NSURL *documentDirectory;
@end

@implementation MediaFileManager

- (NSString *)imageDirectoryName {
    // Refers to saved user data on disk
    return @"img";
}

- (NSString *)pdfDirectoryName {
    // Refers to saved user data on disk
    return @"pdf";
}

- (NSURL *)documentDirectory {
    NSArray *dirPaths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    return [dirPaths lastObject];
}

- (NSURL *)pdfDocumentDirectory {
    NSURL *pdfDir = [self userDocumentsURLForSubdirectory:self.pdfDirectoryName];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self createDirectoryAtURL:pdfDir];
    });
    return pdfDir;
}

- (NSURL *)previewDocumentDirectory {
    NSURL *previewDir = [self userDocumentsURLForSubdirectory:self.imageDirectoryName];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self createDirectoryAtURL:previewDir];
    });
    return previewDir;
}

- (NSURL *)urlForDocument:(NSString *)documentPath {
    return [self userDocumentsURLForSubdirectory:documentPath];
}

- (NSString *)fullPathToDocument:(NSString *)documentPath {
    return [self userDocumentsURLForSubdirectory:documentPath].path;
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

#pragma MARK - private

- (NSURL *)userDocumentsURLForSubdirectory:(NSString *)subdirectory {
    if (nil == subdirectory) {
        // Else would throw NSInvalidArgumentException
        return nil;
    }
    return [self.documentDirectory URLByAppendingPathComponent:subdirectory];
}


@end
