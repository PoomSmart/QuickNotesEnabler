#import <MobileGestalt/MobileGestalt.h>
#import <theos/IOSMacros.h>
#import <PSHeader/Misc.h>

static BOOL PhoneTest() {
    return NO; // Make it return yes if you want to test on iPhone devices
}

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

+ (NSSet *)_supportedDeviceFamiliesForBundleInfoDictionary:(id)infoDict {
    NSSet *set = %orig;
    if (PhoneTest() && set.count == 1 && [set containsObject:@(2)] && [infoDict[@"CFBundleIdentifier"] isEqualToString:@"com.apple.mobilenotes.SystemPaperControlCenterModule"]) {
        return [NSSet setWithArray:@[@(1), @(2)]];
    }
    return set;
}

%end

%end

static void initControlCenterHooks() {
    %init(ControlCenter);
}

%group SpringBoard

%hook SYFeatureEligibility

+ (BOOL)supportsQuickNote {
    return YES;
}

%end

%end

%group Notes

%hook ICDeviceSupport

+ (BOOL)deviceSupportsSystemPaper {
    return YES;
}

%end

%end

static void initNotesHooks() {
    %init(Notes);
}

%group Phone

BOOL (*SBIsSystemNotesSupported)(void);
%hookf(BOOL, SBIsSystemNotesSupported) {
    return YES;
}

%end

static void bundleLoaded(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSBundle* bundle = (__bridge NSBundle*)(object);
    if ([bundle.bundleIdentifier isEqualToString:@"com.apple.ControlCenterServices"]) {
        initControlCenterHooks();
    }
    if ([bundle.bundleIdentifier isEqualToString:@"com.apple.NotesSettings"]) {
        initNotesHooks();
    }
}

%hookf(bool, MGGetBoolAnswer, CFStringRef question) {
    return CFStringEqual(question, CFSTR("QuickNoteCapability")) ? true : %orig;
}

%ctor {
    %init;
    if (IN_SPRINGBOARD) {
        %init(SpringBoard);
        if (PhoneTest()) {
            MSImageRef ref = MSGetImageByName("/System/Library/PrivateFrameworks/SpringBoard.framework/SpringBoard");
            SBIsSystemNotesSupported = (BOOL (*)(void))MSFindSymbol(ref, "_SBIsSystemNotesSupported");
            %init(Phone);
        }
        initControlCenterHooks();
    } else if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.Preferences"]) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, bundleLoaded, (CFStringRef)NSBundleDidLoadNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    } else if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.mobilenotes"]) {
        initNotesHooks();
    }
}
