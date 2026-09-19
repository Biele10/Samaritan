#include <Arduino.h>
#include "hardware-components/Hardware.hpp"
#include "hardware-components/Led.hpp"
#include "output/Result.hpp"
#include "structures/HashTable.hpp"
#include "config/config.hpp"

Led::Led(const uint8_t arduinoPin, const uint8_t hcPin, bool state) : Hardware(arduinoPin, hcPin, state) {};

/**
 * Function that turns the LED on or off, this
 * is only used via the website because the website does not
 * have a way of tracking the state of the LED.
 */
Result Led::power(uint16_t* args, uint8_t count)
{
    this->_state = !(this->_state);
    Hardware::power(); // call parent function to commit changes, component level just sets state
}

// The on and off functions are used internally for specific behaviour
// as current state of the LED can easily be tracked.

/**
 * Turns LED on.
 */
Result Led::_on()
{
    digitalWrite(this->_arduinoPin, HIGH);
    this->_state = !(this->_state);
    return Result::Success("Turned LED on.");
}

/**
 * Turns LED off.
 */
Result Led::_off()
{
    digitalWrite(_pin, LOW);
    this->_state = !(this->_state);
    return Result::Success("Turned LED off.");
}

/**
 * Function that flashes the LED for a given period of time.
 * 
 * args:
 * [0] - Time in ms to flash LED for.
 */
Result Led::flash(uint16_t* args, uint8_t count)
{
    uint16_t flashTime = 2000; // 2 seconds default
    if (count != 0)
    {
        flashTime = args[0];
    }

    if ((this->_state) == false)
    {
        this->_state = true;
        digitalWrite(_pin, HIGH);
    }

    delay(flashTime);                              // TEMP THIS IS ONYL FOR TESTING DO NOT ACTUALLY USE THIS THIS BLOCKS WHOLE EVENT LOOP
    digitalWrite(_pin, LOW);
    
    this->_state = false;
    return Result::Success("Flashed the LED");
}

/**
 * Updates all physical aspects of the LED.
 * This is called at the end of a process loop.
 */
void Led::update()
{
    if (this->_)
    if (this->_state == true)
    {
        
    }
}