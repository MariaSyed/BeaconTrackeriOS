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
    let locationManager: CLLocationManager
    
    init() {
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring(forRegions beaconRegions: [CLBeaconRegion]) {
        for beaconRegion in beaconRegions {
            locationManager.startMonitoring(for: beaconRegion)
        }
    }
    
    func stopMonitoring(forRegions beaconRegions: [CLBeaconRegion]) {
        for beaconRegion in beaconRegions {
            locationManager.stopMonitoring(for: beaconRegion)
        }
    }
    
    func startRanging(forRegion region: CLBeaconRegion) {
        // TODO: Remove ranging beacons later
        locationManager.startRangingBeacons(in: region)
    }
    
    func stopRanging(forRegion region: CLBeaconRegion) {
        // TODO: Remove ranging beacons later
        locationManager.stopRangingBeacons(in: region)
    }
}
