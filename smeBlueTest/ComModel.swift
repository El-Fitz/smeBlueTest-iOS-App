//
//  ComModel.swift
//  smeBlueTest
//
//  Created by Thomas LEGER on 4/10/16.
//  Copyright © 2016 Thomas LEGER. All rights reserved.
//


class Instruction {
    let inst    : UInt8 = 0x21
    var len     : UInt8 = 0x00
    var id      : UInt8
    var instMsg :[UInt8]
    
    init (request: [UInt8] = [0], id: UInt8 = 0) {
        let len = request.count
        let tempLen: UInt8 = 0x00
        let max: UInt8 = 0x60
        
        self.id = id
        while (Int(tempLen) < len && tempLen < max) {
            self.len += 1
        }
        self.instMsg = [self.len]
        self.instMsg += request
    }
}