//
//  CURLProtocol.m
//  CURLHandle
//
//  Created by Mike Abdullah on 19/01/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "CURLProtocol.h"

@interface CURLProtocol()

@property BOOL isResponseSent;

@end

@implementation CURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
{
    return [request shouldUseCurlHandle];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request; { return request; }

- (void)startLoading;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CURLHandle *handle = [[CURLHandle alloc] init];
        [handle setDelegate:self];
        
        // Turn automatic redirects off by default, so can properly report them to delegate
        curl_easy_setopt([handle curl], CURLOPT_FOLLOWLOCATION, NO);
        
        NSError *error;
        if ([handle loadRequest:[self request] error:&error])
        {
            assert(self.isResponseSent);
            [[self client] URLProtocolDidFinishLoading:self];
        }
        else
        {
            [[self client] URLProtocol:self didFailWithError:error];
        }
        
        [handle release];
    });
}

- (void)stopLoading;
{
    // TODO: Instruct handle to cancel
}

- (void)handle:(CURLHandle *)handle didReceiveResponse:(NSURLResponse *)response;
{
    self.isResponseSent=YES;
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)handle:(CURLHandle *)handle didReceiveData:(NSData *)data;
{
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)handle:(CURLHandle *)handle willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    self.isResponseSent=YES;
    [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
}

@end


@implementation NSURLRequest (CURLProtocol)

- (BOOL)shouldUseCurlHandle;
{
    return [[NSURLProtocol propertyForKey:@"useCurlHandle" inRequest:self] boolValue];
}

@end


@implementation NSMutableURLRequest (CURLProtocol)

- (void)setShouldUseCurlHandle:(BOOL)useCurl;
{
    [NSURLProtocol setProperty:[NSNumber numberWithBool:useCurl] forKey:@"useCurlHandle" inRequest:self];
    [NSURLProtocol registerClass:[CURLProtocol class]];
}

@end





