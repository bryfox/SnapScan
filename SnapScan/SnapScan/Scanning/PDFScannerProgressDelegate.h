//
//  PDFScannerProgressDelegate.h
//  SnapScan
//
//  Created by Bryan Fox on 6/12/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#ifndef PDFScannerProgressDelegate_h
#define PDFScannerProgressDelegate_h

@protocol PDFScannerProgressDelegate <NSObject>
-(void)didUpdateProgress:(NSInteger)progress forIdentifier:(NSString *)identifier;
@end

#endif /* PDFScannerProgressDelegate_h */
