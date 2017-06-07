//
//  UIImage+Pix.h
//  SnapScan
//
//  Created by Bryan Fox on 6/6/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <leptonica/allheaders.h>

/**
 * Private additions for snapscan
 * Conversion is (for now) specific to scan input needs
 */
@interface UIImage (Pix)

- (Pix *)asPix;

@end
