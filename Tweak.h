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