//
//  ViewController.swift
//  iBeaconReceiver
//
//  Created by Atsushi Yamamoto on 2018/01/16.
//  Copyright © 2018 Atsushi Yamamoto. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet private weak var uuidLabel: UILabel!
    @IBOutlet private weak var majorLabel: UILabel!
    @IBOutlet private weak var minorLabel: UILabel!
    @IBOutlet private weak var proximityLabel: UILabel!
    @IBOutlet private weak var accuracyLabel: UILabel!
    @IBOutlet private weak var rssiLabel: UILabel!
    @IBOutlet private weak var stateLabel: UILabel!
    @IBOutlet private weak var logTextView: UITextView!
    
    private let uuidTexts = ["F202483B-D784-5B4E-BEF0-9AE63FD81F89"]
//    private let uuidTexts = ["E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"]
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(setUpLocationManagerWhenEnteringForeground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        setUpLocationManger()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController {
    @objc private func setUpLocationManagerWhenEnteringForeground() {
        let status = CLLocationManager.authorizationStatus()
        
        if status == .denied {
            alertForLocationServiceSettings()
        }
    }
    
    private func setUpLocationManger() {
        locationManager.delegate = self
        locationManager.distanceFilter = 1
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .notDetermined || status == .denied {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    private func startMonitoring() {
        uuidTexts.forEach { uuidText in
            logTextView.text = "Start monitoring"
            guard let uuid = UUID(uuidString: uuidText) else { return }
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: uuidText)
            locationManager.startMonitoring(for: beaconRegion)
        }
    }
    
    private func alertLocationService(title: String?, message: String?, _ okHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            okHandler?()
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    private func alertForLocationServiceSettings() {
        alertLocationService(title: "Location Service is denied", message: "To use the iBeacon function, please turn on Location Service.") {
            let url = URL(string: "app-settings:root=General&path=\(Bundle.main.bundleIdentifier ?? "")")
            UIApplication.shared.open(url!, options: [:])
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        logTextView.text = logTextView.text + "Change Authorization"
        switch status {
        case .notDetermined:
            break
        case .restricted:
            // The user can't enable Location Service. e.g. parental controls.
            alertLocationService(title: "Location Service is restricted", message: "You can't use the iBeacon function.")
            break
        case .denied:
            alertForLocationServiceSettings()
        case .authorizedAlways:
            startMonitoring()
        case .authorizedWhenInUse:
            startMonitoring()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        logTextView.text = logTextView.text + "\nStart monitoring for region"
        manager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        logTextView.text = logTextView.text + "\nDetermine state"
        switch state {
        case .inside:
            stateLabel.text = "Inside"
            manager.startRangingBeacons(in: region as! CLBeaconRegion)
        case .outside:
            stateLabel.text = "Outside"
        case .unknown:
            stateLabel.text = "Unknown"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        logTextView.text = logTextView.text + "\nRange beacons"
        beacons.forEach { beacon in
            uuidLabel.text = "\(beacon.proximityUUID.uuidString)"
            majorLabel.text = "\(beacon.major.intValue)"
            majorLabel.text = "\(beacon.minor.intValue)"
            rssiLabel.text = "\(beacon.rssi)"
            accuracyLabel.text = "\(beacon.accuracy)"
            
            switch beacon.proximity {
            case .unknown:
                proximityLabel.text = "Unknown"
            case .far:
                proximityLabel.text = "Far"
            case .near:
                proximityLabel.text = "Near"
            case .immediate:
                proximityLabel.text = "Immediate"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Enter event doesn't always get fired at the begining.
        logTextView.text = logTextView.text + "\nEnter"
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        logTextView.text = logTextView.text + "\nExit"
        manager.stopRangingBeacons(in: region as! CLBeaconRegion)
    }
}
