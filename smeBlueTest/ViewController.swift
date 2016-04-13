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
	
	//Action buttons
	@IBOutlet weak var updateTemp: UIButton!
	@IBOutlet weak var updatePressure: UIButton!
	@IBOutlet weak var updateHumidity: UIButton!
	@IBOutlet weak var updateAll: UIButton!
	@IBOutlet weak var updateString: UIButton!
	@IBOutlet weak var sendPayload: UIButton!
	
	//String field
	@IBOutlet weak var strField: UILabel!


	var sensorValues					: [String: UInt8]		= ["Temperature": 0,
	                			                 		   "Pressure": 0,
	                			                 		   "Humidity": 0,
	                			                 		   "Time": 0]
	var sensorLabels					: [String: UILabel]?
	var sentInstruction				: Bool							= false
	var receivedMessge				: Bool							= false
	var confirmationValid			: Bool							= false
	var sentStr								: [UInt8]						= [0x53, 0x65, 0x6e, 0x74, 0x20, 0x73, 0x74]
	var strSent								: Bool							= false
	var strConfirmation				: Bool							= false
	var writtenStr						: [UInt8]						= [0x57, 0x72, 0x69, 0x74, 0x74, 0x65, 0x6e]
	var instruction						: Instruction!
	var bleCentralManager			: CBCentralManager!
	var smePeripheral					: CBPeripheral!
	var smePeripheralWriteChar: CBCharacteristic?
	var smeInfo								: SmeBleDevice!
	var cryptoKey							: CryptoKeyModel!
	var authToken							: SelfAuthenticator!

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		smeInfo = SmeBleDevice()
		cryptoKey = CryptoKeyModel()
		authToken	= SelfAuthenticator(key: cryptoKey)
		bleCentralManager = CBCentralManager(delegate: self, queue: nil)
		instruction = Instruction()
		sensorLabels = ["Temperature": tempData, "Pressure": pressureData, "Humdity": humData]
		if (authToken.authenticated == true) {
			_ = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: Selector(sendInstruction([0x50])), userInfo: nil, repeats: true)
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		
		
  // Dispose of any resources that can be recreated.
	}
	
	@IBAction func sendPayloadFun(sender: AnyObject) {
		sendInstruction([0x45])
	}
	@IBAction func updatePressureFun(sender: AnyObject) {
		sendInstruction([0x53,0x70])
	}
	@IBAction func updateStrFun(sender: AnyObject) {
		writtenStr = SmeBleDevice.strToUnisgnedBytes8(strField.text!)
		sendInstruction([0x57])
	}
	@IBAction func updateHumidityFun(sender: AnyObject) {
		sendInstruction([0x53,0x74,0x53,0x68,0x53,0x70])
	}
	@IBAction func updateAllFun(sender: AnyObject) {
		sendInstruction([0x53,0x68])
	}
	@IBAction func updateTempFun(sender: AnyObject) {
		sendInstruction([0x53,0x74])
	}
	
	
	func valueToString (type: UInt8, val: UInt8) -> String {
		switch type {
		case 0x74: return "\(val) ˚C"
		case 0x70: return "\((Int)(val) + 1000) mbar"
		case 0x64: return "\(val) %"
		default : return ""
		}
	}
	
	// Send instructions to SmartEverything device
	func sendInstruction(request: [UInt8]) {
		let seconds = 5.0
		let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
		let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
		var counter	: Int = 0
		var len			: Int
		var strLen	: UInt8
		
		len  = request.count
		instruction.instMsg.removeAll()
		// If not yet authenticated with the SmartEverything Device, authenticate
		while (authToken.authenticated == false || instruction.id == 0x00 && counter < 10) {
			instruction.instMsg = authToken.authMsg
			sendToSMEDevice()
			dispatch_after(dispatchTime, dispatch_get_main_queue(), {
				counter += 1
			})
		}
		counter = 0
		instruction.instMsg.append(instruction.id)
		while (counter < len) {
			switch request[counter] {
			case 0x53, 0x50:
				instruction.instMsg.append(request[counter])
				instruction.instMsg.append(request[counter + 1])
				counter += 2
				break
			case 0x44, 0x45, 0x70:
				instruction.instMsg.append(request[counter])
				counter += 1
				break
			case 0x57:
				instruction.instMsg.append(request[counter])
				strLen = (UInt8)(writtenStr.count)
				if (strLen < 8) {
					instruction.instMsg.append((UInt8)(strLen))
					sentStr = writtenStr
				} else {
					instruction.instMsg.append(7)
					sentStr += writtenStr.prefix(7)
				}
				instruction.instMsg += sentStr
				counter += (Int)(strLen)
				break
			default :
				counter += 1
				break
			}
		}
		instruction.instMsg.insert((UInt8)(instruction.instMsg.count - 2), atIndex: 0)
		instruction.instMsg.insert(0x21, atIndex: 0)
		instruction.instMsg.insert(instruction.instMsg[1] + 2, atIndex: 0)
		sendToSMEDevice()
	}
	
	func sendToSMEDevice() {
		// See if characteristic has been discovered before writing to it
		if let writeCharacteristic = self.smePeripheralWriteChar {
			// Need a mutable var to pass to writeValue function
			let data = NSData(bytes: instruction.instMsg, length: sizeof(UInt8))
			self.smePeripheral?.writeValue(data, forCharacteristic: writeCharacteristic, type: CBCharacteristicWriteType.WithResponse)
		}
	}
	
	// Get data values when they are updated
	func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
		
		var valuesIndexKey: String
		var indexKey: UInt8
		var counter = 0
		var msg = SmeBleDevice.dataToUnisgnedBytes8(characteristic.value!)
		let len = msg.count
		
		self.statusLabel.text = "Connected"
		
		while (counter < len) {
			if (msg[counter] == 0x65) {
				instruction.id = (msg[counter + 2])
				authToken.updateStatus(msg[counter + 2])
				counter += 2
			} else {
				counter += 1
				switch msg[counter] {
				case 0x21:
					confirmationValid = SmeBleDevice.checkConfirmation(msg, instruction: instruction.instMsg)
					counter += len
					break
				case 0x74, 0x70, 0x68, 0x64:
					indexKey = msg[counter]
					valuesIndexKey = SmeBleDevice.rxKeysToWords(indexKey)
					sensorValues[valuesIndexKey] = msg[counter + 1]
					sensorLabels![valuesIndexKey]?.text = valueToString(msg[counter], val: msg[counter + 1])
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
		instruction.id = 0x00
		authToken.updateStatus(0x00)
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
				// Enable Write
				self.smePeripheralWriteChar = thisCharacteristic
				self.smePeripheral.writeValue(enablyBytes, forCharacteristic: thisCharacteristic, type: CBCharacteristicWriteType.WithResponse)
			}
		}
	}
}