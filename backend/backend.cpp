#include "Generator/generator.h"
#include "../midend/IR/IRGraph.h"

void backend(RawProgramme *& programme)
{
    generateASM(programme);
}