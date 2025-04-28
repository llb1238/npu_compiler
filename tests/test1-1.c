const int C = 10;
const int D[2] = {1, 2};

int foo() {
    return C;
}

int bar(int x, int y) {
    return x + y;
}

int main() {
    int a;
    int arr[5];
    a = 1 + 2;

    if (a > 2) {
        a = bar(1, 2);
    } else {
        a = foo();
    }

    while (a < 10) {
        a = a + 1;
        if (a == 5) {
            break;
        }
        continue;
    }

    return arr[0];
}
