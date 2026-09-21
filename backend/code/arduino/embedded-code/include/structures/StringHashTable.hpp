#pragma once
#include "structures/HashTable.hpp"

// Key = String, Value = String
// Used for generic storing of data inside program

class StringHashTable : public HashTable<String, String>
{
    private:
        size_t _hash(const String& key) const override;
};