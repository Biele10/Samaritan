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
Result Led::flash(const uint16_t* args, uint8_t count)
{
    this->_flashDuration = 2000;
    if (count > 0)
    {
        _flashDuration = args[0];
    }

    this->_flashStart = millis();

    this->setState(true);
    this->setDirty(true);

    return Result::Success("Flashing the LED");
}

/**
 * Updates all physical aspects of the LED.
 * This is called at the end of a process loop.
 */
void Led::update()
{
    Hardware::power(this->getState());
}

/**
 * Process all aspects of the LED that needs constant processing.
 */
void Led::process()
{
    if (this->_flashDuration == 0)
    {
        return;
    }

    if (millis() - this->_flashStart >= this->_flashDuration)
    {
        this->_flashDuration = 0;

        this->setState(false);
        this->setDirty(true);
    }
}