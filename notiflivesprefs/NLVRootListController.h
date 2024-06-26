#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <AudioToolbox/AudioServices.h>
#import <SpringBoardServices/SBSRestartRenderServerAction.h>
#import <FrontBoardServices/FBSSystemService.h>
#import <Preferences/PreferencesAppController.h>
#import <rootless.h>
#import "Globals.h"

#define TWEAK_NAME @"NotifLives"
#define BUNDLE [NSString stringWithFormat:@"com.wrp1002.%@", [TWEAK_NAME lowercaseString]]
#define BUNDLE_NOTIFY "com.wrp1002.notiflives/ReloadPrefs"

@interface PSListController (iOS12Plus)
-(BOOL)containsSpecifier:(PSSpecifier *)arg1;
@end

@interface NLVRootListController : PSListController
	@property (nonatomic, retain) NSMutableDictionary *savedSpecifiers;
	-(UIWindow*) GetKeyWindow;
@end
