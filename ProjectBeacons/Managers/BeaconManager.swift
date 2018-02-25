//
//  BeaconObserver.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 18/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//
// Description:
// Beacon Manger class starts and stops beacon monitoring
// and keeps track of the region being monitored for

import CoreLocation

class BeaconManager {
    let beaconRegion: CLBeaconRegion
    let locationManager: CLLocationManager
    
    init(proximityUUID: UUID, identifier: String) {
        beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID, identifier: identifier)
        
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()

    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        print("starting beacon monitoring for region: \(beaconRegion)")
        locationManager.startMonitoring(for: beaconRegion)
        // TODO: Remove ranging beacons later
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func stopMonitoring() {
        locationManager.stopMonitoring(for: beaconRegion)
        locationManager.stopRangingBeacons(in: beaconRegion)
    }
}
