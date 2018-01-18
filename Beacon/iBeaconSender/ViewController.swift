//
//  ViewController.swift
//  iBeaconSender
//
//  Created by Atsushi Yamamoto on 2018/01/16.
//  Copyright © 2018 Atsushi Yamamoto. All rights reserved.
//

import Cocoa
import CoreBluetooth
import CoreLocation

class ViewController: NSViewController {
    
    private var manager: CBPeripheralManager!
    @IBOutlet private weak var startButton: NSButton!
    @IBOutlet private weak var endButton: NSButton!
    @IBOutlet private weak var uuidTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBPeripheralManager(delegate: self, queue: nil)
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    @IBAction func didTapStartButton(_ button: NSButton) {
        let uuidText = uuidTextField.stringValue
        let uuid = UUID(uuidString: uuidText)
        let beaconData = BeaconData(proximityUUID: uuid, major: 1, minor: 1, measuredPower: -59)
        
        manager.startAdvertising(beaconData.advertisement as! [String : Any])
    }
    
    @IBAction func didTapEndButton(_ button: NSButton) {
        manager.stopAdvertising()
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            startButton.isEnabled = true
            endButton.isEnabled = true
            uuidTextField.isEnabled = true
        } else {
            startButton.isEnabled = false
            endButton.isEnabled = false
            uuidTextField.isEnabled = false
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("Advertising started")
    }
}

final class BeaconData: NSObject {
    let advertisement: NSDictionary
    
    init(proximityUUID: UUID?, major: UInt16?, minor: UInt16?, measuredPower: Int8?) {
        var buffer = [CUnsignedChar](repeating: 0, count: 21)
        (proximityUUID! as NSUUID).getBytes(&buffer)
        buffer[16] = CUnsignedChar(major! >> 8)
        buffer[17] = CUnsignedChar(major! & 255)
        buffer[18] = CUnsignedChar(major! >> 8)
        buffer[19] = CUnsignedChar(major! & 255)
        buffer[20] = CUnsignedChar(bitPattern: measuredPower!)
        
        let data = Data(bytes: buffer, count: buffer.count)
        advertisement = NSDictionary(object: data, forKey: "kCBAdvDataAppleBeaconKey" as NSCopying)
    }
}
