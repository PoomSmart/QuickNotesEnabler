#import <theos/IOSMacros.h>

extern bool _os_feature_enabled_impl(const char *domain, const char *feature);

%hookf(bool, _os_feature_enabled_impl, const char *domain, const char *feature) {
    return !strcmp(domain, "PencilAndPaper") && !strcmp(feature, "SystemNoteTaking") ? true : %orig;
}

%group ControlCenter

%hook CCSModuleMetadata

+ (NSSet *)_requiredCapabilitiesForInfoDictionary:(id)infoDict {
    NSSet *set = %orig;
    if ([set containsObject:@"QuickNoteCapability"]) {
        NSMutableSet *mutableSet = [set mutableCopy];
        [mutableSet removeObject:@"QuickNoteCapability"];
        return mutableSet.copy;
    }
    return set;
}

// + (NSSet *)_supportedDeviceFamiliesForBundleInfoDictionary:(id)infoDict {
//     NSSet *set = %orig;
//     if (set.count == 1 && [set containsObject:@(2)] && [infoDict[@"CFBundleIdentifier"] isEqualToString:@"com.apple.mobilenotes.SystemPaperControlCenterModule"]) {
//         return [NSSet setWithArray:@[@(1), @(2)]];
//     }
//     return set;
// }

%end

%end

static void initControlCenterHooks() {
    %init(ControlCenter);
}

%hook SYFeatureEligibility

+ (BOOL)supportsQuickNote {
    return YES;
}

%end

static void bundleLoaded(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSBundle* bundle = (__bridge NSBundle*)(object);
	if ([bundle.bundleIdentifier isEqualToString:@"com.apple.ControlCenterServices"]) {
		initControlCenterHooks();
	}
}

%ctor {
    if (IN_SPRINGBOARD) {
        %init;
        initControlCenterHooks();
    } else {
        CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, bundleLoaded, (CFStringRef)NSBundleDidLoadNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    }
}
