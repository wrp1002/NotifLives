#line 1 "Tweak.x"
#import <Cephei/HBPreferences.h>
#import <AudioToolbox/AudioServices.h>
#import <objc/runtime.h>


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




BOOL enabled;
BOOL showNotifications;
NSInteger maxCount;
NSInteger saveInterval;
CGFloat delayTime;
NSString *soundFileName;
NSInteger count = 0;
NSInteger lives = 0;



int startupDelay = 10;
HBPreferences *preferences;



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


void ShowAlert(NSString *msg, NSString *title) {
	if (!springboardReady) return;

	UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:msg
                                 preferredStyle:UIAlertControllerStyleAlert];

    
    UIAlertAction* dismissButton = [UIAlertAction
                                actionWithTitle:@"Cool!"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    
									
                                }];

    
    [alert addAction:dismissButton];

    [GetKeyWindow().rootViewController presentViewController:alert animated:YES completion:nil];
}


void Log(NSString *msg) {
	NSLog(@"%@: %@", LogTweakName, msg);
}


void LogException(NSException *e) {
	NSLog(@"%@: NSException caught", LogTweakName);
	NSLog(@"%@: Name:%@", LogTweakName, e.name);
	NSLog(@"%@: Reason:%@", LogTweakName, e.reason);
	
}




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
			count--;	

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





#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class SBCCDoNotDisturbSetting; @class SpringBoard; @class NCNotificationMasterList; 


#line 145 "Tweak.x"
static void (*_logos_orig$Hooks$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$Hooks$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$Hooks$SBCCDoNotDisturbSetting$_setDNDEnabled$updateServer$source$)(_LOGOS_SELF_TYPE_NORMAL SBCCDoNotDisturbSetting* _LOGOS_SELF_CONST, SEL, BOOL, BOOL, unsigned long long); static void _logos_method$Hooks$SBCCDoNotDisturbSetting$_setDNDEnabled$updateServer$source$(_LOGOS_SELF_TYPE_NORMAL SBCCDoNotDisturbSetting* _LOGOS_SELF_CONST, SEL, BOOL, BOOL, unsigned long long); 

	

		
		static void _logos_method$Hooks$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id application) {
			_logos_orig$Hooks$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);

			Log([NSString stringWithFormat:@"============== %@ started ==============", LogTweakName]);


			springboardReady = true;
		}

	

	


	static void _logos_method$Hooks$SBCCDoNotDisturbSetting$_setDNDEnabled$updateServer$source$(_LOGOS_SELF_TYPE_NORMAL SBCCDoNotDisturbSetting* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL arg1, BOOL arg2, unsigned long long arg3) {
		Log([NSString stringWithFormat:@"Enabled:%d", arg1]);
		_logos_orig$Hooks$SBCCDoNotDisturbSetting$_setDNDEnabled$updateServer$source$(self, _cmd, arg1, arg2, arg3);
	}

	




static void (*_logos_orig$DelayedHooks$NCNotificationMasterList$insertNotificationRequest$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationMasterList* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$DelayedHooks$NCNotificationMasterList$insertNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationMasterList* _LOGOS_SELF_CONST, SEL, id); 

	
		static void _logos_method$DelayedHooks$NCNotificationMasterList$insertNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationMasterList* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
			_logos_orig$DelayedHooks$NCNotificationMasterList$insertNotificationRequest$(self, _cmd, arg1);
			Log(@"- (void)insertNotificationRequest:(id)arg1;");
			UpdateLives();
		}
	






static __attribute__((constructor)) void _logosLocalCtor_7fbd77b1(int __unused argc, char __unused **argv, char __unused **envp) {
	preferences = [[HBPreferences alloc] initWithIdentifier:kIdentifier];

	if ((NSString *)[preferences objectForKey:@"kSoundFile"] == nil)
		[preferences setObject:@"Powerup.wav" forKey:@"kSoundFile"];

    [preferences registerBool:&enabled default:YES forKey:@"kEnabled"];
	[preferences registerBool:&showNotifications default:YES forKey:@"kNotifications"];

	[preferences registerFloat:&delayTime default:1.0f forKey:@"kDelay"];

	[preferences registerInteger:&maxCount default:100 forKey:@"kMaxCount"];
	[preferences registerInteger:&saveInterval default:5 forKey:@"kSaveInterval"];
	lives = [preferences integerForKey:@"kLives" default:0];
	count = [preferences integerForKey:@"kCount" default:0];

	[preferences registerObject:&soundFileName default:@"Powerup.wav" forKey:@"kSoundFile"];

	{Class _logos_class$Hooks$SpringBoard = objc_getClass("SpringBoard"); { MSHookMessageEx(_logos_class$Hooks$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$Hooks$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$Hooks$SpringBoard$applicationDidFinishLaunching$);}Class _logos_class$Hooks$SBCCDoNotDisturbSetting = objc_getClass("SBCCDoNotDisturbSetting"); { MSHookMessageEx(_logos_class$Hooks$SBCCDoNotDisturbSetting, @selector(_setDNDEnabled:updateServer:source:), (IMP)&_logos_method$Hooks$SBCCDoNotDisturbSetting$_setDNDEnabled$updateServer$source$, (IMP*)&_logos_orig$Hooks$SBCCDoNotDisturbSetting$_setDNDEnabled$updateServer$source$);}}

	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, startupDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		{Class _logos_class$DelayedHooks$NCNotificationMasterList = objc_getClass("NCNotificationMasterList"); { MSHookMessageEx(_logos_class$DelayedHooks$NCNotificationMasterList, @selector(insertNotificationRequest:), (IMP)&_logos_method$DelayedHooks$NCNotificationMasterList$insertNotificationRequest$, (IMP*)&_logos_orig$DelayedHooks$NCNotificationMasterList$insertNotificationRequest$);}}
	});
}
