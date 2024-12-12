#import "Bundlepush.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>


@implementation Bundlepush
RCT_EXPORT_MODULE()

NSString *MD5HashOfFile(NSString *filePath) {
    // Load the file data into memory
  NSError *error;
    NSData *fileData = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
    if (!fileData) {
        NSLog(@"Failed to read file at path: %@", filePath);
      NSLog(@"%@", error);
        return nil;
    }
    
    // Create the MD5 hash
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(fileData.bytes, (CC_LONG)fileData.length, md5Buffer);
    
    // Convert to a hexadecimal string
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", md5Buffer[i]];
    }
    
    return [md5String copy];
}

- (NSURL *)workdir
{
  return [[NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]] URLByAppendingPathComponent:@"bp_workdir"
                                                                                                                                                isDirectory:YES];
}

- (void)downloadFileFromURL:(NSURL *)url
              toDestination:(NSURL *)destinationURL
          completionHandler:(void (^)())completionHandler
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSLog(@"Starting download from: %@", [url absoluteString]);
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url
                                                        completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Download error: %@", error.localizedDescription);
            return;
        }
        NSError *fileError;
        [[NSFileManager defaultManager] moveItemAtURL:location
                                                toURL:destinationURL
                                                error:&fileError];
        if (fileError) {
          NSLog(@"File move error: %@", fileError.localizedDescription);
        } else {
          NSLog(@"File downloaded successfully to %@", destinationURL);
          completionHandler();
        }
    }];

    // Start the download task
    [downloadTask resume];
}

- (BOOL)checkBundleFolderAvailable
{
  BOOL isDirectory;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[[self workdir] absoluteString]
                                                     isDirectory:&isDirectory];
  if (exists) {
    return isDirectory;
  }
  NSError *error = nil;
  BOOL result = [[NSFileManager defaultManager] createDirectoryAtURL:[self workdir]
                                         withIntermediateDirectories:YES
                                                          attributes:nil
                                                               error:&error];
  if (!result) {
    NSLog(@"Error creating folder - %@", error);
  }
  return result;
}

- (void)performOTACheck
{
  // Check if there's a extracted bundle available (bp_workdir/current_bundle)
  //   Use it as bundle (bp_workdir/current_bundle/main.jsbundle)
  //   Otherwise, use the default bundle from app
  // Async:
  //   Perform API call to check for the latest bundle (PENDING)
  //   If available:
  //     Check if md5 matches bp_workdir/current.zip (PENDING)
  //     If matches, stop flow. Otherwise continue (PENDING)
  //     Download the new bundle to bp_workdir/downloaded.zip *
  //     Check if md5 matches - if so (PENDING)
  //       Extract it to bp_workdir/current_bundle (PENDING)
  //       Rename it to bp_workdir/current.zip *
  

  BOOL available = [self checkBundleFolderAvailable];
  if (!available) {
    return;
  }
  
  NSURL *downloadDestination = [[self workdir] URLByAppendingPathComponent:@"downloaded.zip"];
  NSURL *downloadURL = [NSURL URLWithString:@"https://iuri.s3.us-east-1.amazonaws.com/bundle.zip"];
  NSLog(@"File will be downloaded to %@", downloadDestination);
  [self downloadFileFromURL:downloadURL
              toDestination:downloadDestination
          completionHandler:^() {
    NSString *md5 = MD5HashOfFile([downloadDestination path]);
    NSLog(@"Downloaded file md5 = %@", md5);
    // TODO Add if to check if hashes match
    // TODO extract file
    NSURL *currentZip = [[self workdir] URLByAppendingPathComponent:@"current.zip"];
    [[NSFileManager defaultManager] moveItemAtURL:downloadDestination
                                            toURL:currentZip
                                            error:nil];
  }];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeBundlepushSpecJSI>(params);
}

@end
