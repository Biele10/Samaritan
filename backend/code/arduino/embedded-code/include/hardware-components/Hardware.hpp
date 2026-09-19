#pragma once
#include "Arduino.h"
#include "output/Result.hpp"
#include "config/config.hpp"

// This is our base class that all hardware will inherit from

class Hardware
{
    // add two pins, arduino pin and HC pin
    // getter functions etc
    private:
    
    protected:
        Hardware(const uint8_t arduinoPin = NO_PIN, const uint8_t hcPin = NO_PIN, bool state = false): _arduinoPin(arduinoPin), _hcPin(hcPin), _state(state) {};
        // some hardware is connected either via direct arudino pin or a chip pin, this allows us to know where to send signals
        const uint8_t _arduinoPin;
        const uint8_t _hcPin;
        bool _state; // is component on or off
        bool _isDirty; // if true, class update function will be run
        
    public:
        virtual ~Hardware() = 0;
        virtual void update() = 0; // must be defined
        void setDirty(bool state);
        void setState(bool state);
        bool getDirty();
        bool getState();
        virtual bool power();
        virtual bool power(bool state);
        virtual bool logicPower();
        virtual bool logicPower(bool state);
        uint8_t getPin();
        uint8_t getArduinoPin();
        uint8_t getHcPin();
};

void Hardware::setState(bool state)
{
    this->_state = state;
}

Hardware::~Hardware() = default; // destructor MUST be defined in child class

/**
 * Flips state of component.
 */
bool Hardware::power()
{
    return this->power(!this->_state);
}

/**
 * Function that turns a component on or off.
 */
bool Hardware::power(bool state)
{
    if (state == false)
    {
        digitalWrite(this->_arduinoPin, HIGH);
    }

    else if ((this->_state) == true)
    {
        digitalWrite(this->_arduinoPin, LOW);
    }

    this->_state = state;
    return true;
}

bool Hardware::logicPower()
{
    this->logicPower(!this->_state);
}

/**
 * If we want to only update hardware at end of event cycle
 * when update() functions are run, we use this to only update
 * the state logically, then when update() runs it will see change has
 * been made and update component accordingly.
 */
bool Hardware::logicPower(bool state)
{
    this->setState(state);
    this->setDirty(true);
    return true;
}

void Hardware::setDirty(bool state)
{
    this->_isDirty = state;
}

uint8_t Hardware::getPin()
{
    if (this->_hcPin == NO_PIN && this->_arduinoPin != NO_PIN)
    {
        return this->getArduinoPin();
    }

    if (this->_arduinoPin == NO_PIN && this->_hcPin != NO_PIN)
    {
        return this->getHcPin();
    }

    return static_cast<uint8_t>(NO_PIN);
}

uint8_t Hardware::getArduinoPin()
{
    return this->_arduinoPin;
}

uint8_t Hardware::getHcPin()
{
    return this->_hcPin;
}

bool Hardware::getDirty()
{
    return this->_isDirty;
}

bool Hardware::getState()
{
    return this->_state;
}