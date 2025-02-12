@interface BundlepushNative : NSObject

+ (NSURL *)latestBundleURL;

+ (void)checkForUpdates:(NSString *)appId;

@end
