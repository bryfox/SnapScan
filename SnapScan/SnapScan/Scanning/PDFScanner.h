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

/**
 Scan image & save PDF file
 @param image from camera
 @returns location of saved PDF
 */
-(NSString *)savePDFFromImage:(UIImage *)image withAccuracy:(PDFScannerAccuracy)accuracy;

@end
