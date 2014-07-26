//
//  MapViewController.h
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "RESideMenu.h"

@interface MapViewController : UIViewController<MKMapViewDelegate, NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSFetchedResultsController *userResultsController;
@property (strong, nonatomic) NSFetchedResultsController *observationResultsController;

@end
