#include <stdint.h>

#include "oled_driver/ssd1306.h"

void i2c_start();
void i2c_stop();
void i2c_send(uint8_t byte);



static void delay_clock(uint32_t n) {
    for (uint32_t i = 0; i < n; i++)
        __asm__ volatile ("nop");
}


int main() {

	SSD1306_Init (SSD1306_ADDR);                                    // 0x3C

	// DRAWING
	// -------------------------------------------------------------------------------------
	SSD1306_ClearScreen ();                                         // clear screen
	SSD1306_DrawLine (0, MAX_X, 4, 4);                              // draw line
	SSD1306_SetPosition (7, 1);                                     // set position
	SSD1306_DrawString ("Turi ip ip ip");                     // draw string
	SSD1306_DrawLine (0, MAX_X, 18, 18);                            // draw line
	SSD1306_SetPosition (40, 3);                                    // set position
	SSD1306_DrawString ("ip ip");                                // draw string
	SSD1306_SetPosition (53, 5);                                    // set position
	SSD1306_UpdateScreen (SSD1306_ADDR);                            // update

	delay_clock (1000);
	SSD1306_InverseScreen (SSD1306_ADDR);

	delay_clock (1000);
	SSD1306_NormalScreen (SSD1306_ADDR);


    return 0;
}
