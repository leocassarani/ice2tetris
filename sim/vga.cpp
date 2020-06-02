#include "vga.h"

VGA::VGA()
{
    pixels.assign(ScreenWidth * ScreenHeight, 0x0FFF);
}

void VGA::draw(uint16_t *dest)
{
    std::lock_guard<std::mutex> lock(pixels_mutex);
    std::copy(pixels.begin(), pixels.end(), dest);
}

void VGA::tick(uint8_t h_sync, uint8_t v_sync, uint8_t red, uint8_t green, uint8_t blue)
{
    h_count++;

    switch (h_state) {
        case ScanlineState::Visible:
            if (h_count == ScreenWidth) {
                h_state = ScanlineState::FrontPorch;
                v_count++;
            }
            break;
        case ScanlineState::FrontPorch:
            if (!h_sync) {
                h_state = ScanlineState::SyncPulse;
            }
            break;
        case ScanlineState::SyncPulse:
            if (h_sync) {
                h_state = ScanlineState::BackPorch;
                h_count = 0;
            }
            break;
        case ScanlineState::BackPorch:
            if (h_count == 48) {
                h_state = ScanlineState::Visible;
                h_count = 0;
            }
            break;
    }

    switch (v_state) {
        case ScanlineState::Visible:
            if (v_count == ScreenHeight) {
                v_state = ScanlineState::FrontPorch;
            }
            break;
        case ScanlineState::FrontPorch:
            if (!v_sync) {
                v_state = ScanlineState::SyncPulse;
            }
            break;
        case ScanlineState::SyncPulse:
            if (v_sync) {
                v_state = ScanlineState::BackPorch;
                v_count = 0;
            }
            break;
        case ScanlineState::BackPorch:
            if (v_count == 33) {
                v_state = ScanlineState::Visible;
                v_count = 0;
            }
            break;
    }

    if (h_visible() && v_visible()) {
        int i = h_count + v_count * ScreenWidth;
        std::lock_guard<std::mutex> lock(pixels_mutex);
        pixels[i] = red << 8 | green << 4 | blue;
        dirty = true;
    } else if (dirty && !v_visible()) {
        if (display) display();
        dirty = false;
    }
}
