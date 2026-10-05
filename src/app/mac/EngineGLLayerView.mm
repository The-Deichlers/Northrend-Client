#include "os/Input.hpp"
#include "os/Queue.hpp"
#include "app/mac/EngineGLLayerView.h"
#include "app/mac/MacClient.h"
#include "event/Input.hpp"
#include <Carbon/Carbon.h>

@implementation EngineGLLayerView

- (void)insertText:(id)string {
    NSString* text = [string isKindOfClass:[NSAttributedString class]] ? [string string] : string;
    for (NSUInteger index = 0; index < [text length]; ++index) {
        uint32_t character = [text characterAtIndex:index];
        if (character >= 0xD800 && character <= 0xDBFF && index + 1 < [text length]) {
            const uint32_t low = [text characterAtIndex:index + 1];
            if (low >= 0xDC00 && low <= 0xDFFF) {
                character = 0x10000 + ((character - 0xD800) << 10) + (low - 0xDC00);
                ++index;
            }
        }
        if (character >= 0x20 && character != 0x7F &&
            !(character >= 0xD800 && character <= 0xDFFF) &&
            !(character >= 0xF700 && character <= 0xF8FF))
            OsQueuePut(OS_INPUT_CHAR, character, 1, 0, 0);
    }
}

- (void)keyDown:(NSEvent*)event {
    uint32_t keyCode = event.keyCode;

    MacClient::CheckKeyboardLayout();

    if (keyCode <= 0x7F) {
        uint32_t key = MacClient::s_keyConversion[keyCode];

        if (key != KEY_NONE) {
            OsQueuePut(OS_INPUT_KEY_DOWN, key, 0, 0, 0);
        }
    }

    if (MacClient::GetTextInputEnabled()) {
        auto events = [NSArray arrayWithObject:event];
        [self interpretKeyEvents:events];
    } else {
        if (!(event.modifierFlags & (NSEventModifierFlagCommand | NSEventModifierFlagControl)))
            [self insertText:event.characters];
    }
}

@end
