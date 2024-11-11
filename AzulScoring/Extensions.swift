//
//  Extensions.swift
//  AzulScoring
//
//  Created by Noah Brauner on 3/29/22.
//

import Foundation

enum Bit: UInt8, CustomStringConvertible {
    case zero, one
    
    var description: String {
        switch self {
        case .one:
            return "1"
        case .zero:
            return "0"
        }
    }
    
    var value: Int {
        switch self {
        case .one:
            return 1
        case .zero:
            return 0
        }
    }
    
    var boolValue: Bool {
        switch self {
        case .one:
            return true
        case .zero:
            return false
        }
    }
    
    static func bits(fromBytes bytes: [UInt8]) -> [Bit] {
        return bytes.map({ bits(fromByte: $0) }).flatMap({ $0 })
    }
    
    static func bits(fromByte byte: UInt8) -> [Bit] {
        var byte = byte
        var bits = [Bit](repeating: .zero, count: 8)
        for i in 0..<8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }
            
            byte >>= 1
        }
        return bits.reversed()
    }
    
    static func bytes(fromBits bits: [Bit]) -> [UInt8] {
        var bytes = [UInt8]()
        
        let chunks = bits.chunked(into: 8)
        
        for chunk in chunks {
            var byte: Int = 0
            for i in 0...7 {
                byte += Int(pow(2, Double(abs(7-i)))) * chunk[i].value
            }
            bytes.append(UInt8(byte))
        }
        
        return bytes
    }
    
    static func byte(fromBits bits: [Bit]) -> UInt8 {
        var byte: Int = 0
        for i in 0...7 {
            byte += Int(pow(2, Double(abs(7-i)))) * bits[i].value
        }
        return UInt8(byte)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
