# BundlePush: Using Objective-C

Below are the steps to integrate BundlePush in an Objective-C environment.

---

## 1. Add the import directive

In your AppDelegate, import the BundlePush native header:

```objc
#import "BundlepushNative.h"
```

---

## 2. Add a snippet of code to perform the update

Inside your `AppDelegate.m` or `AppDelegate.mm`, locate the method:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Your existing code...

    // Initialize BundlePush with your App ID
    [BundlepushNative setupWithAppID:@"YOUR_APP_ID"];

    return YES;
}
```

> Replace `"YOUR_APP_ID"` with the one from [BundlePush Dashboard](https://dash.bundlepu.sh).

---

## 3. Add a snippet of code to use the latest bundle

Inside the `- (NSURL *)getBundleURL` or `- (NSURL *)bundleURL`, add the following snippet:

```objc
- (NSURL *)getBundleURL {
    // Any custom logic
    return [BundlepushNative bundleURL];
}
```
