#import "TSListControllerShared.h"
#import "TSUtil.h"
#import "TSPresentationDelegate.h"
#import "EmbeddedTrollStoreTar.h"

static NSString* const kTrollStoreDownloadURLDefaultsKey = @"TrollStoreDownloadURL";

@implementation TSListControllerShared

- (BOOL)isTrollStore
{
	return YES;
}

- (NSString*)getTrollStoreVersion
{
	if([self isTrollStore])
	{
		return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	}
	else
	{
		NSString* trollStorePath = trollStoreAppPath();
		if(!trollStorePath) return nil;

		NSBundle* trollStoreBundle = [NSBundle bundleWithPath:trollStorePath];
		return [trollStoreBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	}
}

- (NSString*)trollStoreDownloadURL
{
	return [NSUserDefaults.standardUserDefaults stringForKey:kTrollStoreDownloadURLDefaultsKey] ?: @"";
}

- (void)setTrollStoreDownloadURL:(NSString*)urlString
{
	NSString* trimmedURLString = [urlString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	[NSUserDefaults.standardUserDefaults setObject:trimmedURLString ?: @"" forKey:kTrollStoreDownloadURLDefaultsKey];
}

- (void)setTrollStoreDownloadURLValue:(NSObject*)value specifier:(PSSpecifier*)specifier
{
	[self setTrollStoreDownloadURL:(NSString*)value];
}

- (NSObject*)readTrollStoreDownloadURLValue:(PSSpecifier*)specifier
{
	return [self trollStoreDownloadURL];
}

- (NSString*)bundledTrollStoreTarPath
{
	NSString* bundledTarPath = [NSBundle.mainBundle pathForResource:@"TrollStore" ofType:@"tar"];
	if(bundledTarPath && [[NSFileManager defaultManager] fileExistsAtPath:bundledTarPath])
	{
		return bundledTarPath;
	}

#ifdef EMBEDDED_TROLLSTORE_TAR
	if(EmbeddedTrollStoreTarLength > 0)
	{
		NSString* embeddedTarPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TrollStore.tar"];
		NSData* embeddedTarData = [NSData dataWithBytes:EmbeddedTrollStoreTarData length:EmbeddedTrollStoreTarLength];
		if([embeddedTarData writeToFile:embeddedTarPath atomically:YES])
		{
			return embeddedTarPath;
		}
	}
#endif

	return nil;
}

- (void)installTrollStoreFromLocalTarPath:(NSString*)localTrollStoreTarPath
{
	[TSPresentationDelegate startActivity:@"Installing TrollStore"];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		int ret = spawnRoot(rootHelperPath(), @[@"install-trollstore", localTrollStoreTarPath], nil, nil);
		if([localTrollStoreTarPath hasPrefix:NSTemporaryDirectory()])
		{
			[[NSFileManager defaultManager] removeItemAtPath:localTrollStoreTarPath error:nil];
		}

		if(ret == 0)
		{
			respring();

			if([self isTrollStore])
			{
				exit(0);
			}
			else
			{
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[TSPresentationDelegate stopActivityWithCompletion:^
					{
						[self reloadSpecifiers];
					}];
				});
			}
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[TSPresentationDelegate stopActivityWithCompletion:^
				{
					UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Error installing TrollStore: trollstorehelper returned %d", ret] preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
					[errorAlert addAction:closeAction];
					[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
				}];
			});
		}
	});
}

- (void)installBundledTrollStore
{
	NSString* bundledTarPath = [self bundledTrollStoreTarPath];
	if(!bundledTarPath)
	{
		UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"No bundled TrollStore.tar is available." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
		[errorAlert addAction:closeAction];
		[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
		return;
	}

	[self installTrollStoreFromLocalTarPath:bundledTarPath];
}

- (void)downloadTrollStoreAndRun:(void (^)(NSString* localTrollStoreTarPath))doHandler
{
	NSString* rawURLString = [self trollStoreDownloadURL];
	NSString* urlString = [rawURLString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	NSURL* trollStoreURL = [NSURL URLWithString:urlString];
	if(!trollStoreURL || !trollStoreURL.scheme || !trollStoreURL.host)
	{
		UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Please enter a valid TrollStore.tar download URL." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
		[errorAlert addAction:closeAction];
		[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
		return;
	}

	[self downloadTrollStoreFromURL:trollStoreURL andRun:doHandler];
}

- (void)handleTrollStoreLaunchURLString:(NSString*)urlString
{
	if(!urlString)
	{
		return;
	}

	[self setTrollStoreDownloadURL:urlString];
	[NSUserDefaults.standardUserDefaults synchronize];
	[self reloadSpecifiers];
	[self installTrollStoreFromRemoteURL:[NSURL URLWithString:[self trollStoreDownloadURL]]];
}

- (void)downloadTrollStoreFromURL:(NSURL*)trollStoreURL andRun:(void (^)(NSString* localTrollStoreTarPath))doHandler
{
	NSURLRequest* trollStoreRequest = [NSURLRequest requestWithURL:trollStoreURL];
	[TSPresentationDelegate startActivity:@"Downloading TrollStore"];

	NSURLSessionDownloadTask* downloadTask = [NSURLSession.sharedSession downloadTaskWithRequest:trollStoreRequest completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
	{
		if(error)
		{
			UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Error downloading TrollStore: %@", error] preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
			[errorAlert addAction:closeAction];

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[TSPresentationDelegate stopActivityWithCompletion:^
				{
					[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
				}];
			});
		}
		else
		{
			NSString* tarTmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TrollStore.tar"];
			[[NSFileManager defaultManager] removeItemAtPath:tarTmpPath error:nil];
			[[NSFileManager defaultManager] copyItemAtPath:location.path toPath:tarTmpPath error:nil];

			doHandler(tarTmpPath);
		}
	}];

	[downloadTask resume];
}

- (void)_installTrollStoreFromURL:(NSURL*)trollStoreURL comingFromUpdateFlow:(BOOL)update
{
	[self setTrollStoreDownloadURL:trollStoreURL.absoluteString];
	[self downloadTrollStoreFromURL:trollStoreURL andRun:^(NSString* tmpTarPath)
	{
		int ret = spawnRoot(rootHelperPath(), @[@"install-trollstore", tmpTarPath], nil, nil);
		[[NSFileManager defaultManager] removeItemAtPath:tmpTarPath error:nil];

		if(ret == 0)
		{
			respring();

			if([self isTrollStore])
			{
				exit(0);
			}
			else
			{
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[TSPresentationDelegate stopActivityWithCompletion:^
					{
						[self reloadSpecifiers];
					}];
				});
			}
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[TSPresentationDelegate stopActivityWithCompletion:^
				{
					UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Error installing TrollStore: trollstorehelper returned %d", ret] preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
					[errorAlert addAction:closeAction];
					[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
				}];
			});
		}
	}];
}

- (void)_installTrollStoreComingFromUpdateFlow:(BOOL)update
{
	NSString* bundledTarPath = [self bundledTrollStoreTarPath];
	if(![self isTrollStore] && bundledTarPath)
	{
		[self installBundledTrollStore];
		return;
	}

	NSString* rawURLString = [self trollStoreDownloadURL];
	NSString* urlString = [rawURLString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	NSURL* trollStoreURL = [NSURL URLWithString:urlString];
	if(!trollStoreURL || !trollStoreURL.scheme || !trollStoreURL.host)
	{
		UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Please enter a valid TrollStore.tar download URL." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
		[errorAlert addAction:closeAction];
		[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
		return;
	}

	[self _installTrollStoreFromURL:trollStoreURL comingFromUpdateFlow:update];
}

- (void)installTrollStoreFromRemoteURL:(NSURL*)remoteURL
{
	if(!remoteURL || !remoteURL.scheme || !remoteURL.host)
	{
		return;
	}

	[self _installTrollStoreFromURL:remoteURL comingFromUpdateFlow:NO];
}

- (void)installTrollStorePressed
{
	[self _installTrollStoreComingFromUpdateFlow:NO];
}

- (void)updateTrollStorePressed
{
	[self _installTrollStoreComingFromUpdateFlow:YES];
}

- (void)rebuildIconCachePressed
{
	[TSPresentationDelegate startActivity:@"Rebuilding Icon Cache"];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		spawnRoot(rootHelperPath(), @[@"refresh-all"], nil, nil);

		dispatch_async(dispatch_get_main_queue(), ^
		{
			[TSPresentationDelegate stopActivityWithCompletion:nil];
		});
	});
}

- (void)refreshAppRegistrationsPressed
{
	[TSPresentationDelegate startActivity:@"Refreshing"];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		spawnRoot(rootHelperPath(), @[@"refresh"], nil, nil);
		respring();

		dispatch_async(dispatch_get_main_queue(), ^
		{
			[TSPresentationDelegate stopActivityWithCompletion:nil];
		});
	});
}

- (void)uninstallPersistenceHelperPressed
{
	if([self isTrollStore])
	{
		spawnRoot(rootHelperPath(), @[@"uninstall-persistence-helper"], nil, nil);
		[self reloadSpecifiers];
	}
	else
	{
		UIAlertController* uninstallWarningAlert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Uninstalling the persistence helper will revert this app back to it's original state, you will however no longer be able to persistently refresh the TrollStore app registrations. Continue?" preferredStyle:UIAlertControllerStyleAlert];
	
		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		[uninstallWarningAlert addAction:cancelAction];

		UIAlertAction* continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
		{
			spawnRoot(rootHelperPath(), @[@"uninstall-persistence-helper"], nil, nil);
			exit(0);
		}];
		[uninstallWarningAlert addAction:continueAction];

		[TSPresentationDelegate presentViewController:uninstallWarningAlert animated:YES completion:nil];
	}
}

- (void)handleUninstallation
{
	if([self isTrollStore])
	{
		exit(0);
	}
	else
	{
		[self reloadSpecifiers];
	}
}

- (NSMutableArray*)argsForUninstallingTrollStore
{
	return @[@"uninstall-trollstore"].mutableCopy;
}

- (void)uninstallTrollStorePressed
{
	UIAlertController* uninstallAlert = [UIAlertController alertControllerWithTitle:@"Uninstall" message:@"You are about to uninstall TrollStore, do you want to preserve the apps installed by it?" preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* uninstallAllAction = [UIAlertAction actionWithTitle:@"Uninstall TrollStore, Uninstall Apps" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		NSMutableArray* args = [self argsForUninstallingTrollStore];
		spawnRoot(rootHelperPath(), args, nil, nil);
		[self handleUninstallation];
	}];
	[uninstallAlert addAction:uninstallAllAction];

	UIAlertAction* preserveAppsAction = [UIAlertAction actionWithTitle:@"Uninstall TrollStore, Preserve Apps" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		NSMutableArray* args = [self argsForUninstallingTrollStore];
		[args addObject:@"preserve-apps"];
		spawnRoot(rootHelperPath(), args, nil, nil);
		[self handleUninstallation];
	}];
	[uninstallAlert addAction:preserveAppsAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[uninstallAlert addAction:cancelAction];

	[TSPresentationDelegate presentViewController:uninstallAlert animated:YES completion:nil];
}

@end
