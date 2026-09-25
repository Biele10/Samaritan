#pragma once
#include "structures/HashTable.hpp"
#include "output/Result.hpp"
#include "hardware-components/Hardware.hpp"

class Led: public Hardware
{
    public:
        using Hardware::Hardware; // inherit constructor from hardware

        Result flash(uint16_t* args, uint8_t count);
        void update() override;
};