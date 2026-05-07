#import "TSHSceneDelegate.h"
#import "TSHRootViewController.h"

static NSString* trollHelperLaunchURLString(void)
{
	NSArray<NSString*>* arguments = NSProcessInfo.processInfo.arguments;
	for(NSUInteger i = 1; i < arguments.count; i++)
	{
		NSString* argument = arguments[i];
		if([argument hasPrefix:@"--url="] || [argument hasPrefix:@"--install-url="] || [argument hasPrefix:@"--trollstore-url="])
		{
			NSRange separatorRange = [argument rangeOfString:@"="];
			return [argument substringFromIndex:separatorRange.location + 1];
		}
		else if(([argument isEqualToString:@"--url"] || [argument isEqualToString:@"--install-url"] || [argument isEqualToString:@"--trollstore-url"]) && i + 1 < arguments.count)
		{
			return arguments[i + 1];
		}
		else if([argument hasPrefix:@"http://"] || [argument hasPrefix:@"https://"])
		{
			return argument;
		}
	}

	return nil;
}

static BOOL trollHelperShouldInstallBundledTrollStore(void)
{
	NSArray<NSString*>* arguments = NSProcessInfo.processInfo.arguments;
	for(NSUInteger i = 1; i < arguments.count; i++)
	{
		NSString* argument = arguments[i];
		if([argument isEqualToString:@"--install-bundled-trollstore"] || [argument isEqualToString:@"--install-bundled"] || [argument isEqualToString:@"--bundled-trollstore"])
		{
			return YES;
		}
	}

	return NO;
}

@implementation TSHSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
	// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
	// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
	// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

	UIWindowScene* windowScene = (UIWindowScene*)scene;
	_window = [[UIWindow alloc] initWithWindowScene:windowScene];
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[TSHRootViewController alloc] init]];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];

	NSString* launchURLString = trollHelperLaunchURLString();
	if(launchURLString)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			TSHRootViewController* rootViewController = (TSHRootViewController*)_rootViewController.topViewController;
			[rootViewController handleTrollStoreLaunchURLString:launchURLString];
		});
	}
	else if(trollHelperShouldInstallBundledTrollStore())
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			TSHRootViewController* rootViewController = (TSHRootViewController*)_rootViewController.topViewController;
			[rootViewController installBundledTrollStore];
		});
	}
}

- (void)sceneDidDisconnect:(UIScene *)scene {
	// Called as the scene is being released by the system.
	// This occurs shortly after the scene enters the background, or when its session is discarded.
	// Release any resources associated with this scene that can be re-created the next time the scene connects.
	// The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
	// Called when the scene has moved from an inactive state to an active state.
	// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
	// Called when the scene will move from an active state to an inactive state.
	// This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
	// Called as the scene transitions from the background to the foreground.
	// Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
	// Called as the scene transitions from the foreground to the background.
	// Use this method to save data, release shared resources, and store enough scene-specific state information
	// to restore the scene back to its current state.
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
}

@end
