//
//  KeyModel.swift
//  smeBlueTest
//
//  Created by Thomas LEGER on 4/10/16.
//  Copyright © 2016 Thomas LEGER. All rights reserved.
//

class CryptoKeyModel {
    var seed: UInt64
    var authKey: [UInt8]
    var newKey : Bool
    
    init (seed: UInt64 = 0, authKey: [UInt8] = [1, 1, 1, 1, 1, 1]) {
        self.seed = seed
        if seed == 0 {
            self.authKey = authKey
        } else {
            self.authKey = authKey
        }
        self.newKey = true
    }
    
    func getKey() -> [UInt8] {
        return authKey
    }
    func newKeyGenerated() -> Bool {
        return newKey
    }
    func switchKeyStatus() {
        newKey = !newKey
    }
}
