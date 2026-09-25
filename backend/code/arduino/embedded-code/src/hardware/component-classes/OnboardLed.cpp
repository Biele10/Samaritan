#include <Arduino.h>
#include "hardware-components/OnboardLed.hpp"
#include "output/Result.hpp"
#include "structures/HashTable.hpp"
#include "config/config.hpp"

bool OnboardLed::power()
{
    return this->power(!this->getState());
}

/**
 * Function that turns a component on or off.
 */
bool OnboardLed::power(const bool state)
{
    if (state == false)
    {
        digitalWrite(LED_BUILTIN, HIGH);
    }

    else if (state == true)
    {
        digitalWrite(LED_BUILTIN, LOW);
    }

    this->setState(state);
    return true;
}