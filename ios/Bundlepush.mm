#import "Bundlepush.h"
#import <Foundation/Foundation.h>


@implementation Bundlepush
RCT_EXPORT_MODULE()


- (void)downloadFileFromURL:(NSURL *)url
              toDestination:(NSURL *)destinationURL
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
            NSLog(@"File downloaded successfully to %@", location);
        }
    }];

    // Start the download task
    [downloadTask resume];
}

- (NSURL *)fileURLInDocumentsDirectoryWithFileName:(NSString *)filename {
    // Get the Documents directory path
    NSArray<NSURL *> *documentDirectories = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                                   inDomains:NSUserDomainMask];

    // The Documents directory for the app
    NSURL *documentsDirectory = [documentDirectories firstObject];

    // Append the file name to create the full file URL
    NSURL *fileURL = [documentsDirectory URLByAppendingPathComponent:filename];
    return fileURL;
}

- (void)performOTACheck
{
  NSURL *downloadURL = [NSURL URLWithString:@"https://iuri.s3.us-east-1.amazonaws.com/main.jsbundle"];
  NSURL *destination = [self fileURLInDocumentsDirectoryWithFileName:@"bundle-result.jsbundle"];
  NSLog(@"File downloaded to %@", destination);
  [self downloadFileFromURL:downloadURL toDestination:destination];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeBundlepushSpecJSI>(params);
}

@end
