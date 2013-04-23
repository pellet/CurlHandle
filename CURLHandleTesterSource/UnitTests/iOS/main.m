//
//  main.m
//  Videohog-Tests-iOS
//
//  Created by eggers on 6/09/12.
//  Copyright (c) 2012 Digimulti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GHUnitIOS/GHUnit.h>

int main(int argc, char *argv[])
{
    @try {
        @autoreleasepool {
            return UIApplicationMain(argc, argv, nil, @"GHUnitIOSAppDelegate");
        }
        
    } @catch (NSException *exception) {
        NSLog(@"Unhandled exception occured:%@", exception.reason);
    }
}
