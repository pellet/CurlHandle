//
//  CURLHandleHTTPTest.m
//  CURLHandleTester
//
//  Created by eggers on 21/02/13.
//
//

#import "CURLHandleHTTPTest.h"
#import <CURLHandle/CURLProtocol.h>
#import <CommonCrypto/CommonDigest.h>


#pragma mark - Private Interface
@interface CURLHandleHTTPTest()

#pragma Constants
@property (retain, readonly) NSString *TestWorkspace;
@property (retain, readonly) NSString *CURLHandleDestinationDirectory;
@property (retain, readonly) NSString *VanillaConnectionDestinationDirectory;

#pragma Accessors
@property BOOL isFinished;
@property (retain) NSError *error;

@property (retain) NSString *curlHandleDestinationPath;
@property (retain) NSString *vanillaConnectionDestinationPath;

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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:source];
    
    self.curlHandleDestinationPath = [self.CURLHandleDestinationDirectory stringByAppendingPathComponent:[filename stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    [request setShouldUseCurlHandle:YES];
    [self getFileFromSiteWithNSURLConnection:request destination:self.curlHandleDestinationPath];
    
    GHAssertNil(self.error, @"Error occured whilst running the CURLHandle NSURLConnection: %@",self.error.description);
    
    self.vanillaConnectionDestinationPath = [self.VanillaConnectionDestinationDirectory stringByAppendingPathComponent:[filename stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    [request setShouldUseCurlHandle:NO];
    [self getFileFromSiteWithNSURLConnection:request destination:self.vanillaConnectionDestinationPath];
    
    GHAssertNil(self.error, @"Error occured whilst running the vanilla NSURLConnection: %@",self.error.description);
    
    NSString *curlDestChecksum = [self getMD5FromFile:self.curlHandleDestinationPath];
    NSString *vanillaDestChecksum = [self getMD5FromFile:self.vanillaConnectionDestinationPath];
    GHAssertEqualStrings(vanillaDestChecksum, curlDestChecksum, @"The md5 checksum of the curl destination file does not match the vanilla destination file.");
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
    self.isFinished=NO;
    self.error=nil;
    [request start];//just to remove warning about it being unused... :/
    while (NO==self.isFinished && nil==self.error) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:SECONDS_WAIT_FOR_CONNECTION_TO_COMPLETE]];
	}
    [self.output close];
}

- (NSString *)getMD5FromFile:(NSString *)pathToFile {
    unsigned char outputData[CC_MD5_DIGEST_LENGTH];
	
    NSData *inputData = [[NSData alloc] initWithContentsOfFile:pathToFile];
    CC_MD5([inputData bytes], (CC_LONG)[inputData length], outputData);
    [inputData release];
	
    NSMutableString *hash = [[NSMutableString new] autorelease];
	{
    NSUInteger i = 0;
    for (; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", outputData[i]];
    }
	}
	
    return hash;
}

- (void)setUp
{
    NSError *error;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _TestWorkspace = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"CURLHandleTests"];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.TestWorkspace withIntermediateDirectories:NO attributes:nil error:&error];
    
    _CURLHandleDestinationDirectory = [self.TestWorkspace stringByAppendingPathComponent:@"CURLHandle_Destination"];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.CURLHandleDestinationDirectory withIntermediateDirectories:NO attributes:nil error:&error];
    
    _VanillaConnectionDestinationDirectory = [self.TestWorkspace stringByAppendingPathComponent:@"NSURLConnection_Destination"];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.VanillaConnectionDestinationDirectory withIntermediateDirectories:NO attributes:nil error:&error];
}

- (void)tearDown
{
    NSError *removeError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.curlHandleDestinationPath error:&removeError];
    [[NSFileManager defaultManager] removeItemAtPath:self.CURLHandleDestinationDirectory error:&removeError];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.vanillaConnectionDestinationPath error:&removeError];
    [[NSFileManager defaultManager] removeItemAtPath:self.VanillaConnectionDestinationDirectory error:&removeError];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.TestWorkspace error:&removeError];
}

@end
