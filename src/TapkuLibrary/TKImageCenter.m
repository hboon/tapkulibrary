//
//  TKImageCenter.m
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


#import <CommonCrypto/CommonDigest.h>

#import "TKImageCenter.h"
#import "NSArray+TKCategory.h"

static NSString* kDefaultDirectoryName = @"TKImageCenter";


@interface TKPersistentCache()

- (void)createCachePathWithDirectoryName:(NSString*)aString;
- (BOOL)hasKeyExpired:(NSString*)aString;

@end


@implementation TKPersistentCache

@synthesize cachePath;
@synthesize cachedTimes;
@synthesize expiryEnabled;

- (id)initWithCacheDirectoryName:(NSString*)aString {
	if (self = [super init]) {
		[self createCachePathWithDirectoryName:aString];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCachedTimesToFile) name:UIApplicationDidEnterBackgroundNotification object:nil];
		
	}

	return self;
}


- (id)init {
	return [self initWithCacheDirectoryName:kDefaultDirectoryName];
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[cachePath release];
	[cachedTimes release];

	[super dealloc];
}


// Courtesy of Three20's TTURLCache.m
- (NSString*)keyFromString:(NSString*)aString {
	const char* str = [aString UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(str, strlen(str), result);

	return [NSString stringWithFormat:
		@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
		result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
			];
}


- (NSString*)cachePathForKey:(NSString*)aString {
	return [self.cachePath stringByAppendingPathComponent:[self keyFromString:aString]];
}


- (void)createCachePathWithDirectoryName:(NSString*)aString {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString* parentDirectoryPath = [paths objectAtIndex:0];
	self.cachePath = [parentDirectoryPath stringByAppendingPathComponent:aString];
	NSFileManager* fileManager = [NSFileManager defaultManager];

	if (![fileManager fileExistsAtPath:parentDirectoryPath]) {
	[fileManager createDirectoryAtPath:parentDirectoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	if (![fileManager fileExistsAtPath:self.cachePath]) {
	[fileManager createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:NULL];
	}
}


- (NSString*)cachedTimesPath {
	return [self.cachePath stringByAppendingPathComponent:@"cachedTimes"];
}


- (void)writeCachedTimesToFile {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[cachedTimes writeToFile:[self cachedTimesPath] atomically:YES];
	});
}

#pragma mark Cache access

- (void)setData:(NSData*)aData forKey:(NSString*)aString {
	NSString* filePath = [self cachePathForKey:aString];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	[fileManager createFileAtPath:filePath contents:aData attributes:nil];
	[self.cachedTimes setObject:[NSDate date] forKey:aString];
}


- (NSData*)dataForKey:(NSString*)aString {
	NSString* filePath = [self cachePathForKey:aString];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:filePath]) return nil;

	return [NSData dataWithContentsOfFile:filePath];
}

#pragma mark Cache expiry

- (NSMutableDictionary*)cachedTimes {
	if (!expiryEnabled || cachedTimes) return cachedTimes;
	
	cachedTimes = [[NSMutableDictionary alloc] initWithContentsOfFile:[self cachedTimesPath]];
	
	if (!cachedTimes) cachedTimes = [[NSMutableDictionary alloc] init];
	
	return cachedTimes;
}


- (int)expiryThreshold {
	//2 days
	return 172800;
}


- (BOOL)hasKeyExpired:(NSString*)aString {
	NSDate* date = [self.cachedTimes objectForKey:aString];
	return !date || -[date timeIntervalSinceNow] > [self expiryThreshold];
}

@end


@interface ImageLoadOperation : NSOperation {
    NSString *imageURL;
	TKImageCenter *imageCenter;
}

@property(copy) NSString *imageURL;
@property(assign) TKImageCenter *imageCenter;

- (id)initWithImageURLString:(NSString*)imageURL;

@end
@implementation ImageLoadOperation
@synthesize imageURL,imageCenter;

- (id) initWithImageURLString:(NSString*)url{
    if (!(self=[super init])) return nil;
    self.imageURL = url;
    return self;
}

- (void) dealloc {
    self.imageURL = nil;
    [super dealloc];
}

- (void) main {
	
	UIImage *img = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[imageCenter adjustURL:self.imageURL]]]];
	if(img!=nil){
		
		
		if ([imageCenter respondsToSelector:@selector(adjustImageRecieved:)]) {
			img = [imageCenter performSelector:@selector(adjustImageRecieved:) withObject:img];
		} else {
			img = [imageCenter adjustImageReceived:img];
		}
		
		if(img!=nil){
			[imageCenter performSelectorOnMainThread:@selector(sendNewImageNotification:) 
										  withObject:[NSArray arrayWithObjects:img,self.imageURL,nil] 
									   waitUntilDone:YES];
		}
		

		
	}
	
}

@end


@interface TKImageCenter()

- (NSString*)cacheDirectoryName;

@end


@implementation TKImageCenter
@synthesize queue,images,persistentCachingEnabled,expiryEnabled,persistentCache;

+ (TKImageCenter*) sharedImageCenter{
	static TKImageCenter *sharedInstance = nil;
	if (!sharedInstance) {
		sharedInstance = [[[self class] alloc] init];
	}
	return sharedInstance;
}
- (id) init{
	if(!(self=[super init])) return nil;
	queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:3];
	images = [[NSMutableDictionary alloc] init];
	return self;
}


- (UIImage*) imageAtURL:(NSString*)imageURL queueIfNeeded:(BOOL)addToQueue{
	if ([imageURL length] == 0) return nil;
	
	UIImage *img = [images objectForKey:imageURL];
	if(img != nil) return img;

	if (persistentCachingEnabled) {
		NSData* data = [self.persistentCache dataForKey:imageURL];
		if (data && (img = [UIImage imageWithData:data])) {
			if (!expiryEnabled) return img;
			if (![self.persistentCache hasKeyExpired:imageURL]) return img;
		}
	}
	
	BOOL addOperation = addToQueue ? YES : NO;
	
	if(addOperation){
		
		for(ImageLoadOperation *op in [queue operations]){
			if([op.imageURL isEqualToString:imageURL]){
				addOperation = NO;
				break;
			}
		}
		
		if(addOperation){
			ImageLoadOperation *op = [[ImageLoadOperation alloc] initWithImageURLString:imageURL];
			op.imageCenter = self;
			[queue addOperation:op];
			[op release];
		}
		
	}
	
	
	
	return img;
	
}



- (UIImage*) adjustImageReceived:(UIImage*)image{
	return image;
}


- (NSString*) adjustURL:(NSString*)aString{
	return aString;
}

- (void) sendNewImageNotification:(NSArray*)ar{
	[images setObject:[ar firstObject] forKey:[ar lastObject]];

	if (persistentCachingEnabled) {
		[self.persistentCache setData:UIImagePNGRepresentation([ar firstObject]) forKey:[ar lastObject]];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:NewImageCenterImage object:self];
}






- (void) clearImages{
	[queue cancelAllOperations];
	[images removeAllObjects];
}
- (void) dealloc{
	[queue release];
	[images release];
	[persistentCache release];
	[super dealloc];
}

#pragma mark Accessor

- (void)setPersistentCachingEnabled:(BOOL)yesOrNo {
	BOOL cachingPreviouslyEnabled = self.persistentCachingEnabled;
	persistentCachingEnabled = yesOrNo;

	if (!persistentCachingEnabled) {
		self.persistentCache = nil;
		return;
	}

	if (persistentCachingEnabled && !cachingPreviouslyEnabled) {
		self.persistentCache = [[[TKPersistentCache alloc] initWithCacheDirectoryName:[self cacheDirectoryName]] autorelease];
	}
}


- (NSString*)cacheDirectoryName {
	return [NSString stringWithUTF8String:object_getClassName(self)];
}


- (void)setExpiryEnabled:(BOOL)yesOrNo {
	expiryEnabled = yesOrNo;
	self.persistentCache.expiryEnabled = yesOrNo;
}
	 
@end
