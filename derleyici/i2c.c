#include <stdint.h>
#include <sys/types.h>


#define SCL 0x4000000
#define SDA 0x4000004

#define SCL_WRITE(v)  (*((volatile uint32_t *)SCL) = (v))
#define SDA_WRITE(v)  (*((volatile uint32_t *)SDA) = (v))

void i2c_setup();
void i2c_start();
void i2c_stop();
void i2c_send(uint8_t byte);
static void delay_ns(uint32_t n);


#define count 100 // salladım


//delayleri random atacam böyle bitbanging.space'te böyle yapmış

// siteden baktım bu düzene. kötü duruyo da
void i2c_start(){
	SDA_WRITE(1);
	delay_ns(count);
	SCL_WRITE(1);
	delay_ns(count);
	SDA_WRITE(0);
	delay_ns(count);
	SCL_WRITE(0);
	delay_ns(count);

}

void i2c_stop(){
	SDA_WRITE(0);
	delay_ns(count);
	SCL_WRITE(1);
	delay_ns(count);
	SDA_WRITE(1);
	delay_ns(count);

}

void i2c_send(uint8_t byte) {

	for (int i = 0; i < 8; i++) {
		(byte & 0b10000000) ? SDA_WRITE(1) : SDA_WRITE(0);
		byte <<= 1;
		delay_ns(count);
		SCL_WRITE(1);
		delay_ns(count);
		SCL_WRITE(0);
		delay_ns(count);
	}

	SDA_WRITE(1);
	SCL_WRITE(1);
	delay_ns(count);
	SCL_WRITE(0);

}




static void delay_ns(uint32_t n) {
    for (uint32_t i = 0; i < count; i++)
        __asm__ volatile ("nop");
}
