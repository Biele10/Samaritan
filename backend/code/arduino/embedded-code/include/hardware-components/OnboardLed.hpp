#pragma once
#include "structures/HashTable.hpp"
#include "output/Result.hpp"
#include "hardware-components/Hardware.hpp"

class OnboardLed : public Hardware
{
    public:
        using Hardware::Hardware;

        bool power();
        bool power(const bool state);
};