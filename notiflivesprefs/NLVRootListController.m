#include "NLVRootListController.h"

@implementation NLVRootListController 

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	//In this array you should add the IDs of all the specifiers you are going to hide & show.
	//Do not include the IDs of the cells you will reinsert them under.
	//Notice I only included "cellID" and not "switchID".
	NSArray *chosenIDs = @[@"kSelectButton"];
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
			[self removeContiguousSpecifiers:@[self.savedSpecifiers[@"kSelectButton"]] animated:YES];
		else if(![self containsSpecifier:self.savedSpecifiers[@"kSelectButton"]])
			[self insertContiguousSpecifiers:@[self.savedSpecifiers[@"kSelectButton"]] afterSpecifierID:@"kAllEnabled" animated:YES];
	}
}

-(void)reloadSpecifiers {
  [super reloadSpecifiers];

  //Since we don't have access to a specific specifier and value like in the previous step, we just have to read our preferences file.
  //I check if our switchKey is NO, then hide the specifier
  //Customize this to however you get your preferences, whether is directly from a plist or Cephei.
  HBPreferences *preferences = [[HBPreferences alloc] initWithIdentifier:@"com.wrp1002.notiflives"];
  if([preferences boolForKey:@"kAllEnabled"]) {
    [self removeContiguousSpecifiers:@[self.savedSpecifiers[@"kSelectButton"]] animated:YES];
  }
}

-(void)viewDidLoad {
  [super viewDidLoad];
  [self reloadSpecifiers];
}



-(void)Respring {
    pid_t pid;
	int status;
	const char* args[] = {"killall", "-9", "SpringBoard", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	waitpid(pid, &status, WEXITED);//wait untill the process completes (only if you need to do that)
}

-(void)OpenGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://github.com/wrp1002/NotifLives"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenPaypal {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://paypal.me/wrp1002"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenReddit {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://reddit.com/u/wes_hamster"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenEmail {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"mailto:wes.hamster@gmail.com?subject=NotifLives"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)ResetSettings {
	HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier: @"com.wrp1002.notiflives"];

	NSInteger lives = [prefs integerForKey:@"kLives"];
	NSInteger count = [prefs integerForKey:@"kCount"];

	[prefs removeAllObjects];

	[prefs setInteger:lives forKey:@"kLives"];
	[prefs setInteger:count forKey:@"kCount"];

	//NSFileManager *fm = [NSFileManager defaultManager];
	//[fm removeItemAtPath: @"/var/mobile/Library/Preferences/com.wrp1002.notiflives.plist" error: nil];

	[self Respring];
}

-(void)ResetLives {
	HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier: @"com.wrp1002.notiflives"];

	[prefs setInteger:0 forKey:@"kLives"];
	[prefs setInteger:0 forKey:@"kCount"];

	//NSFileManager *fm = [NSFileManager defaultManager];
	//[fm removeItemAtPath: @"/var/mobile/Library/Preferences/com.wrp1002.notiflives.plist" error: nil];

	[self Respring];
}

-(void)ResetAll {
	[[[HBPreferences alloc] initWithIdentifier: @"com.wrp1002.notiflives"] removeAllObjects];

	//NSFileManager *fm = [NSFileManager defaultManager];
	//[fm removeItemAtPath: @"/var/mobile/Library/Preferences/com.wrp1002.notiflives.plist" error: nil];

	[self Respring];
}

-(void)PlaySound {
	NSLog(@"NotifLives: PlaySound");

	[self.view endEditing:YES];

	HBPreferences *preferences;
	preferences = [[HBPreferences alloc] initWithIdentifier:@"com.wrp1002.notiflives"];

	NSString *fileName = (NSString *)[preferences objectForKey:@"kSoundFile"];

	SystemSoundID sound;
	OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[NSString stringWithFormat:@"/Library/NotifLives/Sounds/%@", fileName]], &sound);
	if (error == kAudioServicesNoError) {
		AudioServicesPlaySystemSoundWithCompletion(sound, ^{
			AudioServicesDisposeSystemSoundID(sound);
		});
	}
	else {
		UIWindow        *keyWindow = nil;
		NSArray         *windows = [[UIApplication sharedApplication]windows];
		for (UIWindow   *window in windows) {
			if (window.isKeyWindow) {
				keyWindow = window;
				break;
			}
		}

		UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Error with sound file"
                                 message:@"There was an error playing your sound file. Check the file name and make sure it's in /Library/NotifLives/Sounds/"
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

		[keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
	}
}

-(void)SelectApps {
    SparkAppListTableViewController* s = [[SparkAppListTableViewController alloc] initWithIdentifier:@"com.wrp1002.notiflives" andKey:@"kApps"];

    [self.navigationController pushViewController:s animated:YES];
    self.navigationItem.hidesBackButton = FALSE;
}

@end
