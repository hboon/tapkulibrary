//
//  TKImageCenter.h
//  Created by Devin Ross on 4/12/10.
//
/*
 
 tapku.com || http://github.com/tapku/tapkulibrary/tree/master
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define NewImageCenterImage @"newImage"
#define FailedImageCenterImage @"failedImage"
#define NewImageCenterURLKey @"url"

@interface TKPersistentCache : NSObject {
	NSString* cachePath;
	NSMutableDictionary* cachedTimes;
	BOOL expiryEnabled;
}

@property (nonatomic,retain) NSString* cachePath;
@property (nonatomic,retain) NSMutableDictionary* cachedTimes;
@property (nonatomic,assign) BOOL expiryEnabled;

- (void)setData:(NSData*)aData forKey:(NSString*)aString;
- (NSData*)dataForKey:(NSString*)aString;

@end


@interface TKImageCenter : NSObject {

	NSOperationQueue *queue;
	NSCache *images;
	BOOL persistentCachingEnabled;
	BOOL expiryEnabled;
	TKPersistentCache* persistentCache;
	
}

+ (TKImageCenter*) sharedImageCenter;

@property (nonatomic,retain) NSOperationQueue *queue;
@property (nonatomic,retain) NSCache *images;
@property (nonatomic,assign) BOOL persistentCachingEnabled;
@property (nonatomic,assign) BOOL expiryEnabled;
@property (nonatomic,retain) TKPersistentCache* persistentCache;


- (void)deleteCache;
- (UIImage*) imageAtURL:(NSString*)imageURL queueIfNeeded:(BOOL)addToQueue priority:(NSOperationQueuePriority)aPriority;
- (UIImage*) imageAtURL:(NSString*)url queueIfNeeded:(BOOL)addToQueue;
- (void)addToCacheImage:(UIImage*)anImage atURL:(NSString*)aString;

- (UIImage*) adjustImageReceived:(UIImage*)image; // subclass to add cropping or manipulation
- (NSString*) adjustURL:(NSString*)aString;	// subclass to manipulate actual URL to fetch

- (void) clearImages;
- (void) clearImagesOnly;
- (void) clearImageAtURL:(NSString*)imageURL;

@end
