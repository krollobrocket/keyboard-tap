#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

CGEventRef _Nullable eventCallback(CGEventTapProxy proxy, CGEventType eventType, CGEventRef event, void *userInfo)
{
    CGKeyCode keyCode = (CGKeyCode) CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags flags = CGEventGetFlags(event);
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

int main(int argc, char** argv)
{
  void* userInfo = nil;
  CGEventMask mask = CGEventMaskBit(kCGEventKeyDown);

  // Create a tap for keyboard events.
  CFMachPortRef tap = CGEventTapCreate(
      kCGHIDEventTap,
      kCGHeadInsertEventTap,
      kCGEventTapOptionListenOnly,
      mask,
      eventCallback,
      userInfo
  );
  CFRunLoopRef ref = CFRunLoopGetCurrent();
  CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0);
  CFRunLoopAddSource(ref, source, kCFRunLoopCommonModes);
  CGEventTapEnable(tap, true);

  // Run loop.
  CFRunLoopRun();

  // Cleanup our tap.
  CGEventTapEnable(tap, false);
  CFRunLoopRemoveSource(ref, source, kCFRunLoopCommonModes);
  CFRelease(source);
  CFRelease(tap);
}
