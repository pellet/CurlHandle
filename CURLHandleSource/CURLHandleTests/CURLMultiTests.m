//
//  CURLMultiTests.m
//
//  Created by Sam Deane on 20/09/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "CURLMulti.h"
#import "CURLHandleBasedTest.h"

#import "NSURLRequest+CURLHandle.h"
#import "KMSServer.h"

@interface CURLMultiTests : CURLHandleBasedTest

@end

@implementation CURLMultiTests

- (void)testStartupShutdown
{
    CURLMulti* multi = [[CURLMulti alloc] init];

    [multi startup];

    [multi shutdown];

    [multi release];
}

- (void)testHTTPDownload
{
    CURLMulti* multi = [[CURLMulti alloc] init];

    [multi startup];

    NSURLRequest* request = [NSURLRequest requestWithURL:[self testFileRemoteURL]];
    CURLHandle* handle = [[CURLHandle alloc] initWithRequest:request credential:nil delegate:self multi:multi];

    [self runUntilPaused];

    [self checkDownloadedBufferWasCorrect];

    [handle release];

    [multi shutdown];

    [multi release];

}

- (void)testFTPDownload
{
    CURLMulti* multi = [[CURLMulti alloc] init];

    [multi startup];
    
    NSURL* ftpRoot = [self ftpTestServer];
    if (ftpRoot)
    {
        NSURL* ftpDownload = [[ftpRoot URLByAppendingPathComponent:@"CURLHandleTests"] URLByAppendingPathComponent:@"TestContent.txt"];

        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:ftpDownload];
        CURLHandle* handle = [[CURLHandle alloc] initWithRequest:request credential:nil delegate:self multi:multi];

        [self runUntilPaused];

        [self checkDownloadedBufferWasCorrect];
        
        [handle release];
    }

    [multi shutdown];

    [multi release];
}

- (void)testFTPUpload
{
    CURLMulti* multi = [[CURLMulti alloc] init];

    [multi startup];
    
    NSURL* ftpRoot = [self ftpTestServer];
    if (ftpRoot)
    {
        NSURL* ftpUpload = [[ftpRoot URLByAppendingPathComponent:@"CURLHandleTests"] URLByAppendingPathComponent:@"Upload.txt"];

        NSError* error = nil;
        NSURL* devNotesURL = [self testFileURL];
        NSString* devNotes = [NSString stringWithContentsOfURL:devNotesURL encoding:NSUTF8StringEncoding error:&error];

        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:ftpUpload];
        request.shouldUseCurlHandle = YES;
        [request curl_setCreateIntermediateDirectories:1];
        [request setHTTPBody:[devNotes dataUsingEncoding:NSUTF8StringEncoding]];
        CURLHandle* handle = [[CURLHandle alloc] initWithRequest:request credential:nil delegate:self multi:multi];

        [self runUntilPaused];

        STAssertTrue(self.sending, @"should have set sending flag");
        STAssertNil(self.error, @"got error %@", self.error);
        STAssertNotNil(self.response, @"expected response");
        STAssertTrue([self.buffer length] == 0, @"got unexpected data %@", self.buffer);
        
        [handle release];
    }

    [multi shutdown];

    [multi release];

}

- (void)testCancelling
{
    CURLMulti* multi = [[CURLMulti alloc] init];

    [multi startup];

    NSURLRequest* request = [NSURLRequest requestWithURL:[self testFileRemoteURL]];
    CURLHandle* handle = [[CURLHandle alloc] initWithRequest:request credential:nil delegate:self multi:multi];

    [handle cancel];

    STAssertTrue([handle isCancelled], @"should have been cancelled");

    [handle release];

    [multi shutdown];
    
    [multi release];

}

@end
