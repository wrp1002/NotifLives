#import <Cephei/HBPreferences.h>
#import <AudioToolbox/AudioServices.h>
#import <objc/runtime.h>
#import <SparkAppList/SparkAppList.h>


#define kIdentifier @"com.wrp1002.notiflives"


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

//	=========================== Other vars ===========================

int startupDelay = 10;
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

void SaveCount() {
	Log(@"Saving count");
	[preferences setInteger:count forKey:@"kCount"];
}

void SaveLives() {
	Log(@"Saving lives");
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
		SaveLives();
	}

	if (count % saveInterval == 0) 
		SaveCount();

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
			Log(@"- (void)insertNotificationRequest:(id)arg1;");
			%orig;
			if (!enabled) return;

			NCNotificationRequest *notif = arg1;
			NSString *bundleID = [notif sectionIdentifier];

			if (allEnabled || [SparkAppList doesIdentifier:kIdentifier andKey:@"kApps" containBundleIdentifier:bundleID]) {
				Log([NSString stringWithFormat:@"New notification from: %@", bundleID]);
				UpdateLives();
			}

		}
	%end

%end


//	=========================== Constructor stuff ===========================

%ctor {
	preferences = [[HBPreferences alloc] initWithIdentifier:kIdentifier];

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

	%init(Hooks);

	//	Wait a few seconds to start watching for new notifications in case of old notifications from before respring
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, startupDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		%init(DelayedHooks);
	});
}
