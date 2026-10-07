#include <stdint.h>

void i2c_start();
void i2c_stop();
void i2c_send(uint8_t byte);

int main() {
    i2c_start();
    i2c_send(0xA0); // device address (write)
    i2c_send(0x00); // register
    i2c_send(0x42); // data
    i2c_stop();
    return 0;
}
