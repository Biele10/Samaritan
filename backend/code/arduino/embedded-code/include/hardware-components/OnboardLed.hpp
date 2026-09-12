#pragma once
#include "structures/HashTable.hpp"
#include "output/Result.hpp"

class OnboardLed
{
    public:
        OnboardLed(bool initialState = false);
        Result power(uint16_t* args, uint8_t count);

    private:
        bool _state;     // represents whether the LED is on or off
};