//
//  ViewController.m
//  trilaterationDemo
//
//  Created by Daniel Lockman on 12/19/13.
//  Copyright (c) 2013 Daniel Lockman. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/NSJSONSerialization.h>

@interface ViewController () <CLLocationManagerDelegate, NSURLConnectionDelegate>

@property (nonatomic) CLBeaconRegion *beaconRegion;
@property (nonatomic) CLLocationManager *locationManager;
@property NSURL *serverUrl;
@property NSMutableData *responseData;
@property (nonatomic, strong) IBOutlet UILabel* coordinatesLabel;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	NSLog(@"Booting Up....");
    [self setupBeaconTracking];
}

- (void)setupBeaconTracking {
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
    self.serverUrl = [NSURL URLWithString:@"http://192.168.1.6:9000"];
	
	NSUUID *uuid = [[NSUUID alloc] initWithUUIDString: @"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
	self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID: uuid identifier: @"thoughtWorksNRF"];
    [self.locationManager startMonitoringForRegion: self.beaconRegion];
    [self.locationManager startRangingBeaconsInRegion: self.beaconRegion];

    NSLog(@"Configuration Complete");
}



//Beacon Events, manage overall tracking on/off
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
	NSLog(@"Entered region");
	[self.locationManager startRangingBeaconsInRegion: self.beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
	NSLog(@"Exited region");
	[self.locationManager stopRangingBeaconsInRegion: self.beaconRegion];
    
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    
    NSMutableArray *distances = [[NSMutableArray alloc] initWithCapacity:3];
    NSMutableArray *identifiers = [[NSMutableArray alloc] initWithCapacity:3];
    NSError* error;
    
    
    for (int i = 0;i<3;i++)
    {
        CLBeacon *beacon = beacons[i];
        [distances addObject:[NSNumber numberWithFloat:beacon.accuracy]];
        [identifiers addObject:[NSString stringWithFormat: @"%@%@%@", beacon.proximityUUID.UUIDString, beacon.major, beacon.minor]];
    }
    
    //build an info object and convert to json
    NSDictionary* messageData = [NSDictionary dictionaryWithObjectsAndKeys:distances, @"distances", identifiers, @"identifiers", nil];
    
    //convert object to data
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:messageData options:NSJSONWritingPrettyPrinted error:&error];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:self.serverUrl];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:jsonData];
    
    // print json:
    NSLog(@"JSON summary: %@", [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding]);
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
    
    
	CLBeacon *lastBeacon = (CLBeacon *)[beacons lastObject];
	
	NSLog(@"found %i beacons. Last one: %@", [beacons count], lastBeacon);
	
	NSString *howClose;
    if (lastBeacon.proximity == CLProximityUnknown) {
        howClose = @"Unknown Proximity";
    } else if (lastBeacon.proximity == CLProximityImmediate) {
        howClose = @"Immediate";
    } else if (lastBeacon.proximity == CLProximityNear) {
        howClose = @"Near";
    } else if (lastBeacon.proximity == CLProximityFar) {
        howClose = @"Far";
    }
	
    NSLog(@"Beacon: %@ -\n  major: %@, minor: %@\n  accuracy: %f\n  rssi: %i\n howClose? %@", lastBeacon.proximityUUID.UUIDString,
		  lastBeacon.major, lastBeacon.minor, lastBeacon.accuracy, lastBeacon.rssi, howClose);
}


#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:self.responseData //1
                          
                          options:kNilOptions
                          error:&error];
    
    NSArray* pointEstimate = [json objectForKey:@"point_estimate"]; //2
    
    NSString* coordinatesString = [NSString stringWithFormat: @"X: \n %@ Y: %@ \n Z: %@", pointEstimate[0], pointEstimate[1], pointEstimate[2]];
    self.coordinatesLabel.text = coordinatesString;
    
    NSLog(@"Point Estimate: %@", pointEstimate); //3
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Connection to server failed!");
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
