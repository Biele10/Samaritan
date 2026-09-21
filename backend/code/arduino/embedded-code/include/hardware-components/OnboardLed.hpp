#pragma once
#include "structures/HashTable.hpp"
#include "output/Result.hpp"
#include "hardware-components/Hardware.hpp"

class OnboardLed : public Hardware
{
    public:
        OnboardLed(bool initialState = false);
};