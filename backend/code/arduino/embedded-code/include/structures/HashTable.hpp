#pragma once

#include <Arduino.h>
#include "config/config.hpp"

// allows us to define the types at runtime, can be used for generic string storing + binary command dispatcher.
template<typename K, typename V>
class HashTable
{
    private:
        struct entry
        {
            K key;
            V value;
            entry* nextEntry;
        };

        entry** _initializeHashTable(size_t size) const;
        entry* _createEntry(const K& key, const V& value);

    protected:

        virtual size_t _hash(const K& key) const = 0; // each class must implement this itself, hash functions differ depending on datatype

    public:
        entry** ht;
        const size_t size;

        void insert(const K& key, const V& value);
        entry* get(const K& key);
        V getValue(const K& key);
        entry* getByIndex(const size_t index);

        ~HashTable();

        HashTable(size_t size = Config::BASE_HASH_TABLE_SIZE);
};


/**
 * Constructor that initializes all values.
 */
template<typename K, typename V>
HashTable<K, V>::HashTable(size_t size)
    : ht(_initializeHashTable(size)), size(size)
{}


/**
 * Creates the hash table array and safely initializes all values to nullptr.
 */
template<typename K, typename V>
typename HashTable<K, V>::entry**
HashTable<K, V>::_initializeHashTable(size_t size) const
{
    return new entry*[size](); // safely creates fixed array and initializes all values to nullptr
}


template<typename K, typename V>
typename HashTable<K, V>::entry*
HashTable<K, V>::_createEntry(const K& key, const V& value)
{
    entry* e = new entry;

    e->key = key;
    e->value = value;
    e->nextEntry = nullptr;

    return e;
}


/**
 * Deconstructor that clears up all memory being
 * used by the class.
 */
template<typename K, typename V>
HashTable<K, V>::~HashTable()
{
    for (size_t i = 0; i < size; i++)
    {
        entry* current = ht[i];

        while (current != nullptr)
        {
            entry* next = current->nextEntry;

            delete current;

            current = next;
        }
    }

    delete[] ht;
}


template<typename K, typename V>
void HashTable<K, V>::insert(const K& key, const V& value)
{
    const size_t hashKey = this->hash(key);

    if (this->ht[hashKey] == nullptr) // no other key stored here
    {
        this->ht[hashKey] = _createEntry(key, value);
        return;
    }

    // another value already stored there, loop through linked list to find next empty node
    entry* next = this->ht[hashKey];

    while (next != nullptr)
    {
        if (next->key == key)
        {
            next->value = value; // if keys match, value is just overwritten
            return;
        }

        if (next->nextEntry == nullptr)
        {
            next->nextEntry = _createEntry(key, value); // assigns the newly created entry
            return;
        }

        next = next->nextEntry;
    }
}


template<typename K, typename V>
typename HashTable<K, V>::entry*
HashTable<K, V>::get(const K& key)
{
    const size_t hashKey = this->hash(key);

    entry* fetchedEntry = this->ht[hashKey];

    while (fetchedEntry != nullptr && fetchedEntry->key != key)
    {
        fetchedEntry = fetchedEntry->nextEntry;
    }

    return fetchedEntry; // if found, found entry returned, if not nullptr returned
}


template<typename K, typename V>
V HashTable<K, V>::getValue(const K& key)
{
    entry* e = this->get(key);

    if (e == nullptr)
    {
        return nullptr; // indicates that key/value-pair does not exist
    }

    return e->value;
}


/**
 * Function that gets an item from the
 * hash table by a direct index number
 * rather than using a key.
 */
template<typename K, typename V>
typename HashTable<K, V>::entry*
HashTable<K, V>::getByIndex(const size_t index)
{
    if (index >= size)
    {
        return nullptr;
    }

    return this->ht[index]; // if value there, entry is returned if not nullptr is
}