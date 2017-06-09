//
//  TimeInterval.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/8/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import Foundation

extension TimeInterval {
    var minutes: TimeInterval { return self / 60 }
    var hours: TimeInterval { return self / 60 / 60 }
    var days: TimeInterval { return self / 60 / 60 / 24 }
}
