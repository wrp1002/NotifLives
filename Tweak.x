#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>
#import <AudioToolbox/AudioServices.h>
#import <objc/runtime.h>
#import <SparkAppList.h>
#import <rootless.h>
#import "Tweak.h"
#import "Globals.h"


#define TWEAK_NAME @"NotifLives"
#define BUNDLE @"com.wrp1002.notiflives"


//	=========================== Preference vars ===========================

BOOL enabled;
BOOL allEnabled;
BOOL showNotifications;
NSInteger maxCount;
NSInteger saveInterval;
CGFloat delayTime;
NSString *soundFileName;
NSInteger count = 0;
NSInteger lives = 0;
NSArray *selectedApps;

//	=========================== Other vars ===========================

int startupDelay = 10;
HBPreferences *preferences;

//	=========================== Classes / Functions ===========================

void SaveCount() {
	//[Debug Log:@"Saving count"];
	[preferences setInteger:count forKey:@"kCount"];
}

void SaveLives() {
	//[Debug Log:@"Saving lives"];
	[preferences setInteger:lives forKey:@"kLives"];
}


void UpdateLives() {
	if (!enabled) return;

	count++;

	if (count >= maxCount) {
		count = 0;
		lives++;

		if (showNotifications) {
			NSString *soundPath = [NSString stringWithFormat:@"/Library/NotifLives/Sounds/%@", soundFileName];
			soundPath = ROOT_PATH_NS(soundPath);
			NSString *imagePath = ROOT_PATH_NS(@"/Library/NotifLives/Images/icon.png");

			[[objc_getClass("JBBulletinManager") sharedInstance]
				showBulletinWithTitle:@"1UP!"
				message:[NSString stringWithFormat:@"Lives: %li", (long)lives]
				overrideBundleImage:(UIImage *)[UIImage imageNamed:imagePath]
				soundPath:soundPath];
		}
		else {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
				NSString *soundPath = [NSString stringWithFormat:@"/Library/NotifLives/Sounds/%@", soundFileName];
				soundPath = ROOT_PATH_NS(soundPath);

				SystemSoundID sound;
				OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &sound);
				if (error == kAudioServicesNoError) {
					AudioServicesPlaySystemSoundWithCompletion(sound, ^{
						AudioServicesDisposeSystemSoundID(sound);
					});
				}
			});
		}

		//[Debug Log:[NSString stringWithFormat:@"1UP! Lives: %li", (long)lives]];
		SaveLives();
	}

	if (count % saveInterval == 0)
		SaveCount();

	//[Debug Log:[NSString stringWithFormat:@"count: %li", (long)count]];
}


//	=========================== Hooks ===========================

%group iOS12AndBelowHooks
	%hook NCNotificationAlertQueue
		-(void)postNotificationRequest:(id)arg1 forCoalescedNotification:(id)arg2 {
			%orig;

			if (!enabled) return;

			NCNotificationRequest *notif = arg1;
			NSString *bundleID = [notif sectionIdentifier];

			if (allEnabled || [SparkAppList doesIdentifier:BUNDLE andKey:@"kApps" containBundleIdentifier:bundleID]) {
				//[Debug Log:[NSString stringWithFormat:@"New notification from: %@", bundleID]];
				UpdateLives();
			}

		}
	%end
%end

%group iOS13AndUpHooks
	%hook NCNotificationMasterList
		- (void)insertNotificationRequest:(id)arg1 {
			%orig;
			//[Debug Log:@"- (void)insertNotificationRequest:(id)arg1;"];

			if (!enabled) return;

			NCNotificationRequest *notif = arg1;
			NSString *bundleID = [notif sectionIdentifier];

			if (allEnabled || [SparkAppList doesIdentifier:BUNDLE andKey:@"kApps" containBundleIdentifier:bundleID]) {
				//[Debug Log:[NSString stringWithFormat:@"New notification from: %@", bundleID]];
				UpdateLives();
			}

		}
	%end
%end


//	=========================== Constructor stuff ===========================

%ctor {
	//[Debug Log:[NSString stringWithFormat:@"============== %@ started ==============", TWEAK_NAME]];


	preferences = [[HBPreferences alloc] initWithIdentifier:BUNDLE];

	if ((NSString *)[preferences objectForKey:@"kSoundFile"] == nil)
		[preferences setObject:@"Powerup.wav" forKey:@"kSoundFile"];

    [preferences registerBool:&enabled default:YES forKey:@"kEnabled"];
	[preferences registerBool:&allEnabled default:YES forKey:@"kAllEnabled"];
	[preferences registerBool:&showNotifications default:YES forKey:@"kNotifications"];

	[preferences registerFloat:&delayTime default:1.0f forKey:@"kDelay"];

	[preferences registerInteger:&maxCount default:100 forKey:@"kMaxCount"];
	[preferences registerInteger:&saveInterval default:5 forKey:@"kSaveInterval"];
	lives = [preferences integerForKey:@"kLives" default:0];
	count = [preferences integerForKey:@"kCount" default:0];

	[preferences registerObject:&soundFileName default:@"Powerup.wav" forKey:@"kSoundFile"];

	//	Wait a few seconds to start watching for new notifications in case of old notifications from before respring
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, startupDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		if (@available(iOS 13.0, *)) {
			%init(iOS13AndUpHooks);
		}
		else {
			%init(iOS12AndBelowHooks);
		}
	});
}
