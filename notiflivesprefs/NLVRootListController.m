#include "NLVRootListController.h"


@implementation NLVRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	//In this array you should add the IDs of all the specifiers you are going to hide & show.
	//Do not include the IDs of the cells you will reinsert them under.
	//Notice I only included "cellID" and not "switchID".
	NSArray *chosenIDs = @[@"kApps"];
	self.savedSpecifiers = (self.savedSpecifiers) ?: [[NSMutableDictionary alloc] init];
	for(PSSpecifier *specifier in _specifiers) {
		if([chosenIDs containsObject:[specifier propertyForKey:@"id"]]) {
			[self.savedSpecifiers setObject:specifier forKey:[specifier propertyForKey:@"id"]];
		}
	}

	return _specifiers;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];

	//Here we will check if the value of our switch has been set to.
	//We then check if the value has been set to NO in the following if statement to remove the other cell.
	//Otherwise we check if the cell currently exists in our preferences, if not we reinserting the cell after the switch cell using its ID.
	NSString *key = [specifier propertyForKey:@"key"];
	if([key isEqualToString:@"kAllEnabled"]) {
		if([value boolValue])
			[self removeContiguousSpecifiers:@[self.savedSpecifiers[@"kApps"]] animated:YES];
		else if(![self containsSpecifier:self.savedSpecifiers[@"kApps"]])
			[self insertContiguousSpecifiers:@[self.savedSpecifiers[@"kApps"]] afterSpecifierID:@"kAllEnabled" animated:YES];
	}
}

-(void)reloadSpecifiers {
	[super reloadSpecifiers];

	//Since we don't have access to a specific specifier and value like in the previous step, we just have to read our preferences file.
	//I check if our switchKey is NO, then hide the specifier
	//Customize this to however you get your preferences, whether is directly from a plist or Cephei.

	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	NSDictionary *defaultPrefs = @{@"kAllEnabled": @YES};
	[prefs registerDefaults:defaultPrefs];

	if ([prefs integerForKey:@"kAllEnabled"]) {
		[self removeContiguousSpecifiers:@[self.savedSpecifiers[@"kApps"]] animated:YES];
	}
}

-(void)viewDidLoad {
  [super viewDidLoad];
  [self reloadSpecifiers];
}


-(void)Respring {
	// From Cephei since other methods I tried didn't work
	[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/FrontBoardServices.framework"] load];
	[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SpringBoardServices.framework"] load];

	Class $FBSSystemService = NSClassFromString(@"FBSSystemService");
	Class $SBSRelaunchAction = NSClassFromString(@"SBSRelaunchAction");
	if ($FBSSystemService && $SBSRelaunchAction) {
		SBSRelaunchAction *restartAction = [$SBSRelaunchAction actionWithReason:@"RestartRenderServer" options:SBSRelaunchActionOptionsFadeToBlackTransition targetURL:nil];
		[[$FBSSystemService sharedService] sendActions:[NSSet setWithObject:restartAction] withResult:nil];
	}
}

-(void)OpenGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://github.com/wrp1002/NotifLives"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			//NSLog(@"Opened url");
		}
	}];
}

-(void)OpenPaypal {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://paypal.me/wrp1002"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			//NSLog(@"Opened url");
		}
	}];
}

-(void)OpenReddit {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://reddit.com/u/wes_hamster"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			//NSLog(@"Opened url");
		}
	}];
}

-(void)OpenEmail {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"mailto:wes.hamster@gmail.com?subject=NotifLives"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			//NSLog(@"Opened url");
		}
	}];
}

-(void)ResetSettings {
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];

	// Save life and count to set them after
	NSInteger lives = [prefs integerForKey:@"kLives"];
	NSInteger count = [prefs integerForKey:@"kCount"];

	NSArray *allKeys = [prefs dictionaryRepresentation].allKeys;
	for (NSString *key in allKeys) {
		[prefs removeObjectForKey:key];
	}

	[prefs setInteger:lives forKey:@"kLives"];
	[prefs setInteger:count forKey:@"kCount"];

	[prefs synchronize];

	[self reloadSpecifiers];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(BUNDLE_NOTIFY), nil, nil, true);
}

-(void)ResetLives {
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	[prefs removeObjectForKey:@"kLives"];
	[prefs removeObjectForKey:@"kCount"];

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(BUNDLE_NOTIFY), nil, nil, true);
}

-(void)ResetAll {
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];

	NSArray *allKeys = [prefs dictionaryRepresentation].allKeys;

	for (NSString *key in allKeys) {
		[prefs removeObjectForKey:key];
	}
	[prefs synchronize];

	[self reloadSpecifiers];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(BUNDLE_NOTIFY), nil, nil, true);
}

-(UIWindow*) GetKeyWindow {
	if (@available(iOS 13, *)) {
		NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
		for (UIScene *scene in connectedScenes) {
			if ([scene isKindOfClass:[UIWindowScene class]]) {
				UIWindowScene *windowScene = (UIWindowScene *)scene;
				for (UIWindow *window in windowScene.windows) {
					if (window.isKeyWindow) {
						return window;
					}
				}
			}
		}
	} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		NSArray		 *windows = [[UIApplication sharedApplication] windows];
#pragma clang diagnostic pop
		for (UIWindow   *window in windows) {
			if (window.isKeyWindow) {
				return window;
			}
		}
	}
	return nil;
}

-(void)PlaySound {
	//NSLog(@"NotifLives: PlaySound");

	[self.view endEditing:YES];

	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	NSDictionary *defaultPrefs = @{@"kSoundFile": @"Powerup.wav"};
	[prefs registerDefaults:defaultPrefs];

	NSString *dir = ROOT_PATH_NS(@"/Library/NotifLives/Sounds/");
	NSString *fileName = [prefs stringForKey:@"kSoundFile"];
	fileName = [NSString stringWithFormat:@"%@%@", dir, fileName];

	SystemSoundID sound;
	OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:fileName], &sound);
	if (error == kAudioServicesNoError) {
		AudioServicesPlaySystemSoundWithCompletion(sound, ^{
			AudioServicesDisposeSystemSoundID(sound);
		});
	}
	else {
		//NSLog(@"NotifLives: Error");

		UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Error with sound file"
                                 message: @"There was an error playing your sound file. Check the file name and make sure it's in /Library/NotifLives/Sounds/ or /var/jb/Library/NotifLives/Sounds/ on rootless"
                                 preferredStyle:UIAlertControllerStyleAlert];

		//Add Buttons
		UIAlertAction* dismissButton = [UIAlertAction
									actionWithTitle:@"Okay"
									style:UIAlertActionStyleDefault
									handler:^(UIAlertAction * action) {
										//Handle dismiss button action here

									}];

		//Add your buttons to alert controller
		[alert addAction:dismissButton];

		[[self GetKeyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
	}
}

@end
