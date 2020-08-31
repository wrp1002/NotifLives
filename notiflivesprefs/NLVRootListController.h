#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Cephei/HBPreferences.h>
#import <AudioToolbox/AudioServices.h>
#import <spawn.h>
#import <objc/runtime.h>
#import <AppList/AppList.h>
#import <SparkAppList/SparkAppListTableViewController.h>

@interface PSListController (iOS12Plus)
-(BOOL)containsSpecifier:(PSSpecifier *)arg1;
@end

@interface NLVRootListController : PSListController
	@property (nonatomic, retain) NSMutableDictionary *savedSpecifiers;
@end
