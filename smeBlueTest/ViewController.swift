//
//  ViewController.swift
//  smeBlueTest
//
//  Created by Thomas LEGER on 4/10/16.
//  Copyright © 2016 Thomas LEGER. All rights reserved.
//

import UIKit
import CoreBluetooth





class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
	
	
	//Status labels
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var uuidLabel: UILabel!
	
	//Device data Labels
	@IBOutlet weak var humData: UILabel!
	@IBOutlet weak var tempData: UILabel!
	@IBOutlet weak var pressureData: UILabel!


	var sensorValues			: [String: UInt8]		= ["Temperature": 0,
	                			                 		   "Pressure": 0,
	                			                 		   "Humidity": 0,
	                			                 		   "Time": 0]
	var instruction				: [UInt8]						= [0]
	var sentInstruction		: Bool							= false
	var receivedMessge		: Bool							= false
	var confirmationValid : Bool							= false
	var sentStr						: [UInt8]						= [0x53, 0x65, 0x6e, 0x74, 0x20, 0x73, 0x74, 0x72, 0x69, 0x6e, 0x67]
	var strSent						: Bool							= false
	var strConfirmation		: Bool							= false
	var writtenStr				: [UInt8]						= [0x57, 0x72, 0x69, 0x74, 0x74, 0x65, 0x6e, 0x20, 0x53, 0x74, 0x72, 0x69, 0x6e, 0x67]
	var bleCentralManager	: CBCentralManager!
	var smePeripheral			: CBPeripheral!
	var smeInfo						: SmeBleDevice!
	var cryptoKey					: CryptoKeyModel!
	var authToken					: SelfAuthenticator!

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		smeInfo = SmeBleDevice()
		cryptoKey = CryptoKeyModel()
		authToken	= SelfAuthenticator(key: cryptoKey)
		bleCentralManager = CBCentralManager(delegate: self, queue: nil)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
  // Dispose of any resources that can be recreated.
	}
	
// The original code for the Bluetooth part, aside from a few minor modifications,
// can be found here https://github.com/anasimtiaz/SwiftSensorTag
//  © Syed Anas Imtiaz | 2015 | MIT License
	
	func centralManagerDidUpdateState(central: CBCentralManager) {
		if central.state == CBCentralManagerState.PoweredOn {
			// Scan for peripherals if BLE is turned on
			central.scanForPeripheralsWithServices(nil, options: nil)
			statusLabel.text = "Searching for SmartEverything BLE Device..."
		} else {
			statusLabel.text = "Bluetooth is switched off or not initialized"
		}
	}

	// Check out the discovered peripherals to find SmartEverything Device
	func centralManager(central: CBCentralManager!, discoveredPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
		
		let deviceName = SmeBleDevice.getDeviceName()
		
		if SmeBleDevice.deviceFound(advertisementData) {
			//Update Status Label
			self.statusLabel.text = "\(deviceName) Found"
			
			// Stop scanning
			self.bleCentralManager.stopScan()
			// Set as the peripheral to use and establish connection
			self.smePeripheral = peripheral
			self.smePeripheral.delegate = self
			self.bleCentralManager.connectPeripheral(peripheral, options: nil)
			self.uuidLabel.text = "\(deviceName.capitalizedString) UUID: \(peripheral.identifier.UUIDString)"
		}
		else {
			self.statusLabel.text = "\(deviceName) NOT Found"
		}
	}
	
	//Discover services of the peripheral
	func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
		self.statusLabel.text = "Discovering peripheral services"
		peripheral.discoverServices(nil)
	}
	
	// If disconnected, start searching again
	func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
		self.statusLabel.text = "Disconnected"
		central.scanForPeripheralsWithServices(nil, options: nil)
	}
	
	/******* CBCentralPeripheralDelegate *******/
	
	// Check if the service discovered is valid
	func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
		self.statusLabel.text = "Looking at peripheral services"
		for service in peripheral.services! {
			let thisService = service as CBService
			if SmeBleDevice.validUUID(thisService.UUID.UUIDString) {
				// Discover characteristics of Service
				peripheral.discoverCharacteristics(nil, forService: service as CBService)
			}
			// Uncomment to print list of UUIDs
			//println(thisService.UUID)
		}
	}
	
	// Enable notification and sensor for each characteristic of valid service
	func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
		
		self.statusLabel.text = "Enabling sensors"
		
		var enableValue = 1
		let enablyBytes = NSData(bytes: &enableValue, length: sizeof(UInt8))
		
		for charateristic in service.characteristics! {
			let thisCharacteristic = charateristic as CBCharacteristic
			if SmeBleDevice.validUUID(thisCharacteristic.UUID.UUIDString){
				// Enable Sensor Notification
				self.smePeripheral.setNotifyValue(true, forCharacteristic: thisCharacteristic)
			}
			if SmeBleDevice.validUUID(thisCharacteristic.UUID.UUIDString) {
				// Enable Sensor
				self.smePeripheral.writeValue(enablyBytes, forCharacteristic: thisCharacteristic, type: CBCharacteristicWriteType.WithResponse)
			}
		}
	}
	
	// Get data values when they are updated
	func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
		
		var valuesIndexKey: String
		var indexKey: UInt8
		var counter = 1
		var msg = SmeBleDevice.dataToUnisgnedBytes8(characteristic.value!)
		let len = msg.count
		
		self.statusLabel.text = "Connected"
		
		while (counter < len) {
			switch msg[counter] {
				case 0x21:
						confirmationValid = SmeBleDevice.checkConfirmation(msg, instruction: instruction)
						counter += len
						break
				case 0x74, 0x70, 0x68, 0x64:
						indexKey = msg[counter]
						valuesIndexKey = SmeBleDevice.rxKeysToWords(indexKey)
						sensorValues[valuesIndexKey] = msg[counter + 1]
						counter += 2
						break
			default :
				if strSent && (sentStr.count) == (Int)(msg.last!) {
					msg.removeLast()
					if strSent && sentStr == msg {
						strConfirmation = true
					}
				}
				break
			}
		}
	}
}