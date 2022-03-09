(
   eForth 1.04 for j1 Simulator by Edward A., July 2014
   Much of the code is derived from the following sources:
      j1 Cross-compiler by James Bowman August 2010
     8086 eForth 1.0 by Bill Muench and C. H. Ting, 1990
)

only forth definitions hex

wordlist constant meta.1 \ wordlist（ -- empty-wordlist-addr ）创建词表 转移编译词汇 
wordlist constant target.1 \ 目标词汇(自定义forth系统的词汇)
wordlist constant assembler.1	\ 汇编词汇 组成目标词汇

: (order) ( w wid*n n -- wid*n w n ) 
\ w表示一个词表  wid*n表示wid1、wid2···widn  n表示n个词表 ；该词的功能为从当前搜索词表中找出该词并丢弃wid*[n-1] w n，若无该词不进行任何操作wid*n w n
   dup if
    1- swap >r recurse over r@ xor if
     1+ r> -rot exit then r> drop then ;
: -order ( wid -- ) get-order (order) nip set-order ; \ 把词表从搜索词表的序列中删除 ，get-order返回结果widn~wid1 n（wid1为栈顶元素，n为词表wid个数）
: +order ( wid -- ) dup >r -order get-order r> swap 1+ set-order ; \ 把词表添加搜索词表的序列中

: ]asm ( -- ) assembler.1 +order ; immediate \ 把汇编词表加入到搜索队列中

get-current meta.1 set-current

: [a] ( "name" -- ) \ 如果后面跟随的词在汇编(assembler.1)列表中，则把该词的执行地址（代码指针域地址）编译到使用本词的定义中（即本定义词的参数域中）
  parse-word assembler.1 search-wordlist 0=
   abort" [a]?" compile, ; immediate
: a: ( "name" -- ) \ 把一个词汇加入到汇编词列表中
  get-current >r  assembler.1 set-current
  : r> set-current ;

target.1 +order meta.1 +order  \ 搜索列表及顺序为 meta.1 target.1 forth root

a: asm[ ( -- ) assembler.1 -order ; immediate \ asm[ 功能：把汇编词表从搜索表中删除

create tflash 4000 cells here over erase allot \ 创建一个数组tflash，1000个单元大小，并且清空单元内的所有废数据，将here指针向后推进1000个单元


variable tdp 	\ tflash的指针 按字节移动

: there ( -- tdp ) tdp @ ;  \ 变量tdp的值
: tc! ( n tdp -- ) tflash + c! ; \ 把n的低8位存到数组tflash的addr位置  字节 为单位
: tc@ ( tdp -- ) tflash + c@ ; \ 取数组tflash的addr位置的值 字节 为单位
: t! ( n tdp -- ) over ff and over tc! swap 8 rshift swap 1+ tc! ; \ 把n存到数组tflash的addr位置  字 为单位
: t@ ( tdp -- n ) dup tc@ swap 1+ tc@ 8 lshift or ; \ 取数组tflash的addr位置的值 字 为单位
: talign ( -- ) there 1 and tdp +! ; \ 若变量tdp中存的是地址 则判断地址是否是按字对齐的（最低位为0是对齐） 若不对齐则对齐（地址+1）
: tc, ( n -- ) there tc! 1 tdp +! ; \ 把变量中的值低8位存到tflash数组的tdp位置后tdp指针自增1
: t, ( n -- ) there t! 2 tdp +! ; \ 把变量中的值存到tflash数组的tdp位置后tdp指针自增2
: $literal [char] " word count dup tc, 0 ?do 
	count tc, loop drop talign ; \ 读取一个词存入到tflash中  tflash的内容为【5，‘a’,'b','x','s','e',·····】
: tallot tdp +! ; \ 加减法更改指针位置 
: org tdp ! ; \ 更改指针位置
 
\ 32位存取    **forth中数据以小端存储**     meta
: t32! tflash + ! ;
: t32@ tflash + @ ;
: t32, ( n -- ) there t32! 4 tdp +! ;
: t32align ( -- ) 4 there 3 and - dup 4 = if drop 0 then tdp +! ; \ 32位对齐
: 32$literal [char] " word count dup tc, 0 ?do 
	count tc, loop drop t32align ;

\ [char] " 把“ " ”的ascii码放到栈顶，然后word从输入中获取一个词以“ " ”结尾，返回带有词长度的地址，count把这个带有词长度的地址转换成词的第一个字符的地址和词长度，此时堆栈应为 addr len，dup和tc,后,堆栈为addr len。tflash为【len[8:0],······】其中len[8:0]为len的低8位。进入循环后 执行count和tc，后堆栈为addr+1。tflash为【len[8:0], len[8:0]-1,······】。难道tflash就存长度不存字符
a: t    0000 ;
a: n    0100 ;
a: t+n  0200 ;
a: t&n  0300 ;
a: t|n  0400 ;
a: t^n  0500 ;
a: ~t   0600 ;
a: n==t 0700 ;
a: n<t  0800 ;
a: n>>t 0900 ;
a: t-1  0a00 ;
a: rt   0b00 ;
a: din  0c00 ;
a: n<<t 0d00 ;
a: dsp  0e00 ;
a: nu<t 0f00 ;

a: tcb->t   1000 ;
a: pc->t    1100 ;
a: g_c_n    1200 ;
a: g_c_t    1300 ;
a: g_scdl   1400 ;
a: g_crtl   1500 ;
a: g_c_s    1600 ;

a: start-core 4000 or ;
a: close-core 8000 or ;

a: itpt-sw  20000  or ;
a: set-itpt 40000  or ;
a: itpt-re  60000  or ;
a: itpt-stt 80000  or ;

a: core_o	100000 or ;
a: re_p     200000 or ;

a: t->tcb   400000 or ;
a: t->pc    800000 or ;
a: t->tml   c00000 or ;

a: crtl_in  1000000 or ;
a: crtl_out 2000000 or ;
a: a_scdl   3000000 or ;
a: f_scdl   4000000 or ;

a: time_c   8000000 or ;
a: time_o   10000000 or ;
a: t->time  18000000 or ;

a: r->pc    2000 or ;
a: t->n		0080 or ;
a: t->r		0040 or ;
a: n->[t]	0020 or ;
a: [t]		0010 or ;
a: d-1		0003 or ;
a: d+1		0001 or ;
a: r-1		000c or ;
a: r-2  	0008 or ;
a: r+1  	0004 or ;

a: alu  60000000 or t32, ;

a: return [a] t [a] r->pc [a] r-1 [a] alu ; \ （ -- ）将指令6000100c送至tflash[tdp];  指令6000100c：逻辑运算 返回栈顶地址送至pc 返回堆栈指针-1 ，其中1000为r->pc
a: branch 4 / 00000000 or t32, ; \ （ n -- ） jump
a: ?branch 4 / 20000000 or t32, ; \ 条件跳转
a: call 4 / 40000000 or t32, ;

a: literal \ ( n -- ) 若n>8000h 则在tflash[tdp]处存放值8000h的取反值（即取非值）和6600h（非 运算指令）；若 n!=8000h 则在tflash[tdp]处存放值8000h|n（按位或运算） 的值即转换为文字
	dup 80000000 and if
		ffffffff xor
		recurse
		[a] ~t [a] alu
	else
		80000000 or t32,
	then ;



variable tlast \ tflash中最后一个词的指针
variable tuser

0002 constant =ver	\ 版本号
0005 constant =ext	\ 版次号
0040 constant =comp \ 与某词长度or运算可使该词为只编译词不搜索，即词长度的次高位置为1
0080 constant =imed \ 与某词长度or运算可使该词为立即词，即词长度的最高位置为1
7f7f7f1f constant =mask \ 取出带有字符串长度的4个字节 低位为字符长度
0004 constant =cell	\ 系统基础单元所占字节数
0002 constant =bitwidth \ 基础单元所占字节数的宽度log2 (=cell)
0010 constant =base \ 系统初始进制 16进制
0008 constant =bksp	\ 退格符的ascii码
000a constant =lf	\ 换行符的ascii码
000d constant =cr	\ 回车符的ascii码
0020 constant =sp	\ 空格符的ascii码
\ 系统以字节为单位计算，cpu以字长为单位（32位系统为4个字长）
c000 constant =em	\ 48KB 存储空间 rom: 0-fff ; ram: 1000-2fff 
0000 constant =cold \ 冷启动位置

 8 constant =vocs \ context列表词汇数
120 constant =us	\ 72*4B 的空间

=em 2 / 200 - constant =tib \ 5e00  128*4B的键盘输入缓冲区  内存地址2f80
=cell constant =up 		\ 4  内存地址1

=cold =us + constant =pick \ 0120
=pick 200 + constant =code \ 0300

\ 4 constant =core-num
2 constant =block ( log 块字数 )
=em 2 / constant =dataaddr
=em =dataaddr - constant =datasize
5 constant =sys-list-num ( 就绪队列数 )
0 constant =task-ready ( 任务就绪态 )
1 constant =task-run ( 任务待执行态 )
2 constant =task-running ( 任务执行态 )
3 constant =task-block ( 任务阻塞态 )
4 constant =task-end ( 任务终止态 )
40 constant =tcb-size ( tcb空间大小 )
80 constant =tcb-stack-size ( 堆栈空间大小 )
: newforthdp =up =us + ;
\ : core-next-mem ( -- ) =core-num 1 - for 0 t32, next ;

: thead ( "name" -- ) \ 以空格为结尾 存放字符串 一般为词头名称 第一个单元存放长度,,
	t32align
	tlast @ t32, there tlast !
	parse-word dup tc, 0 ?do count tc, loop drop t32align ; 

: [t] ( "name" -- n ) \ 如果后面跟随的词在目标(target.1)列表中，则把该词的参数域的内容放在堆栈上
  parse-word target.1 search-wordlist 0=
    abort" [t]?" >body @ ; immediate
: [last] ( -- ) tlast @ ; immediate \ 最后一个词的指针
: ( [char] ) parse 2drop ; immediate \ 括号定义 忽略括号内部的内容
: literal [a] literal ;
: lookback ( -- n ) there =cell - t32@ ; \ 取前一个单元的值
: call? ( -- 1or0 ) lookback e0000000 and 40000000 = ; \ 如果前一单元的指令为跳转指令则栈顶为1 反之为0
: call>goto ( -- ) there =cell - dup t32@ 1fffffff and swap t32! ; \ 将tdp-4处的跳转指令中的地址取出并重新存入当前指令的位置
: safe? ( -- 1or0 ) lookback e0000000 and 60000000 = lookback 004c and 0= and ; \ 判断tflash[tdp-4]中的指令是否是alu并且参数栈顶数据不穿传到返回栈顶，是返回1，反之0  指令004c 参数栈顶数据传到返回栈顶
: alu>return there =cell - dup t32@ [a] r->pc [a] r-1 swap t32! ;	\ 在指令中添加返回位即R->PC,以及返回堆栈指针-1指令
: t: \ 创建跟在t：之后的词，并将tdp指针存到创建词的参数域，运行该词的时候会跳转到参数域的tdp指针处。创建t；之前的词不会编译到词参数域中，而是存储到tflash的tdp处。
  >in @ thead >in !
    get-current >r target.1 set-current create
	 r> set-current 947947 t32align there , does> @ [a] call ; \ t: noop noop t;
: exit \ 若是跳转指令call 则将地址取出并重新存入当前指令的位置，否则判断是否是alu并且参数栈顶不传数据到返回栈顶，是则在该指令中添加返回位即R->PC否则直接写返回指令到tdp-2位置
  	call? if
  		call>goto
  	else 
		safe? if
			alu>return 
		else
	 		[a] return
   		then
  	then ;
: t; \ t：的结束词，它会使该定义词返回到原来调用的下一条语句
  947947 <> if
   abort" unstructured" then true if
	exit else [a] return then ;
: u: \ 创建用户变量 参数域存为tflash的地址，并且在tflash中存跟随在u:后的词名和当前用户变量的地址（文字指令）以及一个返回字段 
  >in @ thead >in !
   get-current >r target.1 set-current create
    r> set-current t32align tuser @ dup ,
	 [a] literal exit =cell tuser +! does> @ [a] literal ;
: [u] \ 取后跟随的词的参数域的内容 减去地址=up再加2
  parse-word target.1 search-wordlist 0=
    abort" [t]?" >body @ =up - =cell + ; immediate
: immediate tlast @ tflash + dup c@ =imed or swap c! ;
: compile-only tlast @ tflash + dup c@ =comp or swap c! ;

      0 tlast !
    =up tuser !  \ 4

: hex# ( u -- addr len )  0 <# base @ >r hex =lf hold # # # # # # # # r> base ! #> ; \ 将无符号单字长整数转换为4有效位的16进制整数字符串 
: save-hex ( <name> -- ) 
  parse-word w/o create-file throw
  there 0 do i t32@  over >r hex# r> write-file throw 4 +loop
   close-file throw ; \ 将代码编译保存为16进制文件
: save-target ( <name> -- ) \ 将代码编译保存为2进制文件
  parse-word w/o create-file throw >r
   tflash there r@ write-file throw r> close-file ;
: hex#_32 ( u -- addr len )  0 <# base @ >r hex # # # # # # # # r> base ! #> ;
: save-hex128 ( <name> -- ) 
  parse-word w/o create-file throw
  there 0 do 
  		i c + dup there > if drop 0 else t32@ then over >r hex#_32 r> write-file throw 
  		i 8 + dup there > if drop 0 else t32@ then over >r hex#_32 r> write-file throw 
  		i 4 + dup there > if drop 0 else t32@ then over >r hex#_32 r> write-file throw 
  		i     t32@ over >r hex# r> write-file throw 
        \ dup >r 0 <# base @ >r hex =lf hold r> base ! #> r> write-file throw 
  10 +loop
  close-file throw ; \ 将代码编译保存为16进制文件

: begin  there ; \ tdp指针的值
: until  [a] ?branch ; \ 2/ 2000 or t,

: if     there 0 [a] ?branch ;
: skip   there 0 [a] branch ;
: then   begin 4 / over t32@ or swap t32! ; \ tdp tdp1/2 tdp@ or 
: else   skip swap then ;
: while  if swap ;
: repeat [a] branch then ;
: again  [a] branch ;
: aft    drop skip begin swap ; \ 与then搭配，效果：跳过一次aft和then之间的操作 常用在for循环中

: noop ]asm t alu asm[ ;
: + ]asm t+n d-1 alu asm[ ;
: xor ]asm t^n d-1 alu asm[ ;
: and ]asm t&n d-1 alu asm[ ;
: or ]asm t|n d-1 alu asm[ ;
: invert ]asm ~t alu asm[ ;
: = ]asm n==t d-1 alu asm[ ;
: < ]asm n<t d-1 alu asm[ ;
: u< ]asm nu<t d-1 alu asm[ ;
: swap ]asm n t->n alu asm[ ;
: dup ]asm t t->n d+1 alu asm[ ;
: drop ]asm n d-1 alu asm[ ;
: over ]asm n t->n d+1 alu asm[ ;
: nip ]asm t d-1 alu asm[ ;
: >r ]asm n t->r r+1 d-1 alu asm[ ;
: r> ]asm rt t->n r-1 d+1 alu asm[ ;
: r@ ]asm rt t->n d+1 alu asm[ ;
: @ ]asm t [t] alu 
		din alu asm[ ;
: ! ]asm t n->[t] d-1 alu
    n d-1 alu asm[ ;
: dsp ]asm dsp t->n d+1 alu asm[ ;
: lshift ]asm n<<t d-1 alu asm[ ;
: rshift ]asm n>>t d-1 alu asm[ ;
: 1- ]asm t-1 alu asm[ ;
: 2r> ]asm rt t->n r-1 d+1 alu
    rt t->n r-1 d+1 alu
    n t->n alu asm[ ;
: 2>r ]asm n t->n alu
    n t->r r+1 d-1 alu
    n t->r r+1 d-1 alu asm[ ;
: 2r@ ]asm rt t->n r-1 d+1 alu
    rt t->n r-1 d+1 alu
    n t->n d+1 alu
    n t->n d+1 alu
    n t->r r+1 d-1 alu
    n t->r r+1 d-1 alu
    n t->n alu asm[ ;
: unloop
    ]asm t r-1 alu
    t r-1 alu asm[ ;

: dup@ ]asm t [t] alu
			din t->n d+1 alu asm[ ;
: dup>r ]asm t t->r r+1 alu asm[ ;
: 2dupxor ]asm t^n t->n d+1 alu asm[ ;
: 2dup= ]asm n==t t->n d+1 alu asm[ ;
: !nip ]asm t n->[t] d-1 alu asm[ ;
: 2dup! ]asm t n->[t] alu asm[ ;

: get-tcb ]asm tcb->t t->n d+1 alu asm[ ;
: get-pc ]asm pc->t t->n d+1 alu asm[ ;
: get-core-num ]asm g_c_n t->n d+1 alu asm[ ;
: get-core-total ]asm g_c_t t->n d+1 alu asm[ ;
: get-scheduler ]asm g_scdl t->n d+1 alu asm[ ;
: get-critical ]asm g_crtl t->n d+1 alu asm[ ;
: get-terminal ]asm g_c_t t->n d+1 alu asm[ ;
: get-core-state ]asm g_c_s alu asm[ ;

: start-core ]asm n start-core d-1 alu asm[ ;
: close-core ]asm t close-core alu asm[ ;

: interrupt-switch ]asm t itpt-sw alu t alu asm[ ; 
: interrupt-set ]asm n set-itpt d-1 alu 
                        n d-1 alu asm[ ;
: interrupt-return ]asm t itpt-re alu t alu asm[ ;
: interrupt-start ]asm t itpt-stt alu t alu asm[ ;

: reset-point ]asm t re_p alu asm[ ;
: showtask ]asm n core_o d-1 alu asm[ ;

: set-terminal ]asm n t->tml d-1 alu asm[ ;
: set-pc ]asm n t->pc d-1 alu asm[ ; 
: set-tcb ]asm n t->tcb d-1 alu asm[ ;

: apply-scheduler ]asm t a_scdl alu asm[ ; 
: free-scheduler ]asm t f_scdl alu asm[ ;
: critical-in ]asm t crtl_in alu asm[ ;
: critical-out ]asm t crtl_out alu asm[ ;

: close-time ]asm t time_c alu asm[ ;
: open-time ]asm t time_o alu asm[ ;
: set-time ]asm n t->time d-1 alu asm[ ;

: up1 ]asm t d+1 alu asm[ ;
: down1 ]asm t d-1 alu asm[ ;
: copy ]asm n alu asm[ ;

a: down e for down1 next copy exit  ;
a: up e for up1 next noop exit ;

: for >r begin ; ( 从0开始计数，2 for ... next 循环3次 )
: next r@ while r> 1- >r repeat r> drop ;

=pick org

    ]asm down up asm[
	
there constant =pickbody

	copy ]asm return asm[
	ac 2 * ]asm call asm[ cc 2 * ]asm branch asm[
	aa 2 * ]asm call asm[ ca 2 * ]asm branch asm[
	a8 2 * ]asm call asm[ c8 2 * ]asm branch asm[
	a6 2 * ]asm call asm[ c6 2 * ]asm branch asm[
	a4 2 * ]asm call asm[ c4 2 * ]asm branch asm[
	a2 2 * ]asm call asm[ c2 2 * ]asm branch asm[
	a0 2 * ]asm call asm[ c0 2 * ]asm branch asm[
	9e 2 * ]asm call asm[ be 2 * ]asm branch asm[
	9c 2 * ]asm call asm[ bc 2 * ]asm branch asm[
	9a 2 * ]asm call asm[ ba 2 * ]asm branch asm[
	98 2 * ]asm call asm[ b8 2 * ]asm branch asm[
	96 2 * ]asm call asm[ b6 2 * ]asm branch asm[
	94 2 * ]asm call asm[ b4 2 * ]asm branch asm[
	92 2 * ]asm call asm[ b2 2 * ]asm branch asm[
	90 2 * ]asm call asm[ b0 2 * ]asm branch asm[
	]asm return asm[

=cold org
0 t32,

there constant =uzero
   =base t32, ( base )
   0 t32,     ( temp )
   0 t32,     ( >in )		( 指向当前被操作字符的指针，值为距起始输入缓冲区的位移 )
   0 t32,     ( #tib )      ( 终端输入缓冲区可容纳的字符个数 )
   =tib t32,  ( tib )       ( 终端输入缓冲区的起始地址 )
   0 t32,     ( 'eval )     ( 存储文本解释程序的pc即tdp指针 )
   0 t32,     ( 'abort )
   0 t32,     ( 'pad )       ( <# #>词的缓冲区 )

            ( context )

   0 t32, 0 t32, 0 t32, 0 t32, 0 t32, 0 t32, 0 t32, 0 t32, 0 t32,

            ( forth-wordlist )

   0 t32,     ( na, of last definition, linked )
   0 t32,     ( wid|0, next or last wordlist in chain )
   0 t32,     ( na, wordlist name pointer )

            ( current ) ( 当前词典中最后一个词的link域指针 )

   0 t32,     ( wid, new definitions )
   0 t32,     ( wid, head of chain )

   0 t32,     ( dp )		( 可用空间指针，指向词典中下一个可用的主存单元 )
   0 t32,     ( last )      ( 最后一个词的名字域指针 )
   0 t32,     ( '?key )
   0 t32,     ( 'emit )
   0 t32,     ( 'boot )
   0 t32,     ( '\ )
   0 t32,     ( '?name )
   0 t32,     ( '$,n )
   0 t32,     ( 'overt )
   0 t32,     ( '; )
   0 t32,     ( 'create )
   
   0 t32,     ( mdp )
   \ core-next-mem ( core-task )
   0 t32, 0 t32, there 8 - t32, ( readylist0,readylist0-num,readylist0-tail ) 
   0 t32, 0 t32, there 8 - t32, ( readylist1,readylist1-num,readylist1-tail ) 
   0 t32, 0 t32, there 8 - t32, ( readylist2,readylist2-num,readylist2-tail ) 
   0 t32, 0 t32, there 8 - t32, ( readylist3,readylist3-num,readylist3-tail ) 
   0 t32, 0 t32, there 8 - t32, ( readylist4,readylist4-num,readylist4-tail ) 
   0 t32, 0 t32, there 8 - t32, ( blocklist ,blocklist-num ,blocklist-tail  )
   0 t32, 0 t32, there 8 - t32, ( alllist   ,alllist-num   ,alllist-tail    )
   0 t32,     ( scheduler-critical 调度临界区变量 )
   0 t32,     ( mdp-critical 可用空间临界区变量 )
   0 t32,     ( alst-critcal 可用空间临界区变量 )
   0 t32,     ( terminal-num )
   0 t32,     ( core-task )
there constant =ulast
=ulast =uzero - constant =udiff

=code org

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ \ 												target词汇构建过程                                                 \\
\ \ 1.首先 t：把跟在其后的第一个target词名存在tflash[tdp]处，存储完成后tdp指针移动到最后一个字符之后的16bit对齐位置上. \\
\ \ 2.紧接着t：会在target词表中创建一个词，词名仍是t：后的第一个词名，词头创建好后在词的词身（body）处保存当前tdp的值。\\
\ \ 	**并且，给该词添加运行时间代码call，当调用该词的时候，系统会执行[call tdp]指令，将pc指向tflash[tdp]处。**      \\
\ \ 3.到此t：执行完成。然后执行target词名之后的汇编词汇（a:开头定义的词汇），汇编词汇会在当前tflash[tdp]处写入对应的指 \\
\ \ 	令，tdp指针向后推进。                                                                                          \\
\ \ 4.最后执行t; 判断汇编词汇的最后一条指令是否是跳转指令，是则跳转，否则在当前tflash[tdp]处加入一条返回指令。         \\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ target词汇结构
\ target词表中：
\			词名（开头一个字节存放词名字符个数）| ··· @ [a] call 或者 @ [a] literal | tdp指针的值
\ tflash中：
\			词名（开头一个字节存放词名字符个数）| 若干运行指令 + 返回指令			




t: noop noop t;
t: + + t;
t: xor xor t;
t: and and t;
t: or or t;
t: invert invert t;
t: = = t;
t: < < t;
t: u< u< t;
t: swap swap t;
t: u> swap u< t;
t: dup dup t;
t: drop drop t;
t: over over t;
t: nip nip t;
t: lshift lshift t;
t: rshift rshift t;
t: 1- 1- t;
t: >r r> swap >r >r t; compile-only
t: r> r> r> swap >r t; compile-only
t: r@ r> r> dup >r swap >r t; compile-only
t: @ ( a -- w ) @ t;
t: ! ( w a -- ) ! t;

t: <> = invert t;
t: 0< 0 literal < t;
t: 0= 0 literal = t;
t: > swap < t;
t: 0> 0 literal swap < t;
t: >= < invert t;
t: tuck swap over t;
t: -rot swap >r swap r> t;
t: 2/ 1 literal rshift t;
t: 2* 1 literal lshift t;
t: 1+ 1 literal + t; 
t: sp@ dsp ff literal and t;
t: rp@ dsp 8 literal rshift ff literal and 1- t;
t: execute ( ca -- ) >r t;
t: bye ( -- ) f0000002 literal ! t;
\ c@ c! 需要乘法 故写在472行重写
\ t: c@ ( b -- c )   dup @ swap 1 literal and if    8 literal rshift else ff literal and then exit t;
\ t: c! ( c b -- )   swap ff literal and dup 8 literal lshift or swap    tuck dup @ swap 1 literal and 0 literal = ff literal xor    >r over xor r> and xor swap ! t;
t: um+ ( w1 w2 -- w1+w2 1or0 )  \ 1or0 表示w1和w2中是否有负数 有为1 反之0
  over over + >r
   r@ 0 literal >= >r
    over over and
	 0< r> or >r
   or 0< r> and invert 1+
  r> swap t;
t: dovar ( -- a ) r> t; compile-only
t: up dovar =up t32, t;
t: douser ( -- a ) up @ r> @ + t; compile-only

u: base
u: temp
u: >in
u: #tib
u: tib
u: 'eval
u: 'abort
u: 'pad
u: context
	=vocs =cell * tuser +!
u: forth-wordlist
    =cell tuser +!
	=cell tuser +!
u: current
	=cell tuser +!
u: dp
u: last
u: '?key
u: 'emit
u: 'boot
u: '\
u: 'name?
u: '$,n
u: 'overt
u: ';
u: 'create

u: mdp
\ u: core0-task
    \ =core-num 1 - =cell * tuser +!
u: task-readylist0 
   2 =cell * tuser +!
u: task-readylist1 
   2 =cell * tuser +!
u: task-readylist2 
   2 =cell * tuser +!
u: task-readylist3 
   2 =cell * tuser +!
u: task-readylist4 
   2 =cell * tuser +!
u: task-blocklist
   2 =cell * tuser +!
u: task-alllist
   2 =cell * tuser +!
u: scheduler-critical
u: mdp-critical
u: alst-critcal
u: terminal-num
u: core0-task

t: ?dup ( w -- w w | 0 ) dup if dup then exit t;
t: rot ( w1 w2 w3 -- w2 w3 w1 ) >r swap r> swap t;
t: 2drop ( w w -- ) drop drop t;
t: 2dup ( w1 w2 -- w1 w2 w1 w2 ) over over t;
t: negate ( n -- -n ) invert 1+ t; \ 获得负数  补码
t: dnegate ( d -- -d ) \ 双字长 负数 补码
   invert >r invert 1 literal um+ r> + t;
t: - ( n1 n2 -- n1-n2 ) negate + t;
t: abs ( n -- n ) dup 0< if negate then exit t;
t: max ( n n -- n ) 2dup > if drop exit then nip t;
t: min ( n n -- n ) 2dup < if drop exit then nip t;
t: within ( u ul uh -- t ) over - >r - r> u< t;
t: um/mod ( udl udh u -- ur uq )
   2dup u< if
    negate 1f literal
     for >r dup um+ >r >r dup um+ r> + dup
     r> r@ swap >r um+ r> or if
      >r drop 1+ r>
     else
      drop
     then r>
     next drop swap exit
   then drop 2drop -1 literal dup t;
t: m/mod ( d n -- r q )
   dup 0< dup >r if
    negate >r dnegate r>
   then >r dup 0< if
    r@ +
   then r> um/mod r> if
    swap negate swap then exit t;
t: /mod ( n n -- r q ) over 0< swap m/mod t;
t: mod ( n n -- r ) /mod drop t;
t: / ( n n -- q ) /mod nip t;
t: um* ( u u -- ud )
   0 literal swap 1f literal
    for dup um+ >r >r dup um+ r> + r> if
    >r over um+ r> + then
    next rot drop t;
t: * ( n n -- n ) um* drop t;

\ ****c@ 重写**********
t: c@ ( addr -- char )
	dup @ swap 3 literal and 
	dup 1 literal = if
		drop 8 literal rshift 
	else
		dup 2 literal = if
			drop 10 literal rshift
		else
			dup 3 literal = if
				drop 18 literal rshift
			else
				drop
			then				
		then
	then 
	ff literal and exit t;
t: c! ( c a -- )
	dup rot ff literal and swap
	dup @ >r 3 literal and 
	dup 1 literal = if
		drop ffff00ff literal r> and >r
		8 literal lshift r>
	else
		dup 2 literal = if
			drop ff00ffff literal r> and >r
			10 literal lshift r>
		else
			dup 3 literal = if
				drop 00ffffff literal r> and >r
				18 literal lshift r>
			else
				drop ffffff00 literal r> and
			then
		then
	then or swap ! t;
\ *********************

t: m* ( n n -- d )
   2dup xor 0< >r abs swap abs um* r> if
    dnegate then exit t;
t: */mod ( n1 n2 n3 -- r q ) >r m* r> m/mod t;
t: */ ( n1 n2 n3 -- q ) */mod nip t;
t: cell+ ( a -- a ) =cell literal + t;
t: cell- ( a -- a ) =cell literal - t;
t: cells ( n -- n ) 2 literal lshift t;
t: bl ( -- 32 ) 20 literal t;
t: >char ( c -- c )
   7f literal and dup 7f literal bl within if
    drop 5f literal then exit t;
t: +! ( n a -- ) tuck @ + swap ! t;
t: 2! ( d a -- ) swap over ! cell+ ! t;
t: 2@ ( a -- d ) dup cell+ @ swap @ t;

( ********************************************************* )
t: >tcb-ready ( >tcb-a -- >tcb ) 4 literal - t;
t: >tcb-all   ( >tcb -- >tcb-a ) 4 literal + t;
t: >tcb-priority ( >tcb -- >tcb-priority ) 8 literal + t;
t: >tcb-name           c literal + t;
t: >tcb-sp             10 literal + t;
t: >tcb-data           14 literal + t;
t: >tcb-rp             18 literal + t;
t: >tcb-return         1c literal + t;
t: >tcb-terminal-num   20 literal + t;
t: >tcb-state          24 literal + t;
t: >tcb-pc             28 literal + t;
t: >tcb-memory-num     2c literal + t;
t: >tcb-memory-pointer 30 literal + t;
t: >tcb-memory         34 literal + t;
( ********************************************************* )

t: count ( b -- b+1 n ) dup 1+ swap c@ t;
t: mhere ( -- addr ) mdp @ t; ( 可用内存首地址 )
t: here ( -- a ) dp @ t; ( 该任务的可用空间的指针 )
t: aligned ( b -- a ) dup =cell literal 1- and dup if =cell literal swap - then + t;
t: align ( -- ) here aligned dp ! t;
t: @execute ( a -- ) @ ?dup if execute then exit t;
t: pad ( -- a ) 'pad @execute t;

t: fill ( a u c -- )
   swap for swap aft 2dup c! 1+ then next 2drop t; 
t: erase 0 literal fill t;
t: digit ( u -- c ) 9 literal over < 7 literal and + 30 literal + t;
t: extract ( n base -- n c ) 0 literal swap um/mod swap digit t;
t: hld ( -- a ) get-tcb >tcb-memory-pointer t;
t: <# ( -- ) pad hld ! t;
t: hold ( c -- ) hld @ 1- dup hld ! c! t;
t: # ( u -- u ) base @ extract hold t;
t: #s ( u -- 0 )  begin # dup while repeat t;
t: sign ( n -- ) 0< if 2d literal hold then exit t;
t: #> ( w -- b u ) drop hld @ pad over - t;
t: str ( n -- b u ) dup >r abs <# #s r> sign #> t;
t: hex ( -- ) 10 literal base ! t;
t: decimal ( -- ) a literal base ! t;
t: digit? ( c base -- u t ) \ 将c转换为base进制的数字  如果是该进制的数字则为1 反正为0   b 10 -- 11 0  ,   b 16 -- b 1
   >r 30 literal - 9 literal  over < if
    dup 20 literal > if
	 20 literal  -
	then
	7 literal - dup a literal  < or
   then dup r> u< t;
t: number? ( a -- n t | a f )
   base @ >r 0 literal over count
   over c@ 24 literal = if
    hex swap 1+ swap 1- then
   over c@ 2d literal = >r
   swap r@ - swap r@ + ?dup if
    1-
     for dup >r c@ base @ digit?
       while swap base @ * + r> 1+
     next r@ nip if
	  negate then swap
     else r> r> 2drop 2drop 0 literal
      then dup
   then r> 2drop r> base ! t;
t: ?rx ( -- c t | f ) f0000001 literal @ 1 literal and 0= invert t;
t: tx! ( c -- )
   begin
    f0000001 literal @ 2 literal and 0=
   until f0000000 literal ! t;
t: ?key ( -- c ) '?key @execute t;
t: emit ( c -- ) 'emit @execute t;
t: key ( -- c )
    begin
     ?key
	until f0000000 literal @ t;
t: nuf? ( -- t ) ?key dup if drop key =cr literal = then exit t; \ 是否从串口rx处接收到了回车符 是返回1 反之0
t: space ( -- ) bl emit t;
t: spaces ( +n -- ) 0 literal max  for aft space then next t;
t: type ( b u -- ) for aft count emit then next drop t;
t: cr ( -- ) =cr literal emit =lf literal emit t;
t: do$ ( -- a ) r> r@ r> count + aligned >r swap >r t; compile-only \ 取出字符串的收尾地址 放首地址在参数栈 放尾地址在返回栈
t: $"| ( -- a ) do$ noop t; compile-only
t: .$ ( a -- ) count type t;
t: ."| ( -- ) do$ .$ t; compile-only
t: .r ( n +n -- ) >r str r> over - spaces type t;
t: u.r ( u +n -- ) >r <# #s #> r> over - spaces type t;
t: u. ( u -- ) <# #s #> space type t;
t: . ( w -- ) base @ a literal xor if u. exit then str space type t;
t: cmove ( b1 b2 u -- ) for aft >r dup c@ r@ c! 1+ r> 1+ then next 2drop t;
t: pack$ ( b u a -- a ) dup >r 2dup ! 1+ swap cmove r> t; ( 将一堆非字符串的字符从b处搬运到a处，并在a处形成字符串 )
t: ? ( a -- ) @ . t;
t: (parse) ( b u c -- b u delta ; <string> )
	temp ! over >r dup if
		1- temp @ bl = if
			for
				count temp @ swap - 0< invert r@ 0> and
				while
					next r> drop 0 literal dup exit
	 			then 1- r>
    	then over swap
			for
				count temp @ swap - temp @ bl = if
				0< then
				while 
					next dup >r 
				else r> drop dup >r 1-
     			then over - r> r> - exit
   then over r> - t;
t: parse ( c -- b u ; <string> )
   >r
   tib @ >in @ +
   #tib @ >in @ - r>
   (parse)
   >in +! t;
t: .( ( -- ) 29 literal parse type t; immediate
t: ( ( -- ) 29 literal parse 2drop t; immediate
t: <\> ( -- ) #tib @ >in ! t; immediate
t: \ ( -- ) '\ @execute t; immediate
t: word ( c -- a ; <string> ) parse here cell+ pack$ t;
t: token ( -- a ; <string> ) bl word t;
t: name> ( na -- ca ) count 1f literal and + aligned t;
t: same? ( a a u -- a a f \ -0+ ) 
   3 literal -
    for aft over r@ + c@
     over r@ + c@ - ?dup
   if r> drop exit then then
    next 0 literal t;
t: find ( a va -- ca na | a f )  ( va为词汇变量 变量中存放的是该词汇中最后定义一个词的nfa（词名地址）) 
	swap
	dup c@ temp !
	dup @ >r
	cell+ swap
	begin
		@ dup if 
			dup @ =mask literal and r@ 
			xor if 
				cell+ -1 literal 
			else 
				dup c@ 1f literal and 3 literal u< if
					cell+ 0 literal
				else
					cell+ temp @ same? 
				then
			then
		else 
			r> drop swap cell- swap exit
		then
	while
		2 literal cells -
	repeat r> drop nip cell- dup name> swap t;
t: <name?> ( a -- ca na | a f )
   context dup 2@ xor if cell- then >r
    begin
	 r> cell+ dup >r @ ?dup
    while
	 find ?dup
    until r> drop exit then r> drop 0 literal t;
t: name? ( a -- ca na | a f ) 'name? @execute t;
t: ^h ( bot eot cur -- bot eot cur )
   >r over r@ < dup if
    =bksp literal dup emit space
	emit then r> + t;
t: tap ( bot eot cur c -- bot eot cur )
   dup emit over c! 1+ t;
t: ktap ( bot eot cur c -- bot eot cur )
   dup =cr literal xor if
    =bksp literal xor if
     bl tap exit
    then ^h exit
   then drop nip dup t;
t: accept ( b u -- b u )
   over + over
    begin
    2dup xor
    while
      key dup bl - 7f literal u< if tap else ktap then
    repeat drop over - t;
t: query ( -- ) tib @ 50 literal accept #tib ! drop 0 literal >in ! t;
t: abort2 do$ drop t;
t: abort1 space .$ 3f literal emit cr  t; ( 'abort @execute abort2 )
t: <?abort"> if do$ abort1 exit then abort2 t; compile-only
t: forget ( -- )
   token name? ?dup if
    cell- dup dp !
     @ dup context ! last !
     drop exit
   then abort1 t;
t: $interpret ( a -- )
	name? ?dup if
    	@ =comp literal and
    	<?abort"> 32$literal compile-only" execute exit
	else
		number? if
			exit 
		then abort1 
	then noop t;
t: [ ( -- ) [t] $interpret literal 'eval ! t; immediate
t: .ok ( -- )
   [t] $interpret literal 'eval @ = if
    ."| 32$literal  ok"
   then cr t;
t: eval ( -- )
    begin
     token dup c@
    while
	 'eval @execute
    repeat drop .ok t;
t: $eval ( a u -- )
   >in @ >r #tib @ >r tib @ >r
   [t] >in literal 0 literal swap !
    #tib ! tib ! eval r> tib ! r> #tib ! r> >in ! t; compile-only
t: preset ( -- ) =tib literal #tib cell+ ! t;
t: quit ( -- )
   .ok 'boot @execute .ok
   [ begin
	 query eval
   again t;
t: abort drop preset .ok quit t;
t: ' ( -- ca ) token name? if exit then abort1 t;
t: allot ( n -- ) aligned dp +! t;
t: , ( w -- ) here dup cell+ dp ! ! t;
t: call, ( ca -- ) 2 literal rshift 40000000 literal or , t; compile-only
t: ?branch ( ca -- ) 2 literal rshift 20000000 literal or , t; compile-only
t: branch ( ca -- ) 2 literal rshift 00000000 literal or , t; compile-only
t: [compile] ( -- ; <string> ) ' call, t; immediate
t: compile ( -- ) r> dup @ , cell+ >r t; compile-only
t: recurse last @ name> call, t; immediate
t: pick dup 2* 2* 2* =pickbody literal + >r t;
t: literal ( w -- )
   dup 80000000 literal and if
    ffffffff literal xor [t] literal ]asm call asm[ compile invert
   else
    80000000 literal or ,
   then exit t; immediate
t: ['] ' [t] literal ]asm call asm[ t; immediate
t: $," ( -- ) 22 literal parse here pack$ count + aligned dp ! t;
t: for ( -- a ) compile [t] >r ]asm call asm[ here t; compile-only immediate
t: begin ( -- a ) here t; compile-only immediate
t: (next) ( n -- ) r> r> ?dup if 1- >r @ >r exit then cell+ >r t; compile-only
t: next ( -- ) compile (next) , t; compile-only immediate
t: (do) ( limit index -- index ) r> dup >r swap rot >r >r cell+ >r t; compile-only
t: do ( limit index -- ) compile (do) 0 literal , here t; compile-only immediate
t: (leave) r> drop r> drop r> drop t; compile-only
t: leave compile (leave) noop t; compile-only immediate
t: (loop)
   r> r> 1+ r> 2dup <> if
    >r >r @ >r exit
   then >r 1- >r cell+ >r t; compile-only
t: (unloop) r> r> drop r> drop r> drop >r t; compile-only
t: unloop compile (unloop) noop t; compile-only immediate
t: (?do)
   2dup <> if
     r> dup >r swap rot >r >r cell+ >r exit
   then 2drop exit t; compile-only
t: ?do ( limit index -- ) compile (?do) 0 literal , here t; compile-only immediate
t: loop ( -- ) compile (loop) dup , compile (unloop) cell- here 2 literal rshift swap ! t; compile-only immediate
t: (+loop)
   r> swap r> r> 2dup - >r
   2 literal pick r@ + r@ xor 0< 0=
   3 literal pick r> xor 0< 0= or if
    >r + >r @ >r exit
   then >r >r drop cell+ >r t; compile-only
t: +loop ( n -- ) compile (+loop) dup , compile (unloop) cell- here 2 literal rshift swap ! t; compile-only immediate
t: (i) ( -- index ) r> r> tuck >r >r t; compile-only
t: i ( -- index ) compile (i) noop t; compile-only immediate
t: until ( a -- ) ?branch t; compile-only immediate
t: again ( a -- ) branch t; compile-only immediate
t: if ( -- a ) here 0 literal ?branch t; compile-only immediate
t: then ( a -- ) here 2 literal rshift over @ or swap ! t; compile-only immediate
t: repeat ( a a -- ) branch [t] then ]asm call asm[ t; compile-only immediate
t: skip here 0 literal branch t; compile-only immediate
t: aft ( a -- a a ) drop [t] skip ]asm call asm[ [t] begin ]asm call asm[ swap t; compile-only immediate
t: else ( a -- a ) [t] skip ]asm call asm[ swap [t] then ]asm call asm[ t; compile-only immediate
t: while ( a -- a a ) [t] if ]asm call asm[ swap t; compile-only immediate
t: (case) r> swap >r >r	t; compile-only
t: case compile (case) 30 literal t; compile-only immediate
t: (of) r> r@ swap >r = t; compile-only
t: of compile (of) [t] if ]asm call asm[ t; compile-only immediate
t: endof [t] else ]asm call asm[ 31 literal t; compile-only immediate
t: (endcase) r> r> drop >r t;
t: endcase
   begin
    dup 31 literal =
   while
    drop			
    [t] then ]asm call asm[
   repeat
   30 literal <> <?abort"> 32$literal bad case construct."
   compile (endcase) noop t; compile-only immediate
t: $" ( -- ; <string> ) compile $"| $," t; compile-only immediate
t: ." ( -- ; <string> ) compile ."| $," t; compile-only immediate
t: >body ( ca -- pa ) cell+ t;
t: (to) ( n -- ) r> dup cell+ >r @ ! t; compile-only
t: to ( n -- ) compile (to) ' >body , t; compile-only immediate
t: (+to) ( n -- ) r> dup cell+ >r @ +! t; compile-only
t: +to ( n -- ) compile (+to) ' >body , t; compile-only immediate
t: get-current ( -- wid ) current @ t;
t: set-current ( wid -- ) current ! t;
t: definitions ( -- ) context @ set-current t;
t: ?unique ( a -- a )
   dup get-current find if ."| 32$literal  redef " over .$ then drop t;
t: <$,n> ( na -- ) ( 创建一个新词的名字域和link链接域 )
	dup c@ if
    	?unique
		dup count + aligned
		dp !
    	dup last ! 
    	cell-
    	get-current @
    	swap ! exit
	then drop $"| 32$literal name" abort1 t;
t: $,n ( na -- ) '$,n @execute t;
t: $compile ( a -- )
   name? ?dup if
    @ =imed literal and if
	 execute exit
	 else call, exit
	then
   then
   number? if
     [t] literal ]asm call asm[ exit then abort1 t;
t: abort" compile <?abort"> $," t; immediate
t: <overt> ( -- ) last @ get-current ! t;
t: overt ( -- ) 'overt @execute t;
t: exit r> drop t;
t: <;> ( -- )
   compile [t] exit ]asm call asm[
   [ overt 0 literal here ! t; compile-only immediate
t: ; ( -- ) '; @execute t; compile-only immediate
t: ] ( -- ) [t] $compile literal 'eval ! t;
t: : ( -- ; <string> ) token $,n ]  t;
t: immediate ( -- ) =imed literal last @ @ or last @ ! t;
t: user ( u -- ; <string> ) token $,n overt compile douser , t;
t: <create> ( -- ; <string> ) token $,n overt [t] dovar ]asm literal asm[ call, t;
t: create ( -- ; <string> ) 'create @execute t;
t: variable ( -- ; <string> ) create 0 literal , t;
t: (does>) ( -- )
   r> 2 literal rshift here 2 literal rshift
   last @ name> dup cell+ ]asm 80000000 literal asm[ or , ! , t; compile-only
t: compile-only ( -- ) =comp literal last @ @ or last @ ! t;
t: does> ( -- ) compile (does>) noop t; immediate
t: char ( <char> -- char ) ( -- c ) bl word 1+ c@ t;
t: [char] char [t] literal ]asm call asm[ t; immediate
t: constant create , (does>) @ t;
t: defer create 0 literal , 
   (does>) 
    @ ?dup 0 literal =
   <?abort"> 32$literal uninitialized" execute t;
t: is ' >body ! t; immediate
t: .id ( na -- )
   ?dup if
   count 1f literal and type exit then
   cr ."| 32$literal {noname}" t;
t: wordlist ( -- wid ) align here 0 literal , dup current cell+ dup @ , ! 0 literal , t;
t: order@ ( a -- u*wid u ) dup @ dup if >r cell+ order@ r> swap 1+ exit then nip t;
t: get-order ( -- u*wid u ) context order@ t;
t: >wid ( wid -- ) cell+ t;
t: .wid ( wid -- )
   space dup >wid cell+ @ ?dup if .id drop exit then 0 literal u.r t;
t: !wid ( wid -- ) >wid cell+ last @ swap ! t;
t: vocs ( -- ) ( list all wordlists )
   cr ."| 32$literal vocs:" current cell+
   begin
    @ ?dup
   while
    dup .wid >wid
   repeat t;
t: order ( -- ) ( list search order )
   cr ."| 32$literal search:" get-order
   begin
    ?dup
   while
    swap .wid 1-
   repeat
   cr ."| 32$literal define:" get-current .wid t;
t: set-order ( u*wid n -- ) ( 16.6.1.2197 )
   dup -1 literal = if
   drop forth-wordlist 1 literal then
   =vocs literal over u< <?abort"> 32$literal over size of #vocs"
   context swap
   begin
    dup
   while
    >r swap over ! cell+ r>
    1-
   repeat swap ! t;
t: only ( -- ) -1 literal set-order t;
t: also ( -- ) get-order over swap 1+ set-order t;
t: previous ( -- ) get-order swap drop 1- set-order t;
t: >voc ( wid 'name' -- )
   create dup , !wid
   (does>)
	 @ >r get-order swap drop r> swap set-order t;
t: widof ( "vocabulary" -- wid ) ' >body @ t;
t: vocabulary ( 'name' -- ) wordlist >voc t;
t: _type ( b u -- )  for aft count >char emit then next drop t;
t: dm+ ( a u -- a )
   over 4 literal u.r space
   for aft count 3 literal u.r then next t;
t: dump ( a u -- )
   base @ >r hex 10 literal /
   for cr 10 literal 2dup dm+ -rot
   2 literal spaces _type
   next drop r> base ! t;
t: .s ( ... -- ... ) cr sp@ 1- f literal and for r@ pick . next ."| 32$literal <tos" t;
t: (>name) ( ca va -- na | f )
   begin
    @ ?dup
   while
    2dup name> xor
     while cell-
   repeat nip exit
   then drop 0 literal t;
t: >name ( ca -- na | f )
   >r get-order
   begin
	  ?dup
   while
	  swap
	  r@ swap
	  (>name)
	  ?dup if
		>r
		1- for aft drop then next
		r> r> drop
		exit
	  then
	  1-
   repeat
   r> drop 0 literal t;
t: see ( -- ; <string> )
   ' cr
   begin
    dup @ ?dup 6000100c literal xor
   while
    3fffffff literal and 2 literal lshift
	>name ?dup if
     space .id
	else
	  dup @ 7fffffff literal and u.
	then
	cell+
   repeat 2drop t;
t: (words) ( -- )
   cr
   begin
    @ ?dup
   while
    dup .id space cell-
   repeat t;
t: words
   get-order
   begin
	  ?dup
   while
	  swap
	  cr cr ."| 32$literal :" dup .wid cr
	  (words)
	  1-
   repeat t;
t: ver ( -- n ) =ver literal 100 literal * =ext literal + t;
t: hi ( -- )
   cr ."| 32$literal eforth j1_32 v"
	base @ hex
	ver <# # # 2e literal hold # #>
	type base ! cr t;

( t: get-tcb get-tcb t;               )
( t: get-pc get-pc t;                 )
( t: get-core-num get-core-num t;     )
( t: get-core-total get-core-total t; )
( t: get-scheduler get-scheduler t;   )
( t: get-critical get-critical t;     )

( t: interrupt-return interrupt-return t; )

( t: set-pc set-pc t;                  )
( t: set-tcb set-tcb t;                )
( t: apply-scheduler apply-scheduler t; ) 
( t: free-scheduler free-scheduler t;  )
( t: critical-in critical-in t;        )
( t: critical-out critical-out t;      )
( t: close-time close-time t;          )
( t: open-time open-time t;            )
( t: set-time set-time t;              )



t: >list-num  ( >list -- >list-num )  4 literal + t; ( 获得队列列表数 )
t: >list-tail ( >list -- >list-tail ) 8 literal + t; ( 获得队列队尾指针 )
t: >next-list ( >list -- >list-next ) c literal + t; ( 获得下一个就绪队列指针 )

t: >critical-alst
    close-time
    begin
	    critical-in ( 申请进入临界区 )
        get-critical if  ( 是否获得进入临界区资格 )
            scheduler-critical @ 0= if ( 查询是否该临界资源被占用 )
                1 literal alst-critcal ! ( 占用该资源 )
                critical-out ( 退出临界区 )
                1 literal ( 退出循环 )
            else
                0 literal ( 继续循环 )
            then
        else 
            0 literal ( 继续循环 )
        then 
    until t;

t: critical-alst> 0 literal alst-critcal ! open-time t; ( 释放该资源 )

t: into-alllist ( >tcb -- )
    >tcb-all task-alllist over over >list-tail @ ! ( >tcb -- >tcb-a >alllist ) ( 将tcb插入到最后一个tcb之后 )
    swap over >list-tail ! ( >tcb-a >alllist -- >alllist ) ( 将队列尾部指向该tcb )
    >list-num dup @ 1 literal + swap ! t; ( >alllist -- ) ( 将队列数减一 )

t: find-all ( >na -- >tcb-pre >tcb | >na false )
    task-alllist dup >list-num @ if ( >na -- >na >alllist ) ( 判断队列是否有任务 )
        begin ( >na >alllist -- >na >tcb-a )
            dup >r @ dup if ( >na >tcb0-a -- >na >tcb1-a|0 ) ( 判断是否不是队尾 )
                over over >tcb-ready >tcb-name @ = if ( >na >tcb1-a -- >na >tcb1-a ) ( 判断是否匹配名字 )
                    swap drop r> swap 1 literal ( >na >tcb1-a -- >tcb1-a >tcb0-a true ) ( 匹配，丢弃名字 )
                else r> drop 0 literal ( >na >tcb1-a -- >na >tcb1-a false ) ( 不匹配继续寻找下一个tcb )
                then
            else r> drop 1 literal ( >na 0 -- >na false true ) ( 队尾，结束循环 )
            then
        until
    else drop 0 literal ( >na >alllist -- >na false ) ( 队列没有任务 )
    then noop t;
    
t: out-alllist ( >na -- >tcb|false )
    task-alllist dup >list-num @ if ( >na -- >na >alllist ) ( 判断队列是否有任务 )
        begin ( >na >alllist -- >na >tcb-a )
            dup >r @ dup if ( >na >tcb0-a -- >na >tcb1-a|0 ) ( 判断是否不是队尾 )
                over over >tcb-ready >tcb-name @ = if ( >na >tcb1-a -- >na >tcb1-a ) ( 判断是否匹配名字 )
                    swap drop dup @ if ( >na >tcb1-a -- >tcb1-a >tcb2-a|0 ) ( 判断是否不是队尾 )
                        r> ! ( >tcb1-a >tcb2-a -- >tcb1-a ) ( 不是队尾则把上一个tcb指向下一个tcb )
                    else 
                        drop r@ task-alllist >list-tail ! ( >tcb1-a 0 -- >tcb1-a ) ( 是队尾则把队尾指向上一个tcb )
                        0 literal r> ! ( >tcb1-a -- >tcb1-a ) ( 把上一个tcb指向0 表示队尾 )
                    then task-alllist >list-num dup @ 1- swap ! >tcb-ready 1 literal ( >tcb1-a -- >tcb1 true ) ( 队列任务数减一 )
                else r> drop 0 literal ( >na >tcb1-a -- >na >tcb1-a false ) ( 不匹配继续寻找下一个tcb )
                then
            else swap drop r> drop 1 literal ( >na 0 -- false true ) ( 队尾，结束循环 )
            then
        until
    else drop drop 0 literal ( >na >alllist -- false ) ( 队列没有任务 )
    then noop t;
    

t: into-readylist ( >tcb -- ) ( 将tcb插入到就绪队列队尾 )
    dup >tcb-priority @ dup 0= if ( >tcb -- >tcb priority ) ( 获得任务优先级,根据优先级获得对应的就绪任务队列；注：此时的>tcb为就绪列表链接 )
        drop task-readylist0 ( >tcb priority -- >tcb >readylist )
    else ( >tcb priority -- >tcb priority )
        task-readylist0 swap 1 literal - for ( >tcb priority -- >tcb >readylist )
            >next-list
        next ( >tcb -- >tcb >readylist )
    then ( >tcb priority -- >tcb >readylist )
    over dup 0 literal swap ! ( >tcb >readylist -- >tcb >readylist >tcb) ( 将需要插入就绪队列的tcb的就绪队列指针置为0 )
    over >list-tail @ ! ( >tcb >readylist >tcb -- >tcb >readylist ) ( 将队列最后一个tcb的就绪队列指针指向要插入队列的tcb )
    dup >r >list-tail ! ( >tcb >readylist -- ) ( 将队列尾部置为的就绪指针指向该tcb )
    r> >list-num dup @ 1+ swap ! t; ( -- ) ( 就绪队列tcb数加1 )
    
t: out-readylist ( mode -- >tcb|0 ) ( 根据模式选择一个对应的tcb出队，mode ：0，就绪任务；4阻塞任务 )
    0= if ( mode -- )
        task-readylist0 =sys-list-num literal 1- for ( -- >readylist )
            dup dup >r >list-num @ if ( >readylist -- >readylist ) ( 当前队列是否有任务 )
                begin ( >tcb -- >tcb)
                    dup @ dup >tcb-state @ =task-ready literal = if ( >tcb0 --- >tcb0 >tcb1 ) ( 是否是就绪态tcb )
                        dup >r @ dup 0= if ( >tcb0 >tcb1 -- >tcb0 >tcb2 ) ( 是否是队尾 )
                            drop r> r@ swap >r >list-tail over swap ! ( >tcb0 >tcb2 -- >tcb0 ) ( 将队尾指针指向前一个tcb )
                            0 literal ( >tcb0 -- >tcb0 0 ) ( 将0放置堆栈 )
                        then swap ! ( >tcb0 >tcb2 -- ) ( 将下一个指针存入前一个tcb中 )
                        r> r@ >list-num dup @ 1- swap ! ( -- >tcb1 ) ( 将队列tcb数减1 )
                        r> drop r> drop 0 literal >r 1 literal ( >tcb1 -- >tcb1 true ) ( 结束两个循环 )
                    else ( 不是就绪态 )
                        swap drop ( >tcb0 >tcb1 -- >tcb1 ) ( 丢弃上一个tcb地址 )
                        dup @ if ( >tcb1 -- >tcb1 ) ( 判断本tcb是否不是队尾 )
                            0 literal  ( >tcb1 -- >tcb1 false )  ( 不是队尾则继续循环 )
                        else 
                            drop r> r@ if ( >tcb1 -- >readylist ) ( 是队尾则判断是否不是最后一个就绪队列 )
                                >next-list ( >readylist -- >readylist-next ) ( 不是最后一个就绪队列 则进入下一个队列 )
                            else 
                                drop 0 literal ( >readylist -- 0 ) ( 是最后一个就绪队列 则在堆栈上放0 表示没有找到对应的任务 )
                            then 1 literal ( >readylist-next -- >readylist-next true ) ( 结束本次循环 )
                        then ( >tcb1 -- >readylist-next|0 true|false )
                    then
                until
            else ( 没有任务 )
                drop r> r@ if >next-list else drop 0 literal then ( >readylist -- >readylist-next|0 ) ( 若是最后一个就绪队列 则在堆栈上放0 表示没有找到对应的任务，否则进入下一个队列 )
            then
        next
    else
        task-readylist0 =sys-list-num literal 1- for ( -- >readylist )
            dup dup >r >list-num @ if ( >readylist -- >readylist ) ( 当前队列是否有任务 )
                begin ( >tcb -- >tcb)
                    dup @ dup >tcb-state @ =task-block literal = if ( >tcb0 --- >tcb0 >tcb1 ) ( 是否是就绪态tcb )
                        dup >r @ dup 0= if ( >tcb0 >tcb1 -- >tcb0 >tcb2 ) ( 是否是队尾 )
                            drop r> r@ swap >r >list-tail over swap ! ( >tcb0 >tcb2 -- >tcb0 ) ( 将队尾指针指向前一个tcb )
                            0 literal ( >tcb0 -- >tcb0 0 ) ( 将0放置堆栈 )
                        then swap ! ( >tcb0 >tcb2 -- ) ( 将下一个指针存入前一个tcb中 )
                        r> r@ >list-num dup @ 1- swap ! ( -- >tcb1 ) ( 将队列tcb数减1 )
                        r> drop r> drop 0 literal >r 1 literal ( >tcb1 -- >tcb1 true ) ( 结束两个循环 )
                    else ( 不是阻塞态 )
                        swap drop ( >tcb0 >tcb1 -- >tcb1 ) ( 丢弃上一个tcb地址 )
                        dup @ if ( >tcb1 -- >tcb1 ) ( 判断本tcb是否不是队尾 )
                            0 literal  ( >tcb1 -- >tcb1 false )  ( 不是队尾则继续循环 )
                        else 
                            drop r> r@ if ( >tcb1 -- >readylist ) ( 是队尾则判断是否是最后一个就绪队列 )
                                >next-list ( >readylist -- >readylist-next ) ( 不是最后一个就绪队列 则进入下一个队列 )
                            else 
                                drop 0 literal ( >readylist -- 0 ) ( 是最后一个就绪队列 则在堆栈上放0 表示没有找到对应的任务 )
                            then 1 literal ( >readylist-next -- >readylist-next true ) ( 结束本次循环 )
                        then ( >tcb1 -- >readylist-next|0 true|false )
                    then
                until
            else ( 没有任务 )
                drop r> r@ if >next-list else drop 0 literal then ( >readylist -- >readylist-next|0 ) ( 若是最后一个就绪队列 则在堆栈上放0 表示没有找到对应的任务，否则进入下一个队列 )
            then
        next
    then noop t; 

t: pop-readylist ( >na -- >tcb|false )
    task-readylist0 =sys-list-num literal 1- for ( >na -- >readylist )
        dup dup >r >list-num @ if ( >na >readylist -- >na >readylist ) ( 当前队列是否有任务 )
            begin ( >na >readylist -- >na >tcb0 )
                swap >r dup @ dup if ( >na >tcb0 -- >tcb0 >tcb1|0 ) ( 判断是否是队列最后一个 )
                    dup >tcb-name @ r@ = if ( >tcb0 >tcb1 -- >tcb0 >tcb1 ) ( 判断名字是否一样 )
                        r> drop dup @ dup if ( >tcb0 >tcb1 -- >tcb0 >tcb1 >tcb2|0 ) ( 判断是否不是是队列最后一个 )
                            swap >r swap ! r> ( >tcb0 >tcb1 >tcb2 -- >tcb1 ) ( 将tcb0指向tcb1 )
                        else
                            drop swap 0 literal over ! ( >tcb0 >tcb1 0 -- >tcb1 >tcb0 ) ( 将tcb0指向0 表示队尾 )
                            r@ >list-tail ! ( >tcb1 >tcb0 -- >tcb1 ) ( 将队尾指向tcb0 )
                        then
                            r> >list-num dup @ 1- swap ! ( >tcb1 -- >tcb1 ) ( 队列任务数减一 )
                            r> drop 0 literal >r 1 literal ( >tcb1 -- >tcb1 true ) ( 退出双重循环 )
                    else
                        swap drop r> swap 0 literal ( >tcb0 >tcb1 -- >na >tcb1 ) ( 不一样则下一次循环 )
                    then
                else
                    drop drop r> r> r@ if >next-list else drop drop 0 literal then 1 literal ( >readylist -- >na >readylist-next | 0 ) ( 若是最后一个就绪队列 则在堆栈上放0 表示没有找到对应的任务，否则进入下一个队列 )
                then
            until
        else ( 没有任务 )
            drop r> r@ if >next-list else drop drop 0 literal then ( >na >readylist -- >na >readylist-next | 0 ) ( 若是最后一个就绪队列 则在堆栈上放0 表示没有找到对应的任务，否则进入下一个队列 )
        then
    next noop t;

t: into-blocklist ( >tcb -- )
    dup 0 literal ! ( >tcb -- >tcb ) ( 下一个tcb指针置零 表示队尾 )
    task-blocklist dup >r >list-tail dup >r @ ( >tcb -- >tcb >tcb1 ) ( 将目前队列最后一个tcb队列指针取出 )
    over swap ! ( >tcb >tcb1 -- >tcb ) ( 将目前队列最后一个tcb指向要插入队列的tcb )
    r> ! ( >tcb ) ( 将队列尾部置的指针指向该tcb )
    r> >list-num dup @ 1+ swap ! t; ( -- ) ( 阻塞队列tcb数加1 )


t: out-blocklist ( -- >tcb|false ) ( 将阻塞队列的所有就绪tcb送入就绪队列 )
    task-blocklist dup >list-num @ if ( -- >blocklist ) ( task-blocklist是存有阻塞列表表头的指针；遍历阻塞列表将就绪的tcb插入到就绪队列；注：此时的>tcb为阻塞列表链接 )
        begin ( >blocklist -- >tcb0 ) 
            dup @ dup if ( >tcb0 -- >tcb0 >tcb1|0 ) ( 判断下一个tcb是否存在，即是否不是队尾 )
                dup >tcb-state @ =task-ready literal = if ( >tcb0 >tcb1 -- >tcb0 >tcb1 ) ( 判断是否是就绪任务 )
                    dup @ dup if ( >tcb0 >tcb1 -- >tcb0 >tcb1 >tcb2|0 ) ( 判断是否不是队尾 )
                        swap >r swap ! r> ( >tcb0 >tcb1 >tcb2 -- >tcb1 ) ( 把要取出的tcb下一个tcb地址送入上一个tcb中 )
                    else
                        drop >r dup task-blocklist >list-tail ! ( >tcb0 >tcb1 -- >tcb0 ) ( 把队尾指针指向tcb0 )
                        0 literal ! r> ( >tcb0 -- >tcb1 ) ( 下一个tcb指针置零 表示队尾 )
                    then task-blocklist >list-num dup @ 1- swap ! 1 literal ( >tcb1 -- >tcb1 ) ( 队列任务数减一 )
                else
                    swap drop 0 literal ( >tcb0 >tcb1 -- >tcb1 ) ( 不是就绪任务，下一次循环 )
                then
            else 
                swap drop 1 literal ( >tcb0 0 -- false true ) ( 队尾，结束循环 )
            then
        until
    else drop 0 literal ( >blocklist -- false ) 
    then noop t;

t: pop-blocklist ( >na -- >tcb | false )
    task-blocklist dup >list-num @ if ( >na -- >na >blocklist )
        swap >r ( >blocklist -- >blocklist ) 
        begin ( >blocklist -- >tcb0 ) 
            dup @ dup if ( >tcb0 -- >tcb0 >tcb1|0 ) ( 判断下一个tcb是否存在，即是否不是队尾 )
                dup >tcb-name @ r@ = if ( >tcb0 >tcb1 -- >tcb0 >tcb1 ) ( 判断是否是名字匹配 )
                    dup @ dup if ( >tcb0 >tcb1 -- >tcb0 >tcb1 >tcb2|0 ) ( 判断是否不是队尾 )
                        swap >r swap ! r> ( >tcb0 >tcb1 >tcb2 -- >tcb1 ) ( 把要取出的tcb下一个tcb地址送入上一个tcb中 )
                    else
                        drop >r dup task-blocklist >list-tail ! ( >tcb0 >tcb1 -- >tcb0 ) ( 把队尾指针指向tcb0 )
                        0 literal ! r> ( >tcb0 -- >tcb1 ) ( 下一个tcb指针置零 表示队尾 )
                    then task-blocklist >list-num dup @ 1- swap ! 1 literal ( >tcb1 -- >tcb1 ) ( 队列任务数减一 )
                else
                    swap drop 0 literal ( >tcb0 >tcb1 -- >tcb1 ) ( 不是匹配任务，下一次循环 )
                then
            else 
                swap drop 1 literal ( >tcb0 0 -- false true ) ( 队尾，结束循环 )
            then
        until r> drop
    else
        drop drop 0 literal 
    then noop t;

t: block->ready ( -- )
    begin
        out-blocklist dup if  ( -- >tcb|0 )
            into-readylist 0 literal
        else invert
        then
    until noop t;

t: find-tcb ( na -- >tcb-pre >tcb | na false )
    task-readylist0 =sys-list-num literal 1- for ( na -- na >readylist ) ( 遍历就绪队列 )
        dup >list-num @ if ( na >readylist -- na >readylist ) ( 判断就绪队列是否有任务 )
            dup >r ( na >readylist -- na >readylist ) ( 储存队列头结点地址 )
            begin ( 循环查找tcb )
                dup >r @ dup if ( na >tcb-pre -- na >tcb0|false ) ( 判断tcb是否不是空 )
                    over over >tcb-name @ = if ( na >tcb0 -- na >tcb0 ) ( 判断是否是需要的tcb )
                        swap drop r> r> drop r> drop swap exit ( na >tcb0 -- >tcb-pre >tcb ) ( 丢弃无用数据 退出 )
                    else
                        r> drop 0 literal ( na >tcb0 -- na >tcb0 false ) ( 丢弃无用数据 为查找下一个tcb准备 )
                    then 
                else
                    drop r> drop r> 1 literal ( na false -- na >readylist true ) ( 丢弃无用数据 为查找下一个就绪队列准备 )
                then
            until
        then >next-list ( na >readylist -- na >readylist-next ) ( 取得下一个就绪队列 )
    next drop ( na >readylist -- na ) ( 就绪队列没有对应tcb，查询阻塞队列 )
    task-blocklist dup >list-num @ if ( na -- na >blocklist ) ( 阻塞队列是否有任务 )
        dup >r ( na >blocklist -- na >blocklist )
        begin ( 循环查找tcb )
            dup >r @ dup if ( na >tcb-pre -- na >tcb0|false ) ( 判断tcb是否不是空 )
                over over >tcb-name @ = if ( na >tcb0 -- na >tcb0 ) ( 判断是否是需要的tcb )
                    swap drop r> r> drop swap exit ( na >tcb-0 -- >tcb-pre >tcb-0 ) ( 丢弃无用数据 退出 )
                else
                    r> drop 0 literal ( na >tcb0 -- na >tcb0 false ) ( 丢弃无用数据 为查找下一个tcb准备 )
                then 
            else
                drop r> drop r> drop 1 literal ( na false -- na true ) ( 丢弃无用数据 查找结束 )
            then
        until
    then 0 literal t; ( na -- na false )
    
t: >critical-scdl
    close-time
    begin
	    critical-in ( 申请进入临界区 )
        get-critical if  ( 是否获得进入临界区资格 )
            scheduler-critical @ 0= if ( 查询是否该临界资源被占用 )
                1 literal scheduler-critical ! ( 占用该资源 )
                critical-out ( 退出临界区 )
                1 literal ( 退出循环 )
            else
                0 literal ( 继续循环 )
            then
        else 
            0 literal ( 继续循环 )
        then 
    until t;

t: critical-scdl> 0 literal scheduler-critical ! open-time t; ( 释放该资源 )

t: tasklist-updata ( -- )
    begin
        close-time
        >critical-scdl
        block->ready ( -- ) ( 将所有就绪任务从阻塞队列中送入就绪队列 )
        begin ( 将所有阻塞任务从就绪队列中送入阻塞队列 )
            1 literal out-readylist ( -- >tcb|0 )
            dup if
                into-blocklist ( -- )
                0 literal ( -- false )
            else
                invert ( -- true )
            then ( -- true|false )
        until
        critical-scdl> 
        open-time
        interrupt-switch
    again t;
    
t: scheduler ( -- ) 
    >critical-scdl
    0 literal out-readylist ( -- >tcb|0 )
    dup if ( >tcb|0 -- >tcb|0 )
        dup >tcb-state =task-run literal swap ! core0-task get-core-num =bitwidth literal lshift + ! ( >tcb -- ) ( 修改状态，分配任务 )
    else
        critical-scdl> noop exit ( 0 -- 0 )  ( 释放该资源,无任务 退出 )
    then
    core0-task get-core-total 1- for ( -- >core0-task ) ( 取得第一个核心任务的地址 ) ( 分配任务给核心 )
        dup >r @ 0= if ( >core-task -- ) ( 判断该核心是否被分配任务 )
            0 literal out-readylist ( -- >tcb|0 )  ( 需要分配则 从就绪队列选出一个 )
            dup if ( >tcb|0 -- >tcb|0 ) ( 选出的若是0则说明无就绪任务 非0就是有就绪任务 )
                dup >tcb-state =task-run literal swap ! r@ ! ( >tcb -- ) ( 修改状态，分配任务 )
                r> get-core-total 1- r@ - get-core-state 0 literal = if get-core-total 1- r@ - start-core then >r ( 当有任务时判断核心是否启动了，未启动时将其启动 )
            else
                drop r> r> drop 0 literal >r >r ( 0 -- ) ( 丢弃0 )
                ( r> r@ get-core-state if r@ close-core then >r ) ( 当没有任务时判断核心是否启动了，启动时将其关闭 )
            then
        then r> cell+ ( -- >core-task ) ( 下一个核心任务 )
    next drop ( >core-task -- )
    critical-scdl>  ( 释放该资源 )
    core0-task get-core-num 2 literal lshift + @ t; ( -- >tcb|0 )
t: save-scene ( -- )
    ( 保存返回栈 )
    r> ( -- >save-scene ) ( 取出本词的返回地址 )
    rp@ dup get-tcb >tcb-rp ! ( >save-scene -- >save-scene rp ) ( 保存返回栈指针 )
    get-tcb >tcb-return @ swap ( >save-scene rp -- >save-scene >return rp ) ( 取得返回栈地址 )
    ?dup if 
        1- for ( >save-scene >return rp -- >save-scene >return ) ( 循环保存 )
            r> r> swap >r over ! ( >save-scene >return -- >save-scene >return )
            cell+ ( >save-scene >return -- >save-scene >return+ )
        next
    then drop >r ( >save-scene >return+ -- ) ( 送回本词的返回地址 )
    ( 保存数据栈 )
    sp@ dup get-tcb >tcb-sp ! ( -- sp ) ( 保存数据栈指针 )
    get-tcb >tcb-data @ swap ( sp -- >data sp ) ( 取得数据栈地址 )
    ?dup if 
        1- for ( >data sp -- >data ) ( 循环保存 )
            dup >r ! ( ... >data -- .. )
            r> cell+ ( .. -- ... >data+ )
        next 
    then drop ( -- )
    get-pc get-tcb >tcb-pc ! t; ( -- ) ( 保存当前pc )

t: restore-scene ( >tcb -- )
    dup set-tcb ( >tcb -- >tcb ) ( 保存tcb地址 )
    >tcb-sp @ dup 2 literal lshift get-tcb >tcb-data @ + cell- swap ( >tcb -- >data+ sp ) ( 恢复数据栈 )
    ?dup if 
        1- for ( >data+ sp -- >data+ )
            dup >r @ ( >data+ -- . )
            r> cell- ( . -- . >data+ )
        next ( ... >data -- ... >data )
    then drop ( ... -- ... )
    rp@ dup 0 literal > if 1- dup for r> r> swap >r swap next then ( -- >restore-scene ... rp-1 ) ( 取出当前任务的调用地址 )
    get-tcb >tcb-rp @ dup 2 literal lshift get-tcb >tcb-return @ + cell- swap ( >restore-scene ... rp-1 -- >restore-scene .. rp-1 >return+ rp ) ( 恢复返回栈 )
    ?dup if 
        1- for ( >restore-scene ... rp-1 >return+ rp -- >restore-scene ... rp-1 >return+ )
            dup @ ( >restore-scene ... rp-1 >return+ -- >restore-scene ... rp-1 >return+ data )
            r> swap >r >r cell- ( >restore-scene ... rp-1 >return+ data -- >restore-scene ... rp-1 >return+ )
        next
    then drop ( >restore-scene ... rp-1 >return+ -- ..>restore-scene ... rp-1 ) 
    for r> swap >r >r next  ( >restore-scene ... rp-1 -- ) ( 送回当前任务的调用地址 )
    get-tcb >tcb-pc @ set-pc ( -- ) ( 恢复pc，仅暂存，真正恢复等到interrupt-return指令执行 )
    get-tcb >tcb-terminal-num @ set-terminal 
    64 literal get-tcb >tcb-priority @ lshift set-time t;

t: block-align ( num1 -- num2 ) ( 将字节数变为块数 )
    dup f literal and if 
        =block literal rshift 1 literal +
    else
        =block literal rshift
    then noop t;

t: malloc ( num -- addr|false )
    close-time ( 关闭时间计数 )
    begin
        critical-in ( 申请进入临界区 )
        get-critical if  ( 是否获得进入临界区资格 )
            mdp-critical @ 0= if ( 查询是否该临界资源被占用 )
                1 literal mdp-critical ! ( 占用该资源 )
                critical-out ( 退出临界区 )
                1 literal ( 退出循环 )
            else
                0 literal ( 继续循环 )
            then
        else 
            0 literal ( 继续循环 )
        then 
    until
    mdp >r ( num -- num )
    begin ( 遍历可用空间挑选一块可用空间 )
        r@ @ dup if ( num -- num mdp-next ) ( 判断下一个的空闲空间块是否可用,即是否不是最后一个空间块 )
            dup >r cell+ @ ( num mdp-next -- num mnum ) ( 取出当前空闲空间的字节数 )
            over block-align over block-align < if ( num mnum -- num mnum ) ( 判断当前空间块容量是否大于请求的空间 )
                over r@ + dup r@ @ swap ! ( num mnum -- num mnum mdp-next+ ) ( 更新空闲空间链表 )
                >r swap - r@ cell+ ! r> ( num mnum mdp-next+ -- mdp-next+ ) ( 更新该块空闲字节数 )
                r> r> swap >r ! ( mdp-next+ -- ) ( 更新mdp指针 )
                r> 1 literal ( -- addr true ) ( 退出循环 )
            else 
                over block-align over block-align = if ( num mnum -- num mnum ) ( 判断当前空间块容量是否等于请求的空间 )
                    drop drop r> dup r> ! ( num mnum -- addr ) ( 更新mdp指针 )
                    1 literal ( -- addr true ) ( 本tcb分配完毕 退出循环 分配下一个tcb )
                else ( 判断当前空间块容量是否小于请求的空间 )
                    drop r> r> drop >r ( num mnum -- num ) ( 丢弃空间容量 取出下一个空间地址,丢弃上一个空间地址 )
                    0 literal ( num -- num false ) ( 继续循环查找下一块可用空间 )
                then
            then
        else ( 没有可用空间 )
            drop drop ( num mdp-next -- )
            0 literal 1 literal ( -- false true ) ( 分配失败 退出循环 )
        then
    until 0 literal mdp-critical !
    open-time t;

t: free ( num addr -- )
    close-time
    begin
        critical-in ( 申请进入临界区 )
        get-critical if  ( 是否获得进入临界区资格 )
            mdp-critical @ 0= if ( 查询是否该临界资源被占用 )
                1 literal mdp-critical ! ( 占用该资源 )
                critical-out ( 退出临界区 )
                1 literal ( 退出循环 )
            else
                0 literal ( 继续循环 )
            then
        else 
            0 literal ( 继续循环 )
        then 
    until
    mhere over over < if ( tnum tm -- tnum tm @mdp ) ( 判断释放的空间地址是否在该可用地址之前 )
        >r over over + r@ = if ( tnum tm @mdp -- tnum tm ) ( 判断释放的空间是否与该可用空间连续 )
            r@ cell+ @ swap r> @ over ! ( tnum tm -- tnum mnum tm ) ( 更新空闲空间链表，将下一个空闲空间地址放在此处 )
            >r + r@ cell+ ! ( tnum mnum tm -- ) ( 更新该块空闲字节数 )
            r> mdp ! ( -- ) ( 更新mdp指针 )
        else ( 空间不连续 )
            r> over ! ( tnum tm -- tnum tm ) ( 将下一个空闲地址存入当前地址处 )
            dup >r cell+ ! ( tnum tm -- ) ( 将空闲空间大小存到当前地址后面一个字空间中 )
            r> mdp ! ( -- ) ( 更新mdp指针 )
        then
    else
        begin ( tnum tm @mdp -- tnum tm @mdp ) ( 遍历空闲空间，找到合适的位置 释放空间 )
            dup >r @ over over < if ( tnum tm @mdp -- tnum tm @mdp-next ) ( 判断是否释放空间地址是否在@mdp-next之前 )
                >r over over + r@ = if ( tnum tm @mdp-next -- tnum tm ) ( 判断释放的空间是否与该可用空间连续 )
                    r> cell+ @ swap >r + dup r@ cell+ ! ( tnum tm -- mnum1 ) ( 将连续的部分空间累加 )
                else ( 与@mdp-next空间不连续 )
                    r> over ! ( tnum tm -- tnum tm ) ( 将下一个空闲地址存入当前地址处 )
                    >r dup r@ cell+ ! ( tnum tm -- mnum1 ) ( 将空闲空间大小存到当前地址后面一个字空间中 )
                then
                r> r@ cell+ @ r@ + over = if ( mnum1 -- mnum1 tm ) ( 判断与@mdp是否连续 )
                    drop r@ cell+ @ + r> cell+ ! ( mnum1 tm -- ) ( 更新@mdp的空间大小 )
                else
                    r> ! drop ( mnum1 tm -- ) ( 更新上一个空闲空间的链表指针 )
                then 1 literal ( -- true ) ( 释放空间完成 结束循环 )
            else ( 不在@mdp和@mdp-next之间 )
                r> drop ( tnum tm @mdp-next -- tnum tm @mdp-next ) ( 丢弃@mdp )
                dup @ if ( tnum tm @mdp-next -- tnum tm @mdp-next ) ( 判断下一个是否是0，0地址代表着@mdp-next为最后一个空闲空间 )
                    0 literal ( tnum tm @mdp-next -- tnum tm @mdp-next false ) ( 继续查询下一个空闲空间地址 )
                else
                    dup >r cell+ @ dup r@ + >r over r> = if ( tnum tm @mdp-next -- tnum tm mnum ) ( 判断释放空间是否与最后一个空间连续 )
                        swap drop + r> cell+ ! ( tnum tm mnum -- ) ( 更新@mdp-next的空闲空间大小 )
                    else
                        drop 0 literal over ! ( tnum tm -- tnum tm ) ( 将本空间链接地址重置为0 )
                        swap over cell+ ! ( tnum tm -- tm ) ( 存入空间大小 )
                        r> ! ( tm -- ) ( @mdp-next的链表指向本空间 )
                    then 1 literal ( -- true ) ( 释放空间完成 结束循环 )
                then
            then
        until
    then 0 literal mdp-critical !
    open-time t;


t: tcb-create ( pc na;<string> -- >tcb | false )
    =tcb-size literal malloc dup if ( pc na;<string> -- pc na;<string> addr|false ) ( 申请tcb空间 )
        >r r@ >tcb-name ! ( pc na;<string> addr|false -- pc ) ( 初始化tcb基本参数 )
        =bitwidth literal rshift r@ >tcb-pc ! ( pc -- ) ( 校正pc地址，未校正前地址是按字节寻址，校正后地址按字寻址 )
        0 literal r@ ! ( -- )
        0 literal r@ >tcb-all ! 
        0 literal r@ >tcb-priority ! 
        0 literal r@ >tcb-sp ! 
        0 literal r@ >tcb-rp !
        terminal-num @ dup r@ >tcb-terminal-num ! 1 literal + terminal-num !
        =task-ready literal r@ >tcb-state !
        0 literal r@ >tcb-memory !
        0 literal r@ >tcb-memory-num !
        0 literal r@ >tcb-memory-pointer !
    else
        drop drop drop 0 literal exit (  pc na;<string> addr|false -- false ) ( 内存空间不足 退出 )
    then
    =tcb-stack-size literal malloc dup if ( -- addr|false ) ( 申请数据堆栈空间 )
        dup r@ >tcb-data ! ( addr|false -- adata )
    else
        drop =tcb-size literal r> free 0 literal exit ( addr|false -- false ) ( 内存空间不足 退出 )
    then
    =tcb-stack-size literal malloc dup if ( adata -- adata addr|false ) ( 申请返回堆栈空间 )
        r@ >tcb-return ! drop ( adata addr|false -- )
    else
        drop =tcb-stack-size literal swap free =tcb-size literal r> free 0 literal exit ( adata false -- false ) ( 内存空间不足 退出 )
    then r> t; ( -- >tcb )
        
t: tcb-free ( >tcb -- )
    =tcb-stack-size literal over >tcb-data free ( >tcb -- >tcb ) ( 释放数据栈空间 )
    =tcb-stack-size literal over >tcb-return free ( >tcb -- >tcb ) ( 释放返回栈空间 )
    dup >tcb-memory-num @ dup if ( >tcb -- >tcb tnum ) ( 判断是否有空闲空间 )
        over >tcb-memory free ( >tcb tnum -- >tcb ) ( 释放空闲空间 )
    else
        drop ( >tcb tnum -- >tcb ) 
    then
    =tcb-size literal swap free t; ( >tcb -- ) ( 释放tcb空间 )

t: fetch-task ( -- true|false ) 
    core0-task get-core-num 2 literal lshift + ( -- >core-task ) ( 取得下一个tcb地址的存储地址 )
    begin
        dup @ dup if ( >core-task -- >core-task >tcb|0 ) ( 判断是否有下一个任务tcb地址 )
            ( dup @ >r 0 literal swap ! r> ) ( >core-task -- >tcb ) ( 有，则取出tcb地址，将任务tcb地址存储单元设为0，表示可以被分配下一个tcb )
            >critical-scdl
            swap drop ( >core-task >tcb -- >tcb )
            dup >tcb-state @ =task-end literal = if ( >tcb -- >tcb ) ( 判断任务是否是结束态 )
                0 literal ( >tcb -- >tcb false )
            else
                ( dup >tcb-state =task-run literal swap ! ) ( >tcb -- >tcb ) ( 修改任务状态为执行态 )
                1 literal ( >tcb -- >tcb true )
            then
            critical-scdl>
            if ( >tcb true|false -- >tcb ) ( 判断任务是运行还是结束 )
                restore-scene 1 literal 1 literal ( >tcb -- true true ) ( 运行 恢复现场 )
            else 
                tcb-free core0-task get-core-num 2 literal lshift + ( >tcb -- >core-task ) ( 结束，释放空间，继续循环取得新tcb )
                0 literal ( >core-task -- >core-task false )
            then 
        else ( 无，则申请调度程序 )
            drop apply-scheduler get-scheduler if ( >core-task 0 -- >core-task ) ( 判断是否获得调度程序执行权力 )
                scheduler ( >core-task -- >core-task >tcb|0 ) ( 是，则执行 )
                free-scheduler
                0 literal = if drop 0 literal 1 literal else 0 literal then ( 没有任务的话给出失败标志，关闭核心运行 )
            else
                0 literal ( >core-task -- >core-task false ) ( 再一次循环 )
            then
        then
    until t;

t: start-task ( 启动一个任务 ) 
    fetch-task if 
        interrupt-return noop 
    else 
        close-core 
    then noop t; ( -- ) ( 返回中断 )

t: task-switch ( -- ) ( 中断采用跳转jump指令 )
    >critical-scdl
    get-tcb >tcb-state @ =task-end literal = if 
        critical-scdl>
        get-tcb tcb-free reset-point
    else
        save-scene ( -- ) ( 保存现场 )
        get-tcb >tcb-priority @ dup 4 literal = if ( -- priority ) ( 判断优先级是否到最低优先级 )
            drop ( priority -- ) ( 最低优先级时不改变优先级 )
        else
            1 literal + get-tcb >tcb-priority ! ( priority -- ) ( 非最低优先级时优先级加1 )
        then get-tcb into-readylist ( -- ) ( 根据优先级将tcb送入对应的队列 )
        =task-ready literal get-tcb >tcb-state ! ( -- ) ( 将任务置为就绪态 )
        0 literal core0-task get-core-num 2 literal lshift + ! ( -- ) ( 将任务tcb地址存储单元设为0 )
        critical-scdl>
    then
    fetch-task if interrupt-return else reset-point close-core then noop t; ( -- ) ( 返回中断 )

t: task ( -- )
    token name? ?dup if ( -- ca na | na false ) ( 获取名字地址 )
        tcb-create ?dup if ( ca na -- >tcb ) ( 获取名字地址 )
            dup
            >critical-alst
            into-alllist
            critical-alst>
            >critical-scdl
            into-readylist
            critical-scdl> ( 释放该资源 )
        else
            ."| 32$literal tcb creation failed!"
        then
    else space .$ 3f literal emit cr 
    then noop t;

t: find-task ( <;name> -- >tcb-pre >tcb | na false )
    token name? ?dup if ( -- ca na | na false ) ( 获取名字地址 )
        swap drop ( ca na -- na ) ( 丢弃执行地址 )
        >critical-scdl ( 进入临界区 )
        find-all ( na -- >tcb-pre >tcb | na false ) ( 找到对应tcb )
        critical-scdl> ( 释放该资源 )
    else dup space .$ 3f literal emit cr 0 literal
    then noop t;

t: kill ( <;name> -- )
    token name? ?dup if ( -- ca na | na false ) ( 获取名字地址 )
        swap drop dup ( ca na -- na ) ( 丢弃执行地址 )
        >critical-alst
        out-alllist ( na na -- na >tcb|0 ) ( 根据名字地址将tcb从队列取出 )
        critical-alst>
        ?dup if ( na >tcb|0 -- na >tcb|0 ) ( 是否从系统队列中取出 )
            >r ( na >tcb -- >na ) ( 将tcb送入返回栈 )
            >critical-scdl
            r@ >tcb-state @ dup =task-ready literal = swap =task-block literal = or if ( >na -- >na ) ( 判断tcb是否为就绪态或者阻塞态 )
                dup pop-readylist 0= if ( >na -- >na >tcb|false ) ( 若在从就绪队列中则出列 )
                    pop-blocklist if ( >na -- ) ( 若在从阻塞队列中则出列 )
                        r> tcb-free ( -- ) ( 在阻塞队列，释放tcb )
                    then
                else 
                    drop r> tcb-free ( >na -- ) ( 在就绪队列，释放tcb )
                then
            else
                drop =task-end literal r> >tcb-state ! ( >na -- ) ( 为运行态，改为终止态，由中断服务程序进行销毁 )
            then
            critical-scdl>
        else
            space .$ ."| 32$literal  is not runing,kill failed " 
        then
    else space .$ 3f literal emit cr 
    then noop t;

t: task-finish ( -- )
    get-tcb >tcb-name ( -- >na )
    >critical-alst
    out-alllist ( >na -- >tcb|0 ) ( 根据名字地址将tcb从队列取出 )
    critical-alst>
    if ( >tcb|0 -- )
        get-tcb tcb-free
    then reset-point 
    fetch-task if interrupt-return noop else close-core then noop t; ( 返回中断 )

t: $pad ( -- a ) get-tcb >tcb-memory @ 0 literal = if begin 40 literal malloc ?dup if get-tcb >tcb-memory ! 40 literal get-tcb >tcb-memory-num ! 1 literal else 0 literal then until then get-tcb >tcb-memory @ get-tcb >tcb-memory-num @ + t;

t: task-num ( -- <;name> ; task-num|false )
    find-task ?dup if ( <;name> -- >tcb-pre >tcb | na false ) ( 判断是否有该任务tcb )
        swap drop >tcb-terminal-num @ ( >tcb-pre >tcb -- task-num|false )
    else
        space .$ ."| 32$literal  is not runing,failed to get number " 0 literal ( na -- false )
    then noop t;

t: showtask ( -- <;name> ) task-num ?dup if showtask then noop t;

t: alltask ( -- )
    cr ."| 32$literal Task list:" cr
    task-alllist ( -- >alllist )
    >critical-alst 
    begin ( >alllist -- >tcb-a )
        @ dup if ( >tcb0-a -- >tcb0-a >tcb1-a|0 )
            swap drop ( >tcb0-a >tcb1-a -- >tcb1-a )
            dup >tcb-ready >tcb-name @ .$ space 0 literal ( >tcb1-a -- >tcb1-a false )
        else drop 1 literal
        then
    until
    critical-alst> noop t; 

t: name0 32$literal interpret" t;
t: name1 32$literal tasklist-updata" t;

t: cold ( -- )
    ( =uzero literal =up literal =udiff literal cmove )
    preset forth-wordlist dup context ! dup current 2! overt
    
    [t] start-task literal 0 literal interrupt-set
    [t] task-switch literal 1 literal interrupt-set ( 设置任务切换中断地址 )
    [t] task-finish literal 2 literal interrupt-set ( 设置任务结束中断地址 )
    
    mdp @ dup cell+ =datasize literal swap ! 0 literal swap !
    10000000 literal set-time
    ( 创建文本解释程序任务 )
    [t] quit literal [t] name0 literal tcb-create ?dup if 
        dup
        >critical-alst
        into-alllist
        critical-alst>
        >critical-scdl
        into-readylist
        critical-scdl> ( 释放该资源 )
    else
        ."| 32$literal tcb creation failed!"
    then
    ( 创建任务状态切换任务 )
    [t] tasklist-updata literal [t] name1 literal tcb-create ?dup if
        dup
        >critical-alst
        into-alllist
        critical-alst>
        >critical-scdl
        into-readylist
        critical-scdl> ( 释放该资源 )
    else
        ."| 32$literal tcb creation failed!"
    then
    interrupt-start t;


target.1 -order set-current

there     		[u] dp t32!
[last] 			[u] last t32!
[t] $pad        [u] 'pad t32!
[t] ?rx			[u] '?key t32!
[t] tx!			[u] 'emit t32!
[t] <\>			[u] '\ t32!
[t] $interpret	[u] 'eval  t32!
[t] abort		[u] 'abort t32!
[t] hi			[u] 'boot t32!
[t] <name?>		[u] 'name? t32!
[t] <overt>		[u] 'overt t32!
[t] <$,n>		[u] '$,n t32!
[t] <;>			[u] '; t32!
[t] <create>	[u] 'create t32!
[t] cold 		4 / =cold t32!
=dataaddr       [u] mdp t32!


save-target j1_32.bin    
save-hex j1_32.hex       
save-hex128 j1_32_128.hex

meta.1 -order            

bye                      
