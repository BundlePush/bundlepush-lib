#import "BundlepushNative.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <SSZipArchive/SSZipArchive.h>


@implementation BundlepushNative

NSString *MD5HashOfFile(NSString *filePath) {
  NSError *error;
  NSData *fileData = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
  if (!fileData) {
    NSLog(@"Failed to read file at path: %@", filePath);
    NSLog(@"%@", error);
    return nil;
  }
  
  unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
  CC_MD5(fileData.bytes, (CC_LONG)fileData.length, md5Buffer);
  
  NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
      [md5String appendFormat:@"%02x", md5Buffer[i]];
  }
  
  return [md5String copy];
}

+ (NSURL *)workdir
{
  NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  return [[NSURL fileURLWithPath:documentsPath] URLByAppendingPathComponent:@"bp_workdir"
                                                                isDirectory:YES];
}

+ (void)downloadFileFromURL:(NSURL *)url
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
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL
                                              error:nil];
    
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
  [downloadTask resume];
}

+ (BOOL)checkBundleFolderAvailable
{
  BOOL isDirectory;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[[[self class] workdir] absoluteString]
                                                     isDirectory:&isDirectory];
  if (exists) {
    return isDirectory;
  }
  NSError *error = nil;
  BOOL result = [[NSFileManager defaultManager] createDirectoryAtURL:[[self class] workdir]
                                         withIntermediateDirectories:YES
                                                          attributes:nil
                                                               error:&error];
  if (!result) {
    NSLog(@"Error creating folder - %@", error);
  }
  return result;
}

+ (void)performOTACheck
{
  // Check if there's an extracted bundle available (bp_workdir/<version_code>/current_bundle) (PENDING)
  //   Use it as bundle (bp_workdir/<version_code>/current_bundle/main.jsbundle) (PENDING)
  //   Otherwise, use the default bundle from app (PENDING)
  // Async:
  //   Perform API call to check for the latest bundle (PENDING)
  //   If available:
  //     Check if md5 matches bp_workdir/<version_code>/current.zip (PENDING)
  //     If doesn't match, stop flow. Otherwise continue (PENDING)
  //     Download the new bundle to bp_workdir/<version_code>/downloaded.zip *
  //     Check if md5 matches - if so (PENDING)
  //       Extract it to bp_workdir/<version_code>/current_bundle *
  //       Rename it to bp_workdir/<version_code>/current.zip *
  
  // TODO add <version_code> to path, here and in latestBundle
  // TODO standardize logs

  BOOL available = [self checkBundleFolderAvailable];
  if (!available) {
    return;
  }
  
  // Download the new bundle to bp_workdir/downloaded.zip
  NSURL *downloadedZip = [[[self class] workdir] URLByAppendingPathComponent:@"downloaded.zip"];
  NSURL *downloadURL = [NSURL URLWithString:@"https://iuri.s3.us-east-1.amazonaws.com/bundle.zip"];
  NSLog(@"File will be downloaded to %@", downloadedZip);
  [self downloadFileFromURL:downloadURL
              toDestination:downloadedZip
          completionHandler:^() {
    NSString *md5 = MD5HashOfFile([downloadedZip path]);
    NSLog(@"Downloaded file md5 = %@", md5);
    // TODO Add if to check if hashes match
    // TODO before extracting, remove the current_bundle directory
    NSURL *extractPath = [[[self class] workdir] URLByAppendingPathComponent:@"current_bundle" isDirectory:YES];
    NSError *zipError = nil;
    BOOL successUnzip = [SSZipArchive unzipFileAtPath:[downloadedZip path]
                                        toDestination:[extractPath path]
                                            overwrite:YES
                                             password:nil
                                                error:&zipError];
    if (!successUnzip) {
      NSLog(@"Error unzipping - %@", zipError);
      return;
    }
    
    NSURL *currentZip = [[[self class] workdir] URLByAppendingPathComponent:@"current.zip"];
    [[NSFileManager defaultManager] moveItemAtURL:downloadedZip
                                            toURL:currentZip
                                            error:nil];
  }];
}

+ (NSURL *)latestBundle
{
  NSURL *bundleUrl = [[self workdir] URLByAppendingPathComponent:@"current_bundle/main.jsbundle"];
  BOOL isDirectory;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[bundleUrl path]
                                                     isDirectory:&isDirectory];
  NSLog(@"Latest bundle: %@", bundleUrl);
  if (exists && !isDirectory) {
    return bundleUrl;
  } else {
    return nil;
  }
}

@end
