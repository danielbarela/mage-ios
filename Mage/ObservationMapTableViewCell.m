//
//  ObservationMapTableViewCell.m
//  MAGE
//
//

#import "ObservationMapTableViewCell.h"
#import "Observations.h"
#import "ObservationDataStore.h"
#import "MapDelegate.h"

@interface ObservationMapTableViewCell ()
@property (nonatomic, strong) ObservationDataStore *observationDataStore;
@property (strong, nonatomic) MapDelegate *mapDelegate;
@end

@implementation ObservationMapTableViewCell

- (void) configureCellForObservation: (Observation *) observation {
    Observations *observations = [Observations observationsForObservation:observation];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    self.mapDelegate = [[MapDelegate alloc] init];
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    
    [self.mapDelegate setObservations:observations];
    self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
    [self.mapDelegate selectedObservation:observation];
    self.mapDelegate.hideStaticLayers = YES;
    
    MapObservation *mapObservation = [self.mapDelegate.mapObservations observationOfId:observation.objectID];
    
    MKCoordinateRegion viewRegion = [mapObservation viewRegionOfMapView:self.mapView];
    [self.mapDelegate selectedObservation:observation region:viewRegion];
}

@end
