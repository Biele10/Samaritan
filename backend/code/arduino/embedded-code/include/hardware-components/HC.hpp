#pragma once
#include "Arduino.h"
#include "config/config.hpp"
#include "hardware-components/Hardware.hpp"

// this is the class for the 74HC595 component, allows for multiple pins to be adjusted by just one

class HC : public Hardware
{
    private:

        const uint8_t _dataPin;
        const uint8_t _clockPin;
        const uint8_t _latchPin;
        const uint8_t _maxIndex; // max index of any of the pins in the chip we can alter (0 -> 7)

        byte _byte = 0b00000000; // each bit will represent a pin in the chip, this will maintain a copy of what is on the chip
    
    public:

        HC(const uint8_t dataPin, const uint8_t clockPin, const uint8_t latchPin, const uint8_t maxIndex);
        bool isValidIndex(const uint8_t& index);
        bool adjustBit(const uint8_t& bitIndex, const bool state);
};