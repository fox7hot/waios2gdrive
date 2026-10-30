#import <UIKit/UIKit.h>

// Hooking into WhatsApp's primary Chat Backup interface controller
%hook WA_ChatBackupSettingsViewController

- (void)viewDidLoad {
    // Run the native WhatsApp loading layout routine first
    %orig;
    
    // Construct the custom Google Drive routing element
    UIButton *gDriveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [gDriveButton setTitle:@"Sideload Backup: Google Drive" forState:UIControlStateNormal];
    gDriveButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    gDriveButton.backgroundColor = [UIColor colorWithRed:0.22 green:0.46 blue:0.84 alpha:1.0]; // Google Brand Blue
    [gDriveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    gDriveButton.layer.cornerRadius = 10.0;
    
    // Position the layout element cleanly below the standard iCloud layout structures
    gDriveButton.frame = CGRectMake(20, 450, self.view.frame.size.width - 40, 52);
    
    // Attach the backup sequence click target
    [gDriveButton addTarget:self action:@selector(triggerSideloadedBackupSequence) forControlEvents:UIControlEventTouchUpInside];
    
    // Inject the new button view component into the runtime hierarchy
    [self.view addSubview:gDriveButton];
}

%new
- (void)triggerSideloadedBackupSequence {
    // Locate the local encrypted database file inside this sideload sandbox app group container
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *sqlitePath = [docsPath stringByAppendingPathComponent:@"ChatStorage.sqlite"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:sqlitePath]) {
        // Expose the raw file structure directly to the native iOS system share controllers
        NSURL *fileURL = [NSURL fileURLWithPath:sqlitePath];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
        
        // Render the system sheet allowing user to target the Google Drive app directly
        [self presentViewController:activityVC animated:YES completion:nil];
    } else {
        // Fallback warning dialog handler if target database indexing fails or is sandboxed out of reach
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Backup Error" 
                                                                       message:@"Database file not found in sideloaded sandbox container." 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertController actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

%end
