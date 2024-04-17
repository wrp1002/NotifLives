#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import <objc/runtime.h>
#import <rootless.h>
#import "Tweak.h"
#import "Globals.h"


#define TWEAK_NAME @"NotifLives"
#define BUNDLE @"com.wrp1002.notiflives"
#define PREFS_RELOAD "com.wrp1002.notiflives/ReloadPrefs"


//	=========================== Preference vars ===========================

BOOL enabled;
BOOL allEnabled;
BOOL showNotifications;
NSInteger maxCount;
NSInteger saveInterval;
CGFloat delayTime;
NSString *soundFileName;
NSInteger count;
NSInteger lives;
NSArray *selectedApps;

NSUserDefaults *prefs = nil;

static void InitPrefs(void) {
	if (!prefs) {
		NSDictionary *defaultPrefs = @{
			@"kEnabled": @YES,
			@"kAllEnabled": @YES,
			@"kNotifications": @YES,
			@"kDelay": @1.0f,
			@"kMaxCount": @100,
			@"kSaveInterval": @5,
			@"kLives": @0,
			@"kCount": @0,
			@"kSoundFile": @"Powerup.wav",
			@"kApps": @[],
		};
		prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.wrp1002.notiflives"];
		[prefs registerDefaults:defaultPrefs];
	}
}


//	=========================== Other vars ===========================

int startupDelay = 10;

//	=========================== Classes / Functions ===========================

void SaveCount() {
	//[Debug Log:@"Saving count"];
	[prefs setInteger:count forKey:@"kCount"];
	[prefs synchronize];
}

void SaveLives() {
	//[Debug Log:@"Saving lives"];
	[prefs setInteger:lives forKey:@"kLives"];
	[prefs synchronize];
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

			if (allEnabled || [selectedApps containsObject:bundleID]) {
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

			if (allEnabled || [selectedApps containsObject:bundleID]) {
				//[Debug Log:[NSString stringWithFormat:@"New notification from: %@", bundleID]];
				UpdateLives();
			}

		}
	%end
%end


//	=========================== Constructor stuff ===========================

static void UpdatePrefs() {
	enabled = [prefs boolForKey: @"kEnabled"];
	allEnabled = [prefs boolForKey: @"kAllEnabled"];
	showNotifications = [prefs boolForKey: @"kNotifications"];

	delayTime = [prefs floatForKey:@"kDelay"];

	maxCount = [prefs integerForKey:@"kMaxCount"];
	saveInterval = [prefs integerForKey:@"kSaveInterval"];
	lives = [prefs integerForKey:@"kLives"];
	count = [prefs integerForKey:@"kCount"];

	soundFileName = [prefs stringForKey:@"kSoundFile"];
	selectedApps = [prefs objectForKey:@"kApps"];
}

static void PrefsChangeCallback(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
	UpdatePrefs();
}

%ctor {
	//[Debug Log:[NSString stringWithFormat:@"============== %@ started ==============", TWEAK_NAME]];

	InitPrefs();
	UpdatePrefs();

	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		&PrefsChangeCallback,
		CFSTR(PREFS_RELOAD),
		NULL,
		0
	);

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
