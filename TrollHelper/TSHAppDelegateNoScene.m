#import "TSHAppDelegateNoScene.h"
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

@implementation TSHAppDelegateNoScene

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
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

	return YES;
}

@end
