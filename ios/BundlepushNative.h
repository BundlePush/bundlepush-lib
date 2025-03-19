@interface BundlepushNative : NSObject

+ (NSURL *)latestBundleURL;

+ (void)checkForUpdates:(NSString *)appId;
+ (void)checkForUpdates:(NSString *)appId withDevMode:(BOOL)devMode;

@end
