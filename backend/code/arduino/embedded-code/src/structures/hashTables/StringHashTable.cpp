#include "structures/StringHashTable.hpp"

/**
 * Function that hashes the key to generate the key/values
 * place inside the hash table.
 */
size_t StringHashTable::_hash(const String& key) const
{
    size_t hashKey = 0;
    for (size_t i=0; i < key.length(); i++)
    {
        hashKey = (hashKey * 31 + key[i]);
    }

    return hashKey % size;
}