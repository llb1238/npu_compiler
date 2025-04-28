#pragma once

#include "Type.h"

class FloatType : public Type {
public:
    FloatType();

    static FloatType* getTypeFloat();
    virtual std::string toString() const override;  
};
