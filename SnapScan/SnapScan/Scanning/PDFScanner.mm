//
//  PDFScanner.m
//  ScanMe
//
//  Created by Bryan Fox on 5/22/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import "PDFScanner.h"
#import "UIImage+Pix.h"
#import "MediaFileManager.h"
#import "PDFScannerProgressDelegate.h"
#import "DLog.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include <tesseract/baseapi.h>
#include <tesseract/renderer.h>
#include <tesseract/ocrclass.h> // for ETEXT_DESC and PROGRESS_FUNC
#include <leptonica/allheaders.h>
#include <zlib.h>
#pragma clang diagnostic pop

#ifdef DEBUG
#define DLogError(isError, ...) if (isError) DLog(@"Error: %@", [NSString stringWithFormat:__VA_ARGS__])
#endif

@interface PDFScanner ()
@property MediaFileManager *defaultFileManager;
@property ETEXT_DESC *progressMonitor;
@end

@implementation PDFScanner {
    PROGRESS_FUNC ocrMonitor;
    id<PDFScannerProgressDelegate> _progressDelegate;
}

// Tesseract's OCR only provides a global callback for progress updates.
// To provide scan-specific updates, we make use of thread_local data.
thread_local unsigned int threadProgress = -1;
thread_local void* threadProgressDelegate = NULL;
thread_local const char* threadScanId = NULL;

- (id<PDFScannerProgressDelegate>)progressDelegate {
    return _progressDelegate;
}

- (void)setProgressDelegate:(id<PDFScannerProgressDelegate>)progressDelegate {
    _progressDelegate = progressDelegate;
    threadProgressDelegate = (__bridge void*)progressDelegate;
}

bool onProgressUpdate(int progress, int left, int right, int top, int bottom) {
    if (threadProgress == progress) {
        return true;
    }

    threadProgress = progress;
    if (nil != threadProgressDelegate) {
        id<PDFScannerProgressDelegate> delegate = (__bridge id<PDFScannerProgressDelegate>)threadProgressDelegate;
        if ([delegate conformsToProtocol:@protocol(PDFScannerProgressDelegate)]) {
            NSString *scanId = [NSString stringWithUTF8String:threadScanId];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate didUpdateProgress:progress forIdentifier:scanId];
            });
        }
    }
    return true;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        _defaultFileManager = [MediaFileManager new];
        ocrMonitor = &onProgressUpdate;
        threadScanId = identifier.UTF8String;
        threadProgress = -1;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithIdentifier:[[NSUUID UUID] UUIDString]];
}

- (NSString *)savePDFFromImage:(UIImage *)image withAccuracy:(PDFScannerAccuracy)accuracy {
    [self setTmpDir];
    BOOL success = 0;
    NSString *filename = [self.identifier stringByAppendingString:@".pdf"];

    // the tessdata directory must contain both language training data and the pdf.ttf font
    NSURL *tessDataDir = [[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"tessdata"];
    // The full path to the file we'll create (e.g., in /var/)
    NSURL *pdfFullPath = [self.defaultFileManager.pdfDocumentDirectory URLByAppendingPathComponent:filename];
    // The PDFRenderer automatically appends a PDF extension to our supplied output path before writing,
    // and expects input to exclude this
    NSURL *pdfBasePath = [pdfFullPath URLByDeletingPathExtension];
    // And we want to return the path *without* the user documents directory, since that could change
    NSString *returnedPath = [self.defaultFileManager.pdfDirectoryName stringByAppendingPathComponent:filename];

    tesseract::TessBaseAPI *api = new tesseract::TessBaseAPI();
    tesseract::OcrEngineMode engineMode = [self engineModeForAccuracy:accuracy];
    tesseract::TessPDFRenderer *renderer = new tesseract::TessPDFRenderer(pdfBasePath.relativePath.UTF8String,
                                                                          tessDataDir.relativePath.UTF8String,
                                                                          false);

    success = api->Init(tessDataDir.relativePath.UTF8String, "eng", engineMode) == 0;
    DLogError(!success, @"api->Init failed");

    // Begin the PDF
    // we can call ProcessPages() instead, in which case we don't need to Begin/End Document
    // Support processing multiple imported photos as one PDF?
    success = renderer->BeginDocument(pdfBasePath.absoluteString.UTF8String);
    DLogError(!success, @"renderer->BeginDocument failed");

    // Process the Image
    if (success) {
        Pix *pix = [image asPix];

        // Equivalent of `api->ProcessPage(pix, 0, NULL, NULL, 0, renderer)`, but adds progress monitor
        api->SetInputName(NULL);
        api->SetImage(pix);
        ETEXT_DESC *monitor;
        monitor = new ETEXT_DESC();
        monitor->progress_callback = ocrMonitor;
        success = api->Recognize(monitor) == 0;
        DLogError(!success, @"renderer->Recognize(monitor) failed");

        if (success) {
            success = renderer->AddImage(api);
            DLogError(!success, @"renderer->AddImage(api) failed");
        }

        pixDestroy(&pix);
    }

    // Finish the PDF
    if (success) {
        success = renderer->EndDocument();
        DLogError(!success, @"Error: renderer->EndDocument failed");
    }

    // N.B. destructor is what writes the output file.
    delete renderer;
    api->End();
    delete(api);

    success = success && [[NSFileManager defaultManager] fileExistsAtPath:pdfFullPath.relativePath];
    DLogError(!success, @"PDF file was not created");

    return success ? returnedPath : nil;
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

@end
