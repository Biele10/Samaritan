#include <Arduino.h>
#include "hardware-components/Hardware.hpp"
#include "hardware-components/Led.hpp"
#include "output/Result.hpp"
#include "structures/HashTable.hpp"
#include "config/config.hpp"
#include "hardware-components/HC.hpp"

/**
 * Function that flashes the LED for a given period of time.
 * 
 * args:
 * [0] - Time in ms to flash LED for.
 */
Result Led::flash(uint16_t* args, uint8_t count)
{
    uint16_t flashTime = 2000; // 2 seconds default
    uint8_t ardPin = this->getArduinoPin();
    if (count != 0)
    {
        flashTime = args[0];
    }

    if ((this->getState()) == false)
    {
        this->setState(true);
        digitalWrite(ardPin, HIGH);
    }

    delay(flashTime);                              // TEMP THIS IS ONYL FOR TESTING DO NOT ACTUALLY USE THIS THIS BLOCKS WHOLE EVENT LOOP
    digitalWrite(ardPin, LOW);
    
    this->setState(false);
    return Result::Success("Flashed the LED");
}

/**
 * Updates all physical aspects of the LED.
 * This is called at the end of a process loop.
 */
void Led::update()
{
    Hardware::power(this->getState());
}