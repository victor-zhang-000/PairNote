//
//  PacketTool.swift
//  PairNote
//
//  Created by 张溢 on 2018/11/13.
//  Copyright © 2018年 z. All rights reserved.
//
/*
 Packet Types:
 Master
    A : notifyNew
    B : confirmRequest
    C : Allcontent
 Slave
    a : Pull
    b : entryAdd
    c : entryModify
    d : RequestModify
 */

import Foundation
import SwiftSocket

enum PacketType {
    case notifyNew
    case confirmRequest
    case allContent
    
    case pull
    case entryAdd
    case entryModify
    case requestModity
    
    case unknown
}

class PacketTool {
    static let share : PacketTool = PacketTool()

    func generateID() -> String{
        func randomInt(_ min: Int, _ max: Int) -> Int {
            return min + Int(arc4random_uniform(UInt32(max - min + 1)))
        }
        
        let timeInterval = NSDate().timeIntervalSince1970
        let doubleToString = "\(timeInterval)"
        let stringToInteger = (doubleToString as NSString).integerValue
        var result = "\(stringToInteger)"
        
        for i in 0..<6{
            result.append(Character(UnicodeScalar(randomInt(65, 125))!))
        }
        return result
    }
    
    func handlePacket(packet : [Byte]) -> PacketType{
        switch packet[0] {
        case UInt8(ascii:"A"):
            return .notifyNew
        case UInt8(ascii:"B"):
            return .confirmRequest
        case UInt8(ascii:"C"):
            return .allContent
            
        case UInt8(ascii:"a"):
            return .pull
        case UInt8(ascii:"b"):
            return .entryAdd
        case UInt8(ascii:"c"):
            return .entryModify
        case UInt8(ascii:"d"):
            return .requestModity

        default:
            return .unknown
        }
    }
    
    //subarray of byte to string
    
    func readAllContentPacket(packet : [Byte]) -> [Entry]{
        let count = Int(packet[1])
        //print(count)
        //print(packet.count)
        var entries : [Entry] = []
        for i in 0..<count{
            entries.append(bytesToEntry(bytes: packet, start: Int(2 + 64 * i)))
        }
        return entries
    }
    
    func bytesToEntry(bytes : [Byte], start : Int) -> Entry {
        //print(start)
        let idBytes = bytes[start ..< (start + 16)]
        let contentBytes = bytes[(start + 16) ..< (start + 64)]
        print(String(bytes: idBytes, encoding: .utf8)!)
        print(String(bytes: contentBytes, encoding: .utf8)!)
        let entry = Entry(id: String(bytes: idBytes, encoding: .utf8)!)
        entry.content = String(bytes: contentBytes, encoding: .utf8)!.trimmingCharacters(in: .whitespaces)
        return entry
    }
    
    
    //pad to 64 bytes fixed length
    func entryToBytes(entry : Entry) -> [Byte]{
        var str = entry.identifier
        str.append(entry.content)
        let paddedStr = str.padding(toLength: 64, withPad: " ", startingAt: 0)
        return Array(paddedStr.utf8)
    }
    
    //MARK: client functions
    func pullRequest() -> [Byte]{
        var bytes : [Byte] = []
        bytes.append(UInt8(ascii:"a"))
        bytes.append(UInt8(0))
        let paddedStr = "".padding(toLength: 3200, withPad: " ", startingAt: 0)
        bytes.append(contentsOf: Array(paddedStr.utf8))
        return bytes
    }
    
    
    
    //MARK: server functions
    func allContent(entries : [Entry]) -> [Byte] {
        var bytes : [Byte] = []
        bytes.append(UInt8(ascii:"C"))
        let count = entries.count
        bytes.append(UInt8(count))
        for i in 0..<count {
            bytes += entryToBytes(entry: entries[i])
        }
        for i in 0..<(50-count) {
            for j in 0..<64{
                bytes += [0]
            }
        }
        
        return bytes
    }

}
