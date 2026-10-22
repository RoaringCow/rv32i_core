#include <stdint.h>

#include "oled_driver/ssd1306.h"
#include "frames.h"

void i2c_start();
void i2c_stop();
void i2c_send(uint8_t byte);

static void delay_clock(uint32_t n) {
    for (uint32_t i = 0; i < n; i++)
        __asm__ volatile ("nop");
}

static void draw_frame(const uint32_t *frame) {
    SSD1306_ClearScreen();
    int i = 0;
    for (int y = 0; y < FRAME_H; y++) {
        int x = 0;
        for (int word = 0; word < 4; word++) {
            uint32_t w = frame[i++];
            uint32_t mask = 0x80000000;  // MSB 0b1000..00; soldan sağa taramaca.
            while (mask) {
                if (w & mask)
                    SSD1306_DrawPixel(x, y);
                x++;
                mask >>= 1;
            }
        }
    }
    SSD1306_UpdateScreen(SSD1306_ADDR);
}

int main() {

	/*
	int x = 0xdeadbeef;
	int y = x;

	while (1) {
		y++;
		x = y;
	}
 */

    SSD1306_Init(SSD1306_ADDR);

    while (1) {
        for (int f = 0; f < NUM_FRAMES; f++) {
            draw_frame(frames[f]);
            delay_clock(63000); // bu civarda bir şey. tam olmadı da
        }
    }

    return 0;
}
