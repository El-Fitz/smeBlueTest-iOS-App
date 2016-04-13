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
    var id      : UInt8 = 0x00
    var instMsg :[UInt8]
    
    init (request: [UInt8] = [0], id: UInt8 = 0) {
        self.instMsg = [self.len]
        self.instMsg += request
    }
}