//
//  PDFScanner.m
//  ScanMe
//
//  Created by Bryan Fox on 5/22/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import "PDFScanner.h"
#import "UIImage+Pix.h"
#import "DefaultFileManager.h"
#import "DLog.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include <tesseract/baseapi.h>
#include <tesseract/renderer.h>
#include <leptonica/allheaders.h>
#include <zlib.h>
#pragma clang diagnostic pop

@interface PDFScanner ()
@property DefaultFileManager *defaultFileManager;
@property (readonly) NSString *baseDirectory;
@end

@implementation PDFScanner

- (instancetype)init
{
    return [self initWithBaseDirectory:[DefaultFileManager new].pdfDirectoryName];
}

- (instancetype)initWithBaseDirectory:(NSString *)baseDirectory
{
    self = [super init];
    if (self) {
        _baseDirectory = baseDirectory;
        _defaultFileManager = [DefaultFileManager new];
    }
    return self;
}

- (NSString *)savePDFForIdentifier:(NSString *)identifier fromImage:(UIImage *)image withAccuracy:(PDFScannerAccuracy)accuracy {
    [self setTmpDir];
    BOOL success = 0;
    NSString *filename = [identifier stringByAppendingString:@".pdf"];

    // the tessdata directory must contain both language training data and the pdf.ttf font
    NSURL *tessDataDir = [[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"tessdata"];
    // The full path to the file we'll create (/var/)
    NSURL *pdfFullPath = [[self saveDestinationDirectory] URLByAppendingPathComponent:filename];
    // The PDFRenderer automatically appends a PDF extension to our supplied output path before writing,
    // and expects input to exclude this
    NSURL *pdfBasePath = [pdfFullPath URLByDeletingPathExtension];
    // And we want to return the path *without* the user documents directory, since that could change
    NSString *returnedPath = [self.baseDirectory stringByAppendingPathComponent:filename];

    tesseract::TessBaseAPI *api = new tesseract::TessBaseAPI();
    tesseract::OcrEngineMode engineMode = [self engineModeForAccuracy:accuracy];
    tesseract::TessPDFRenderer *renderer = new tesseract::TessPDFRenderer(pdfBasePath.relativePath.UTF8String,
                                                                          tessDataDir.relativePath.UTF8String,
                                                                          false);

    api->Init(tessDataDir.relativePath.UTF8String, "eng", engineMode);

    // Begin the PDF
    // we can call ProcessPages() instead, in which case we don't need to Begin/End Document
    // Support processing multiple imported photos as one PDF?
    success = renderer->BeginDocument(pdfBasePath.absoluteString.UTF8String);

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

    success = success && [[NSFileManager defaultManager] fileExistsAtPath:pdfFullPath.relativePath];

    if (success) {
        DLog(@"PDF output file: %@", returnedPath);
        return returnedPath;
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
-(NSURL *)saveDestinationDirectory {
    NSURL *pdfDir = [_defaultFileManager userDocumentsURLForSubdirectory:self.baseDirectory];
    [_defaultFileManager createDirectoryAtURL:pdfDir];
    // TODO: handle failure?
    return pdfDir;
}


@end
