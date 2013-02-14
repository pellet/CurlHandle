//
//  CURLProtocolTests.m
//
//  Created by Sam Deane on 20/09/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "NSURLRequest+CURLHandle.h"

#import "CURLHandleBasedTest.h"

@interface CURLProtocolTests : CURLHandleBasedTest<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@end

@implementation CURLProtocolTests

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"failed with error %@", error);

    self.error = error;
    [self pause];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"got response %@", response);

    self.response = response;
    self.buffer = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)dataIn
{
    NSLog(@"got data %ld bytes", [dataIn length]);

    [self.buffer appendData:dataIn];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"finished");

    [self pause];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
{
    self.sending = YES;
}

- (void)testHTTPDownload
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[self testFileRemoteURL]];
    request.shouldUseCurlHandle = YES;

    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    STAssertNotNil(connection, @"failed to get connection for request %@", request);

    [self runUntilPaused];

    [self checkDownloadedBufferWasCorrect];
}

- (void)testCancelling
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[self testFileRemoteURL]];
    request.shouldUseCurlHandle = YES;

    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    STAssertNotNil(connection, @"failed to get connection for request %@", request);

    [connection cancel];

    // we don't get any delegate message to say that we've been cancelled, so we just have to finish
    // the test here without checking anything else
}

- (void)testFTPDownload
{
    NSURL* ftpRoot = [self ftpTestServer];
    if (ftpRoot)
    {
        NSURL* ftpDownload = [[ftpRoot URLByAppendingPathComponent:@"CURLHandleTests"] URLByAppendingPathComponent:@"TestContent.txt"];

        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:ftpDownload];
        request.shouldUseCurlHandle = YES;

        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
        STAssertNotNil(connection, @"failed to get connection for request %@", request);

        [self runUntilPaused];
        
        [self checkDownloadedBufferWasCorrect];
    }
}

- (void)testFTPUpload
{
    NSURL* ftpRoot = [self ftpTestServer];
    if (ftpRoot)
    {
        NSURL* ftpUpload = [[ftpRoot URLByAppendingPathComponent:@"CURLHandleTests"] URLByAppendingPathComponent:@"Upload.txt"];

        NSError* error = nil;
        NSURL* testNotesURL = [self testFileURL];
        NSString* testNotes = [NSString stringWithContentsOfURL:testNotesURL encoding:NSUTF8StringEncoding error:&error];

        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:ftpUpload];
        request.shouldUseCurlHandle = YES;
        [request curl_setCreateIntermediateDirectories:1];
        [request setHTTPBody:[testNotes dataUsingEncoding:NSUTF8StringEncoding]];

        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
        STAssertNotNil(connection, @"failed to get connection for request %@", request);

        [self runUntilPaused];

        NSHTTPURLResponse* response = (NSHTTPURLResponse*)self.response;
        STAssertTrue([response isMemberOfClass:[NSHTTPURLResponse class]], @"got response of class %@", [response class]);
        STAssertEquals([response statusCode], (NSInteger) 226, @"got unexpected code %ld", [response statusCode]);
        STAssertNil(self.error, @"got error %@", self.error);
        STAssertTrue([self.buffer length] == 0, @"got unexpected data %@", self.buffer);
    }
}

@end
