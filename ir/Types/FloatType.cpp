#include "FloatType.h"
#include "IntegerType.h"  // 需要的话加上，否则可以省略

FloatType::FloatType() : Type() {}  // 不要传参数，直接默认构造就行！

FloatType* FloatType::getTypeFloat()
{
    static FloatType* floatType = nullptr;
    if (floatType == nullptr) {
        floatType = new FloatType();
    }
    return floatType;
}

std::string FloatType::toString() const
{
    return "float";
}
