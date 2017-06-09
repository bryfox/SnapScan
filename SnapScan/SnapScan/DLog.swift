//
//  DLog.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/9/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import Foundation

#if DEBUG
func DLog(_ message: String = "", _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    NSLog("[\((file as NSString).lastPathComponent)] \(function):\(line) \(message)")
}
#endif
