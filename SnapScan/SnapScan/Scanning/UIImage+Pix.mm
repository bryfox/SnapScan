//
//  UIImage+Pix.m
//  SnapScan
//
//  Created by Bryan Fox on 6/6/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

#import "UIImage+Pix.h"

@implementation UIImage (Pix)

static const NSUInteger kDefaultRes = 72;

/**
 * Pix struct source: http://tpgit.github.io/Leptonica/pix_8h_source.html#l00079
 */
- (Pix *)asPix {

    NSData *pngData = UIImagePNGRepresentation(self);

    const l_uint8 *bytes = (l_uint8 *)pngData.bytes;
    Pix *pix = pixReadMem(bytes, pngData.length);
    pix = [self correctlyOrientedPix:pix];

    // TODO: Add debug timing, and see if 72dpi/300dpi matters
    pixSetXRes(pix, kDefaultRes);
    pixSetYRes(pix, kDefaultRes);

    // TODO: This still writes to tempfile. Consider implementing streams,
    // or including https://github.com/tmm1/fmemopen and building lept with HAVE_FMEMOPEN=1
    // (see environ.h in leptonica)
    return pix;
}

- (Pix *)correctlyOrientedPix:(Pix *)pix {
    // TODO: more rotation cases
    //    typedef NS_ENUM(NSInteger, UIImageOrientation) {
    //        UIImageOrientationUp,            // default orientation
    //        UIImageOrientationDown,          // 180 deg rotation
    //        UIImageOrientationLeft,          // 90 deg CCW
    //        UIImageOrientationRight,         // 90 deg CW
    //        UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
    //        UIImageOrientationDownMirrored,  // horizontal flip
    //        UIImageOrientationLeftMirrored,  // vertical flip
    //        UIImageOrientationRightMirrored, // vertical flip
    //    };

    // TODO: or see vimage fns: https://developer.apple.com/documentation/accelerate/vimage_geometry#//apple_ref/doc/uid/TP40005490-CH212-145717
    // ...and https://developer.apple.com/library/content/documentation/Performance/Conceptual/vImage/OverviewofvImage/OverviewofvImage.html
    if (self.imageOrientation == UIImageOrientationRight) {
        pix = pixRotate90(pix, 1);
    }
    return pix;
}

@end
