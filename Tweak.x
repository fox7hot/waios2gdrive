#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

static NSString * const WA2DriveLogPrefix = @"[WA2Drive]";

static void WA2DriveLog(NSString *message) {
    NSLog(@"%@ %@", WA2DriveLogPrefix, message);
}

static BOOL WA2DriveCheckFile(NSString *directory, NSString *filename) {
    if (directory.length == 0) {
        return NO;
    }

    NSString *candidate = [directory stringByAppendingPathComponent:filename];
    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:candidate
                                                       isDirectory:&isDirectory];

    WA2DriveLog([NSString stringWithFormat:@"check %@ exists=%@ directory=%@",
                 candidate,
                 exists ? @"YES" : @"NO",
                 isDirectory ? @"YES" : @"NO"]);
    return exists && !isDirectory;
}

/*
 Diagnostic-only bootstrap.

 This library deliberately does not hook private WhatsApp classes, modify the
 WhatsApp UI, or assume that ChatStorage.sqlite is stored in Documents.

 A loaded dylib inherits the effective sandbox and entitlements of its host
 process. It does not gain app-group or cross-container access by injection.
 */

static void WA2DriveWriteDiagnostics(void) {
    @autoreleasepool {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *bundleID = bundle.bundleIdentifier ?: @"<unknown>";
        NSString *home = NSHomeDirectory();
        NSFileManager *fm = [NSFileManager defaultManager];

        NSURL *documentsURL = [[fm URLsForDirectory:NSDocumentDirectory
                                          inDomains:NSUserDomainMask] firstObject];
        NSURL *libraryURL = [[fm URLsForDirectory:NSLibraryDirectory
                                        inDomains:NSUserDomainMask] firstObject];
        NSURL *cachesURL = [[fm URLsForDirectory:NSCachesDirectory
                                        inDomains:NSUserDomainMask] firstObject];

        NSMutableArray<NSString *> *lines = [NSMutableArray array];
        [lines addObject:@"WA2Drive diagnostic probe"];
        [lines addObject:[NSString stringWithFormat:@"bundle_id=%@", bundleID]];
        [lines addObject:[NSString stringWithFormat:@"home=%@", home]];
        [lines addObject:[NSString stringWithFormat:@"documents=%@",
                          documentsURL.path ?: @"<unavailable>"]];
        [lines addObject:[NSString stringWithFormat:@"library=%@",
                          libraryURL.path ?: @"<unavailable>"]];
        [lines addObject:[NSString stringWithFormat:@"caches=%@",
                          cachesURL.path ?: @"<unavailable>"]];

        NSMutableArray<NSString *> *candidateDirectories = [NSMutableArray array];
        if (documentsURL.path.length > 0) {
            [candidateDirectories addObject:documentsURL.path];
        }
        if (libraryURL.path.length > 0) {
            [candidateDirectories addObject:[libraryURL.path stringByAppendingPathComponent:@"Application Support"]];
            [candidateDirectories addObject:libraryURL.path];
        }

        BOOL foundDatabase = NO;
        for (NSString *directory in candidateDirectories) {
            NSString *candidate = [directory stringByAppendingPathComponent:@"ChatStorage.sqlite"];
            BOOL found = WA2DriveCheckFile(directory, @"ChatStorage.sqlite");
            [lines addObject:[NSString stringWithFormat:@"database_candidate=%@ found=%@",
                              candidate, found ? @"YES" : @"NO"]];
            foundDatabase = foundDatabase || found;
        }

        [lines addObject:[NSString stringWithFormat:@"database_found_in_host_container=%@",
                          foundDatabase ? @"YES" : @"NO"]];
        [lines addObject:@"note=No app-group discovery or cross-container access is attempted."];

        if (cachesURL.path.length > 0) {
            NSString *reportDirectory = [cachesURL.path stringByAppendingPathComponent:@"WA2Drive"];
            NSError *directoryError = nil;
            [fm createDirectoryAtPath:reportDirectory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&directoryError];

            if (directoryError) {
                WA2DriveLog([NSString stringWithFormat:@"cannot create diagnostics directory: %@",
                             directoryError.localizedDescription]);
            } else {
                NSString *reportPath = [reportDirectory stringByAppendingPathComponent:@"diagnostics.txt"];
                NSError *writeError = nil;
                NSString *report = [lines componentsJoinedByString:@"\n"];
                [report writeToFile:reportPath
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:&writeError];

                if (writeError) {
                    WA2DriveLog([NSString stringWithFormat:@"cannot write diagnostics: %@",
                                 writeError.localizedDescription]);
                } else {
                    WA2DriveLog([NSString stringWithFormat:@"diagnostics written to %@", reportPath]);
                }
            }
        }

        WA2DriveLog([NSString stringWithFormat:@"loaded in bundle %@; host-container database found=%@",
                     bundleID, foundDatabase ? @"YES" : @"NO"]);
    }
}

__attribute__((constructor))
static void WA2DriveConstructor(void) {
    @autoreleasepool {
        WA2DriveLog(@"dylib constructor executed");
        dispatch_async(dispatch_get_main_queue(), ^{
            WA2DriveWriteDiagnostics();
        });
    }
}
