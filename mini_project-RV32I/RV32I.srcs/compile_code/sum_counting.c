int adder(int a, int b);
void main(void)
{
    int a = 0;
    int sum = 0;
    while (a < 10)
    {
        a = a + 1;
        sum = adder(a, sum);
    }

    return;
}
int adder(int a, int b)
{
    return a + b;
}
