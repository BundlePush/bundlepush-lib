#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <bundlepush/BundlepushNative.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"BundlepushExample";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};
  
  [BundlepushNative performOTACheck:@"app-id"];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self bundleURL];
}

- (NSURL *)bundleURL
{
  NSURL *latest = [BundlepushNative latestBundle];
  NSLog(@"latest: %@", latest);
  if (latest != nil) {
    NSLog(@"using latest: %@", latest);
    return latest;
  }
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
