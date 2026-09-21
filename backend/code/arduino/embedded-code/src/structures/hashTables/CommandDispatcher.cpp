#include "structures/CommandDispatcher.hpp"
#include "controller/ArduinoController.hpp"
#include "Endpoints.hpp"
#include "packet/Packet.hpp"
#include "endpoints/EndpointService.hpp"

template<typename T>
Result CommandDispatcher::_invokeEndpoint(void* object, Result (T::*method)(const uint16_t*, uint8_t), const uint16_t* args, uint8_t count)
{
    T* typedObject = static_cast<T*>(object); // we convert using the object pointer stored in endpoint struct to the correct type, then we can call the function

    return (typedObject->*method)(args, count);
}

/**
 * Setups 
 * store object + handler together
 */
template <typename T>
void CommandDispatcher::registerEndpoint(const uint16_t command, T& object, Result (T::*handler)(const uint16_t*, uint8_t))
{
    Endpoint* endpoint = new TypedEndpoint<T>
    {
        &object,
        handler
    };

    this->insert(command, endpoint);
}

/**
 * This is where endpoints are mapped to binary commands.
 */
void CommandDispatcher::setup(EndpointService& endpoints)
{
    registerEndpoint(RED_LED_POWER, endpoints, &EndpointService::redLedPower);
    registerEndpoint(ONBOARD_LED_POWER, endpoints, &EndpointService::onboardLedPower);
    registerEndpoint(GREEN_LED_FLASH, endpoints, &EndpointService::yes);
    registerEndpoint(RED_LED_FLASH, endpoints, &EndpointService::no);
}

/**
 * Function that hashes the key to generate the key/values
 * place inside the hash table.
 */
size_t CommandDispatcher::_hash(const uint16_t& key) const
{
    return key % size;
}

/**
 * This is the function used in main program loop to find correct endpoint
 * and run the function.
 */
Result CommandDispatcher::dispatch(ParsedPacket* packet)
{
    Endpoint* endpoint = this->getValue(packet->command);
    if (endpoint == nullptr)
    {
        // do something proper to return bad result
        return Result(false);
    }

    return endpoint->invoke(packet->args, packet->count); // runs member function and returns a Result object
}