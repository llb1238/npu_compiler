#include "../../midend/IR/IRGraph.h"
#include "../../midend/IR/IRBuilder.h"
#include "../../midend/IR/ValueKind.h"
#include "../../midend/IR/LibFunction.h"
#include "../../midend/AST/AST.h"
#include "../../midend/ValueTable/SignTable.h"
#include "../../midend/Optimizer/OptimizeMem2reg.h"
#include "../../midend/SSA/PHI.h"
#include "../../midend/SSA/rename.h"

void OptimizeMem2Reg(RawProgramme *& programme)
{
    AddPhi(programme);
    renameValue(programme);
}