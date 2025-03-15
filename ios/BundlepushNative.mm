#import "BundlepushNative.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <SSZipArchive/SSZipArchive.h>


@implementation BundlepushNative

NSString *MD5HashOfFile(NSString *filePath) {
  NSError *error;
  NSData *fileData = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
  if (!fileData) {
    BPLog(@"Failed to read file at path: %@", filePath);
    BPLog(@"%@", error);
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

void BPLog(NSString *format, ...) {
  va_list args;
  va_start(args, format);
  NSLog(@"[BundlePush] %@", [[NSString alloc] initWithFormat:format arguments:args]);
  va_end(args);
}

+ (NSString *)getBuildNumber
{
  NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
  return bundleVersion;
}

+ (NSString *)getAppVersion
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSURL *)workdir
{
  NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  NSString *buildNumber = [self getBuildNumber];
  return [[NSURL fileURLWithPath:documentsPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"bp_workdir/%@", buildNumber]
                                                                isDirectory:YES];
}

+ (void)requestBundleForAppId:(NSString *)appId
                  ignoreIfMd5:(NSString *)currentMd5
        withCompletionHandler:(void (^)(NSString *md5, NSURL *bundleURL))completionHandler
{
  NSString *metadataUrlString = [NSString
                         stringWithFormat:@"https://api.bundlepu.sh/public-bundle?platform=IOS&appId=%@&versionCode=%@&versionName=%@",
                         appId,
                         [self getBuildNumber],
                         [self getAppVersion]];
  NSURL *metadataUrl = [NSURL URLWithString:metadataUrlString];
  NSURLSession *session = [NSURLSession sharedSession];
  
  // TODO extract fetch function
  NSURLSessionDataTask *dataTask = [session dataTaskWithURL:metadataUrl
                                          completionHandler:^(NSData *metadata, NSURLResponse *metadataResponse, NSError *metadataError) {
    if (metadataError) {
      BPLog(@"Error: %@", metadataError.localizedDescription);
      return;
    }
    if (!metadata) {
      BPLog(@"Unexpected state - no error and no metadata returned");
      return;
    }

    NSError *metadataJsonError;
    NSDictionary *metadataJson = [NSJSONSerialization JSONObjectWithData:metadata options:0 error:&metadataJsonError];
    if (metadataJsonError) {
      BPLog(@"JSON Parsing Error: %@", metadataJsonError.localizedDescription);
      return;
    }
    NSString *md5 = [metadataJson objectForKey:@"md5"];
    NSString *bundleId = [metadataJson objectForKey:@"bundleId"];
    if (!md5 || !bundleId) {
      BPLog(@"No bundle updates available");
      return;
    }
    if ([currentMd5 isEqualToString:md5]) {
      BPLog(@"Current installed bundle is up to date with the server (md5 = %@)", md5);
      return;
    }
    
    // Everything is ready to download the new bundle
    NSString *downloadLinkUrlString = [NSString stringWithFormat:@"https://api.bundlepu.sh/public-bundle/download-url?appId=%@&bundleId=%@&md5=%@",
                           appId, bundleId, md5];
    NSURL *downloadLinkUrl = [NSURL URLWithString:downloadLinkUrlString];
    
    NSURLSessionDataTask *downloadLinkTask = [session dataTaskWithURL:downloadLinkUrl
                                                    completionHandler:^(NSData *downloadLink, NSURLResponse *downloadLinkResponse, NSError *downloadLinkError) {
      if (downloadLinkError) {
        BPLog(@"Error: %@", downloadLinkError.localizedDescription);
        return;
      }
      if (!downloadLink) {
        BPLog(@"Unexpected state - no error and no download link returned");
        return;
      }

      NSError *downloadLinkJsonError;
      NSDictionary *downloadLinkJson = [NSJSONSerialization JSONObjectWithData:downloadLink options:0 error:&downloadLinkJsonError];
      if (downloadLinkJsonError) {
        BPLog(@"JSON Parsing Error: %@", downloadLinkJsonError.localizedDescription);
        return;
      }
      NSString *signedUrl = [downloadLinkJson objectForKey:@"signedUrl"];
      if (!signedUrl) {
        BPLog(@"Trying to download, but could not retrieve the signed url of %@", bundleId);
        return;
      }

      completionHandler(md5, [NSURL URLWithString:signedUrl]);
    }];
    [downloadLinkTask resume];
  }];
  
  [dataTask resume];
}

+ (void)downloadFileFromURL:(NSURL *)url
              toDestination:(NSURL *)destinationURL
          completionHandler:(void (^)())completionHandler
{
  NSURLSession *session = [NSURLSession sharedSession];
  BPLog(@"Starting download from: %@", [url absoluteString]);
  NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url
                                                      completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (error) {
      BPLog(@"Download error: %@", error.localizedDescription);
      return;
    }
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL
                                              error:nil];
    
    NSError *fileError;
    [[NSFileManager defaultManager] moveItemAtURL:location
                                            toURL:destinationURL
                                            error:&fileError];
    if (fileError) {
      BPLog(@"File move error: %@", fileError.localizedDescription);
    } else {
      BPLog(@"File downloaded successfully to %@", destinationURL);
      completionHandler();
    }
  }];
  [downloadTask resume];
}

+ (BOOL)checkBundleFolderAvailable
{
  NSURL *workdir = [self workdir];
  BPLog([workdir absoluteString]);
  BOOL isDirectory;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[workdir path]
                                                     isDirectory:&isDirectory];
  if (exists) {
    if (!isDirectory) {
      BPLog(@"Unexpected state - workdir is a file (%@)", workdir);
    }
    // TODO check write access available
    return isDirectory;
  }
  NSError *error = nil;
  BOOL result = [[NSFileManager defaultManager] createDirectoryAtURL:workdir
                                         withIntermediateDirectories:YES
                                                          attributes:nil
                                                               error:&error];
  if (!result) {
    BPLog(@"Error creating folder - %@", error);
  }
  return result;
}

+ (void)checkForUpdates:(NSString *)appId
{
  BOOL available = [self checkBundleFolderAvailable];
  if (!available) {
    return;
  }
  NSURL *currentZip = [[self workdir] URLByAppendingPathComponent:@"current.zip"];
  NSString *currentZipMd5 = MD5HashOfFile([currentZip path]);

  [self requestBundleForAppId:appId
        ignoreIfMd5:currentZipMd5
        withCompletionHandler:^(NSString *md5, NSURL *bundleURL) {
    
    NSURL *downloadedZip = [[self workdir] URLByAppendingPathComponent:@"downloaded.zip"];
    BPLog(@"File will be downloaded to %@", downloadedZip);
    [self downloadFileFromURL:bundleURL
                toDestination:downloadedZip
            completionHandler:^() {
      NSString *downloadMd5 = MD5HashOfFile([downloadedZip path]);
      if (![downloadMd5 isEqualToString:md5]) {
        BPLog(@"Aborting bundle install - downloaded file md5 = %@ - expected was: %@", downloadMd5, md5);
        return;
      }
      NSURL *extractPath = [[self workdir] URLByAppendingPathComponent:@"current_bundle" isDirectory:YES];
      
      [[NSFileManager defaultManager] removeItemAtURL:extractPath
                                                error:nil]; // TODO handle error
      NSError *zipError = nil;
      BOOL successUnzip = [SSZipArchive unzipFileAtPath:[downloadedZip path]
                                          toDestination:[extractPath path]
                                              overwrite:YES
                                               password:nil
                                                  error:&zipError];
      if (!successUnzip) {
        BPLog(@"Error unzipping - %@", zipError);
        return;
      }
      
      [[NSFileManager defaultManager] removeItemAtURL:currentZip error:nil];
      [[NSFileManager defaultManager] moveItemAtURL:downloadedZip
                                              toURL:currentZip
                                              error:nil];
    }];
  }];
}

+ (NSURL *)latestBundleURL
{
  NSURL *bundleUrl = [[self workdir] URLByAppendingPathComponent:@"current_bundle/main.jsbundle"];
  BOOL isDirectory;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[bundleUrl path]
                                                     isDirectory:&isDirectory];
  BPLog(@"Latest bundle: %@", bundleUrl);
  if (exists && !isDirectory) {
    return bundleUrl;
  } else {
    return nil;
  }
}

@end
