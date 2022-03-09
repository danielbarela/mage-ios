//
//  MapViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/9/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots

import MagicalRecord

@testable import MAGE

class MapViewControllerTests: KIFSpec {
    
    override func spec() {
        // skipping these tests until the map delegate is fixed
        xdescribe("MapViewControllerTests") {
            var controller: UINavigationController!
            var window: UIWindow!;
            var mapViewController: MapViewController!;
            beforeEach {
                
                if (controller != nil) {
                    waitUntil { done in
                        controller.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                }
                TestHelpers.clearAndSetUpStack();
                NSManagedObject.mr_setDefaultBatchSize(1);
                window = UIWindow(frame: UIScreen.main.bounds);
                window.makeKeyAndVisible();
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                UserDefaults.standard.synchronize();
                
                Server.setCurrentEventId(1);
                TimeFilter.setObservation(.all);

                controller = UINavigationController();
                window.rootViewController = controller;
            }
            
            afterEach {
                
                waitUntil { done in
                    mapViewController.dismiss(animated: false, completion: {                        controller.dismiss(animated: false, completion: {
                            done();
                        });
                    });
                }
                
                window?.resignKey();
                window.rootViewController = nil;
                controller = nil;
                window = nil;
                TestHelpers.clearAndSetUpStack();
                NSManagedObject.mr_setDefaultBatchSize(20);
            }
            
            describe("Feed item tests") {
                it("should get one mappable feed item retriever and start it with no initial items add one") {
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm");
                    MageCoreDataFixtures.addUser(userId: "user")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                    UserDefaults.standard.currentUserId = "user";
                    
                    let feedIds: [String] = ["0","1","2","3"];
                    let feeds = MageCoreDataFixtures.parseJsonFile(jsonFile: "feeds");
                    MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                        let remoteIds: [String] = Feed.populateFeeds(feeds: feeds as! [[AnyHashable : Any]], eventId: 1, context: localContext)
                        expect(remoteIds) == feedIds;
                    })

                    mapViewController = MapViewController(scheme: MAGEScheme.scheme());
                    controller.pushViewController(mapViewController, animated: true);
                                        
                    tester().wait(forTimeInterval: 2);
                    
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "4", properties: ["primary": "Primary Value for item"])
                    tester().wait(forTimeInterval: 2);
                    TestHelpers.printAllAccessibilityLabelsInWindows();
                    tester().waitForView(withAccessibilityLabel: "Feed 1 Item 4");
                }
            }
            
            it("initialize the MapViewController") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm");
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                UserDefaults.standard.currentUserId = "user";

                mapViewController = MapViewController(scheme: MAGEScheme.scheme());
                controller.pushViewController(mapViewController, animated: true);
                
            }
            
            it("initialize the MapViewController and create new observation") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                UserDefaults.standard.currentUserId = "user";

                mapViewController = MapViewController(scheme: MAGEScheme.scheme());
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForTappableView(withAccessibilityLabel: "New");
                tester().tapView(withAccessibilityLabel: "New");
                
                    expect(UIApplication.getTopViewController()).to(beAnInstanceOf(MDCBottomSheetController.self))
                    
                    tester().tapView(withAccessibilityLabel: "Cancel");
                    expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(ObservationEditCardCollectionViewController.self))
                    tester().tapView(withAccessibilityLabel: "Cancel");
                    tester().tapView(withAccessibilityLabel: "Yes, Discard")
                    expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(MapViewController.self))
            }
            
            it("initialize the MapViewController and create new observation with no location") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                UserDefaults.standard.currentUserId = "user";

                mapViewController = MapViewController(scheme: MAGEScheme.scheme());
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = nil;
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForTappableView(withAccessibilityLabel: "New");
                tester().tapView(withAccessibilityLabel: "New");
            
                tester().waitForAnimationsToFinish()

                    expect(UIApplication.getTopViewController()).to(beAnInstanceOf(MDCBottomSheetController.self))
                    
                    tester().tapView(withAccessibilityLabel: "Cancel");
                    expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(ObservationEditCardCollectionViewController.self))
                    tester().tapView(withAccessibilityLabel: "Cancel");
                    tester().tapView(withAccessibilityLabel: "Yes, Discard")
                    expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(MapViewController.self))
            }
            
            it("initialize the MapViewController and create new empty observation") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                UserDefaults.standard.currentUserId = "user";

                mapViewController = MapViewController(scheme: MAGEScheme.scheme());
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForTappableView(withAccessibilityLabel: "New");
                tester().tapView(withAccessibilityLabel: "New");
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                tester().tapView(withAccessibilityLabel: "Save");
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                let properties: [String: Any] = observation.properties! as! [String: Any];
                let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                let geometry: SFGeometry = observation.geometry!;
                let point: SFPoint = geometry as! SFPoint;
                expect(point.x).to(beCloseTo(-105.2677));
                expect(point.y).to(beCloseTo(40.008));
                expect(properties["accuracy"] as? Double).to(equal(5.2))
                expect(properties["delta"] as? Int).to(beGreaterThan(0));
                expect(properties["provider"] as? String).to(equal("gps"));
                expect(properties["timestamp"] as? String).toNot(beNil());
                expect(forms).toNot(beNil());
                expect(observation.isDirty).to(beTrue());
                expect(observation.attachments).to(beEmpty());
                expect(observation.favoritesMap).to(beEmpty());
                expect(geometry).to(beAnInstanceOf(SFPoint.self));
                expect(observation.eventId).to(equal(1));
                expect(observation.remoteId).to(beNil());
            }
            
            it("initialize the MapViewController and cancel creating new observation") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                    
                UserDefaults.standard.currentUserId = "user";
                
                mapViewController = MapViewController(scheme: MAGEScheme.scheme());
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForTappableView(withAccessibilityLabel: "New");
                tester().tapView(withAccessibilityLabel: "New");
                
                // form picker
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Yes, Discard");
                expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(MapViewController.self))
            }
            
            it("initialize the MapViewController and create new empty observation with long press") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                UserDefaults.standard.currentUserId = "user";
                
                mapViewController = MapViewController(scheme: MAGEScheme.scheme());
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForView(withAccessibilityLabel: "map");
                expect(mapViewController.mapView).toEventuallyNot(beNil());

                mapViewController.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), latitudinalMeters: 1, longitudinalMeters: 1), animated: false);
                mapViewController.mapView.setCenter(CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), animated: false);
                tester().longPressView(withAccessibilityLabel: "map", duration: 1.0);
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                tester().tapView(withAccessibilityLabel: "Save");
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                let properties: [String: Any] = observation.properties! as! [String: Any];
                let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                let geometry: SFGeometry = observation.geometry!;
                expect(geometry).to(beAnInstanceOf(SFPoint.self));
                let point: SFPoint = geometry as! SFPoint;
                expect(point.x).to(beCloseTo(-105.2677));
                expect(point.y).to(beCloseTo(40.008));
                expect(properties["accuracy"] as? Double).to(beNil())
                expect(properties["delta"] as? Int).to(equal(0));
                expect(properties["provider"] as? String).to(equal("manual"));
                expect(properties["timestamp"] as? String).toNot(beNil());
                expect(forms).toNot(beNil());
                expect(observation.isDirty).to(beTrue());
                expect(observation.attachments).to(beEmpty());
                expect(observation.favoritesMap).to(beEmpty());
                expect(observation.eventId).to(equal(1));
                expect(observation.remoteId).to(beNil());
            }
            
            it("initialize the MapViewController and create an observation and view it") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                UserDefaults.standard.currentUserId = "user";
                
                mapViewController = MapViewController(scheme: MAGEScheme.scheme());
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "map");
                expect(mapViewController.mapView).toEventuallyNot(beNil());
                mapViewController.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), latitudinalMeters: 1, longitudinalMeters: 1), animated: false);
                mapViewController.mapView.setCenter(CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), animated: false);
                tester().longPressView(withAccessibilityLabel: "map", duration: 1.0);
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                tester().tapView(withAccessibilityLabel: "timestamp");
                
                tester().waitForView(withAccessibilityLabel: "timestamp Date Picker");
                tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .backwardFromCurrentValue);
                tester().tapView(withAccessibilityLabel: "Done");
                
                tester().tapView(withAccessibilityLabel: "Save");
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                let properties: [String: Any] = observation.properties! as! [String: Any];
                let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                let geometry: SFGeometry = observation.geometry!;
                expect(geometry).to(beAnInstanceOf(SFPoint.self));
                let point: SFPoint = geometry as! SFPoint;
                expect(point.x).to(beCloseTo(-105.2677));
                expect(point.y).to(beCloseTo(40.008));
                expect(properties["accuracy"] as? Double).to(beNil())
                expect(properties["delta"] as? Int).to(equal(0));
                expect(properties["provider"] as? String).to(equal("manual"));
                expect(properties["timestamp"] as? String).toNot(beNil());
                expect(forms).toNot(beNil());
                expect(observation.isDirty).to(beTrue());
                expect(observation.attachments).to(beEmpty());
                expect(observation.favoritesMap).to(beEmpty());
                expect(observation.eventId).to(equal(1));
                expect(observation.remoteId).to(beNil());
                
                
                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                tester().tapView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())")
                
                tester().waitForTappableView(withAccessibilityLabel: "More Details");
                tester().tapView(withAccessibilityLabel: "More Details");
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                
                expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(ObservationViewCardCollectionViewController.self))
            }
            
            it("initialize the MapViewController and view a polygon observation") {
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson(filename: "polygonObservation");
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.observationTimeFilter = TimeFilterType.all;
                UserDefaults.standard.currentUserId = "user";
                let mockMapDelegate = MockMKMapViewDelegate();
                mapViewController = MapViewController(scheme: MAGEScheme.scheme(), andMapEventDelegate: mockMapDelegate);
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "map");
                expect(mapViewController.mapView).toNot(beNil());
                mapViewController.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), latitudinalMeters: 1000, longitudinalMeters: 1000), animated: false);
                mapViewController.mapView.setCenter(CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), animated: false);
                
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                let properties: [String: Any] = observation.properties! as! [String: Any];
                let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                let geometry: SFGeometry = observation.geometry!;
                expect(geometry).to(beAnInstanceOf(SFPolygon.self));
                expect(properties["timestamp"] as? String).toNot(beNil());
                expect(forms).toNot(beNil());
                expect(observation.isDirty).to(beFalse());
                expect(observation.eventId).to(equal(1));
                expect(observation.remoteId).to(equal("observationabc"));
                
                TestHelpers.printAllAccessibilityLabelsInWindows();

                
                expect(mockMapDelegate.finishedRendering).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map never rendered");
                tester().tapScreen(at: CGPoint(x: 200, y: 390));
                
                tester().wait(forTimeInterval: 1.0)
                TestHelpers.printAllAccessibilityLabelsInWindows();

                tester().waitForTappableView(withAccessibilityLabel: "More Info");
            }
        }
    }
}
