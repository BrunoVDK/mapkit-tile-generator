//
//  AppDelegate.h
//  map_generator
//
//  Created by Bruno Vandekerkhove on 09/05/18.
//  Copyright (c) 2018 Bruno Vandekerkhove. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MapKit/MapKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, MKMapViewDelegate> {
    int tot;
    NSImage *fullImage;
}

@property (nonatomic, retain) NSNumber *area;
@property (nonatomic, retain) NSNumber *nbTiles;
@property (nonatomic, retain) NSNumber *satellite;
@property (nonatomic, retain) NSNumber *separateTiles;

@end

