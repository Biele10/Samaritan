#pragma once
#include "config/config.hpp"
#include "utilities/memory.hpp"

// This is the Samaritan array class which allows users to store same datatype values in simple arrays which can contain a mixture of pointers + copies
// This is also designed to be semi-dynamic, if a user attempts to add another item to the array and the base array is full, it will automatically create
// a new copy and create more space than the previous one

template<typename x>
class Array
{
    private:
        size_t _capacity; // can hold max 65,535 items
        size_t _arraySize; // how many items are currently in the array
        struct item
        {
            x* value = nullptr;
            bool owns = false; // allows array to be flexible, users can either store copies or references, this tells us whether array owns object being pointed to
        };
        
        item* _internalArray; // creates array with base size of 10 of x datatype

        /**
         * Calls function to calculate if there is enough RAM space.
         */
        bool _canBeAdded()
        {
            // checks there is enough RAM space before creating larger array, also has to account for current array that is in memory as well when being copied over
            return isEnoughMemory(((sizeof(item) * (this->_capacity)) + (sizeof(item) * (this->_capacity + Config::DEFAULT_ARRAY_ADDITION))));
        }

        /**
         * If array needs expanding, a new one is created with a larger capacity 
         * and values from previous array are copied over and original array is deleted.
         * 
         * TRUE = Expanded | FALSE = Could not expand further
         */
        bool _expandArray()
        {
            if (!_canBeAdded()) return false;
            item* expandedArray = new item[this->_capacity + Config::DEFAULT_ARRAY_ADDITION];
            
            for (size_t i=0; i < this->_capacity; i++)
            {
                expandedArray[i] = this->_internalArray[i];
            }

            delete[] this->_internalArray;
            this->_capacity += Config::DEFAULT_ARRAY_ADDITION;
            this->_internalArray = expandedArray;

            return true;
        }

        /**
         * Keeps count of size of array.
         */
        void _incrementArraySize()
        {
            this->_arraySize++;
        }

    public:
        Array(size_t size = Config::BASE_ARRAY_SIZE) : _capacity(size), _arraySize(0)
        {
            this->_internalArray = new item[this->_capacity];
        }

        /**
         * So we can check if array cannot be expanded, we use this function
         * to get the flag.
         */
        bool isFull()
        {
            return this->_arraySize >= this->_capacity;
        }

        void add(x value)
        {
            if (this->_arraySize >= this->_capacity)
            {
                if (!this->_expandArray()) return;
            }

            x* newValue = new x(value);
            this->_internalArray[this->_arraySize] = item {newValue, true};
            this->_incrementArraySize();
        }

        void addByPointer(x* pValue)
        {
            if (this->_arraySize >= this->_capacity)
            {
                if (!this->_expandArray()) return;
            }

            this->_internalArray[this->_arraySize] = item {pValue, false};
            this->_incrementArraySize();
        }

        x* get(const size_t index)
        {
            return (index < this->_arraySize) ? this->_internalArray[index].value : nullptr;
        }

        ~Array()
        {
            for (size_t i = 0; i < _arraySize; i++)
            {
                if (_internalArray[i].owns)
                {
                    delete _internalArray[i].value; // only delete values that belong to array
                }
            }

            delete[] _internalArray;
        }
};
