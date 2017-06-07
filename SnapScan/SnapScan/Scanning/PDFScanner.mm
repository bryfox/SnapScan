//
//  PDFScanner.m
//  ScanMe
//
//  Created by Bryan Fox on 5/22/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import "PDFScanner.h"
#import "UIImage+Pix.h"
#import "DLog.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include <tesseract/baseapi.h>
#include <tesseract/renderer.h>
#include <leptonica/allheaders.h>
#include <zlib.h>
#pragma clang diagnostic pop

@implementation PDFScanner

-(NSString *)savePDFFromImage:(UIImage *)image withAccuracy:(PDFScannerAccuracy)accuracy {
    BOOL success = 0;
    [self setTmpDir];

    // the tessdata directory must contain both language training data and the pdf.ttf font
    NSString *tessDataDir = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"tessdata"];
    NSString *pdfOutputPath = [self pdfOutputPathWithoutExtension];
    tesseract::TessBaseAPI *api = new tesseract::TessBaseAPI();
    tesseract::OcrEngineMode engineMode = [self engineModeForAccuracy:accuracy];
    tesseract::TessPDFRenderer *renderer = new tesseract::TessPDFRenderer(pdfOutputPath.UTF8String, tessDataDir.UTF8String, false);

    api->Init(tessDataDir.UTF8String, "eng", engineMode);

    // Begin the PDF
    // we can call ProcessPages() instead, in which case we don't need to Begin/End Document
    // Support processing multiple imported photos as one PDF?
    success = renderer->BeginDocument(pdfOutputPath.UTF8String);

    // Process the Image
    if (success) {
        DLog(@"renderer->BeginDocument succeeded");
        Pix *pix = [image asPix];
        // TODO: Implement progress monitoring — not available through this (convenient) API
        success = api->ProcessPage(pix, 0, NULL, NULL, 0, renderer);
        pixDestroy(&pix);
    }

    // Finish the PDF
    if (success && !renderer->EndDocument()) {
        DLog(@"Error: renderer->EndDocument failed");
        success = false;
    }
    
    // N.B. destructor is what writes the output file.
    delete renderer;
    api->End();
    delete(api);

    if (!success) {
        DLog(@"Error: Scan success == false");
    }

    // The PDFRenderer automatically appends a PDF extension to our supplied output path before writing
    NSString *pdfFile = [pdfOutputPath stringByAppendingString:@".pdf"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:pdfFile];
    if (exists) {
        DLog(@"PDF output file: %@", pdfFile);
        return pdfFile;
    } else {
        DLog(@"Error: PDF output writing failed");
        return nil;
    }

}

#pragma MARK - private

-(tesseract::OcrEngineMode)engineModeForAccuracy:(PDFScannerAccuracy)accuracy {
    switch (accuracy) {
        case PDFScannerAccuracyHigh:
            return tesseract::OEM_TESSERACT_ONLY;
        case PDFScannerAccuracyMedium:
            return tesseract::OEM_CUBE_ONLY;
            break;
        case PDFScannerAccuracyLow:
            return tesseract::OEM_TESSERACT_CUBE_COMBINED;
    }
}

-(NSString *)pdfOutputPathWithoutExtension {
    // TODO: allow for friendlier names (or move later?)
    NSString *outputFilename = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *pdfSaveDir = [self saveDestinationDirectory];
    return [[NSString alloc] initWithString: [pdfSaveDir stringByAppendingPathComponent:outputFilename]];
}

/**
 Set tmp dir for leptonica (else defaults to unwriteable /tmp)
 (requires forked version for now): https://tpgit.github.io/Leptonica/psio2_8c_source.html
 */
-(void)setTmpDir {
    NSString *tmpDir = NSTemporaryDirectory();
    setenv("TMPDIR", tmpDir.UTF8String, 0);
}

/**
 Save all pdfs to [documents]/pdf/
 */
-(NSString *)saveDestinationDirectory {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *pdfDir = [docsDir stringByAppendingPathComponent:@"pdf"];
    return [self createDirectoryIfNeeded:pdfDir] ? pdfDir : docsDir;
}

/**
 Create dir if not already
 @returns true if exists
 */
- (BOOL)createDirectoryIfNeeded:(NSString *)dir {
    NSError *error = [NSError new];
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];
    if (!success) {
        DLog(@"Error during directory creation: %@", error);
    }

    return success;
}

@end
