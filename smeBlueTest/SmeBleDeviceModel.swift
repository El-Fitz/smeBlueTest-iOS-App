//
//  SmeBleDeviceModel.swift
//  smeBlueTest
//
//  Created by Thomas LEGER on 4/11/16.
//  Copyright © 2016 Thomas LEGER. All rights reserved.
//

import Foundation
import CoreBluetooth

let name            : String = "FOX-BRDG"
let UUIDs           : [String: String] = ["service": "FFF0",
                                          "write": "FFF3",
                                          "notify": "FFF4"]
let instructionSet  : [String: UInt8] = ["Send" : 0x53,
                                         "Print": 0x50,
                                         "Write": 0x57,
                                         "Delog": 0x44,
                                         "Update": 0x55,
                                         "Emit" : 0x45]
let sensorSet       : [String: UInt8] = ["Temperature": 0x75,
                                         "Pressure" : 0x70,
                                         "Humidity" : 0x68,
                                         "Time"     : 0x64]
let rxDictionnary   : [UInt8: String] = [0x75: "Temperature",
                                         0x70: "Pressure",
                                         0x68: "Humidity",
                                         0x64: "Time"]

class SmeBleDevice {
    
    
    // Return Device Name
    class func getDeviceName() -> String {
        return name
    }
    
    // Check name of device from advertisement data
    class func deviceFound (advertisementData: [NSObject : AnyObject]!) -> Bool {
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? NSString
        return (nameOfDeviceFound == name)
    }
    
    // Check if the service or characteristic has a valid or valid data / characteristic  UUID
    class func validUUID (uuid : String) -> Bool {
        if UUIDs.indexForKey(uuid) != nil {
            return uuid == UUIDs[uuid]
        }
        return false
    }

    // Return stored sensor value
    class func getSensorValue(inout sensorValues: [String: UInt8], key: String) -> UInt8 {
        if (sensorValues.indexForKey(key) != nil) {
            return sensorValues[key]!
        } else {
            return 0
        }
    }
    
    // Update stored sensor value
    class func updateSensorValue(inout sensorValues: [String: UInt8], key: String, val: UInt8) -> Bool {
        if sensorValues.indexForKey(key) != nil {
            sensorValues[key] = val
            return true
        }
        return false
    }
    
    //Translate Received Data to human language
    class func rxKeysToWords(key: UInt8) -> String {
        if rxDictionnary.indexForKey(key) != nil {
            return rxDictionnary[key]!
        }
        return "0"
    }
    
    //Convert Received Data to an array of UInt8 bytes
    class func dataToUnisgnedBytes8(value : NSData) -> [UInt8] {
        let count = value.length
        var array = [UInt8](count: count, repeatedValue: 0)
        value.getBytes(&array, length:count * sizeof(UInt8))
        return array
    }
    
    class func checkConfirmation(confirmation: [UInt8], instruction: [UInt8]) -> Bool {
        if confirmation.dropFirst() == instruction.dropFirst(4) {
            return true
        }
        return false
    }
    
    class func isValidInstruction(instruction: UInt8, param: UInt8 = 0) -> Bool {
        switch instruction {
        case 0x53, 0x50 :
            if rxDictionnary.keys.contains(param) {
                return true
            } else {
                return false
            }
        case 0x57, 0x44, 0x55, 0x45:
            return true
        default:
            return false
        }
    }
}