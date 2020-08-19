#include "NLVRootListController.h"

@implementation NLVRootListController 

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
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

@end
