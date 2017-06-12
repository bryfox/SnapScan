//
//  MediaFileManager.h
//  SnapScan
//
//  Created by Bryan Fox on 6/7/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Provides an interface to app Documents.

 A Document is a resource such as a PDF or image that is persisted on the filesystem,
 and represented by a "subpath" such as "/pdf/xxxxx.pdf". This manager encapsulates knowledge
 of a Document's actual location on disk (such as /var/.../Documents).

 When displaying an image or PDF, access the full path or URL using
 MediaFileManager:fullPathToDocument:documentPath and MediaFileManager:urlForDocument:documentPath
 */
@interface MediaFileManager : NSObject

@property (readonly) NSString *imageDirectoryName;
@property (readonly) NSString *pdfDirectoryName;

/**
 Note: Creates the directory if needed
 Example: /var/.../Documents/pdf
 @returns NSURL the directory where PDFs are stored, inside user Documents.
 */
@property (readonly) NSURL *pdfDocumentDirectory;

/**
 Note: Creates the directory if needed
 Example: /var/.../Documents/preview
 @returns NSURL the directory for [JPG] previews
 */
@property (readonly) NSURL *previewDocumentDirectory;

/**
 Convert a document's path into a usable resource by prepending the documents directory
 @param documentPath the document's location inside the document directory, such as @"/pdf/xxxx.jpg"
 @returns the local URL to the PDF or image
 */
- (NSURL *)urlForDocument:(NSString *)documentPath;

/**
 @param documentPath the document's location inside the document directory, such as @"/pdf/xxxx.jpg"
 @returns the full path on the filesystem, such as @"/var/.../pdf/xxxx.jpg"
 */
- (NSString *)fullPathToDocument:(NSString *)documentPath;

/**
 Delete the file at the path, but prepend the user docs dir
 */
- (BOOL)deleteDocumentAtPath:(NSString *)path error:(NSError **)error;

// for debugging
- (NSInteger)pdfCount;

@end
