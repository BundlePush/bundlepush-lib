@interface BundlepushNative : NSObject

+ (NSURL *)latestBundle;

+ (void)performOTACheck:(NSString *)appId;

@end
