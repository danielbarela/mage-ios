//
//  EnlargedAnnotation.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

public class EnlargedAnnotation: NSObject, MKAnnotation {
    var enlarged: Bool = false

    var shouldEnlarge: Bool = false

    var shouldShrink: Bool = false

    var clusteringIdentifierWhenShrunk: String?

    var clusteringIdentifier: String?

    var annotationView: MKAnnotationView?

    var color: UIColor {
        return UIColor.clear
    }

    public var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    func markForEnlarging() {
        clusteringIdentifier = nil
        shouldEnlarge = true
    }

    func markForShrinking() {
        clusteringIdentifier = clusteringIdentifierWhenShrunk
        shouldShrink = true
    }

    func enlargeAnnoation() {
        guard let annotationView = annotationView else {
            return
        }
        enlarged = true
        shouldEnlarge = false
        annotationView.clusteringIdentifier = nil
        let currentOffset = annotationView.centerOffset
        annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
        annotationView.centerOffset = CGPoint(x: currentOffset.x * 2.0, y: currentOffset.y * 2.0)
    }

    func shrinkAnnotation() {
        guard let annotationView = annotationView else {
            return
        }
        enlarged = false
        shouldShrink = false
        annotationView.clusteringIdentifier = clusteringIdentifier
        let currentOffset = annotationView.centerOffset
        annotationView.transform = annotationView.transform.scaledBy(x: 0.5, y: 0.5)
        annotationView.centerOffset = CGPoint(x: currentOffset.x * 0.5, y: currentOffset.y * 0.5)
    }
}

class EnlargedAnnotationView: MKAnnotationView {
    static let ReuseID = "enlarged"

    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
