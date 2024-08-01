//
//  Chip8.swift
//  emu8
//
//  Created by Vincenzo Garambone on 01/08/24.
//

import Foundation

class Chip8 {
    
    var currentOpCode: UInt8 = 0
    
    // 4K memory
    var memory: [UInt8] = [UInt8](repeating: 0, count: Constants.memorySize)
    
    // 16 registers V0 ... VF
    let registers: [UInt8] = [UInt8](repeating: 0, count: 16)
    var indexRegister: UInt16 = 0
    
    var programCounter: UInt16 = 0
    
    var screen: [[Bool]] = [[Bool]](repeating: [Bool](repeating: false, count: Constants.height), count: Constants.width)
    
    // Timers, both counting at 60Hz
    var delayTimer: UInt8 = 0
    var soundTimer: UInt8 = 0
    
    // 16-lenght stack to hold the program counter
    var stack: [UInt16] = [UInt16](repeating: 0, count: 16)
    var stackIndex: UInt8 = 0
    
    // Keymap (16 buttons) - stored in single dimension
    var keyMap: [Bool] = [Bool] (repeating: false, count: 16)

    
    func start(rom: [UInt8]) {
        programCounter = 0x200
        currentOpCode = 0
        indexRegister = 0
        stackIndex = 0
        
        loadFontSet()
        loadRom(rom: rom)
    }
    
    func loop() {
        currentOpCode = fetchOpCode()
        
        executeOpCode()
    }
    
    private func loadFontSet() {
        memory.replaceSubrange(0 ... Constants.fontSet.count, with: Constants.fontSet)
    }
    
    private func loadRom(rom: [UInt8]) {
        
        let romSize = rom.count
        let memoryStart = Constants.romMemoryStartIndex
        let memoryEnd = memoryStart + romSize
        
        memory.replaceSubrange(memoryStart ... memoryEnd, with: rom)
    }
    
    private func fetchOpCode() -> UInt8 {
        // an OpCode is 2 bytes long
        // merging the stored two next bytes
        return memory[Int(programCounter)] << 8 | memory[Int(programCounter) + 1]
    }
    
    private func executeOpCode() {
        // execute the instruction
    }
}
