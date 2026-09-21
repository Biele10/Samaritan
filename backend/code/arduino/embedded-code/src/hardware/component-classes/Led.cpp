#include <Arduino.h>
#include "hardware-components/Led.hpp"
#include "output/Result.hpp"
#include "structures/HashTable.hpp"
#include "config/config.hpp"

Led::Led(int pinNumber, bool initialState) : _pin(pinNumber), _state(initialState) {};

/**
 * Function that turns the LED on or off, this
 * is only used via the website because the website does not
 * have a way of tracking the state of the LED.
 */
Result Led::power(uint16_t* args, uint8_t count)
{
    if ((this->_state) == false)
    {
        digitalWrite(_pin, HIGH);
    }

    else if ((this->_state) == true)
    {
        digitalWrite(_pin, LOW);
    }

    this->_state = !(this->_state);
    return Result::Success("Changed state of the LED");
}

// The on and off functions are used internally for specific behaviour
// as current state of the LED can easily be tracked.

/**
 * Turns LED on.
 */
Result Led::_on()
{
    if ((this->_state) == false)             // these state checks are done to avoid unecessary digitalWrites
    {
        digitalWrite(_pin, HIGH);
    }

    this->_state = !(this->_state);
    return Result::Success("Turned LED on.");
}

/**
 * Turns LED off.
 */
Result Led::_off()
{
    if ((this->_state) == true)
    {
        digitalWrite(_pin, LOW);
    }

    this->_state = !(this->_state);
    return Result::Success("Turned LED off.");
}