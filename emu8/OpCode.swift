//
//  OpCode.swift
//  emu8
//
//  Created by Vincenzo Garambone on 01/08/24.
//

import Foundation
import SwiftRadix

struct OpCode {
    private let operation, first, second, third: UInt8

    init(firstTwo: UInt8, lastTwo: UInt8) {
        operation = firstTwo.hex.nibble(0).value
        first = firstTwo.hex.nibble(1).value
        second = lastTwo.hex.nibble(2).value
        third = lastTwo.hex.nibble(3).value
    }
}
