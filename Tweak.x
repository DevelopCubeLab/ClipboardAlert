#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *localizedString(NSString *key) {
    NSString *language = [[NSLocale preferredLanguages].firstObject lowercaseString];
    BOOL isChinese = [language hasPrefix:@"zh"];
    NSDictionary *en = @{
        @"ClipboardAccessTitle": @"Clipboard Access Reminder",
        @"ClipboardAccessMessage": @"This app requests access to clipboard content\n",
        @"Remember": @"Don't remind me again",
        @"Allow": @"Allow Paste",
        @"Deny": @"Deny Paste"
    };
    NSDictionary *zh = @{
        @"ClipboardAccessTitle": @"剪贴板访问提醒",
        @"ClipboardAccessMessage": @"此 App 请求访问剪贴板内容\n",
        @"Remember": @"本次启动不再提示",
        @"Allow": @"允许粘贴",
        @"Deny": @"不允许粘贴"
    };
    if (isChinese) {
        return zh[key] ?: key;
    } else {
        return en[key] ?: key;
    }
}

@interface _UIConcretePasteboard : UIPasteboard
@end

static BOOL gClipboardAllowed = NO;
static BOOL gClipboardRememberForSession = NO;
static BOOL gCheckboxSelected = NO;

static UIButton *gCheckboxButton = nil;
static void (^gUpdateCheckboxUI)(void) = nil;

static id handleClipboardAccess(id (^origBlock)(void), id emptyValue) {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *pbName = [pasteboard valueForKey:@"name"];
    if ([pbName isEqual:UIPasteboardNameGeneral]) {
        if (gClipboardRememberForSession) {
            return gClipboardAllowed ? origBlock() : emptyValue;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:localizedString(@"ClipboardAccessTitle")
                                                                           message:localizedString(@"ClipboardAccessMessage")
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            
            UIViewController *contentVC = [[UIViewController alloc] init];
            UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 50)];
            UIButton *checkboxButton = [UIButton buttonWithType:UIButtonTypeSystem];
            checkboxButton.frame = CGRectMake(0, 0, 270, 50);
            gCheckboxButton = checkboxButton;

            gUpdateCheckboxUI = ^{
                if (@available(iOS 13.0, *)) {
                    UIImage *image = [UIImage systemImageNamed:(gCheckboxSelected ? @"checkmark.circle.fill" : @"circle")];
                    [gCheckboxButton setImage:image forState:UIControlStateNormal];
                    [gCheckboxButton setTitle:localizedString(@"Remember") forState:UIControlStateNormal];
                    gCheckboxButton.tintColor = [UIColor systemBlueColor];
                    gCheckboxButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                    gCheckboxButton.titleLabel.font = [UIFont systemFontOfSize:15];
                } else {
                    NSString *title = gCheckboxSelected ? [@"☑️" stringByAppendingString:localizedString(@"Remember")] : [@"⬜️" stringByAppendingString:localizedString(@"Remember")];
                    [gCheckboxButton setTitle:title forState:UIControlStateNormal];
                    [gCheckboxButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    gCheckboxButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                    gCheckboxButton.titleLabel.font = [UIFont systemFontOfSize:15];
                    [gCheckboxButton setImage:nil forState:UIControlStateNormal];
                }
            };
            if (gUpdateCheckboxUI) gUpdateCheckboxUI();

            [gCheckboxButton addTarget:pasteboard action:@selector(toggleCheckbox:) forControlEvents:UIControlEventTouchUpInside];
            [containerView addSubview:checkboxButton];
            contentVC.view = containerView;

            [alert setValue:contentVC forKey:@"contentViewController"];

            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:localizedString(@"Allow")
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * _Nonnull action) {
                gClipboardAllowed = YES;
                gClipboardRememberForSession = gCheckboxSelected;
            }];
            UIAlertAction *denyAction = [UIAlertAction actionWithTitle:localizedString(@"Deny")
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction * _Nonnull action) {
                gClipboardAllowed = NO;
                gClipboardRememberForSession = gCheckboxSelected;
            }];
            [alert addAction:confirmAction];
            [alert addAction:denyAction];

            UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
            UIViewController *vc = window.rootViewController;
            while (vc.presentedViewController) {
                vc = vc.presentedViewController;
            }
            [vc presentViewController:alert animated:YES completion:nil];
        });

        return emptyValue; // 在用户选择前返回空或空数组
    }
    return origBlock();
}

%hook _UIConcretePasteboard

- (NSString *)string {
    return handleClipboardAccess(^id{
        return %orig;
    }, @"");
}

- (UIImage *)image {
    return handleClipboardAccess(^id{
        return %orig;
    }, nil);
}

- (NSURL *)URL {
    return handleClipboardAccess(^id{
        return %orig;
    }, nil);
}

- (NSArray<NSURL *> *)URLs {
    return handleClipboardAccess(^id{
        return %orig;
    }, @[]);
}

%new
- (void)toggleCheckbox:(UIButton *)sender {
    extern BOOL gCheckboxSelected;
    gCheckboxSelected = !gCheckboxSelected;
    if (gUpdateCheckboxUI) gUpdateCheckboxUI();
}

%end
