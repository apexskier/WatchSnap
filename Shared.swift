//
//  Shared.swift
//  Watch Snap
//
//  Created by Cameron Little on 4/22/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import Foundation

extension NSError {
    var usefulDescription: String {
        if let m = self.localizedFailureReason {
            return m
        } else if self.localizedDescription != "" {
            return self.localizedDescription
        }
        return self.domain
    }
}