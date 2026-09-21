#pragma once
#include "structures/HashTable.hpp"
#include "controller/ArduinoController.hpp"
#include "Endpoints.hpp"
#include "packet/Packet.hpp"

// Key = 2 byte HEX (uint16_t), Value = Function Reference
// Used for generic storing of data inside program

class CommandDispatcher : public HashTable<uint16_t, Endpoint*>
{
    public:
        void setup(ArduinoController& ac); // function that is run at startup to load all endpoints into the hashtable
        template<typename T>
        void registerEndpoint(const uint16_t command, T& object, Result (T::*handler)(uint16_t*, uint8_t));
        Result dispatch(ParsedPacket* packet);

    private:
        size_t _hash(const uint16_t& key) const override;
        
        template<typename T>
        Result _invokeEndpoint(void* object, Result (T::*method)(uint16_t*, uint8_t), uint16_t* args, uint8_t count);
};