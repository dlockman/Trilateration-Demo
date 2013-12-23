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

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self setupBeaconTracking];
}

- (void)setupBeaconTracking {
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
    self.serverUrl = [NSURL URLWithString:@"http://google.com"];
	
	NSUUID *uuid = [[NSUUID alloc] initWithUUIDString: @"097300A0-A48D-4BEB-A65B-8EB815E51DD8"];
	self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID: uuid identifier: @"delta1"];
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
    NSDictionary *messageData = [NSDictionary dictionaryWithObjectsAndKeys:distances, @"distances", identifiers, @"identifiers"];
    
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



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
