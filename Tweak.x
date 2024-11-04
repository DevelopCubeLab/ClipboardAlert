#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface ClipboardMonitor : NSObject
@end

@implementation ClipboardMonitor

// 显示提示框，询问用户是否允许读取剪贴板
- (void)showAlertWithCompletion:(void (^)(BOOL allow))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clipboard Access"
                                                                       message:@"This app wants to access your clipboard. Allow?"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // 添加 "允许" 按钮
        UIAlertAction *allowAction = [UIAlertAction actionWithTitle:@"Allow" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completion(YES); // 用户选择允许访问
        }];
        [alert addAction:allowAction];

        // 添加 "拒绝" 按钮
        UIAlertAction *denyAction = [UIAlertAction actionWithTitle:@"Deny" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completion(NO); // 用户选择拒绝访问
        }];
        [alert addAction:denyAction];

        // 获取当前的顶层视图控制器
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        UIViewController *topViewController = keyWindow.rootViewController;
        while (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        }

        // 使用 objc_msgSend 动态调用 presentViewController:animated:completion:
        ((void (*)(id, SEL, UIViewController *, BOOL, void (^)(void)))objc_msgSend)(topViewController, @selector(presentViewController:animated:completion:), alert, YES, nil);
    });
}

// Hook UIPasteboard 的读取方法

- (id)hookedPasteboardRead:(SEL)selector withOriginal:(id (^)(void))originalMethod {
    __block BOOL allow = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    // 显示提示框
    [self showAlertWithCompletion:^(BOOL userAllowed) {
        allow = userAllowed;
        dispatch_semaphore_signal(semaphore);
    }];

    // 等待用户选择
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (allow) {
        return originalMethod(); // 允许读取，调用原始方法
    } else {
        return nil; // 禁止读取，返回nil
    }
}

@end

// Hook UIPasteboard 的相关方法
%hook UIPasteboard

// Hook string 方法
- (NSString *)strings {
    __block NSString *clipboardContent = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clipboard Access"
                                                                       message:@"This app is trying to read your clipboard. Allow?"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // Allow action
        UIAlertAction *allowAction = [UIAlertAction actionWithTitle:@"Allow" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            clipboardContent = %orig;
            dispatch_semaphore_signal(sem);
        }];

        // Deny action
        UIAlertAction *denyAction = [UIAlertAction actionWithTitle:@"Deny" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            clipboardContent = nil;
            dispatch_semaphore_signal(sem);
        }];

        [alert addAction:allowAction];
        [alert addAction:denyAction];

        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return clipboardContent;
}

// Hook image 方法
- (UIImage *)image {
    return [[ClipboardMonitor new] hookedPasteboardRead:_cmd withOriginal:^UIImage *{
        return %orig;
    }];
}

// Hook dataForPasteboardType: 方法
- (NSData *)dataForPasteboardType:(NSString *)type {
    return [[ClipboardMonitor new] hookedPasteboardRead:_cmd withOriginal:^NSData *{
        return %orig(type);
    }];
}

%end

%ctor {
    // 初始化代码
    NSLog(@"[Clipboard Tweak] 插件加载成功");

    // 在主线程显示弹窗
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"插件加载成功"
                                                                       message:@"Clipboard Tweak 已成功注入。"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // 添加一个确定按钮
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];

        // 获取当前的顶层视图控制器
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        UIViewController *topViewController = keyWindow.rootViewController;
        while (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        }

        // 显示弹窗
        [topViewController presentViewController:alert animated:YES completion:nil];
    });
}

