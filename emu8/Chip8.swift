//
//  Chip8.swift
//  emu8
//
//  Created by Vincenzo Garambone on 01/08/24.
//

import Foundation

class Chip8 {
    // 4K memory
    var memory: [UInt8] = [UInt8](repeating: 0, count: Constants.memorySize)
    
    // 16 registers V0 ... VF
    var registers: [UInt8] = [UInt8](repeating: 0, count: 16)
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
        indexRegister = 0
        stackIndex = 0
        
        loadFontSet()
        loadRom(rom: rom)
    }
    
    func loop() {
        let currentOpCode = fetchOpCode()

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
    
    private func fetchOpCode() -> OpCode {
        // an OpCode is 2 bytes long
        // merging the stored two next bytes
        // and returning it as a OpCode
        return OpCode(firstTwo: memory[Int(programCounter)], lastTwo: memory[Int(programCounter + 1)])
    }
    
    private func executeOpCode() {
        // execute the instruction
        
    }
    
    // 00E0
    private func clearScreen() {
        screen = [[Bool]](repeating: [Bool](repeating: false, count: Constants.height), count: Constants.width)
    }
    
    // 00EE
    private func returnFromSubroutine() {
        // decrease stack index
        stackIndex -= 1
        // set the program counter to the current stack value and increment it by 2
        programCounter = stack[Int(stackIndex)] + 2
    }
    
    // 1NNN
    private func jumpToAddress(n1: UInt8, n2: UInt8, n3: UInt8) {
        // combine the next three nibbles to obtain the NNN address and update the program counter
        let newAddress = combineThreeNibbles(first: n1, second: n2, third: n3)
        programCounter = newAddress
    }
    
    // 2NNN
    private func callSubroutine(n1: UInt8, n2: UInt8, n3: UInt8) {
        // add the program counter value to the stack
        stack[Int(stackIndex)] = programCounter
        // call the function at NNN
        jumpToAddress(n1: n1, n2: n2, n3: n3)
    }
    
    // 3XNN
    private func conditionalEqualsSkip(x: UInt8, n1: UInt8, n2: UInt8) {
        // skip the next instruction if registers[X] is equals to NN
        if (registers[Int(x)] == combineTwoNibbles(first: n1, second: n2)) {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }
    
    // 4XNN
    private func conditionalNotEqualsSkip(x: UInt8, n1: UInt8, n2: UInt8) {
        // skip the next instruction if registers[X] is not equals to NN
        if (registers[Int(x)] != combineTwoNibbles(first: n1, second: n2)) {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }
    
    
    // 5XY0
    private func conditionalXyEqualsSkip(x: UInt8, y: UInt8) {
        // skip the next instruction if registers[X] is not equals to registers[Y]
        if (registers[Int(x)] == registers[Int(y)]) {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }
    
    // 6XNN
    private func setRegisterToNN (x: UInt8, n1: UInt8, n2: UInt8) {
        // sets registers[x] to NN
        registers[Int(x)] = combineTwoNibbles(first: n1, second: n2)
        programCounter += 2
    }
    
    // 7XNN
    private func addNNtoRegisterX(x: UInt8, n1: UInt8, n2: UInt8) {
        registers[Int(x)] += combineTwoNibbles(first: n1, second: n2)
        programCounter += 2
    }
    
    // 8XY0
    private func setRegisterXToY(x: UInt8, y: UInt8) {
        registers[Int(x)] = registers[Int(y)]
        programCounter += 2
    }
    
    // 8XY1
    private func setRegisterXToYBitwiseOr(x: UInt8, y: UInt8) {
        registers[Int(x)] |= registers[Int(y)]
        programCounter += 2
    }
    
    // 8XY2
    private func setRegisterXToYBitwiseAnd(x: UInt8, y: UInt8) {
        registers[Int(x)] &= registers[Int(y)]
        programCounter += 2
    }
    
    // 8XY3
    private func setRegisterXToYBitwiseXor(x: UInt8, y: UInt8) {
        registers[Int(x)] ^= registers[Int(y)]
        programCounter += 2
    }
    
    
}
