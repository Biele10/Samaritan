#pragma once
#include "structures/HashTable.hpp"
#include "output/Result.hpp"
#include "hardware-components/Hardware.hpp"

class Led: public Hardware
{
    public:
        Led(const uint8_t arduinoPin, const uint8_t hcPin = NO_PIN, bool state = false);
        Result power(uint16_t* args, uint8_t count);
        Result flash(uint16_t* args, uint8_t count);
        void update() override;

    private:
        bool _state; // represents whether the LED is on or off
        Result _on();
        Result _off();
};