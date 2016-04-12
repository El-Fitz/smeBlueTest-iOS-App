//
//  SenderModel.swift
//  smeBlueTest
//
//  Created by Thomas LEGER on 4/10/16.
//  Copyright © 2016 Thomas LEGER. All rights reserved.
//


class SelfAuthenticator {
	let authVal	: UInt8 = 0x4b
	var len		: UInt8 = 0x62
    var authKey	:[UInt8]
	var authMsg	:[UInt8]
	var authenticated : Bool = false
	
    init (key: CryptoKeyModel = CryptoKeyModel()) {
		self.authKey = key.getKey()
        self.len = 0x062
        self.authMsg = [self.len]
        self.authMsg += [authVal]
        self.authMsg += self.authKey
		key.newKey = false
    }
	
	func updateAuthKey(key: CryptoKeyModel) {
		if key.newKeyGenerated() {
			self.authKey = key.getKey()
			key.switchKeyStatus()
		}
	}
	func getAuthMsg() -> [UInt8] {
		return authMsg
	}
	
	func updateStatus(status: UInt8) {
		if status == 0x00 {
			authenticated = false
		} else {
			authenticated = true
		}
	}
}


