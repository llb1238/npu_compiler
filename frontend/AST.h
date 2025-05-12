///
/// @file AST.h
/// @brief 抽象语法树AST管理的头文件
/// @author zenglj (zenglj@live.com)
/// @version 1.5
/// @date 2024-11-21
///
#pragma once

#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

#include "AttrType.h"
#include "IRCode.h"
#include "Value.h"
#include "VoidType.h"

/// @brief AST节点类型枚举，包含所有语法和 AST.cpp 中用到的 AST_OP_XXX
enum class ast_operator_type : int {
    /* 叶子节点 */
    AST_OP_LEAF_LITERAL_UINT,
    AST_OP_LEAF_LITERAL_FLOAT,
    AST_OP_LEAF_VAR_ID,
    AST_OP_LEAF_TYPE,

    /* 编译单元与函数 */
    AST_OP_COMPILE_UNIT,
    AST_OP_FUNC_DEF,
    AST_OP_FUNC_FORMAL_PARAMS,
    AST_OP_FUNC_FORMAL_PARAM,
    AST_OP_FUNC_CALL,
    AST_OP_FUNC_REAL_PARAMS,

    /* 语句块与声明 */
    AST_OP_BLOCK,
    AST_OP_COMPOUNDSTMT = AST_OP_BLOCK,
    AST_OP_RETURN,
    AST_OP_DECL_STMT,
    AST_OP_VAR_DECL,
    AST_OP_CONST_DECL,

    /* 赋值 */
    AST_OP_ASSIGN,
    AST_OP_ASSIGN_STMT,

    /* 算术运算 */
    AST_OP_ADD,
    AST_OP_SUB,
    AST_OP_MUL,
    AST_OP_DIV,
    AST_OP_MOD,

    /* 关系与逻辑 */
    AST_OP_LT,
    AST_OP_LE,
    AST_OP_GT,
    AST_OP_GE,
    AST_OP_EQ,
    AST_OP_NEQ,
    AST_OP_AND,
    AST_OP_OR,
    AST_OP_NEG,
    AST_OP_NOT,

    /* 控制流 */
    AST_OP_IF,
    AST_OP_IF_STMT,
    AST_OP_IF_ELSE,
    AST_OP_IF_ELSE_STMT,
    AST_OP_WHILE,
    AST_OP_BREAK,
    AST_OP_CONTINUE,

    /* 数组与初始化 */
    AST_OP_ARRAY_ACCESS,
    AST_OP_VAR_ARRAY_DECL,
    AST_OP_ARRAY_DIM,
    AST_OP_ARRAY_INDEX,
    AST_OP_INITVAL,
    AST_OP_CONST_ARRAY_DECL,
    AST_OP_CONST_INITVAL,
    AST_OP_ARRAY_CONST_DEF,
    AST_OP_ARRAY_VAR_DEF,

    /* 左值与通用表达式 */
    AST_OP_LVAL,
    AST_OP_EXP,

    /* 其他扩展节点 */
    AST_OP_CONST_DEF,
    AST_OP_VAR_DEF,
    AST_OP_SCALAR_CONST_INIT,
    AST_OP_ARRAY_CONST_INIT,
    AST_OP_SCALAR_INIT,
    AST_OP_ARRAY_INIT_VAL,
    AST_OP_EXPR_STMT,
    AST_OP_NESTED_BLOCK,
    AST_OP_UNARY_EXP,
    AST_OP_UNARY_OP,
    AST_OP_FUNC_RPARAMS,
    AST_OP_MUL_EXP,
    AST_OP_ADD_EXP,
    AST_OP_REL_EXP,
    AST_OP_EQ_EXP,
    AST_OP_LAND_EXP,
    AST_OP_LOR_EXP,
    AST_OP_CONST_EXP,
    AST_OP_FUNC_FPARAM,

    /* 最大标识符，非法运算符 */
    AST_OP_MAX,
};

/// @brief AST节点描述类
class ast_node {
public:
    ast_operator_type node_type;    ///< 节点类型
    int64_t line_no;                ///< 行号
    Type *type;                     ///< 值类型
    uint32_t integer_val;           ///< 整数字面量值
    float float_val;                ///< 浮点字面量值
    Op op_type;                     ///< 操作符类型
    std::string name;               ///< 标识符或函数名
    bool is_array = false;          ///< 是否数组
    std::vector<int> array_dimensions; ///< 数组维度大小
    Type *array_element_type = nullptr; ///< 数组元素类型
    ast_node *parent = nullptr;     ///< 父节点
    std::vector<ast_node*> sons;    ///< 子节点列表
    InterCode blockInsts;           ///< 线性IR指令块
    Value *val = nullptr;           ///< 计算结果或值对象
    bool needScope = true;          ///< 是否进入新作用域

    /// @brief 构造函数
    ast_node(ast_operator_type _node_type, Type *_type = VoidType::getType(), int64_t _line_no = -1);
    ast_node(Type *_type);
    ast_node(digit_int_attr attr);
    ast_node(digit_real_attr attr);
    ast_node(var_id_attr attr);
    ast_node(std::string id, int64_t _line_no);

    bool isLeafNode();
    ast_node *insert_son_node(ast_node *node);

    static ast_node *New(ast_operator_type type, ...);
    static ast_node *New(digit_int_attr attr);
    static ast_node *New(digit_real_attr attr);
    static ast_node *New(var_id_attr attr);
    static ast_node *New(std::string id, int64_t line_no);
    static ast_node *New(Type *type);
    static void Delete(ast_node *node);
};

/// @brief 释放 AST 资源
void free_ast(ast_node *root);
extern ast_node *ast_root;

/// @name 通用节点创建函数
///@{
ast_node* create_contain_node(ast_operator_type type,
                               ast_node* c1 = nullptr,
                               ast_node* c2 = nullptr,
                               ast_node* c3 = nullptr);
///@}

/// @name 函数相关创建接口
///@{
ast_node* create_func_def(ast_node* type_node, ast_node* name_node, ast_node* block = nullptr, ast_node* params = nullptr);
ast_node* create_func_formal_param(uint32_t line_no, const char* param_name);
ast_node* create_func_call(ast_node* funcname_node, ast_node* params_node = nullptr);
ast_node* create_return_stmt_node(ast_node* expr, int64_t line_no);
///@}

/// @name Bison 语法所需节点创建函数（实现见 AST.cpp）
///@{
ast_node* create_while_node(ast_node* cond, ast_node* body);
ast_node* create_break_node();
ast_node* create_continue_node();
ast_node* create_if_node(ast_node* cond, ast_node* then_stmt);
ast_node* create_if_else_node(ast_node* cond, ast_node* then_stmt, ast_node* else_stmt);
ast_node* create_assign_stmt_node(ast_node* lval, ast_node* expr);
ast_node* create_array_index_node(ast_node* array, ast_node* index);
ast_node* create_lval_node(ast_node* id_node, std::vector<ast_node*>& indices);
ast_node* create_exp_node(ast_node* expr);
ast_node* create_func_real_params_node();
ast_node* add_real_param_node(ast_node* params_node, ast_node* param);
///@}

/// @name 其他 create_* 声明（根据需要添加完整）
///@{
ast_node* create_var_decl_stmt_node(ast_node* first_child);
ast_node* add_var_decl_node(ast_node* stmt_node, var_id_attr& id);
ast_node* create_const_decl_node(type_attr& type, var_id_attr& id, ast_node* init_val);
ast_node* create_type_node(type_attr& type_attr);
ast_node* create_float_literal_node(digit_real_attr& attr);
// . 可根据 MiniC.y 中的所有调用继续补充 .
///@}
// ----------------------------------------------------------------
// Antlr4 Visitor 中会调用到，但需要在头文件中声明
// ----------------------------------------------------------------

// const / var 定义
ast_node* create_const_def_node(ast_node* id_node, ast_node* init_node);
ast_node* create_array_const_def_node(ast_node* id_node,
                                      std::vector<ast_node*>& dimensions,
                                      ast_node* init_node);
ast_node* create_var_def_node(ast_node* id_node, ast_node* init_node);

// 初始化器
ast_node* create_scalar_const_init_node(ast_node* expr_node);
ast_node* create_array_const_init_node(std::vector<ast_node*>& elements);
ast_node* create_scalar_init_node(ast_node* expr_node);
ast_node* create_array_init_val_node(std::vector<ast_node*>& elements);

// 语句／表达式
ast_node* create_expr_stmt_node(ast_node* expr);
ast_node* create_nested_block_node(ast_node* block);
ast_node* create_if_else_stmt_node(ast_node* cond,
                                   ast_node* then_stmt,
                                   ast_node* else_stmt);
ast_node* create_break_stmt_node(int64_t line_no);
ast_node* create_continue_stmt_node(int64_t line_no);

// 基础字面量和运算
ast_node* create_number_node(int value);
ast_node* create_float_node(float value);
ast_node* create_unary_exp_node(ast_node* op, ast_node* operand);
ast_node* create_unary_op_node(Op op_type);

// 函数实参、二元表达式
ast_node* create_func_rparams_node(std::vector<ast_node*>& params);
ast_node* create_mul_exp_node(ast_node* left,
                              ast_node* right,
                              Op op_type);
ast_node* create_add_exp_node(ast_node* left,
                              ast_node* right,
                              Op op_type);
ast_node* create_rel_exp_node(ast_node* left,
                              ast_node* right,
                              Op op_type);
ast_node* create_eq_exp_node(ast_node* left,
                             ast_node* right,
                             Op op_type);
ast_node* create_land_exp_node(ast_node* left, ast_node* right);
ast_node* create_lor_exp_node(ast_node* left, ast_node* right);
