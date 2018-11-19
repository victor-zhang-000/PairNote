//
//  Entry.swift
//  PairNote
//
//  Created by 张溢 on 2018/11/13.
//  Copyright © 2018年 z. All rights reserved.
//

import Foundation

class Entry {
    var identifier : String
    var content : String
    var isLocked : Bool
    var serverEditing : Bool
    init(id : String){
        identifier = id
        content = ""
        isLocked = false
        serverEditing = false
    }
}


class AllEntries {
    var entryList: [Entry] = []
    let queue = DispatchQueue(label: "MyArrayQueue")
    var exportString = "Thanks for using PairNote"
    
    public func add(content : String, completion : @escaping () -> Void){
        let newEntry = Entry(id : PacketTool.share.generateID())
        newEntry.content = content
        let myGroup = DispatchGroup()
        myGroup.enter()
        queue.async(flags : .barrier) {
            self.entryList.append(newEntry)
            myGroup.leave()
        }
        myGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
   
    public func remove(id : String, completion : @escaping () -> Void) {
        let myGroup = DispatchGroup()
        myGroup.enter()
        queue.async {
            self.entryList = self.entryList.filter() { $0.identifier != id }
            myGroup.leave()
        }
        myGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
    
    public func edit(id : String, newContent : String, completion : @escaping () -> Void) {
        let myGroup = DispatchGroup()
        myGroup.enter()
        queue.async {
            for entry in self.entryList {
                if(entry.identifier == id) {
                    entry.content = newContent
                }
            }
            myGroup.leave()
        }
        myGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
    
    public func getEntry(id : String) -> Entry?{
        for entry in entryList{
            if(entry.identifier == id) {
                return entry
            }
        }
        return nil
    }
    
    public func initList(entries: [Entry]){
        entryList = entries
    }
    
    public func exportToString(completion : @escaping () -> Void) {
        let myGroup = DispatchGroup()
        myGroup.enter()
        var ret = ""
        queue.async {
            for i in 0..<self.entryList.count {
                ret += "\(i + 1). "
                ret += self.entryList[i].content
                ret += "\n"
            }
            self.exportString = ret
            myGroup.leave()
        }
        myGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
    
}

