#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface TSListControllerShared : PSListController
- (BOOL)isTrollStore;
- (NSString*)getTrollStoreVersion;
- (NSString*)trollStoreDownloadURL;
- (void)setTrollStoreDownloadURL:(NSString*)urlString;
- (void)setTrollStoreDownloadURLValue:(NSObject*)value specifier:(PSSpecifier*)specifier;
- (NSObject*)readTrollStoreDownloadURLValue:(PSSpecifier*)specifier;
- (void)downloadTrollStoreAndRun:(void (^)(NSString* localTrollStoreTarPath))doHandler;
- (void)installTrollStorePressed;
- (void)updateTrollStorePressed;
- (void)rebuildIconCachePressed;
- (void)refreshAppRegistrationsPressed;
- (void)uninstallPersistenceHelperPressed;
- (void)handleUninstallation;
- (NSMutableArray*)argsForUninstallingTrollStore;
- (void)uninstallTrollStorePressed;
@end
