//
//  Chip8.swift
//  emu8
//
//  Created by Vincenzo Garambone on 01/08/24.
//

import Foundation

class Chip8 {
    // 4K memory
    var memory: [UInt8] = .init(repeating: 0, count: Constants.memorySize)

    // 16 registers V0 ... VF
    var registers: [UInt8] = .init(repeating: 0, count: 16)
    var indexRegister: UInt16 = 0

    var programCounter: UInt16 = 0

    var screen: [[Bool]] = .init(repeating: [Bool](repeating: false, count: Constants.height), count: Constants.width)
    var redraw: Bool = false

    // Timers, both counting at 60Hz
    var delayTimer: UInt8 = 0
    var soundTimer: UInt8 = 0

    // 16-lenght stack to hold the program counter
    var stack: [UInt16] = .init(repeating: 0, count: 16)
    var stackIndex: UInt8 = 0

    // Keymap (16 buttons) - stored in single dimension
    var keyMap: [Bool] = .init(repeating: false, count: 16)

    func start(rom: [UInt8]) {
        programCounter = 0x200
        indexRegister = 0
        stackIndex = 0

        loadFontSet()
        loadRom(rom: rom)

        while true {
            loop()
        }
    }

    func loop() {
        executeOpCode(opCode: fetchOpCode())
        updateTimers()
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

    private func executeOpCode(opCode: OpCode) {
        switch (opCode.nibble1, opCode.nibble2, opCode.nibble3, opCode.nibble4) {
        case (0x00, 0x00, 0x0E, 0x00):
            clearScreen()
        case (0x00, 0x00, 0x0E, 0x00):
            returnFromSubroutine()
        case let (0x00, n1, n2, n3):
            callSubroutine(n1: n1, n2: n2, n3: n3)
        case let (0x01, n1, n2, n3):
            jumpToAddress(n1: n1, n2: n2, n3: n3)
        case let (0x02, n1, n2, n3):
            callSubroutine(n1: n1, n2: n2, n3: n3)
        case let (0x03, x, n2, n3):
            conditionalEqualsSkip(x: x, n1: n2, n2: n3)
        case let (0x04, x, n1, n2):
            conditionalNotEqualsSkip(x: x, n1: n1, n2: n2)
        case let (0x05, x, y, 0x00):
            conditionalXyEqualsSkip(x: x, y: y)
        case let (0x06, x, n1, n2):
            setRegisterToNN(x: x, n1: n1, n2: n2)
        case let (0x07, x, n1, n2):
            addNNtoRegisterX(x: x, n1: n1, n2: n2)
        case let (0x08, x, y, 0x00):
            setRegisterXToY(x: x, y: y)
        case let (0x08, x, y, 0x01):
            setRegisterXToYBitwiseOr(x: x, y: y)
        case let (0x08, x, y, 0x02):
            setRegisterXToYBitwiseAnd(x: x, y: y)
        case let (0x08, x, y, 0x03):
            setRegisterXToYBitwiseXor(x: x, y: y)
        case let (0x08, x, y, 0x04):
            addRegisterYtoXWithOverflow(x: x, y: y)
        case let (0x08, x, y, 0x05):
            subtractRegisterYtoXWithOverflow(x: x, y: y)
        case let (0x08, x, y, 0x06):
            rightShiftRegisterXAndStoreLeastSignficant(x: x, y: y)
        case let (0x08, x, y, 0x07):
            setRegisterXtoYminusXWithOverflow(x: x, y: y)
        case let (0x08, x, y, 0x0E):
            leftShiftRegisterXAndStoreLeastSignficant(x: x, y: y)
        case let (0x09, x, y, 0x00):
            skipIfRegisterXandYEquals(x: x, y: y)
        case let (0x0A, n1, n2, n3):
            setIndexRegister(n1: n1, n2: n2, n3: n3)
        case let (0x0B, n1, n2, n3):
            jumpToPlusRegister0(n1: n1, n2: n2, n3: n3)
        case let (0x0C, x, n1, n2):
            setRegisterXToRandomAndNn(x: x, n1: n1, n2: n2)
        case let (0x0D, x, y, height):
            drawSprite(x: x, y: y, height: height)
        case let (0x0E, x, 0x09, 0x0E):
            skipInstructionIfXisPressed(x: x)
        case let (0x0E, x, 0x0A, 0x01):
            skipInstructionIfXisNotPressed(x: x)
        case let (0x0F, x, 0x00, 0x0A):
            setRegisterXToDelayTimer(x: x)
        case let (0x0F, x, 0x00, 0x07):
            awaitKeyPressAndStore(x: x)
        case let (0x0F, x, 0x00, 0x0A):
            setDelayTimerToRegisterX(x: x)
        case let (0x0F, x, 0x01, 0x05):
            setSoundTimerToRegisterX(x: x)
        case let (0x0F, x, 0x01, 0x08):
            addRegisterXtoIndexRegister(x: x)
        case let (0x0F, x, 0x02, 0x09):
            setIndexRegisterSpriteLocationFromRegisterX(x: x)
        case let (0x0F, x, 0x03, 0x03):
            storeDecimalRepresentationOfAddress(x: x)
        case let (0x0F, x, 0x05, 0x05):
            storeIncrementedIndexRegister(x: x)
        case let (0x0F, x, 0x06, 0x05):
            fillRegisterFromMemoryAtIndex(x: x)
        default:
            print("not implememented")
        }
    }

    private func updateTimers() {
        if delayTimer > 0 {
            delayTimer -= 1
        }

        if soundTimer > 0 {
            if soundTimer == 1 {
                print("making a sound")
            }
            soundTimer = 0
        }
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
        if registers[Int(x)] == combineTwoNibbles(first: n1, second: n2) {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }

    // 4XNN
    private func conditionalNotEqualsSkip(x: UInt8, n1: UInt8, n2: UInt8) {
        // skip the next instruction if registers[X] is not equals to NN
        if registers[Int(x)] != combineTwoNibbles(first: n1, second: n2) {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }

    // 5XY0
    private func conditionalXyEqualsSkip(x: UInt8, y: UInt8) {
        // skip the next instruction if registers[X] is not equals to registers[Y]
        if registers[Int(x)] == registers[Int(y)] {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }

    // 6XNN
    private func setRegisterToNN(x: UInt8, n1: UInt8, n2: UInt8) {
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

    // BXY4
    private func addRegisterYtoXWithOverflow(x: UInt8, y: UInt8) {
        let (result, overflow) = registers[Int(x)].addingReportingOverflow(registers[Int(y)])
        registers[Int(x)] = result
        // sets the last register to 0 or 1 depending on the overflow
        registers[registers.count - 1] = overflow ? 0 : 1
        programCounter += 2
    }

    // 8XY5
    private func subtractRegisterYtoXWithOverflow(x: UInt8, y: UInt8) {
        let (result, overflow) = registers[Int(x)].subtractingReportingOverflow(registers[Int(y)])
        registers[Int(x)] = result
        // sets the last register to 0 or 1 depending on the overflow
        registers[registers.count - 1] = overflow ? 0 : 1
        programCounter += 2
    }

    // 8XY6
    private func rightShiftRegisterXAndStoreLeastSignficant(x: UInt8, y _: UInt8) {
        let leastSignificant = registers[Int(x)] & 0x1
        registers[registers.count - 1] = leastSignificant
        registers[Int(x)] = registers[Int(x)] >> 1
        programCounter += 2
    }

    // 8XY7
    private func setRegisterXtoYminusXWithOverflow(x: UInt8, y: UInt8) {
        let (result, overflow) = registers[Int(y)].subtractingReportingOverflow(registers[Int(x)])
        registers[Int(x)] = result
        // sets the last register to 0 or 1 depending on the overflow
        registers[registers.count - 1] = overflow ? 0 : 1
        programCounter += 2
    }

    // 8XYE
    private func leftShiftRegisterXAndStoreLeastSignficant(x: UInt8, y _: UInt8) {
        let leastSignificant = registers[Int(x)] & 0x1
        registers[registers.count - 1] = leastSignificant
        registers[Int(x)] = registers[Int(x)] << 1
        programCounter += 2
    }

    // 9XY0
    private func skipIfRegisterXandYEquals(x: UInt8, y: UInt8) {
        if registers[Int(x)] == registers[Int(y)] {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }

    // ANNN
    private func setIndexRegister(n1: UInt8, n2: UInt8, n3: UInt8) {
        indexRegister = combineThreeNibbles(first: n1, second: n2, third: n3)
        programCounter += 2
    }

    // BNNN
    private func jumpToPlusRegister0(n1: UInt8, n2: UInt8, n3: UInt8) {
        programCounter += combineThreeNibbles(first: n1, second: n2, third: n3) + UInt16(registers[0])
    }

    // CXNN
    private func setRegisterXToRandomAndNn(x: UInt8, n1: UInt8, n2: UInt8) {
        let result = UInt8.random(in: 0 ... 255) & combineTwoNibbles(first: n1, second: n2)
        registers[Int(x)] = result
        programCounter += 2
    }

    // DXYN
    private func drawSprite(x: UInt8, y: UInt8, height: UInt8) {
        // width is constant
        let drawableWidth = x ... x + 8
        let drawableHeight = y ... y + height

        for line in drawableHeight {
            let pixelAddress = memory[Int(indexRegister) + Int(line)]

            for col in drawableWidth {
                let mask = 0x80 >> line
                let pixelValue: Bool = (mask & mask) > 0
                let oldValue = screen[Int(line)][Int(col)]

                if oldValue != pixelValue {
                    registers[registers.count - 1] = 1
                }

                screen[Int(line)][Int(col)] = pixelValue
            }
        }

        redraw = true
    }

    // EX9E
    private func skipInstructionIfXisPressed(x: UInt8) {
        let keyPressedIndex = registers[Int(x)]

        if keyMap[Int(keyPressedIndex)] == true {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }

    // EXA1
    private func skipInstructionIfXisNotPressed(x: UInt8) {
        let keyPressedIndex = registers[Int(x)]

        if keyMap[Int(keyPressedIndex)] != true {
            programCounter += 4
        } else {
            programCounter += 2
        }
    }

    // FX07
    private func setRegisterXToDelayTimer(x: UInt8) {
        registers[Int(x)] = delayTimer
    }

    // FX0A
    private func awaitKeyPressAndStore(x: UInt8) {
        var keyPress = false

        for keyIndex in 0 ... keyMap.count {
            if keyMap[keyIndex] == true {
                keyPress = true
                registers[Int(x)] = UInt8(keyIndex)
            }
        }

        if !keyPress {
            return
        }

        programCounter += 2
    }

    // FX15
    private func setDelayTimerToRegisterX(x: UInt8) {
        delayTimer = registers[Int(x)]
        programCounter += 2
    }

    // FX18
    private func setSoundTimerToRegisterX(x: UInt8) {
        soundTimer = registers[Int(x)]
        programCounter += 2
    }

    // FX1E
    private func addRegisterXtoIndexRegister(x: UInt8) {
        indexRegister += UInt16(registers[Int(x)])
        programCounter += 2
    }

    // FX29
    private func setIndexRegisterSpriteLocationFromRegisterX(x: UInt8) {
        // sprite is always 5 pixels tall
        let sprite = registers[Int(x)] * 5
        indexRegister = UInt16(sprite)

        programCounter += 2
    }

    // FX33
    private func storeDecimalRepresentationOfAddress(x: UInt8) {
        let value = registers[Int(x)]
        memory[Int(indexRegister)] = value / 100
        memory[Int(indexRegister) + 1] = (value / 10) % 10
        memory[Int(indexRegister) + 2] = (value / 100) % 10

        programCounter += 2
    }

    // FX55
    private func storeIncrementedIndexRegister(x: UInt8) {
        for memoryIndex in 0 ... x {
            memory[Int(memoryIndex)] = UInt8(indexRegister) + memoryIndex
        }

        programCounter += 2
    }

    // FX65
    private func fillRegisterFromMemoryAtIndex(x: UInt8) {
        for memoryIndex in 0 ... x {
            registers[Int(memoryIndex)] = UInt8(indexRegister) + memoryIndex
        }

        programCounter += 2
    }
}
