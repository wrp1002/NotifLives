#import <Cephei/HBPreferences.h>
#import <AudioToolbox/AudioServices.h>
#import <objc/runtime.h>


#define kIdentifier @"com.wrp1002.notiflives"
#define kSettingsChangedNotification (CFStringRef)@"com.wrp1002.notiflives/ReloadPrefs"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.wrp1002.notiflives.plist"


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


//	=========================== Preference vars ===========================

BOOL enabled;
BOOL showNotifications;
NSInteger maxCount;
CGFloat delayTime;
NSString *soundFileName;

//	=========================== Other vars ===========================

NSInteger count = 0;
NSInteger lives = 0;
bool played = false;
int startupDelay = 5;
HBPreferences *preferences;

//	=========================== Debugging stuff ===========================

NSString *LogTweakName = @"NotifLives";
bool springboardReady = false;

UIWindow* GetKeyWindow() {
    UIWindow        *foundWindow = nil;
    NSArray         *windows = [[UIApplication sharedApplication]windows];
    for (UIWindow   *window in windows) {
        if (window.isKeyWindow) {
            foundWindow = window;
            break;
        }
    }
    return foundWindow;
}

//	Shows an alert box. Used for debugging 
void ShowAlert(NSString *msg, NSString *title) {
	if (!springboardReady) return;

	UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:msg
                                 preferredStyle:UIAlertControllerStyleAlert];

    //Add Buttons
    UIAlertAction* dismissButton = [UIAlertAction
                                actionWithTitle:@"Cool!"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle dismiss button action here
									
                                }];

    //Add your buttons to alert controller
    [alert addAction:dismissButton];

    [GetKeyWindow().rootViewController presentViewController:alert animated:YES completion:nil];
}

//	Show log with tweak name as prefix for easy grep
void Log(NSString *msg) {
	NSLog(@"%@: %@", LogTweakName, msg);
}

//	Log exception info
void LogException(NSException *e) {
	NSLog(@"%@: NSException caught", LogTweakName);
	NSLog(@"%@: Name:%@", LogTweakName, e.name);
	NSLog(@"%@: Reason:%@", LogTweakName, e.reason);
	//ShowAlert(@"TVLock Crash Avoided!", @"Alert");
}


//	=========================== Classes / Functions ===========================


void Save() {
	Log(@"Saving to file");
	[preferences setInteger:lives forKey:@"kLives"];
}


void UpdateLives() {
	if (!enabled) return;

	count++;

	if (count >= maxCount) {
		count = 0;
		lives++;

		if (showNotifications) {
			count--;	//	Dont let this notification count towards lives

			[[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"1UP!" message:[NSString stringWithFormat:@"Lives: %li", (long)lives] overrideBundleImage:(UIImage *)[UIImage imageNamed:@"/Library/NotifLives/Images/icon.png"] soundPath:[NSString stringWithFormat:@"/Library/NotifLives/Sounds/%@", soundFileName]];
		}
		else {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
				SystemSoundID sound;
				OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[NSString stringWithFormat:@"/Library/NotifLives/Sounds/%@", soundFileName]], &sound);
				if (error == kAudioServicesNoError) {
					AudioServicesPlaySystemSoundWithCompletion(sound, ^{
						AudioServicesDisposeSystemSoundID(sound);
					});
				}
			});
		}


		Log([NSString stringWithFormat:@"1UP! Lives: %li", (long)lives]);
		Save();
	}

	Log([NSString stringWithFormat:@"count: %li", (long)count]);
}


//	=========================== Hooks ===========================

%group Hooks

	%hook SpringBoard

		//	Called when springboard is finished launching
		-(void)applicationDidFinishLaunching:(id)application {
			%orig;

			Log([NSString stringWithFormat:@"============== %@ started ==============", LogTweakName]);


			springboardReady = true;
		}

	%end

	%hook SBCCDoNotDisturbSetting

	-(void)_setDNDEnabled:(BOOL)arg1 updateServer:(BOOL)arg2 source:(unsigned long long)arg3
	{
		Log([NSString stringWithFormat:@"Enabled:%d", arg1]);
		%orig;
	}

	%end

%end

//	Delay this hook so that notifications from before respringing do not trigger new lives
%group DelayedHooks

	%hook NCNotificationMasterList
		- (void)insertNotificationRequest:(id)arg1 {
			%orig;
			Log(@"- (void)insertNotificationRequest:(id)arg1;");
			UpdateLives();
		}
	%end

%end


//	=========================== Constructor stuff ===========================

//	Only here so CFNotificationCenterAddObserver doesnt crash
static void reloadPrefs() {
	Log(@"(CFNotificationCallback)");
}

%ctor {
	preferences = [[HBPreferences alloc] initWithIdentifier:kIdentifier];

	if ((NSString *)[preferences objectForKey:@"kSoundFile"] == nil)
		[preferences setObject:@"Powerup.wav" forKey:@"kSoundFile"];

    [preferences registerBool:&enabled default:YES forKey:@"kEnabled"];
	[preferences registerBool:&showNotifications default:YES forKey:@"kNotifications"];

	[preferences registerFloat:&delayTime default:1.0f forKey:@"kDelay"];

	[preferences registerInteger:&maxCount default:100 forKey:@"kMaxCount"];
	[preferences registerInteger:&lives default:0 forKey:@"kLives"];

	[preferences registerObject:&soundFileName default:@"Powerup.wav" forKey:@"kSoundFile"];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, (CFNotificationSuspensionBehavior)kNilOptions);

	%init(Hooks);

	//	Wait a few seconds to start watching for new notifications in case of old notifications from before respring
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, startupDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		%init(DelayedHooks);
	});
}
