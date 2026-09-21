#include "Arduino.h"
#include "hardware-components/HC.hpp"

HC::HC(const uint8_t hcClockPin, const uint8_t hcDataPin, const uint8_t hcLatchPin, const uint8_t hcMaxIndex) : 
_clockPin(hcClockPin), _dataPin(hcDataPin), _latchPin(hcLatchPin), _maxIndex(hcMaxIndex) {}

/**
 * Updates a bit on the class and on the register instantly.
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

    this->_updateShiftRegister(); // updates register instantly, no waiting for update
    return true;
}

/**
 * Updates a bit on the class, not on the actual chip itself.
 * This change will get pushed to actual chip once updateShiftRegister
 * is run.
 */
bool HC::logicAdjustBit(const uint8_t& bitIndex, const bool state)
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

    this->setDirty(true);
    return true;
}

/**
 * Updates the register and releases the latch to
 * update the current bits.
 */
void HC::_updateShiftRegister()
{
    uint8_t lp = this->getLatchPin();
    digitalWrite(lp, LOW);
    shiftOut(this->getDataPin(), this->getClockPin(), LSBFIRST, this->getByte());
    digitalWrite(lp, HIGH);
}

/**
 * Validates whether an index being updated is within 
 * boundaries of chip or not.
 */
bool HC::isValidIndex(const uint8_t& index)
{
    return index <= this->_maxIndex;
}

void HC::update()
{
    this->_updateShiftRegister();
}

uint8_t HC::getDataPin() { return this->_dataPin; }
uint8_t HC::getClockPin() { return this->_clockPin; }
uint8_t HC::getLatchPin() { return this->_latchPin; }
uint8_t HC::getMaxIndex() { return this->_maxIndex; }
byte    HC::getByte() { return this->_byte; }