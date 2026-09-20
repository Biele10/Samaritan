#include <Arduino.h>
#include "hardware-components/OnboardLed.hpp"
#include "output/Result.hpp"
#include "structures/HashTable.hpp"
#include "config/config.hpp"

OnboardLed::OnboardLed(bool initialState) : Hardware(NO_PIN, NO_PIN, initialState) {};

Result OnboardLed::power(uint16_t* args, uint8_t count)
{
    if ((this->getState()) == false)
    {
        digitalWrite(LED_BUILTIN, HIGH);
    }

    else if ((this->getState()) == true)
    {
        digitalWrite(LED_BUILTIN, LOW);
    }

    this->setState(!(this->getState()));
    return Result::Success("Changed state of onboard LED.");
}