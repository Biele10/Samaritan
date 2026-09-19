#include "Arduino.h"
#include "hardware-components/HC.hpp"

HC::HC(const uint8_t hcClockPin, const uint8_t hcDataPin, const uint8_t hcLatchPin, const uint8_t hcMaxIndex) : 
_clockPin(hcClockPin), _dataPin(hcDataPin), _latchPin(hcLatchPin), _maxIndex(hcMaxIndex) {}


/**
 * Validates whether an index being updated is within 
 * boundaries of chip or not.
 */
bool HC::isValidIndex(const uint8_t& index)
{
    return index > this->_maxIndex;
}

/**
 * Writes a 1 or a 0 to a bit.
 */
bool HC::adjustBit(const uint8_t& bitIndex, const bool state)
{
    if (!this->isValidIndex(bitIndex)) return false;
    if (state)
    {
        bitSet(this->_byte, bitIndex);
    }
    else
    {
        bitClear(this->_byte, bitIndex);
    }

    return true;
}