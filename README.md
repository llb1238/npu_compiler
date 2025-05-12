# NPU Compiler!!!!
## 成员：王崇宇（组长）、赵鹏、李蕃宇、梁乐彬
./build/minic -S -T -o ./tests/test1-1.png ./tests/test1-1.c

./build/minic -S -T -A -o ./tests/test1-1.png ./tests/test1-1.c

./build/minic -S -T -D -o ./tests/test1-1.png ./tests/test1-1.c

./build/minic -S -I -o ./tests/test1-1.ir ./tests/test1-1.c

./build/minic -S -I -A -o ./tests/test1-1.ir ./tests/test1-1.c

./build/minic -S -I -D -o ./tests/test1-1.ir ./tests/test1-1.c

./build/minic -S -o ./tests/test1-1.s ./tests/test1-1.c

./build/minic -S -A -o ./tests/test1-1.s ./tests/test1-1.c

./build/minic -S -D -o ./tests/test1-1.s ./tests/test1-1.c

clang -S -emit-llvm -o test1-1-clang.ll ./tests/test1-1.c

cmake --build build --parallel