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

+ (NSString *)getBuildNumber
{
  NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
  return bundleVersion;
}


+ (NSURL *)workdir
{
  NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  NSString *buildNumber = [self getBuildNumber];
  return [[NSURL fileURLWithPath:documentsPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"bp_workdir/%@", buildNumber]
                                                                isDirectory:YES];
}

+ (void)requestBundleForAppId:(NSString *)appId
        withCompletionHandler:(void (^)(NSString *md5, NSURL *bundleURL))completionHandler
{
  NSString *urlString = [NSString stringWithFormat:@"https://y83x5afgd2.api.quickmocker.com/bundle?platform=ios&id=%@&version_code=%@", appId, [self getBuildNumber]];
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLSession *session = [NSURLSession sharedSession];
  
  NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url
                                          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
      NSLog(@"Error: %@", error.localizedDescription);
      return;
    }

    if (data) {
      NSError *jsonError;
      NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
      if (jsonError) {
        NSLog(@"JSON Parsing Error: %@", jsonError.localizedDescription);
      } else {
        NSString *md5 = [json objectForKey:@"md5"];
        NSString *bundle = [json objectForKey:@"url"];
        if (md5 && bundle) {
          completionHandler(md5, [NSURL URLWithString:bundle]);
        } else {
          NSLog(@"No bundle updates available");
        }
      }
    }
  }];
  
  [dataTask resume];
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

+ (void)performOTACheck:(NSString *)appId
{
  // Check if there's an extracted bundle available (bp_workdir/<version_code>/current_bundle) *
  //   Use it as bundle (bp_workdir/<version_code>/current_bundle/main.jsbundle) *
  //   Otherwise, use the default bundle from app *
  // Async:
  //   Perform API call to check for the latest bundle *
  //   If available: *
  //     Check if md5 matches bp_workdir/<version_code>/current.zip (PENDING)
  //     If doesn't match, stop flow. Otherwise continue (PENDING)
  //     Download the new bundle to bp_workdir/<version_code>/downloaded.zip *
  //     Check if md5 matches - if so (PENDING)
  //       Extract it to bp_workdir/<version_code>/current_bundle *
  //       Rename it to bp_workdir/<version_code>/current.zip *
  
  // TODO standardize logs

  BOOL available = [self checkBundleFolderAvailable];
  if (!available) {
    return;
  }
  
  [self requestBundleForAppId:@"app-id"
        withCompletionHandler:^(NSString *md5, NSURL *bundleURL) {
    NSURL *currentZip = [[self workdir] URLByAppendingPathComponent:@"current.zip"];
    NSString *currentZipMD5 = MD5HashOfFile([currentZip path]);
    
    if ([currentZipMD5 isEqualToString:md5]) {
      NSLog(@"Current bundle is up to date with the server (md5 = %@)", md5);
      return;
    }
    
    // Download the new bundle to bp_workdir/<version_code>/downloaded.zip
    NSURL *downloadedZip = [[self workdir] URLByAppendingPathComponent:@"downloaded.zip"];
    NSLog(@"File will be downloaded to %@", downloadedZip);
    [self downloadFileFromURL:bundleURL
                toDestination:downloadedZip
            completionHandler:^() {
      NSString *downloadMd5 = MD5HashOfFile([downloadedZip path]);
      NSLog(@"Downloaded file md5 = %@ - expected is: %@", downloadMd5, md5);
      // TODO Add if to check if hashes match
      NSURL *extractPath = [[self workdir] URLByAppendingPathComponent:@"current_bundle" isDirectory:YES];
      [[NSFileManager defaultManager] removeItemAtURL:extractPath error:nil];
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
      
      [[NSFileManager defaultManager] removeItemAtURL:currentZip error:nil];
      [[NSFileManager defaultManager] moveItemAtURL:downloadedZip
                                              toURL:currentZip
                                              error:nil];
    }];
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
