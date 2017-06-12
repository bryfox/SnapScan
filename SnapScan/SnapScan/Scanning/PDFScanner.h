//
//  PDFScanner.h
//  ScanMe
//
//  Created by Bryan Fox on 5/22/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDFScannerProgressDelegate.h"

typedef enum : NSInteger {
    PDFScannerAccuracyHigh,
    PDFScannerAccuracyMedium,
    PDFScannerAccuracyLow
} PDFScannerAccuracy;

/**
 PDFScanner
 - Each instance must be initialized in its own thread in order for progress updates to work correctly
 */
@interface PDFScanner : NSObject

@property (readonly, copy) NSString *identifier;
@property (weak) id<PDFScannerProgressDelegate> progressDelegate;

- (instancetype)initWithIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

/**
 Scan image & save PDF file
 @param image from camera
 @returns subpath to saved PDF, underneath user documents directory
 */
- (NSString *)savePDFFromImage:(UIImage *)image withAccuracy:(PDFScannerAccuracy)accuracy;

@end
