#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>
#import <AudioToolbox/AudioServices.h>
#import <objc/runtime.h>
#import <SparkAppList.h>
#import <rootless.h>


#define TWEAK_NAME @"NotifLives"
#define BUNDLE @"com.wrp1002.notiflives"

@interface JBBulletinManager : NSObject
	+(id)sharedInstance;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg bundleID:(NSString *)bundleID;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg bundleID:(NSString *)bundleID soundPath:(NSString *)soundPath;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg bundleID:(NSString *)bundleID soundID:(int)inSoundID;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg overrideBundleImage:(UIImage *)bundleImage;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg overrideBundleImage:(UIImage *)bundleImage soundPath:(NSString *)inSoundPath;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg inOverridBundleImage:(UIImage *)bundleImage soundID:(int)soundID;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg bundleID:(NSString *)bundleID hasSound:(BOOL)hasSound soundID:(int)soundID vibrateMode:(int)vibrate soundPath:(NSString *)soundPath attachmentImage:(UIImage *)attachmentImage overrideBundleImage:(UIImage *)overrideBundleImage;
@end

@interface NCNotificationRequest : NSObject
	-(NSString *)sectionIdentifier;
@end


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
			[[objc_getClass("JBBulletinManager") sharedInstance]
				showBulletinWithTitle:@"1UP!"
				message:[NSString stringWithFormat:@"Lives: %li", (long)lives]
				overrideBundleImage:(UIImage *)[UIImage imageNamed:@"/Library/NotifLives/Images/icon.png"]
				soundPath:soundPath];
		}
		else {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
				NSString *fileName = [NSString stringWithFormat:@"/Library/NotifLives/Sounds/%@", soundFileName];
				ROOT_PATH_NS(@"/Library/NotifLives/Images/icon.png");

				SystemSoundID sound;
				OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:fileName], &sound);
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


//	Delay this hook so that notifications from before respringing do not trigger new lives
%group DelayedHooks

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
		%init(DelayedHooks);
	});
}
