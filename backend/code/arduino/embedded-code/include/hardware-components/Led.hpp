#pragma once
#include "structures/HashTable.hpp"
#include "output/Result.hpp"
#include "hardware-components/Hardware.hpp"

class Led: public Hardware
{
    private:

        unsigned long _flashStart = 0;
        unsigned long _flashDuration = 0;

    public:
        using Hardware::Hardware; // inherit constructor from hardware

        Result flash(const uint16_t* args, uint8_t count);
        void update() override;
        void process() override;
};