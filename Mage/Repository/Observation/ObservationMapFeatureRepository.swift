//
//  ObservationMapFeatureRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 4/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition
import MapFramework

class ObservationMapFeatureRepository: MapFeatureRepository, ObservableObject {
    @Injected(\.observationMapItemRepository)
    var mapItemRepository: ObservationMapItemRepository
    
    var dataSource: any DataSourceDefinition = DataSources.observation

    var alwaysShow: Bool = true

    let observationUri: URL

    init(observationUri: URL) {
        self.observationUri = observationUri
    }

    func getAnnotationsAndOverlays(zoom: Int, region: MKCoordinateRegion? = nil) async -> AnnotationsAndOverlays {
        let mapItems = await mapItemRepository.getMapItems(observationUri: observationUri)
        let annotations = mapItems.map { item in
            ObservationMapItemAnnotation(mapItem: item)
        }
        let overlays = mapItems.compactMap { item in
            if let accuracy = item.accuracy, 
                let geometry = item.geometry,
                let centroid = geometry.centroid()
            {
                return ObservationAccuracy(
                    center: CLLocationCoordinate2D(
                        latitude: centroid.y.doubleValue,
                        longitude: centroid.x.doubleValue
                    ),
                    radius: accuracy
                )
            }
            return nil
        }
        return AnnotationsAndOverlays(annotations: annotations, overlays: overlays)
    }

    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]? {
        return []
    }
}

class ObservationMapItemAnnotation: DataSourceAnnotation {
//    var id: URL?
//    var coordinate: CLLocationCoordinate2D
    var mapItem: ObservationMapItem
    var title: String?
    var subtitle: String?
    
    override var dataSource: any DataSourceDefinition {
        get {
            DataSources.observation
        }
        set { }
    }

    init(mapItem: ObservationMapItem) {
        self.mapItem = mapItem
        let itemKey = mapItem.observationLocationId?.absoluteString ?? ""
        if let point = mapItem.geometry?.centroid() {
            super.init(coordinate: CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue), itemKey: itemKey)
        } else {
            super.init(coordinate: kCLLocationCoordinate2DInvalid, itemKey: itemKey)
        }
        self.id = mapItem.observationLocationId?.absoluteString ?? UUID().uuidString
    }
}
