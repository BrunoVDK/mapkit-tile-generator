//
//  AppDelegate.m
//  map_generator
//
//  Created by Bruno Vandekerkhove on 09/05/18.
//  Copyright (c) 2018 Bruno Vandekerkhove. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "AppDelegate.h"

@interface AppDelegate ()
@property (strong) IBOutlet MKMapView *mapView;
@property (strong) IBOutlet NSWindow *window;
- (IBAction)snapShot:(id)sender;
@end

@implementation AppDelegate

- (void)awakeFromNib {
    self.satellite = [NSNumber numberWithInt:0];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 50.8792;
    zoomLocation.longitude= 4.7009;
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 2500, 2500);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:true];
    
    
    self.area = [NSNumber numberWithInt:2000];
    self.nbTiles = [NSNumber numberWithInt:24];
    
    [self.window makeKeyAndOrderFront:self];
    
}

- (void)setSatellite:(NSNumber *)satellite {
    
    [_satellite release];
    _satellite = [satellite retain];
    
    if ([satellite integerValue] > 0)
        [self.mapView setMapType:MKMapTypeSatellite];
    else
        [self.mapView setMapType:MKMapTypeStandard];
    
}

#define TILE_SIZE 256


NSInteger tileNb;
double areaNb;
double tileArea;
CLLocationCoordinate2D center;

- (IBAction)snapShot:(id)sender {
    
    // Vanaf center point van huidige region gewoon hele area opdelen in tiles van die grote en telkens saven
    
    
    
//    [snapshotter startWithCompletionHandler:^(MKMapSnapshot *s, NSError *e) {
//        NSImage *image = s.image;
//        NSBitmapImageRep *imgRep = [[image representations] objectAtIndex: 0];
//        NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];
//        NSString *name = @"/Users/Bruno/Desktop/test";
//        int i=0;
//        while ([[NSFileManager defaultManager] fileExistsAtPath:[name stringByAppendingPathExtension:@"png"]])
//            name = [NSString stringWithFormat:@"%@%i",name,i++];
//
//        [data writeToFile:[name stringByAppendingPathExtension:@"png"] atomically: NO];
//        NSLog(@"%@", e);
//    }];
    
    center = self.mapView.region.center;
    
    NSOpenPanel*    panel = [NSOpenPanel openPanel];
    
    [panel setNameFieldStringValue:@"europe_big"];
    [panel setCanCreateDirectories:true];
    [panel setCanChooseDirectories:true];
    [panel setCanChooseFiles:false];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        
        if (result == NSFileHandlingPanelOKButton)
            
        {
            
            NSURL*  directory = [panel URL];
            
            tileNb = [self.nbTiles integerValue];
            if (tileNb % 2 != 0)
                tileNb = 2;
            areaNb = [self.area doubleValue];
            tileArea = areaNb/tileNb;
            
            
            fullImage = [[NSImage alloc]
                                  initWithSize:NSMakeSize(tileNb*TILE_SIZE, tileNb *TILE_SIZE)];
            
            
            // Could shift so center point is considered but formulae are annoying
            
            tot = 0;
            
            [self recursiveGenerateSnapFori:0 andj:0 anddir:directory];
            
            
            
        }
        
    }];
    
    
   
}

- (void)recursiveGenerateSnapFori:(int)i andj:(int)j anddir:(NSURL *)directory {
    
    MKMapSnapshotOptions *options = [MKMapSnapshotOptions new];
    // options.region = self.mapView.region;
    options.size = NSMakeSize(TILE_SIZE,TILE_SIZE);
    options.mapType = self.mapView.mapType;
    
    MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(center, abs(areaNb/2-tileArea*j-tileArea/2), abs(areaNb/2-tileArea*i-tileArea/2));
    newRegion.center.latitude += (j < tileNb / 2 ? -newRegion.span.latitudeDelta : newRegion.span.latitudeDelta);
    newRegion.center.longitude += (i < tileNb / 2 ? -newRegion.span.longitudeDelta : newRegion.span.longitudeDelta);
    options.region = MKCoordinateRegionMakeWithDistance(newRegion.center, tileArea, tileArea);
    
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    NSLog(@"%i %i\n", i, j);
    
    BOOL separateTiles = (self.separateTiles.integerValue > 0);
    
    [snapshotter startWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
              completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
                  
                  if (error) {
                      NSLog(@"MKMapSnapshotter error: %@", error);
                      return ;
                  }
                  
                  dispatch_async(dispatch_get_main_queue(), ^ {
                      NSImage *image = snapshot.image;
                      
                      NSLog(@"%i %i \n", TILE_SIZE*i, TILE_SIZE*j);
                      
                      tot++;
                      
                      if (separateTiles) {
                          
                          NSData *data = [self PNGRepresentationOfImage:image];
                          NSString *name = [directory.path stringByAppendingPathComponent:@"tile"];
                          
                          [data writeToFile:[[NSString stringWithFormat:@"%@%i-%i",name,i,j] stringByAppendingPathExtension:@"png"] atomically: NO];
                          
                      }
                      else {
                          
                          [fullImage lockFocus];
                          [image compositeToPoint:NSMakePoint(TILE_SIZE*i, TILE_SIZE*j)
                                        operation:NSCompositeSourceOver];
                          [fullImage unlockFocus];
                          
                          if (tot == tileNb*tileNb) {
                              NSData *data = [self PNGRepresentationOfImage:fullImage];
                              NSString *name = [directory.path stringByAppendingPathComponent:@"big"];
                              int k=1;
                              while ([[NSFileManager defaultManager] fileExistsAtPath:[[NSString stringWithFormat:@"%@%i",name,k] stringByAppendingPathExtension:@"png"]])
                                  k++;
                              
                              [data writeToFile:[[NSString stringWithFormat:@"%@%i",name,k] stringByAppendingPathExtension:@"png"] atomically: NO];
                          }
                          
                      }
                      
                      int x = i;
                      int y = j+1;
                      if (y >= tileNb) {
                          y = 0;
                          x = i+1;
                      }
                      
                      if (tot != tileNb * tileNb)
                          [self recursiveGenerateSnapFori:x andj:y anddir:directory];
                      
                      
                      
                  });
              }];
    
    [snapshotter release];
    
}

- (NSData *) PNGRepresentationOfImage:(NSImage *) image {
    // Create a bitmap representation from the current image
    
    [image lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [image unlockFocus];
    
    NSData *data = [bitmapRep representationUsingType:NSPNGFileType properties:Nil];
    
    [bitmapRep release];
    
    return data;
}

@end
