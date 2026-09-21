#include <Arduino.h>
#include "hardware-components/OnboardLed.hpp"
#include "output/Result.hpp"
#include "structures/HashTable.hpp"
#include "config/config.hpp"

OnboardLed::OnboardLed(bool initialState) : _state(initialState) {};

Result OnboardLed::power(uint16_t* args, uint8_t count)
{
    if ((this->_state) == false)
    {
        digitalWrite(LED_BUILTIN, HIGH);
    }

    else if ((this->_state) == true)
    {
        digitalWrite(LED_BUILTIN, LOW);
    }

    this->_state = !(this->_state);
    return Result::Success("Changed state of onboard LED.");
}