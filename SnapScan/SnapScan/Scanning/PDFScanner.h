//
//  PDFScanner.h
//  ScanMe
//
//  Created by Bryan Fox on 5/22/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    PDFScannerAccuracyHigh,
    PDFScannerAccuracyMedium,
    PDFScannerAccuracyLow
} PDFScannerAccuracy;

@interface PDFScanner : NSObject

- (instancetype)initWithBaseDirectory:(NSString *)baseDirectory NS_DESIGNATED_INITIALIZER;

/**
 Scan image & save PDF file
 @param image from camera
 @returns subpath to saved PDF, underneath user documents directory
 */
-(NSString *)savePDFForIdentifier:(NSString *)identifier fromImage:(UIImage *)image withAccuracy:(PDFScannerAccuracy)accuracy;

@end
