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
        virtual ~Hardware();
        virtual void update();
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

Hardware::~Hardware() {}

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
        digitalWrite(this->getArduinoPin(), HIGH);
    }

    else if (state == true)
    {
        digitalWrite(this->getArduinoPin(), LOW);
    }

    this->setState(state);
    return true;
}

bool Hardware::logicPower()
{
    this->logicPower(!this->getState());
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

/**
 * Function that gets the pin currently in use,
 * should really only be used in situations where only ONE pin is being used.
 */
uint8_t Hardware::getPin()
{
    uint8_t arduinoPin = this->getArduinoPin();
    uint8_t hcPin = this->getHcPin();
    if (hcPin == NO_PIN && arduinoPin != NO_PIN)
    {
        return arduinoPin;
    }

    if (arduinoPin == NO_PIN && hcPin != NO_PIN)
    {
        return hcPin;
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

void Hardware::update() {}