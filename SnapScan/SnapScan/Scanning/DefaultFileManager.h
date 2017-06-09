//
//  DefaultFileManager.h
//  SnapScan
//
//  Created by Bryan Fox on 6/7/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 TODO: make this app-specific; all file/dir knowledge encapsulated here/
 The interfaces should work with PATHS (Strings), to avoid need to set documents dir elsewhere.
 Strings are stored by Realm anyway.
 ScanResult can provide a facade for this if needed.
 */
@interface DefaultFileManager : NSObject

@property (readonly) NSString *imageDirectoryName;
@property (readonly) NSString *pdfDirectoryName;

/**
 The defalt user docs directory
 @param subdirectory a named path fragment inside the default user docs  
 @returns NSURL the full path
 */
- (NSURL *)userDocumentsURLForSubdirectory:(NSString *)subdirectory;

/**
 Create dir if not already
 @param url full path of directory
 @returns true if directory exists
 */
- (BOOL)createDirectoryAtURL:(NSURL *)url;


/**
 Delete the file at the path, but prepend the user docs dir
 */
- (BOOL)deleteDocumentAtPath:(NSString *)path error:(NSError **)error;

// for debugging
- (NSInteger)pdfCount;

@end
