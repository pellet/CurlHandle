//
//  CURLHandleHTTPTest.m
//  CURLHandleTester
//
//  Created by eggers on 21/02/13.
//
//

#import "CURLHandleHTTPTest.h"
#import <CURLHandle/CURLProtocol.h>


#pragma mark - Private Interface
@interface CURLHandleHTTPTest()

#pragma Constants
@property (retain, readonly) NSString *CURLHandleDestinationDirectory;
@property (retain, readonly) NSString *VanillaConnectionDestinationDirectory;

#pragma Accessors
@property BOOL isFinished;
@property (retain) NSError *error;

@property (retain) NSString *curlHandleDestinationPath;
@property (retain) NSString *vanillaConnectionDestinationPath;

@property (retain) NSURLConnection *connection;
@property (retain) NSOutputStream *output;

@end


#pragma mark - Implementation
@implementation CURLHandleHTTPTest

#pragma mark Constants
NSInteger const SECONDS_WAIT_FOR_CONNECTION_TO_COMPLETE = (NSInteger)0.25;

#pragma mark Tests
- (void)testBasicHTTPGet
{
    NSString *filename = @"Bear%20In%20Heaven%20-%20You%20Do%20You%20(Live%20on%20KEXP).mp4";
    NSURL *source = [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1/~%@/%@",NSUserName(),filename]];
    
    self.curlHandleDestinationPath = [self.CURLHandleDestinationDirectory stringByAppendingPathComponent:[filename stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    self.output = [NSOutputStream outputStreamToFileAtPath:self.curlHandleDestinationPath append:NO];
    [self.output open];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:source];
    [request setShouldUseCurlHandle:YES];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    while (NO==self.isFinished && NO==self.error) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:SECONDS_WAIT_FOR_CONNECTION_TO_COMPLETE]];
	}
    
    [self.output close];
    
    GHAssertNil(self.error, @"Error occured whilst running the CURLHandle NSURLConnection: %@",self.error.description);
    
    self.vanillaConnectionDestinationPath = [self.VanillaConnectionDestinationDirectory stringByAppendingPathComponent:[filename stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    [request setShouldUseCurlHandle:NO];
    [self getFileFromSiteWithNSURLConnection:request destination:self.vanillaConnectionDestinationPath];
}


#pragma mark NSURLConnection delegates

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.output write:data.bytes maxLength:data.length];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.isFinished=YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    self.error = error;
}

#pragma mark Misc

- (void)getFileFromSiteWithNSURLConnection:(NSURLRequest *)info destination:(NSString *)destination
{
    self.output = [NSOutputStream outputStreamToFileAtPath:destination append:NO];
    [self.output open];
    
    NSURLConnection *request = [[[NSURLConnection alloc] initWithRequest:info delegate:self] autorelease];
    [request start];//just to remove warning about it being unused... :/
    while (NO==self.isFinished || NO==self.error) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:SECONDS_WAIT_FOR_CONNECTION_TO_COMPLETE]];
	}
    GHAssertNil(self.error, @"Error occured whilst running the vanilla NSURLConnection: %@",self.error.description);
    
    [self.output close];
}

- (id)init
{
    self = [super init];
    
    if (nil!=self) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        const NSString *DOCUMENT_BASE = [paths objectAtIndex:0];
        
        _CURLHandle_Destination = [DOCUMENT_BASE stringByAppendingPathComponent:@"CURLHandleTests/CURLHandle_Destination"];
        
        _NSURLConnection_Destination = [DOCUMENT_BASE stringByAppendingPathComponent:@"CURLHandleTests/NSURLConnection_Destination"];
    }
    
    return self;
}

- (void)setUp
{
}

- (void)tearDown
{
    self.isFinished=NO;
    self.error=nil;
}

@end
