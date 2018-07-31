//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 26/7/18.
//  Copyright © 2018 S&J. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
