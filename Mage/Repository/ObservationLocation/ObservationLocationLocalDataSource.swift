//
//  ObservationLocationLocalDataSource.swift
//  MAGE
//
//  Created by Daniel Barela on 4/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

protocol ObservationLocationLocalDataSource {
    func getMapItems(
        observationUri: URL?,
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem]
    func getMapItems(
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem]
    func publisher() -> AnyPublisher<CollectionDifference<ObservationMapItem>, Never>
}

class ObservationLocationCoreDataDataSource: ObservationLocationLocalDataSource {

    func getObservationPredicates() -> [NSPredicate] {
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "observation.eventId == %@", Server.currentEventId() ?? -1))
        if let timePredicate = TimeFilter.getObservationTimePredicate(forField: "observation.timestamp") {
            predicates.append(timePredicate)
        }
        if Observations.getImportantFilter() {
            predicates.append(NSPredicate(format: "observation.observationImportant.important = %@", NSNumber(value: true)))
        }
        if Observations.getFavoritesFilter(),
           let currentUser = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()),
           let remoteId = currentUser.remoteId
        {
            predicates.append(NSPredicate(format: "observation.favorites.favorite CONTAINS %@ AND observation.favorites.userId CONTAINS %@", NSNumber(value: true), remoteId))
        }
        return predicates
    }

    func getMapItems(
        observationUri: URL?,
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem] {
        guard let observationUri = observationUri else {
            return []
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {

            var predicates: [NSPredicate] = []
            if let minLatitude = minLatitude,
               let maxLatitude = maxLatitude,
               let minLongitude = minLongitude,
               let maxLongitude = maxLongitude
            {
                predicates.append(NSPredicate(
                    format: "maxLatitude >= %lf AND minLatitude <= %lf AND maxLongitude >= %lf AND minLongitude <= %lf",
                    minLatitude,
                    maxLatitude,
                    minLongitude,
                    maxLongitude
                ))
            }


            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
                predicates.append(NSPredicate(
                    format: "self == %@",
                    id
                ))
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                if let observation = try? context.existingObject(with: id) as? Observation {
                    return observation.locations?.sorted(by: { one, two in
                        one.order < two.order
                    }).map({ location in
                        ObservationMapItem(observation: location)
                    }) ?? []
                }
            }
            return []
        }
    }

    func getMapItems(
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem] {
        let context = NSManagedObjectContext.mr_default()

        return await context.perform {
            var predicates: [NSPredicate] = self.getObservationPredicates()
            if let minLatitude = minLatitude,
               let maxLatitude = maxLatitude,
               let minLongitude = minLongitude,
               let maxLongitude = maxLongitude
            {
                predicates.append(NSPredicate(
                    format: "maxLatitude >= %lf AND minLatitude <= %lf AND maxLongitude >= %lf AND minLongitude <= %lf",
                    minLatitude,
                    maxLatitude,
                    minLongitude,
                    maxLongitude
                ))
            }
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let fetchRequest = ObservationLocation.fetchRequest()
            fetchRequest.predicate = predicate

            let results = context.fetch(request: fetchRequest)
            return results?.compactMap { location in
                return ObservationMapItem(observation: location)
            } ?? []
        }
    }

    func publisher() -> AnyPublisher<CollectionDifference<ObservationMapItem>, Never> {
        let context = NSManagedObjectContext.mr_default()

        var itemChanges: AnyPublisher<CollectionDifference<ObservationMapItem>, Never> {
            let fetchRequest: NSFetchRequest<ObservationLocation> = ObservationLocation.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "eventId", ascending: false)]
            return context.changesPublisher(for: fetchRequest, transformer: { location in
                ObservationMapItem(observation: location)
            })
            .catch { _ in Empty() }
            .eraseToAnyPublisher()
        }

        return itemChanges
    }
}