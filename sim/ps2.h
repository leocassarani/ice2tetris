#ifndef PS2_H
#define PS2_H

#include <optional>
#include <unordered_map>
#include <SDL2/SDL_scancode.h>

struct PS2_Keycode {
    uint8_t code;
    bool extended;
};

const std::unordered_map<SDL_Scancode, PS2_Keycode> ps2_keycodes = {
    { SDL_SCANCODE_A, { 0x1C, false } },
    { SDL_SCANCODE_B, { 0x32, false } },
    { SDL_SCANCODE_C, { 0x21, false } },
    { SDL_SCANCODE_D, { 0x23, false } },
    { SDL_SCANCODE_E, { 0x24, false } },
    { SDL_SCANCODE_F, { 0x2B, false } },
    { SDL_SCANCODE_G, { 0x34, false } },
    { SDL_SCANCODE_H, { 0x33, false } },
    { SDL_SCANCODE_I, { 0x43, false } },
    { SDL_SCANCODE_J, { 0x3B, false } },
    { SDL_SCANCODE_K, { 0x42, false } },
    { SDL_SCANCODE_L, { 0x4B, false } },
    { SDL_SCANCODE_M, { 0x3A, false } },
    { SDL_SCANCODE_N, { 0x31, false } },
    { SDL_SCANCODE_O, { 0x44, false } },
    { SDL_SCANCODE_P, { 0x4D, false } },
    { SDL_SCANCODE_Q, { 0x15, false } },
    { SDL_SCANCODE_R, { 0x2D, false } },
    { SDL_SCANCODE_S, { 0x1B, false } },
    { SDL_SCANCODE_T, { 0x2C, false } },
    { SDL_SCANCODE_U, { 0x3C, false } },
    { SDL_SCANCODE_V, { 0x2A, false } },
    { SDL_SCANCODE_W, { 0x1D, false } },
    { SDL_SCANCODE_X, { 0x22, false } },
    { SDL_SCANCODE_Y, { 0x35, false } },
    { SDL_SCANCODE_Z, { 0x1A, false } },

    { SDL_SCANCODE_1, { 0x16, false } },
    { SDL_SCANCODE_2, { 0x1E, false } },
    { SDL_SCANCODE_3, { 0x26, false } },
    { SDL_SCANCODE_4, { 0x25, false } },
    { SDL_SCANCODE_5, { 0x2E, false } },
    { SDL_SCANCODE_6, { 0x36, false } },
    { SDL_SCANCODE_7, { 0x3D, false } },
    { SDL_SCANCODE_8, { 0x3E, false } },
    { SDL_SCANCODE_9, { 0x46, false } },
    { SDL_SCANCODE_0, { 0x45, false } },

    { SDL_SCANCODE_RETURN,    { 0x5A, false } },
    { SDL_SCANCODE_ESCAPE,    { 0x76, false } },
    { SDL_SCANCODE_BACKSPACE, { 0x66, false } },
    { SDL_SCANCODE_TAB,       { 0x0D, false } },
    { SDL_SCANCODE_SPACE,     { 0x29, false } },

    { SDL_SCANCODE_MINUS,        { 0x4E, false } },
    { SDL_SCANCODE_EQUALS,       { 0x55, false } },
    { SDL_SCANCODE_LEFTBRACKET,  { 0x54, false } },
    { SDL_SCANCODE_RIGHTBRACKET, { 0x5B, false } },
    { SDL_SCANCODE_BACKSLASH,    { 0x5D, false } },
    { SDL_SCANCODE_SEMICOLON,    { 0x4C, false } },
    { SDL_SCANCODE_APOSTROPHE,   { 0x52, false } },
    { SDL_SCANCODE_GRAVE,        { 0x0E, false } },
    { SDL_SCANCODE_COMMA,        { 0x41, false } },
    { SDL_SCANCODE_PERIOD,       { 0x49, false } },
    { SDL_SCANCODE_SLASH,        { 0x4A, false } },

    { SDL_SCANCODE_CAPSLOCK, { 0x58, false } },

    { SDL_SCANCODE_F1,  { 0x05, false } },
    { SDL_SCANCODE_F2,  { 0x06, false } },
    { SDL_SCANCODE_F3,  { 0x04, false } },
    { SDL_SCANCODE_F4,  { 0x0C, false } },
    { SDL_SCANCODE_F5,  { 0x03, false } },
    { SDL_SCANCODE_F6,  { 0x0B, false } },
    { SDL_SCANCODE_F7,  { 0x83, false } },
    { SDL_SCANCODE_F8,  { 0x0A, false } },
    { SDL_SCANCODE_F9,  { 0x01, false } },
    { SDL_SCANCODE_F10, { 0x09, false } },
    { SDL_SCANCODE_F11, { 0x78, false } },
    { SDL_SCANCODE_F12, { 0x07, false } },

    { SDL_SCANCODE_INSERT,   { 0x70, true } },
    { SDL_SCANCODE_HOME,     { 0x6C, true } },
    { SDL_SCANCODE_PAGEUP,   { 0x7D, true } },
    { SDL_SCANCODE_DELETE,   { 0x71, true } },
    { SDL_SCANCODE_END,      { 0x69, true } },
    { SDL_SCANCODE_PAGEDOWN, { 0x7A, true } },
    { SDL_SCANCODE_RIGHT,    { 0x74, true } },
    { SDL_SCANCODE_LEFT,     { 0x6B, true } },
    { SDL_SCANCODE_DOWN,     { 0x72, true } },
    { SDL_SCANCODE_UP,       { 0x75, true } },

    { SDL_SCANCODE_LSHIFT, { 0x12, false } },
    { SDL_SCANCODE_RSHIFT, { 0x59, false } },
};

std::optional<PS2_Keycode> ps2_keycode(SDL_Scancode scancode)
{
    auto item = ps2_keycodes.find(scancode);

    if (item == ps2_keycodes.end())
        return std::nullopt;

    return std::make_optional(item->second);
}

inline uint8_t ps2_parity(uint8_t byte)
{
    // Calculate odd parity: return 1 if byte has an even number of high
    // bits, otherwise return 0.
    return __builtin_popcount(byte) & 1 ? 0 : 1;
}

#endif
