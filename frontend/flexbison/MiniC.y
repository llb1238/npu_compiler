%{
#include <cstdio>
#include <cstring>

// 词法分析头文件
#include "FlexLexer.h"

// bison生成的头文件
#include "BisonParser.h"

// 抽象语法树函数定义原型头文件
#include "AST.h"

#include "IntegerType.h"

// LR分析失败时所调用函数的原型声明
void yyerror(char * msg);

%}

// 联合体声明，用于后续终结符和非终结符号属性指定使用
%union {
    class ast_node * node;

    struct digit_int_attr integer_num;
    struct digit_real_attr float_num;
    struct var_id_attr var_id;
    struct type_attr type;
    int op_class;
};

// 文法的开始符号
%start  CompileUnit

// 指定文法的终结符号，<>可指定文法属性
// 对于单个字符的算符或者分隔符，在词法分析时可直返返回对应的ASCII码值，bison预留了255以内的值
// %token开始的符号称之为终结符，需要词法分析工具如flex识别后返回
// %type开始的符号称之为非终结符，需要通过文法产生式来定义
// %token或%type之后的<>括住的内容成为文法符号的属性，定义在前面的%union中的成员名字。
%token <integer_num> T_DIGIT
%token <var_id> T_ID
%token <type> T_INT

// 关键或保留字 一词一类 不需要赋予语义属性
%token T_RETURN T_IF T_ELSE T_WHILE T_BREAK T_CONTINUE

// 分隔符 一词一类 不需要赋予语义属性
%token T_SEMICOLON T_L_PAREN T_R_PAREN T_L_BRACE T_R_BRACE T_L_SQUARE T_R_SQUARE 

%token T_COMMA T_CONST

// 运算符
%token T_ASSIGN T_SUB T_ADD T_MUL T_DIV T_MOD T_LT T_LE T_GT T_GE T_EQ T_NEQ T_AND T_OR T_NOT

%token <float_num> T_FLOAT_LITERAL
%token <type> T_FLOAT


// 非终结符
// %type指定文法的非终结符号，<>可指定文法属性
%type <node> CompileUnit
%type <node> FuncDef
%type <node> Block
%type <node> BlockItemList
%type <node> BlockItem
%type <node> Statement
%type <node> Expr
%type <node> LVal
%type <node> VarDecl VarDeclExpr VarDef
%type <node> AddExp UnaryExp PrimaryExp
%type <node> MulExp
%type <node> RelExp
%type <node> EqExp
%type <node> LAndExp
%type <node> LOrExp
%type <node> Cond
%type <node> ConstExp
%type <node> ArrayDim
%type <node> InitVal
%type <node> InitValList
%type <node> ConstDecl
%type <node> ConstDef
%type <node> ConstInitVal
%type <node> ConstDefList
%type <node> ConstInitValList
%type <node> FormalParamList
%type <node> FormalParam
%type <node> FuncFParamArrayDim
%type <node> IFStmt
%type <node> RealParamList
%type <type> BasicType
%type <op_class> AddOp
%type <op_class> MulOp
%type <op_class> RelOp
%type <op_class> EqOp
%%

// 编译单元可包含若干个函数与全局变量定义。要在语义分析时检查main函数存在
// compileUnit: (funcDef | varDecl)* EOF;
// bison不支持闭包运算，为便于追加修改成左递归方式
// compileUnit: funcDef | varDecl | compileUnit funcDef | compileUnit varDecl
CompileUnit
    : FuncDef {
        $$ = create_contain_node(ast_operator_type::AST_OP_COMPILE_UNIT, $1);
        if (ast_root == nullptr) ast_root = $$;
    }
    | VarDecl {
        $$ = create_contain_node(ast_operator_type::AST_OP_COMPILE_UNIT, $1);
        if (ast_root == nullptr) ast_root = $$;
    }
    | ConstDecl {
        $$ = create_contain_node(ast_operator_type::AST_OP_COMPILE_UNIT, $1);
        if (ast_root == nullptr) ast_root = $$;
    }
    | CompileUnit FuncDef {
        $$ = $1->insert_son_node($2);
        // 这里不要改ast_root了！！！！
    }
    | CompileUnit VarDecl {
        $$ = $1->insert_son_node($2);
        // 这里也不要改ast_root了！！
    }
    | CompileUnit ConstDecl {
        $$ = $1->insert_son_node($2);
        // 这里也不要改ast_root了！
    }
    ;


// 函数定义，目前支持整数返回类型，不支持形参
FuncDef
    :  BasicType T_ID T_L_PAREN T_R_PAREN Block {
        type_attr funcReturnType = $1;
        var_id_attr funcId = $2;
		ast_node * formalParamsNode = create_contain_node(ast_operator_type::AST_OP_FUNC_FORMAL_PARAMS);
        ast_node * blockNode = $5;
        $$ = create_func_def(funcReturnType, funcId, blockNode, formalParamsNode);
    }
    | BasicType T_ID T_L_PAREN FormalParamList T_R_PAREN Block {
        type_attr funcReturnType = $1;
        var_id_attr funcId = $2;
        ast_node * formalParamsNode = $4;
        ast_node * blockNode = $6;
        $$ = create_func_def(funcReturnType, funcId, blockNode, formalParamsNode);
    }
    ;

FormalParamList
    : FormalParam {
        $$ = create_contain_node(ast_operator_type::AST_OP_FUNC_FORMAL_PARAMS, $1);
    }
    | FormalParamList T_COMMA FormalParam {
        $$ = $1->insert_son_node($3);
    }
    ;

FormalParam
    : BasicType T_ID {
        // 普通变量形参
        ast_node * type_node = create_type_node($1);
        ast_node * id_node = ast_node::New(var_id_attr{$2.id, $2.lineno});
        free($2.id);
        $$ = create_contain_node(ast_operator_type::AST_OP_VAR_DECL, type_node, id_node);
    }
    | BasicType T_ID FuncFParamArrayDim {
        // 数组变量形参（可能多维）
        ast_node * type_node = create_type_node($1);
        ast_node * id_node = ast_node::New(var_id_attr{$2.id, $2.lineno});
        free($2.id);
        ast_node * array_decl = create_contain_node(ast_operator_type::AST_OP_VAR_ARRAY_DECL, id_node, $3);
        $$ = create_contain_node(ast_operator_type::AST_OP_VAR_DECL, type_node, array_decl);
    }
    ;

FuncFParamArrayDim
    : T_L_SQUARE T_R_SQUARE {
        // 第一个 [] 只是表示是数组，不建 dim
        $$ = nullptr;
    }
    | T_L_SQUARE ConstExp T_R_SQUARE {
        // 第一个 [5] 建 dim
        $$ = create_contain_node(ast_operator_type::AST_OP_ARRAY_DIM, $2);
    }
    | FuncFParamArrayDim T_L_SQUARE ConstExp T_R_SQUARE {
        if ($1 == nullptr) {
            $$ = create_contain_node(ast_operator_type::AST_OP_ARRAY_DIM, $3);
        } else {
            $$ = $1->insert_son_node(create_contain_node(ast_operator_type::AST_OP_ARRAY_DIM, $3));
        }
    }
    ;





// 语句块的文法Block ： T_L_BRACE BlockItemList? T_R_BRACE
// 其中?代表可有可无，在bison中不支持，需要拆分成两个产生式
// Block ： T_L_BRACE T_R_BRACE | T_L_BRACE BlockItemList T_R_BRACE
Block : T_L_BRACE T_R_BRACE {
		// 语句块没有语句

		// 为了方便创建一个空的Block节点
		$$ = create_contain_node(ast_operator_type::AST_OP_BLOCK);
	}
	| T_L_BRACE BlockItemList T_R_BRACE {
		// 语句块含有语句

		// BlockItemList归约时内部创建Block节点，并把语句加入，这里不创建Block节点
		$$ = $2;
	}
	;

// 语句块内语句列表的文法：BlockItemList : BlockItem+
// Bison不支持正闭包，需修改成左递归形式，便于属性的传递与孩子节点的追加
// 左递归形式的文法为：BlockItemList : BlockItem | BlockItemList BlockItem
BlockItemList : BlockItem {
		// 第一个左侧的孩子节点归约成Block节点，后续语句可持续作为孩子追加到Block节点中
		// 创建一个AST_OP_BLOCK类型的中间节点，孩子为Statement($1)
		$$ = create_contain_node(ast_operator_type::AST_OP_BLOCK, $1);
	}
	| BlockItemList BlockItem {
		// 把BlockItem归约的节点加入到BlockItemList的节点中
		$$ = $1->insert_son_node($2);
	}
	;


// 语句块中子项的文法：BlockItem : Statement
// 目前只支持语句,后续可增加支持变量定义
BlockItem
    : Statement {
        $$ = $1;
    }
    | VarDecl {
        $$ = $1;
    }
    | ConstDecl {
        $$ = $1;
    }
	;


// 变量声明语句
// 语法：varDecl: basicType varDef (T_COMMA varDef)* T_SEMICOLON
// 因Bison不支持闭包运算符，因此需要修改成左递归，修改后的文法为：
// VarDecl : VarDeclExpr T_SEMICOLON
// VarDeclExpr: BasicType VarDef | VarDeclExpr T_COMMA varDef
VarDecl : VarDeclExpr T_SEMICOLON {
		$$ = $1;
	}
	;

// 变量声明表达式，可支持逗号分隔定义多个
VarDeclExpr
    : BasicType VarDef {
        // 创建类型节点
        ast_node * type_node = create_type_node($1);

        // 创建变量定义节点
        ast_node * decl_node = create_contain_node(ast_operator_type::AST_OP_VAR_DECL, type_node, $2);
        decl_node->type = type_node->type;

        // 创建变量声明语句，并加入第一个变量
        $$ = create_var_decl_stmt_node(decl_node);
    }
    | VarDeclExpr T_COMMA VarDef {
        // 不要重新建type了！！！直接把VarDef挂到原来的VarDecl语句上
        $$ = $1->insert_son_node($3);
    }
	;


// 变量定义包含变量名，实际上还有初值，这里没有实现。
VarDef
    : T_ID {
        $$ = ast_node::New(var_id_attr{$1.id, $1.lineno});
        free($1.id);
    }
    | T_ID ArrayDim {
        ast_node * id_node = ast_node::New(var_id_attr{$1.id, $1.lineno});
        free($1.id);
        $$ = create_contain_node(ast_operator_type::AST_OP_VAR_ARRAY_DECL, id_node, $2);
    }
    | T_ID T_ASSIGN InitVal {
        ast_node * id_node = ast_node::New(var_id_attr{$1.id, $1.lineno});
        free($1.id);
        $$ = create_contain_node(ast_operator_type::AST_OP_VAR_DECL, id_node, $3);
    }
	| T_ID ArrayDim T_ASSIGN InitVal {
		ast_node * id_node = ast_node::New(var_id_attr{$1.id, $1.lineno});
		free($1.id);

		ast_node * array_decl = create_contain_node(ast_operator_type::AST_OP_VAR_ARRAY_DECL, id_node, $2);

		$$ = create_contain_node(ast_operator_type::AST_OP_VAR_DECL, array_decl, $4);
	}
    ;


ArrayDim
    : T_L_SQUARE ConstExp T_R_SQUARE {
        $$ = create_contain_node(ast_operator_type::AST_OP_ARRAY_DIM, $2);
    }
    | ArrayDim T_L_SQUARE ConstExp T_R_SQUARE {
        $$ = $1->insert_son_node(create_contain_node(ast_operator_type::AST_OP_ARRAY_DIM, $3));
    }
    ;

ConstExp
    : T_DIGIT {
        $$ = ast_node::New($1);
    }
    | AddExp {
        $$ = $1;
    }
    ;




InitVal
    : Expr {
        // 简单初始化
        $$ = create_contain_node(ast_operator_type::AST_OP_INITVAL, $1);
    }
    | T_L_BRACE T_R_BRACE {
        // 空初始化 {}
        $$ = create_contain_node(ast_operator_type::AST_OP_INITVAL);
    }
    | T_L_BRACE InitValList T_R_BRACE {
        // 多个初始化器 {initval, initval, ...}
        $$ = create_contain_node(ast_operator_type::AST_OP_INITVAL, $2);
    }
    ;

InitValList
    : InitVal {
        $$ = create_contain_node(ast_operator_type::AST_OP_INITVAL, $1);
    }
    | InitValList T_COMMA InitVal {
        $$ = $1->insert_son_node($3);
    }
    ;

ConstDecl
    : T_CONST BasicType ConstDefList T_SEMICOLON {
        ast_node * type_node = create_type_node($2);
        $$ = create_contain_node(ast_operator_type::AST_OP_CONST_DECL, type_node, $3);
    }
    ;

ConstDefList
    : ConstDef {
        $$ = $1;
    }
    | ConstDefList T_COMMA ConstDef {
        $$ = $1->insert_son_node($3);
    }
    ;

ConstDef
    : T_ID T_ASSIGN ConstInitVal {
        ast_node * id_node = ast_node::New(var_id_attr{$1.id, $1.lineno});
        free($1.id);
        $$ = create_contain_node(ast_operator_type::AST_OP_VAR_DECL, id_node, $3);
    }
	| T_ID ArrayDim T_ASSIGN ConstInitVal {
		ast_node * id_node = ast_node::New(var_id_attr{$1.id, $1.lineno});
		free($1.id);

		ast_node * array_decl = create_contain_node(ast_operator_type::AST_OP_CONST_ARRAY_DECL, id_node, $2);

		ast_node * array_init = create_contain_node(ast_operator_type::AST_OP_CONST_INITVAL, $4);

		$$ = create_contain_node(ast_operator_type::AST_OP_VAR_DECL, array_decl, array_init);
	}
    ;

ConstInitVal
    : ConstExp {
        $$ = create_contain_node(ast_operator_type::AST_OP_CONST_INITVAL, $1);
    }
    | T_L_BRACE T_R_BRACE {
        $$ = create_contain_node(ast_operator_type::AST_OP_CONST_INITVAL);
    }
    | T_L_BRACE ConstInitValList T_R_BRACE {
        $$ = create_contain_node(ast_operator_type::AST_OP_CONST_INITVAL, $2);
    }
    ;

ConstInitValList
    : ConstInitVal {
        $$ = create_contain_node(ast_operator_type::AST_OP_CONST_INITVAL, $1);
    }
    | ConstInitValList T_COMMA ConstInitVal {
        $$ = $1->insert_son_node($3);
    }
    ;




// 基本类型，目前只支持整型
BasicType
    : T_INT {
        $$ = $1;
    }
    | T_FLOAT {
        $$ = $1;
    }
    ;


// 语句文法：statement:T_RETURN expr T_SEMICOLON | lVal T_ASSIGN expr T_SEMICOLON
// | block | expr? T_SEMICOLON
// 支持返回语句、赋值语句、语句块、表达式语句
// 其中表达式语句可支持空语句，由于bison不支持?，修改成两条
Statement
    : IFStmt {
        $$ = $1;
    }
    | T_RETURN Expr T_SEMICOLON {
        $$ = create_contain_node(ast_operator_type::AST_OP_RETURN, $2);
    }
    | LVal T_ASSIGN Expr T_SEMICOLON {
        $$ = create_contain_node(ast_operator_type::AST_OP_ASSIGN, $1, $3);
    }
    | Block {
        $$ = $1;
    }
    | Expr T_SEMICOLON {
        $$ = $1;
    }
    | T_SEMICOLON {
        $$ = nullptr;
    }
    | T_WHILE T_L_PAREN Cond T_R_PAREN Statement {
        $$ = create_while_node($3, $5);
    }
    | T_BREAK T_SEMICOLON {
        $$ = create_break_node();
    }
    | T_CONTINUE T_SEMICOLON {
        $$ = create_continue_node();
    }
    ;


IFStmt
    : T_IF T_L_PAREN Cond T_R_PAREN Statement {
        $$ = create_if_node($3, $5);
    }
    | T_IF T_L_PAREN Cond T_R_PAREN Statement T_ELSE IFStmt {
        $$ = create_if_else_node($3, $5, $7);
    }
    | T_IF T_L_PAREN Cond T_R_PAREN Statement T_ELSE Statement {
        $$ = create_if_else_node($3, $5, $7);
    }
    ;

// 表达式文法 expr : LOrExp
// 表达式目前只支持加法与减法运算
Expr
    : T_DIGIT {
        $$ = ast_node::New($1);
    }
    | LOrExp {
        $$ = $1;
    }
	;

// 加减表达式文法：addExp: unaryExp (addOp unaryExp)*
// 由于bison不支持用闭包表达，因此需要拆分成左递归的形式
// 改造后的左递归文法：
// addExp : unaryExp | unaryExp addOp unaryExp | addExp addOp unaryExp
AddExp
    : MulExp {
        $$ = $1;
    }
    | MulExp AddOp MulExp {
        $$ = create_contain_node(ast_operator_type($2), $1, $3);
    }
    | AddExp AddOp MulExp {
        $$ = create_contain_node(ast_operator_type($2), $1, $3);
    }
    ;


// 乘除模表达式文法：MulExp : UnaryExp (MulOp UnaryExp)*
// 需要拆成左递归的写法
MulExp
    : UnaryExp {
        $$ = $1;
    }
    | UnaryExp MulOp UnaryExp {
        $$ = create_contain_node(ast_operator_type($2), $1, $3);
    }
    | MulExp MulOp UnaryExp {
        $$ = create_contain_node(ast_operator_type($2), $1, $3);
    }
    ;

RelExp
    : AddExp {
        $$ = $1;
    }
    | AddExp RelOp AddExp {
        $$ = create_contain_node(ast_operator_type($2), $1, $3);
    }
    | RelExp RelOp AddExp {
        $$ = create_contain_node(ast_operator_type($2), $1, $3);
    }
    ;

EqExp
    : RelExp {
        $$ = $1;
    }
    | RelExp EqOp RelExp {
        $$ = create_contain_node(ast_operator_type($2), $1, $3);
    }
    | EqExp EqOp RelExp {
        $$ = create_contain_node(ast_operator_type($2), $1, $3);
    }
    ;

LAndExp
    : EqExp {
        $$ = $1;
    }
    | LAndExp T_AND EqExp {
        $$ = create_contain_node(ast_operator_type::AST_OP_AND, $1, $3);
    }
    ;

LOrExp
    : LAndExp {
        $$ = $1;
    }
    | LOrExp T_OR LAndExp {
        $$ = create_contain_node(ast_operator_type::AST_OP_OR, $1, $3);
    }
    ;

// 加减运算符
AddOp: T_ADD {
		$$ = (int)ast_operator_type::AST_OP_ADD;
	}
	| T_SUB {
		$$ = (int)ast_operator_type::AST_OP_SUB;
	}
	;
//乘除模表达式文法：MulExp
MulOp
    : T_MUL { $$ = (int)ast_operator_type::AST_OP_MUL; }
    | T_DIV { $$ = (int)ast_operator_type::AST_OP_DIV; }
    | T_MOD { $$ = (int)ast_operator_type::AST_OP_MOD; }
    ;
//比较运算
RelOp
    : T_LT { $$ = (int)ast_operator_type::AST_OP_LT; }
    | T_LE { $$ = (int)ast_operator_type::AST_OP_LE; }
    | T_GT { $$ = (int)ast_operator_type::AST_OP_GT; }
    | T_GE { $$ = (int)ast_operator_type::AST_OP_GE; }
    ;
//等与不等
EqOp
    : T_EQ { $$ = (int)ast_operator_type::AST_OP_EQ; }
    | T_NEQ { $$ = (int)ast_operator_type::AST_OP_NEQ; }
    ;
Cond
    : LOrExp {
        $$ = $1;
    }
    ;

// 目前一元表达式可以为基本表达式、函数调用，其中函数调用的实参可有可无
// 其文法为：unaryExp: primaryExp | T_ID T_L_PAREN realParamList? T_R_PAREN
// 由于bison不支持？表达，因此变更后的文法为：
// unaryExp: primaryExp | T_ID T_L_PAREN T_R_PAREN | T_ID T_L_PAREN realParamList T_R_PAREN
UnaryExp
    : PrimaryExp {
        $$ = $1;
    }
    | T_SUB UnaryExp {
        $$ = create_contain_node(ast_operator_type::AST_OP_NEG, $2);
    }
    | T_NOT UnaryExp {
        $$ = create_contain_node(ast_operator_type::AST_OP_NOT, $2);
    }
    | T_ID T_L_PAREN T_R_PAREN {
        // 注意这里即使没有实参也要建 real-params 黄框！
        ast_node * name_node = ast_node::New(std::string($1.id), $1.lineno);
        free($1.id);
        ast_node * paramListNode = create_contain_node(ast_operator_type::AST_OP_FUNC_REAL_PARAMS); // ✅注意
        $$ = create_func_call(name_node, paramListNode);
    }
    | T_ID T_L_PAREN RealParamList T_R_PAREN {
        ast_node * name_node = ast_node::New(std::string($1.id), $1.lineno);
        free($1.id);
        ast_node * paramListNode = $3;
        $$ = create_func_call(name_node, paramListNode);
    }
    ;


// 基本表达式支持无符号整型字面量、带括号的表达式、具有左值属性的表达式
// 其文法为：primaryExp: T_L_PAREN expr T_R_PAREN | T_DIGIT | lVal
PrimaryExp :  T_L_PAREN Expr T_R_PAREN {
		// 带有括号的表达式
		$$ = $2;
	}
	| T_DIGIT {
        	// 无符号整型字面量

		// 创建一个无符号整型的终结符节点
		$$ = ast_node::New($1);
	}
	| LVal  {
		// 具有左值的表达式

		// 直接传递到归约后的非终结符号PrimaryExp
		$$ = $1;
	}
    | T_FLOAT_LITERAL {
        $$ = ast_node::New($1);
    }
	;

// 实参表达式支持逗号分隔的若干个表达式
// 其文法为：realParamList: expr (T_COMMA expr)*
// 由于Bison不支持闭包运算符表达，修改成左递归形式的文法
// 左递归文法为：RealParamList : Expr | 左递归文法为：RealParamList T_COMMA expr
RealParamList : Expr {
		// 创建实参列表节点，并把当前的Expr节点加入
		$$ = create_contain_node(ast_operator_type::AST_OP_FUNC_REAL_PARAMS, $1);
	}
	| RealParamList T_COMMA Expr {
		// 左递归增加实参表达式
		$$ = $1->insert_son_node($3);
	}
	;

// 左值表达式，目前只支持变量名，实际上还有下标变量
LVal
    : T_ID {
        $$ = ast_node::New($1);
        free($1.id);
    }
    | LVal T_L_SQUARE Expr T_R_SQUARE {
        $$ = create_contain_node(ast_operator_type::AST_OP_ARRAY_ACCESS, $1, $3);
    }
    ;


%%
// 语法识别错误要调用函数的定义
void yyerror(char * msg)
{
    printf("Line %d: %s\n", yylineno, msg);
}
