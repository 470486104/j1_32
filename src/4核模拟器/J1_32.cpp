#include <iostream>
#include <windows.h>
#include <thread>
#include <mutex>
#include <atomic>
using namespace std;

unsigned int memory[0x8000]; /* ram */
int start1 = 1, start2 = 1, start3 = 1;
unsigned int inst1 = 0, inst2 = 0, inst3 = 0;
/*
* uart字符送出端模拟
* 由于getchar()只能接收换行符\n 所以不适合模拟串口
*/
int sum = -1, i = 0;  // sum为最后一个字符下标，i为目前字符的下标
char c[2000];           // 键盘输入缓冲区，最大存2000个字符
int input_num = 0;
int output_num = 0;
char keyboard_input(int core_num) // 键盘输入缓冲  
{
    char t;
    if (core_num == input_num)
    {
        if (i <= sum)
            t = c[i++];     // 如果键盘输入缓冲区里有字符，则送出一个字符
        else
        {                   // 如果键盘输入缓冲区里没有有字符，则取一行字符，取到的字符串的结尾字符更改换行符'\n'为回车符'\r'
            sum = 0;
            cout << "\n请输入：";
            while (1)
            {
                if ((t = getchar()) == '\n')
                {
                    output_num = 0;
                    c[sum] = '\r';
                    break;
                }
                else
                    c[sum++] = t;
            }
            i = 0;
            t = c[i++];
        }
        return t;
    }else
        return 66;
}
mutex co_mutex;
void char_output(char c, int core_num)
{
    lock_guard<mutex> gurad(co_mutex);
    if (core_num == output_num)
        putchar(c);
}

mutex mem_mutex;
unsigned int readData(unsigned int addr)
{
    /*lock_guard<mutex> gurad(mem_mutex);*/
    return memory[addr];
}
void writeData(unsigned int addr, unsigned int data)
{
    lock_guard<mutex> gurad(mem_mutex);
    memory[addr] = data;
}


class j1core_m
{
private:
    int core_num;
    unsigned int t;
    unsigned int n;
    unsigned int d[0x20] = { 0 }; /* data stack */
    unsigned int r[0x20] = { 0 }; /* return stack */
    unsigned int pc;    /* program counter, counts cells */
    unsigned char dsp, rsp; /* point to top entry */
    int sx[4] = { 0, 1, -2, -1 }; /* 2-bit sign extension */
public:
    j1core_m(int num)
    {
        core_num = num;
        t = 0;
        n = 0;
        pc = 0;
        dsp = 0;
        rsp = 0;
        cout << "初始化完成core"<< core_num << endl;
    }

    ~j1core_m()
    {
        cout << "结束" << endl;
    }

    void push(int v) // push v on the data stack
    {
        dsp = 0x1f & (dsp + 1);
        d[dsp] = t;
        t = v;
    }

    int pop(void) // pop value from the data stack and return it
    {
        int v = t;
        t = d[dsp];
        dsp = 0x1f & (dsp - 1);
        return v;
    }

    void execute(int entrypoint)  // 指令执行
    {
        unsigned int _pc = 0, _t = 0;
        unsigned int insn = entrypoint; // first insn: "call entrypoint"
        do {
            _pc = pc + 1;
            if (insn & 0x80000000) { // literal
                this->push(insn & 0x7fffffff);
            }
            else {
                int target = insn & 0x1fffffff;
                switch (insn >> 29) {
                case 0: // jump
                    _pc = target;
                    break;
                case 1: // conditional jump
                    if (this->pop() == 0)
                        _pc = target;
                    break;
                case 2: // call
                    rsp = 31 & (rsp + 1);
                    r[rsp] = _pc << 2;
                    _pc = target;
                    break;
                case 3: // alu
                    if (insn & 0x1000) {/* r->pc */
                        _pc = r[rsp] >> 2;
                    }
                    n = d[dsp];
                    switch ((insn >> 8) & 0xf) {
                    case 0:   _t = t; break; /* noop */
                    case 1:   _t = n; break; /* copy */
                    case 2:   _t = t + n; break; /* + */
                    case 3:   _t = t & n; break; /* and */
                    case 4:   _t = t | n; break; /* or */
                    case 5:   _t = t ^ n; break; /* xor */
                    case 6:   _t = ~t; break; /* invert */
                    case 7:   _t = -(t == n); break; /* = */
                    case 8:   _t = -((signed int)n < (signed int)t); break; /* < */
                    case 9:   _t = n >> t; break; /* rshift */   // ***
                    case 0xa:  _t = t - 1; break; /* 1- */
                    case 0xb:  _t = r[rsp];  break; /* r@ */
                    case 0xc:  _t = (t == 0xf0000001) ? 1 : (t == 0xf0000000) ? keyboard_input(this->core_num) : readData(t >> 2); break; /* @ */
                    case 0xd:  _t = n << t; break; /* lshift */
                    case 0xe:  _t = (rsp << 8) + dsp; break; /* dsp */
                    case 0xf:  _t = -(n < t); break; /* u< */
                    }
                    dsp = 31 & (dsp + sx[insn & 3]); /* dstack+- */
                    rsp = 31 & (rsp + sx[(insn >> 2) & 3]); /* rstack+- */
                    if (insn & 0x80) /* t->n */
                        d[dsp] = t;
                    if (insn & 0x40) /* t->r */
                        r[rsp] = t;
                    if (insn & 0x0020) /* n->[t] */
                        if (t == 0xf0000000)
                            char_output(n,this->core_num);
                        else
                            writeData(t >> 2, n); /* ! */
                    switch (insn & 0x00006000)
                    {
                    case 0x2000: _t = start1 + (start2 << 1) + (start3 << 2); break;
                    case 0x4000: switch (t)
                                {
                                    case 1: inst1 = n>>2; start1 = 0; break;
                                    case 2: inst2 = n>>2; start2 = 0; break;
                                    case 3: inst3 = n>>2; start3 = 0; break;
                                }; break;
                    case 0x6000: output_num = t; break;
                    }
                    t = _t;
                }
            }
            pc = _pc;

            insn = readData(pc);
        } while (1);
    }
};
class j1core_s1
{
private:
    int core_num;
    unsigned int t;
    unsigned int n;
    unsigned int d[0x20] = { 0 }; /* data stack */
    unsigned int r[0x20] = { 0 }; /* return stack */
    unsigned int pc;    /* program counter, counts cells */
    unsigned char dsp, rsp; /* point to top entry */
    int sx[4] = { 0, 1, -2, -1 }; /* 2-bit sign extension */
public:
    j1core_s1()
    {
        core_num = 1;
        t = 0;
        n = 0;
        pc = 0;
        dsp = 0;
        rsp = 0;
        cout << "初始化完成core" << core_num << endl;
    }

    ~j1core_s1()
    {
        cout << "结束" << endl;
    }

    void push(int v) // push v on the data stack
    {
        dsp = 0x1f & (dsp + 1);
        d[dsp] = t;
        t = v;
    }

    int pop(void) // pop value from the data stack and return it
    {
        int v = t;
        t = d[dsp];
        dsp = 0x1f & (dsp - 1);
        return v;
    }

    void execute(unsigned int entrypoint)  // 指令执行
    {
        unsigned int _pc = 0, _t = 0;
        unsigned int insn = entrypoint; // first insn: "call entrypoint"
        do {
            _pc = pc + 1;
            if (insn & 0x80000000) { // literal
                this->push(insn & 0x7fffffff);
            }
            else {
                int target = insn & 0x1fffffff;
                switch (insn >> 29) {
                case 0: // jump
                    _pc = target;
                    break;
                case 1: // conditional jump
                    if (this->pop() == 0)
                        _pc = target;
                    break;
                case 2: // call
                    rsp = 31 & (rsp + 1);
                    r[rsp] = _pc << 2;
                    _pc = target;
                    break;
                case 3: // alu
                    if (insn & 0x1000) {/* r->pc */
                        if (rsp)
                            _pc = r[rsp] >> 2;
                        else
                        {
                            start1 = 1;
                            return;
                        }
                    }
                    n = d[dsp];
                    switch ((insn >> 8) & 0xf) {
                    case 0:   _t = t; break; /* noop */
                    case 1:   _t = n; break; /* copy */
                    case 2:   _t = t + n; break; /* + */
                    case 3:   _t = t & n; break; /* and */
                    case 4:   _t = t | n; break; /* or */
                    case 5:   _t = t ^ n; break; /* xor */
                    case 6:   _t = ~t; break; /* invert */
                    case 7:   _t = -(t == n); break; /* = */
                    case 8:   _t = -((signed int)n < (signed int)t); break; /* < */
                    case 9:   _t = n >> t; break; /* rshift */   // ***
                    case 0xa:  _t = t - 1; break; /* 1- */
                    case 0xb:  _t = r[rsp];  break; /* r@ */
                    case 0xc:  _t = (t == 0xf0000001) ? 1 : (t == 0xf0000000) ? keyboard_input(this->core_num) : readData(t >> 2); break; /* @ */
                    case 0xd:  _t = n << t; break; /* lshift */
                    case 0xe:  _t = (rsp << 8) + dsp; break; /* dsp */
                    case 0xf:  _t = -(n < t); break; /* u< */
                    }
                    dsp = 31 & (dsp + sx[insn & 3]); /* dstack+- */
                    rsp = 31 & (rsp + sx[(insn >> 2) & 3]); /* rstack+- */
                    if (insn & 0x80) /* t->n */
                        d[dsp] = t;
                    if (insn & 0x40) /* t->r */
                        r[rsp] = t;
                    if (insn & 0x0020) /* n->[t] */
                        if (t == 0xf0000000)
                            char_output(n, this->core_num);
                        else
                            writeData(t >> 2, n); /* ! */

                    t = _t;
                }
            }
            pc = _pc;
            insn = readData(pc);
        } while (1);
    }

    void run()
    {
        while (true)
        {
            if (!start1)
                this->execute(inst1);
            else
                Sleep(500);
        }
    }
};
class j1core_s2
{
private:
    int core_num;
    unsigned int t;
    unsigned int n;
    unsigned int d[0x20] = { 0 }; /* data stack */
    unsigned int r[0x20] = { 0 }; /* return stack */
    unsigned int pc;    /* program counter, counts cells */
    unsigned char dsp, rsp; /* point to top entry */
    int sx[4] = { 0, 1, -2, -1 }; /* 2-bit sign extension */
public:
    j1core_s2()
    {
        core_num = 2;
        t = 0;
        n = 0;
        pc = 0;
        dsp = 0;
        rsp = 0;
        cout << "初始化完成core" << core_num << endl;
    }

    ~j1core_s2()
    {
        cout << "结束" << endl;
    }

    void push(int v) // push v on the data stack
    {
        dsp = 0x1f & (dsp + 1);
        d[dsp] = t;
        t = v;
    }

    int pop(void) // pop value from the data stack and return it
    {
        int v = t;
        t = d[dsp];
        dsp = 0x1f & (dsp - 1);
        return v;
    }

    void execute(unsigned int entrypoint)  // 指令执行
    {
        unsigned int _pc = 0, _t = 0;
        unsigned int insn = entrypoint; // first insn: "call entrypoint"
        do {
            _pc = pc + 1;
            if (insn & 0x80000000) { // literal
                this->push(insn & 0x7fffffff);
            }
            else {
                int target = insn & 0x1fffffff;
                switch (insn >> 29) {
                case 0: // jump
                    _pc = target;
                    break;
                case 1: // conditional jump
                    if (this->pop() == 0)
                        _pc = target;
                    break;
                case 2: // call
                    rsp = 31 & (rsp + 1);
                    r[rsp] = _pc << 2;
                    _pc = target;
                    break;
                case 3: // alu
                    if (insn & 0x1000) {/* r->pc */
                        if (rsp)
                            _pc = r[rsp] >> 2;
                        else
                        {
                            start2 = 1;
                            return;
                        }
                    }
                    n = d[dsp];
                    switch ((insn >> 8) & 0xf) {
                    case 0:   _t = t; break; /* noop */
                    case 1:   _t = n; break; /* copy */
                    case 2:   _t = t + n; break; /* + */
                    case 3:   _t = t & n; break; /* and */
                    case 4:   _t = t | n; break; /* or */
                    case 5:   _t = t ^ n; break; /* xor */
                    case 6:   _t = ~t; break; /* invert */
                    case 7:   _t = -(t == n); break; /* = */
                    case 8:   _t = -((signed int)n < (signed int)t); break; /* < */
                    case 9:   _t = n >> t; break; /* rshift */   // ***
                    case 0xa:  _t = t - 1; break; /* 1- */
                    case 0xb:  _t = r[rsp];  break; /* r@ */
                    case 0xc:  _t = (t == 0xf0000001) ? 1 : (t == 0xf0000000) ? keyboard_input(this->core_num) : readData(t >> 2); break; /* @ */
                    case 0xd:  _t = n << t; break; /* lshift */
                    case 0xe:  _t = (rsp << 8) + dsp; break; /* dsp */
                    case 0xf:  _t = -(n < t); break; /* u< */
                    }
                    dsp = 31 & (dsp + sx[insn & 3]); /* dstack+- */
                    rsp = 31 & (rsp + sx[(insn >> 2) & 3]); /* rstack+- */
                    if (insn & 0x80) /* t->n */
                        d[dsp] = t;
                    if (insn & 0x40) /* t->r */
                        r[rsp] = t;
                    if (insn & 0x0020) /* n->[t] */
                        if (t == 0xf0000000)
                            char_output(n, this->core_num);
                        else
                            writeData(t >> 2, n); /* ! */

                    t = _t;

                    
                }
            }
            pc = _pc;
            insn = readData(pc);
        } while (1);
    }

    void run()
    {
        while (true)
        {
            if (!start2)
                this->execute(inst2);
            else
                Sleep(500);
        }
    }
};
class j1core_s3
{
private:
    int core_num;
    unsigned int t;
    unsigned int n;
    unsigned int d[0x20] = { 0 }; /* data stack */
    unsigned int r[0x20] = { 0 }; /* return stack */
    unsigned int pc;    /* program counter, counts cells */
    unsigned char dsp, rsp; /* point to top entry */
    int sx[4] = { 0, 1, -2, -1 }; /* 2-bit sign extension */
public:
    j1core_s3()
    {
        core_num = 3;
        t = 0;
        n = 0;
        pc = 0;
        dsp = 0;
        rsp = 0;
        cout << "初始化完成core" << core_num << endl;
    }

    ~j1core_s3()
    {
        cout << "结束" << endl;
    }

    void push(int v) // push v on the data stack
    {
        dsp = 0x1f & (dsp + 1);
        d[dsp] = t;
        t = v;
    }

    int pop(void) // pop value from the data stack and return it
    {
        int v = t;
        t = d[dsp];
        dsp = 0x1f & (dsp - 1);
        return v;
    }

    void execute(unsigned int entrypoint)  // 指令执行
    {
        unsigned int _pc = 0, _t = 0;
        unsigned int insn = entrypoint; // first insn: "call entrypoint"
        do {
            _pc = pc + 1;
            if (insn & 0x80000000) { // literal
                this->push(insn & 0x7fffffff);
            }
            else {
                int target = insn & 0x1fffffff;
                switch (insn >> 29) {
                case 0: // jump
                    _pc = target;
                    break;
                case 1: // conditional jump
                    if (this->pop() == 0)
                        _pc = target;
                    break;
                case 2: // call
                    rsp = 31 & (rsp + 1);
                    r[rsp] = _pc << 2;
                    _pc = target;
                    break;
                case 3: // alu
                    if (insn & 0x1000) {/* r->pc */
                        if (rsp)
                            _pc = r[rsp] >> 2;
                        else
                        {
                            start3 = 1;
                            return;
                        }
                    }
                    n = d[dsp];
                    switch ((insn >> 8) & 0xf) {
                    case 0:   _t = t; break; /* noop */
                    case 1:   _t = n; break; /* copy */
                    case 2:   _t = t + n; break; /* + */
                    case 3:   _t = t & n; break; /* and */
                    case 4:   _t = t | n; break; /* or */
                    case 5:   _t = t ^ n; break; /* xor */
                    case 6:   _t = ~t; break; /* invert */
                    case 7:   _t = -(t == n); break; /* = */
                    case 8:   _t = -((signed int)n < (signed int)t); break; /* < */
                    case 9:   _t = n >> t; break; /* rshift */   // ***
                    case 0xa:  _t = t - 1; break; /* 1- */
                    case 0xb:  _t = r[rsp];  break; /* r@ */
                    case 0xc:  _t = (t == 0xf0000001) ? 1 : (t == 0xf0000000) ? keyboard_input(this->core_num) : readData(t >> 2); break; /* @ */
                    case 0xd:  _t = n << t; break; /* lshift */
                    case 0xe:  _t = (rsp << 8) + dsp; break; /* dsp */
                    case 0xf:  _t = -(n < t); break; /* u< */
                    }
                    dsp = 31 & (dsp + sx[insn & 3]); /* dstack+- */
                    rsp = 31 & (rsp + sx[(insn >> 2) & 3]); /* rstack+- */
                    if (insn & 0x80) /* t->n */
                        d[dsp] = t;
                    if (insn & 0x40) /* t->r */
                        r[rsp] = t;
                    if (insn & 0x0020) /* n->[t] */
                        if (t == 0xf0000000)
                            char_output(n, this->core_num);
                        else
                            writeData(t >> 2, n); /* ! */
                    
                    t = _t;

                }
            }
            pc = _pc;
            insn = readData(pc);
        } while (1);
    }

    void run()
    {
        while (true)
        {
            if (!start3)
                this->execute(inst3);
            else
                Sleep(500);
        }
    }
};

int main()
{
    //FILE* f = fopen("D:\\Cygwin\\tmp\\gforth-0.7.3\\j1_32.bin", "rb");  // j1 forth系统的二进制文件
    FILE* f;
    errno_t err = fopen_s(&f,"E:\\j1_32.bin", "rb");
    if (!err && f)
    {
        fread(memory, 0x4000, sizeof(memory[0]), f);
        fclose(f);
    }
    j1core_m c0(0);
    j1core_s1 c1;
    j1core_s2 c2;
    j1core_s3 c3;
    thread th0(&j1core_m::execute,c0,0);
    thread th1(&j1core_s1::run, c1);
    thread th2(&j1core_s2::run, c2);
    thread th3(&j1core_s3::run, c3);
    th0.join();
    th1.join();
    th2.join();
    th3.join();
    return 0;
}
