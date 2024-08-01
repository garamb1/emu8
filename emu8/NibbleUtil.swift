//
//  NibbleUtil.swift
//  emu8
//
//  Created by Vincenzo Garambone on 01/08/24.
//

import Foundation

func combineThreeNibbles(first: UInt8, second: UInt8, third: UInt8) -> UInt16 {
    return UInt16(first) << 8 | UInt16(second) | UInt16(third) << 4
}

func combineTwoNibbles(first: UInt8, second: UInt8) -> UInt8 {
    (first << 8) | (second)
}
