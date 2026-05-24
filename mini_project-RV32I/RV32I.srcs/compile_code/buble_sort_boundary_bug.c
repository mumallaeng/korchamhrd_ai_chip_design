#include <stdio.h>

void buble_sort(int *pNum, int size);
void swap(int *a, int *b);

int main(void)
{
    int Num[6] = {3, 5, 9, 1, 7};
    int a = 0;

    buble_sort(Num, 5);

    a = 0x12345678;

    return 0;
}

void buble_sort(int *pNum, int size)
{
    for (int i = 0; i < size; i++)
    {
        for (int j = 0; j < size - i; j++)
        {
            if (pNum[j] > pNum[j + 1])
            {
                swap(&pNum[j], &pNum[j + 1]);
            }
        }
    }
}

void swap(int *a, int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}
