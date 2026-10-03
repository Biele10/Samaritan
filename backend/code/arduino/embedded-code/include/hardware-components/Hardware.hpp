#pragma once
#include "Arduino.h"
#include "output/Result.hpp"
#include "config/config.hpp"

class HC;

// This is our base class that all hardware will inherit from

class Hardware
{
    // add two pins, arduino pin and HC pin
    // getter functions etc
    private:
    
    protected:
        // some hardware is connected either via direct arudino pin or a chip pin, this allows us to know where to send signals
        const uint8_t _arduinoPin;
        const uint8_t _hcPin;
        bool _state; // is component on or off
        bool _isDirty; // if true, class update function will be run
        HC* _hc; // if component is attached to a chip, this can be used to make changes to it
        
    public:
        Hardware(const uint8_t arduinoPin = NO_PIN, const uint8_t hcPin = NO_PIN, bool state = false, HC* hc = nullptr): 
        _arduinoPin(arduinoPin), _hcPin(hcPin), _state(state), _isDirty(false), _hc(hc) {};
        virtual ~Hardware();
        virtual void update();
        virtual void process();
        void setDirty(bool state);
        void setState(bool state);
        virtual bool power();
        virtual bool power(bool state);
        virtual bool logicPower();
        virtual bool logicPower(bool state);

        uint8_t getPin();
        uint8_t getArduinoPin();
        uint8_t getHcPin();
        bool getDirty();
        bool getState();
};