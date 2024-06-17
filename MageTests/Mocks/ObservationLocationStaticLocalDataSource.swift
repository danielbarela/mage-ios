//
//  ObservationLocationStaticLocalDataSource.swift
//  MAGETests
//
//  Created by Dan Barela on 5/16/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class ObservationLocationStaticLocalDataSource: ObservationLocationLocalDataSource {
    func getObservationLocation(observationLocationUri: URL?) async -> MAGE.ObservationLocation? {
        return nil
    }
    
    var list: [ObservationMapItem] = []
    
    func getMapItems(observationLocationUri: URL?, minLatitude: Double?, maxLatitude: Double?, minLongitude: Double?, maxLongitude: Double?) async -> [ObservationMapItem] {
        
        guard let minLatitude = minLatitude, let maxLatitude = maxLatitude, let minLongitude = minLongitude, let maxLongitude = maxLongitude else {
            return []
        }
        return list.filter { mapItem in
            guard let latitude = mapItem.coordinate?.latitude,
                  let longitude = mapItem.coordinate?.longitude,
                  let observationLocationUri = observationLocationUri
            else {
                return false
            }
            return observationLocationUri == mapItem.observationLocationId && minLatitude...maxLatitude ~= latitude && minLongitude...maxLongitude ~= longitude
        }
    }
    
    func getMapItems(observationUri: URL?, minLatitude: Double?, maxLatitude: Double?, minLongitude: Double?, maxLongitude: Double?) async -> [ObservationMapItem] {
        
        guard let minLatitude = minLatitude, let maxLatitude = maxLatitude, let minLongitude = minLongitude, let maxLongitude = maxLongitude else {
            return []
        }
        return list.filter { mapItem in
            guard let latitude = mapItem.coordinate?.latitude,
                  let longitude = mapItem.coordinate?.longitude,
                  let observationUri = observationUri
            else {
                return false
            }
            return observationUri == mapItem.observationId && minLatitude...maxLatitude ~= latitude && minLongitude...maxLongitude ~= longitude
        }
    }
    
    func getMapItems(minLatitude: Double?, maxLatitude: Double?, minLongitude: Double?, maxLongitude: Double?) async -> [MAGE.ObservationMapItem] {
        guard let minLatitude = minLatitude, let maxLatitude = maxLatitude, let minLongitude = minLongitude, let maxLongitude = maxLongitude else {
            return []
        }
        let filtered = list.filter { mapItem in
            guard let latitude = mapItem.coordinate?.latitude,
                  let longitude = mapItem.coordinate?.longitude
            else {
                NSLog("No coordinate")
                return false
            }
            let match = minLatitude...maxLatitude ~= latitude && minLongitude...maxLongitude ~= longitude
            NSLog("match \(match)")
            NSLog("latitude \(latitude) longitude \(longitude)")
            return match
        }
        
        NSLog("Filtered list to this many \(filtered)")
        return filtered
    }
    
    // Not quite right, just publishes the difference between an empty array
    func publisher() -> AnyPublisher<CollectionDifference<MAGE.ObservationMapItem>, Never> {
        AnyPublisher(Just(list.difference(from: [])).setFailureType(to: Never.self))
    }
    
    
}
