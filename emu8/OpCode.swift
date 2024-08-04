//
//  OpCode.swift
//  emu8
//
//  Created by Vincenzo Garambone on 01/08/24.
//

import Foundation
import SwiftRadix

struct OpCode {
    let nibble1, nibble2, nibble3, nibble4: UInt8

    init(firstTwo: UInt8, lastTwo: UInt8) {
        nibble1 = firstTwo.hex.nibble(0).value
        nibble2 = firstTwo.hex.nibble(1).value
        nibble3 = lastTwo.hex.nibble(2).value
        nibble4 = lastTwo.hex.nibble(3).value
    }
}
