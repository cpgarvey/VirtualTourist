//
//  GCDBlackBox.swift
//  On The Map
//
//  Created by Chris Garvey on 2/1/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import Foundation

/* Global GCD function to update main queue */
func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}