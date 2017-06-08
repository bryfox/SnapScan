//
//  DefaultFileManager.h
//  SnapScan
//
//  Created by Bryan Fox on 6/7/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import <Foundation/Foundation.h>

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
- (BOOL)createDirectoryAtPathURL:(NSURL *)url;

@end
