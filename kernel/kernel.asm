
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	91013103          	ld	sp,-1776(sp) # 80008910 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	92070713          	addi	a4,a4,-1760 # 80008970 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	d2e78793          	addi	a5,a5,-722 # 80005d90 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc81f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dee78793          	addi	a5,a5,-530 # 80000e9a <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3ae080e7          	jalr	942(ra) # 800024d8 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	92650513          	addi	a0,a0,-1754 # 80010ab0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a66080e7          	jalr	-1434(ra) # 80000bf8 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	91648493          	addi	s1,s1,-1770 # 80010ab0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9a690913          	addi	s2,s2,-1626 # 80010b48 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	80e080e7          	jalr	-2034(ra) # 800019ce <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	15a080e7          	jalr	346(ra) # 80002322 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ea4080e7          	jalr	-348(ra) # 8000207a <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	270080e7          	jalr	624(ra) # 80002482 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	88a50513          	addi	a0,a0,-1910 # 80010ab0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a7e080e7          	jalr	-1410(ra) # 80000cac <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	87450513          	addi	a0,a0,-1932 # 80010ab0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a68080e7          	jalr	-1432(ra) # 80000cac <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8cf72b23          	sw	a5,-1834(a4) # 80010b48 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7e450513          	addi	a0,a0,2020 # 80010ab0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	924080e7          	jalr	-1756(ra) # 80000bf8 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	23c080e7          	jalr	572(ra) # 8000252e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7b650513          	addi	a0,a0,1974 # 80010ab0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9aa080e7          	jalr	-1622(ra) # 80000cac <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	79270713          	addi	a4,a4,1938 # 80010ab0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	76878793          	addi	a5,a5,1896 # 80010ab0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7d27a783          	lw	a5,2002(a5) # 80010b48 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	72670713          	addi	a4,a4,1830 # 80010ab0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	71648493          	addi	s1,s1,1814 # 80010ab0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6da70713          	addi	a4,a4,1754 # 80010ab0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	76f72223          	sw	a5,1892(a4) # 80010b50 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	69e78793          	addi	a5,a5,1694 # 80010ab0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	70c7ab23          	sw	a2,1814(a5) # 80010b4c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	70a50513          	addi	a0,a0,1802 # 80010b48 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c98080e7          	jalr	-872(ra) # 800020de <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	65050513          	addi	a0,a0,1616 # 80010ab0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	700080e7          	jalr	1792(ra) # 80000b68 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	9d078793          	addi	a5,a5,-1584 # 80020e48 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6207a223          	sw	zero,1572(a5) # 80010b70 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	3af72823          	sw	a5,944(a4) # 80008930 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	5b4dad83          	lw	s11,1460(s11) # 80010b70 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	55e50513          	addi	a0,a0,1374 # 80010b58 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5f6080e7          	jalr	1526(ra) # 80000bf8 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	40050513          	addi	a0,a0,1024 # 80010b58 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	54c080e7          	jalr	1356(ra) # 80000cac <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3e448493          	addi	s1,s1,996 # 80010b58 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3e2080e7          	jalr	994(ra) # 80000b68 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	3a450513          	addi	a0,a0,932 # 80010b78 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	38c080e7          	jalr	908(ra) # 80000b68 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	3b4080e7          	jalr	948(ra) # 80000bac <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1307a783          	lw	a5,304(a5) # 80008930 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	426080e7          	jalr	1062(ra) # 80000c4c <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1007b783          	ld	a5,256(a5) # 80008938 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	10073703          	ld	a4,256(a4) # 80008940 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	316a0a13          	addi	s4,s4,790 # 80010b78 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0ce48493          	addi	s1,s1,206 # 80008938 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0ce98993          	addi	s3,s3,206 # 80008940 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	84a080e7          	jalr	-1974(ra) # 800020de <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	2a850513          	addi	a0,a0,680 # 80010b78 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	320080e7          	jalr	800(ra) # 80000bf8 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0507a783          	lw	a5,80(a5) # 80008930 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	05673703          	ld	a4,86(a4) # 80008940 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0467b783          	ld	a5,70(a5) # 80008938 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	27a98993          	addi	s3,s3,634 # 80010b78 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	03248493          	addi	s1,s1,50 # 80008938 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	03290913          	addi	s2,s2,50 # 80008940 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	75c080e7          	jalr	1884(ra) # 8000207a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	24448493          	addi	s1,s1,580 # 80010b78 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fee7bc23          	sd	a4,-8(a5) # 80008940 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	352080e7          	jalr	850(ra) # 80000cac <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	1be48493          	addi	s1,s1,446 # 80010b78 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	234080e7          	jalr	564(ra) # 80000bf8 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2d6080e7          	jalr	726(ra) # 80000cac <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	5e478793          	addi	a5,a5,1508 # 80021fe0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2e0080e7          	jalr	736(ra) # 80000cf4 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	19490913          	addi	s2,s2,404 # 80010bb0 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1d2080e7          	jalr	466(ra) # 80000bf8 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	272080e7          	jalr	626(ra) # 80000cac <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0f650513          	addi	a0,a0,246 # 80010bb0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	0a6080e7          	jalr	166(ra) # 80000b68 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	51250513          	addi	a0,a0,1298 # 80021fe0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0c048493          	addi	s1,s1,192 # 80010bb0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0fe080e7          	jalr	254(ra) # 80000bf8 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	0a850513          	addi	a0,a0,168 # 80010bb0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	19a080e7          	jalr	410(ra) # 80000cac <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1d4080e7          	jalr	468(ra) # 80000cf4 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	07c50513          	addi	a0,a0,124 # 80010bb0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	170080e7          	jalr	368(ra) # 80000cac <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <free_memory_pages>:
//This function is declared to count the number of free memory pages.
//The function uses the kmem.freelist and iterates through it to count total
//free pages
int
free_memory_pages(void)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  struct run *head;
  int count = 0;
  head = kmem.freelist;
    80000b4c:	00010797          	auipc	a5,0x10
    80000b50:	07c7b783          	ld	a5,124(a5) # 80010bc8 <kmem+0x18>
  while(head){
    80000b54:	cb81                	beqz	a5,80000b64 <free_memory_pages+0x1e>
  int count = 0;
    80000b56:	4501                	li	a0,0
    count++;
    80000b58:	2505                	addiw	a0,a0,1
    head = head->next;
    80000b5a:	639c                	ld	a5,0(a5)
  while(head){
    80000b5c:	fff5                	bnez	a5,80000b58 <free_memory_pages+0x12>
  }
  return count;
}
    80000b5e:	6422                	ld	s0,8(sp)
    80000b60:	0141                	addi	sp,sp,16
    80000b62:	8082                	ret
  int count = 0;
    80000b64:	4501                	li	a0,0
    80000b66:	bfe5                	j	80000b5e <free_memory_pages+0x18>

0000000080000b68 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b68:	1141                	addi	sp,sp,-16
    80000b6a:	e422                	sd	s0,8(sp)
    80000b6c:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b6e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b70:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b74:	00053823          	sd	zero,16(a0)
}
    80000b78:	6422                	ld	s0,8(sp)
    80000b7a:	0141                	addi	sp,sp,16
    80000b7c:	8082                	ret

0000000080000b7e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b7e:	411c                	lw	a5,0(a0)
    80000b80:	e399                	bnez	a5,80000b86 <holding+0x8>
    80000b82:	4501                	li	a0,0
  return r;
}
    80000b84:	8082                	ret
{
    80000b86:	1101                	addi	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b90:	6904                	ld	s1,16(a0)
    80000b92:	00001097          	auipc	ra,0x1
    80000b96:	e20080e7          	jalr	-480(ra) # 800019b2 <mycpu>
    80000b9a:	40a48533          	sub	a0,s1,a0
    80000b9e:	00153513          	seqz	a0,a0
}
    80000ba2:	60e2                	ld	ra,24(sp)
    80000ba4:	6442                	ld	s0,16(sp)
    80000ba6:	64a2                	ld	s1,8(sp)
    80000ba8:	6105                	addi	sp,sp,32
    80000baa:	8082                	ret

0000000080000bac <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bac:	1101                	addi	sp,sp,-32
    80000bae:	ec06                	sd	ra,24(sp)
    80000bb0:	e822                	sd	s0,16(sp)
    80000bb2:	e426                	sd	s1,8(sp)
    80000bb4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bb6:	100024f3          	csrr	s1,sstatus
    80000bba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bbe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc0:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bc4:	00001097          	auipc	ra,0x1
    80000bc8:	dee080e7          	jalr	-530(ra) # 800019b2 <mycpu>
    80000bcc:	5d3c                	lw	a5,120(a0)
    80000bce:	cf89                	beqz	a5,80000be8 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd0:	00001097          	auipc	ra,0x1
    80000bd4:	de2080e7          	jalr	-542(ra) # 800019b2 <mycpu>
    80000bd8:	5d3c                	lw	a5,120(a0)
    80000bda:	2785                	addiw	a5,a5,1
    80000bdc:	dd3c                	sw	a5,120(a0)
}
    80000bde:	60e2                	ld	ra,24(sp)
    80000be0:	6442                	ld	s0,16(sp)
    80000be2:	64a2                	ld	s1,8(sp)
    80000be4:	6105                	addi	sp,sp,32
    80000be6:	8082                	ret
    mycpu()->intena = old;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	dca080e7          	jalr	-566(ra) # 800019b2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf0:	8085                	srli	s1,s1,0x1
    80000bf2:	8885                	andi	s1,s1,1
    80000bf4:	dd64                	sw	s1,124(a0)
    80000bf6:	bfe9                	j	80000bd0 <push_off+0x24>

0000000080000bf8 <acquire>:
{
    80000bf8:	1101                	addi	sp,sp,-32
    80000bfa:	ec06                	sd	ra,24(sp)
    80000bfc:	e822                	sd	s0,16(sp)
    80000bfe:	e426                	sd	s1,8(sp)
    80000c00:	1000                	addi	s0,sp,32
    80000c02:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c04:	00000097          	auipc	ra,0x0
    80000c08:	fa8080e7          	jalr	-88(ra) # 80000bac <push_off>
  if(holding(lk))
    80000c0c:	8526                	mv	a0,s1
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	f70080e7          	jalr	-144(ra) # 80000b7e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c16:	4705                	li	a4,1
  if(holding(lk))
    80000c18:	e115                	bnez	a0,80000c3c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1a:	87ba                	mv	a5,a4
    80000c1c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c20:	2781                	sext.w	a5,a5
    80000c22:	ffe5                	bnez	a5,80000c1a <acquire+0x22>
  __sync_synchronize();
    80000c24:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	d8a080e7          	jalr	-630(ra) # 800019b2 <mycpu>
    80000c30:	e888                	sd	a0,16(s1)
}
    80000c32:	60e2                	ld	ra,24(sp)
    80000c34:	6442                	ld	s0,16(sp)
    80000c36:	64a2                	ld	s1,8(sp)
    80000c38:	6105                	addi	sp,sp,32
    80000c3a:	8082                	ret
    panic("acquire");
    80000c3c:	00007517          	auipc	a0,0x7
    80000c40:	43450513          	addi	a0,a0,1076 # 80008070 <digits+0x30>
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	8fc080e7          	jalr	-1796(ra) # 80000540 <panic>

0000000080000c4c <pop_off>:

void
pop_off(void)
{
    80000c4c:	1141                	addi	sp,sp,-16
    80000c4e:	e406                	sd	ra,8(sp)
    80000c50:	e022                	sd	s0,0(sp)
    80000c52:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c54:	00001097          	auipc	ra,0x1
    80000c58:	d5e080e7          	jalr	-674(ra) # 800019b2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c5c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c60:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c62:	e78d                	bnez	a5,80000c8c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c64:	5d3c                	lw	a5,120(a0)
    80000c66:	02f05b63          	blez	a5,80000c9c <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c6a:	37fd                	addiw	a5,a5,-1
    80000c6c:	0007871b          	sext.w	a4,a5
    80000c70:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c72:	eb09                	bnez	a4,80000c84 <pop_off+0x38>
    80000c74:	5d7c                	lw	a5,124(a0)
    80000c76:	c799                	beqz	a5,80000c84 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c78:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c7c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c80:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c84:	60a2                	ld	ra,8(sp)
    80000c86:	6402                	ld	s0,0(sp)
    80000c88:	0141                	addi	sp,sp,16
    80000c8a:	8082                	ret
    panic("pop_off - interruptible");
    80000c8c:	00007517          	auipc	a0,0x7
    80000c90:	3ec50513          	addi	a0,a0,1004 # 80008078 <digits+0x38>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>
    panic("pop_off");
    80000c9c:	00007517          	auipc	a0,0x7
    80000ca0:	3f450513          	addi	a0,a0,1012 # 80008090 <digits+0x50>
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	89c080e7          	jalr	-1892(ra) # 80000540 <panic>

0000000080000cac <release>:
{
    80000cac:	1101                	addi	sp,sp,-32
    80000cae:	ec06                	sd	ra,24(sp)
    80000cb0:	e822                	sd	s0,16(sp)
    80000cb2:	e426                	sd	s1,8(sp)
    80000cb4:	1000                	addi	s0,sp,32
    80000cb6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	ec6080e7          	jalr	-314(ra) # 80000b7e <holding>
    80000cc0:	c115                	beqz	a0,80000ce4 <release+0x38>
  lk->cpu = 0;
    80000cc2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cc6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cca:	0f50000f          	fence	iorw,ow
    80000cce:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd2:	00000097          	auipc	ra,0x0
    80000cd6:	f7a080e7          	jalr	-134(ra) # 80000c4c <pop_off>
}
    80000cda:	60e2                	ld	ra,24(sp)
    80000cdc:	6442                	ld	s0,16(sp)
    80000cde:	64a2                	ld	s1,8(sp)
    80000ce0:	6105                	addi	sp,sp,32
    80000ce2:	8082                	ret
    panic("release");
    80000ce4:	00007517          	auipc	a0,0x7
    80000ce8:	3b450513          	addi	a0,a0,948 # 80008098 <digits+0x58>
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	854080e7          	jalr	-1964(ra) # 80000540 <panic>

0000000080000cf4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cfa:	ca19                	beqz	a2,80000d10 <memset+0x1c>
    80000cfc:	87aa                	mv	a5,a0
    80000cfe:	1602                	slli	a2,a2,0x20
    80000d00:	9201                	srli	a2,a2,0x20
    80000d02:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d06:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d0a:	0785                	addi	a5,a5,1
    80000d0c:	fee79de3          	bne	a5,a4,80000d06 <memset+0x12>
  }
  return dst;
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret

0000000080000d16 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d16:	1141                	addi	sp,sp,-16
    80000d18:	e422                	sd	s0,8(sp)
    80000d1a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d1c:	ca05                	beqz	a2,80000d4c <memcmp+0x36>
    80000d1e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d22:	1682                	slli	a3,a3,0x20
    80000d24:	9281                	srli	a3,a3,0x20
    80000d26:	0685                	addi	a3,a3,1
    80000d28:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d2a:	00054783          	lbu	a5,0(a0)
    80000d2e:	0005c703          	lbu	a4,0(a1)
    80000d32:	00e79863          	bne	a5,a4,80000d42 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d36:	0505                	addi	a0,a0,1
    80000d38:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d3a:	fed518e3          	bne	a0,a3,80000d2a <memcmp+0x14>
  }

  return 0;
    80000d3e:	4501                	li	a0,0
    80000d40:	a019                	j	80000d46 <memcmp+0x30>
      return *s1 - *s2;
    80000d42:	40e7853b          	subw	a0,a5,a4
}
    80000d46:	6422                	ld	s0,8(sp)
    80000d48:	0141                	addi	sp,sp,16
    80000d4a:	8082                	ret
  return 0;
    80000d4c:	4501                	li	a0,0
    80000d4e:	bfe5                	j	80000d46 <memcmp+0x30>

0000000080000d50 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d50:	1141                	addi	sp,sp,-16
    80000d52:	e422                	sd	s0,8(sp)
    80000d54:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d56:	c205                	beqz	a2,80000d76 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d58:	02a5e263          	bltu	a1,a0,80000d7c <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5c:	1602                	slli	a2,a2,0x20
    80000d5e:	9201                	srli	a2,a2,0x20
    80000d60:	00c587b3          	add	a5,a1,a2
{
    80000d64:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d66:	0585                	addi	a1,a1,1
    80000d68:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd021>
    80000d6a:	fff5c683          	lbu	a3,-1(a1)
    80000d6e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d72:	fef59ae3          	bne	a1,a5,80000d66 <memmove+0x16>

  return dst;
}
    80000d76:	6422                	ld	s0,8(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret
  if(s < d && s + n > d){
    80000d7c:	02061693          	slli	a3,a2,0x20
    80000d80:	9281                	srli	a3,a3,0x20
    80000d82:	00d58733          	add	a4,a1,a3
    80000d86:	fce57be3          	bgeu	a0,a4,80000d5c <memmove+0xc>
    d += n;
    80000d8a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d8c:	fff6079b          	addiw	a5,a2,-1
    80000d90:	1782                	slli	a5,a5,0x20
    80000d92:	9381                	srli	a5,a5,0x20
    80000d94:	fff7c793          	not	a5,a5
    80000d98:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d9a:	177d                	addi	a4,a4,-1
    80000d9c:	16fd                	addi	a3,a3,-1
    80000d9e:	00074603          	lbu	a2,0(a4)
    80000da2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da6:	fee79ae3          	bne	a5,a4,80000d9a <memmove+0x4a>
    80000daa:	b7f1                	j	80000d76 <memmove+0x26>

0000000080000dac <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dac:	1141                	addi	sp,sp,-16
    80000dae:	e406                	sd	ra,8(sp)
    80000db0:	e022                	sd	s0,0(sp)
    80000db2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000db4:	00000097          	auipc	ra,0x0
    80000db8:	f9c080e7          	jalr	-100(ra) # 80000d50 <memmove>
}
    80000dbc:	60a2                	ld	ra,8(sp)
    80000dbe:	6402                	ld	s0,0(sp)
    80000dc0:	0141                	addi	sp,sp,16
    80000dc2:	8082                	ret

0000000080000dc4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dc4:	1141                	addi	sp,sp,-16
    80000dc6:	e422                	sd	s0,8(sp)
    80000dc8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dca:	ce11                	beqz	a2,80000de6 <strncmp+0x22>
    80000dcc:	00054783          	lbu	a5,0(a0)
    80000dd0:	cf89                	beqz	a5,80000dea <strncmp+0x26>
    80000dd2:	0005c703          	lbu	a4,0(a1)
    80000dd6:	00f71a63          	bne	a4,a5,80000dea <strncmp+0x26>
    n--, p++, q++;
    80000dda:	367d                	addiw	a2,a2,-1
    80000ddc:	0505                	addi	a0,a0,1
    80000dde:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000de0:	f675                	bnez	a2,80000dcc <strncmp+0x8>
  if(n == 0)
    return 0;
    80000de2:	4501                	li	a0,0
    80000de4:	a809                	j	80000df6 <strncmp+0x32>
    80000de6:	4501                	li	a0,0
    80000de8:	a039                	j	80000df6 <strncmp+0x32>
  if(n == 0)
    80000dea:	ca09                	beqz	a2,80000dfc <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dec:	00054503          	lbu	a0,0(a0)
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	9d1d                	subw	a0,a0,a5
}
    80000df6:	6422                	ld	s0,8(sp)
    80000df8:	0141                	addi	sp,sp,16
    80000dfa:	8082                	ret
    return 0;
    80000dfc:	4501                	li	a0,0
    80000dfe:	bfe5                	j	80000df6 <strncmp+0x32>

0000000080000e00 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e00:	1141                	addi	sp,sp,-16
    80000e02:	e422                	sd	s0,8(sp)
    80000e04:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e06:	872a                	mv	a4,a0
    80000e08:	8832                	mv	a6,a2
    80000e0a:	367d                	addiw	a2,a2,-1
    80000e0c:	01005963          	blez	a6,80000e1e <strncpy+0x1e>
    80000e10:	0705                	addi	a4,a4,1
    80000e12:	0005c783          	lbu	a5,0(a1)
    80000e16:	fef70fa3          	sb	a5,-1(a4)
    80000e1a:	0585                	addi	a1,a1,1
    80000e1c:	f7f5                	bnez	a5,80000e08 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e1e:	86ba                	mv	a3,a4
    80000e20:	00c05c63          	blez	a2,80000e38 <strncpy+0x38>
    *s++ = 0;
    80000e24:	0685                	addi	a3,a3,1
    80000e26:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e2a:	40d707bb          	subw	a5,a4,a3
    80000e2e:	37fd                	addiw	a5,a5,-1
    80000e30:	010787bb          	addw	a5,a5,a6
    80000e34:	fef048e3          	bgtz	a5,80000e24 <strncpy+0x24>
  return os;
}
    80000e38:	6422                	ld	s0,8(sp)
    80000e3a:	0141                	addi	sp,sp,16
    80000e3c:	8082                	ret

0000000080000e3e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e3e:	1141                	addi	sp,sp,-16
    80000e40:	e422                	sd	s0,8(sp)
    80000e42:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e44:	02c05363          	blez	a2,80000e6a <safestrcpy+0x2c>
    80000e48:	fff6069b          	addiw	a3,a2,-1
    80000e4c:	1682                	slli	a3,a3,0x20
    80000e4e:	9281                	srli	a3,a3,0x20
    80000e50:	96ae                	add	a3,a3,a1
    80000e52:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e54:	00d58963          	beq	a1,a3,80000e66 <safestrcpy+0x28>
    80000e58:	0585                	addi	a1,a1,1
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff5c703          	lbu	a4,-1(a1)
    80000e60:	fee78fa3          	sb	a4,-1(a5)
    80000e64:	fb65                	bnez	a4,80000e54 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e66:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e6a:	6422                	ld	s0,8(sp)
    80000e6c:	0141                	addi	sp,sp,16
    80000e6e:	8082                	ret

0000000080000e70 <strlen>:

int
strlen(const char *s)
{
    80000e70:	1141                	addi	sp,sp,-16
    80000e72:	e422                	sd	s0,8(sp)
    80000e74:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e76:	00054783          	lbu	a5,0(a0)
    80000e7a:	cf91                	beqz	a5,80000e96 <strlen+0x26>
    80000e7c:	0505                	addi	a0,a0,1
    80000e7e:	87aa                	mv	a5,a0
    80000e80:	4685                	li	a3,1
    80000e82:	9e89                	subw	a3,a3,a0
    80000e84:	00f6853b          	addw	a0,a3,a5
    80000e88:	0785                	addi	a5,a5,1
    80000e8a:	fff7c703          	lbu	a4,-1(a5)
    80000e8e:	fb7d                	bnez	a4,80000e84 <strlen+0x14>
    ;
  return n;
}
    80000e90:	6422                	ld	s0,8(sp)
    80000e92:	0141                	addi	sp,sp,16
    80000e94:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e96:	4501                	li	a0,0
    80000e98:	bfe5                	j	80000e90 <strlen+0x20>

0000000080000e9a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e9a:	1141                	addi	sp,sp,-16
    80000e9c:	e406                	sd	ra,8(sp)
    80000e9e:	e022                	sd	s0,0(sp)
    80000ea0:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ea2:	00001097          	auipc	ra,0x1
    80000ea6:	b00080e7          	jalr	-1280(ra) # 800019a2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eaa:	00008717          	auipc	a4,0x8
    80000eae:	a9e70713          	addi	a4,a4,-1378 # 80008948 <started>
  if(cpuid() == 0){
    80000eb2:	c139                	beqz	a0,80000ef8 <main+0x5e>
    while(started == 0)
    80000eb4:	431c                	lw	a5,0(a4)
    80000eb6:	2781                	sext.w	a5,a5
    80000eb8:	dff5                	beqz	a5,80000eb4 <main+0x1a>
      ;
    __sync_synchronize();
    80000eba:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	ae4080e7          	jalr	-1308(ra) # 800019a2 <cpuid>
    80000ec6:	85aa                	mv	a1,a0
    80000ec8:	00007517          	auipc	a0,0x7
    80000ecc:	1f050513          	addi	a0,a0,496 # 800080b8 <digits+0x78>
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	6ba080e7          	jalr	1722(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	0d8080e7          	jalr	216(ra) # 80000fb0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ee0:	00002097          	auipc	ra,0x2
    80000ee4:	8d8080e7          	jalr	-1832(ra) # 800027b8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee8:	00005097          	auipc	ra,0x5
    80000eec:	ee8080e7          	jalr	-280(ra) # 80005dd0 <plicinithart>
  }

  scheduler();        
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	fd8080e7          	jalr	-40(ra) # 80001ec8 <scheduler>
    consoleinit();
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	558080e7          	jalr	1368(ra) # 80000450 <consoleinit>
    printfinit();
    80000f00:	00000097          	auipc	ra,0x0
    80000f04:	86a080e7          	jalr	-1942(ra) # 8000076a <printfinit>
    printf("\n");
    80000f08:	00007517          	auipc	a0,0x7
    80000f0c:	1c050513          	addi	a0,a0,448 # 800080c8 <digits+0x88>
    80000f10:	fffff097          	auipc	ra,0xfffff
    80000f14:	67a080e7          	jalr	1658(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f18:	00007517          	auipc	a0,0x7
    80000f1c:	18850513          	addi	a0,a0,392 # 800080a0 <digits+0x60>
    80000f20:	fffff097          	auipc	ra,0xfffff
    80000f24:	66a080e7          	jalr	1642(ra) # 8000058a <printf>
    printf("\n");
    80000f28:	00007517          	auipc	a0,0x7
    80000f2c:	1a050513          	addi	a0,a0,416 # 800080c8 <digits+0x88>
    80000f30:	fffff097          	auipc	ra,0xfffff
    80000f34:	65a080e7          	jalr	1626(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f38:	00000097          	auipc	ra,0x0
    80000f3c:	b72080e7          	jalr	-1166(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f40:	00000097          	auipc	ra,0x0
    80000f44:	326080e7          	jalr	806(ra) # 80001266 <kvminit>
    kvminithart();   // turn on paging
    80000f48:	00000097          	auipc	ra,0x0
    80000f4c:	068080e7          	jalr	104(ra) # 80000fb0 <kvminithart>
    procinit();      // process table
    80000f50:	00001097          	auipc	ra,0x1
    80000f54:	99e080e7          	jalr	-1634(ra) # 800018ee <procinit>
    trapinit();      // trap vectors
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	838080e7          	jalr	-1992(ra) # 80002790 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f60:	00002097          	auipc	ra,0x2
    80000f64:	858080e7          	jalr	-1960(ra) # 800027b8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e52080e7          	jalr	-430(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f70:	00005097          	auipc	ra,0x5
    80000f74:	e60080e7          	jalr	-416(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	ffe080e7          	jalr	-2(ra) # 80002f76 <binit>
    iinit();         // inode table
    80000f80:	00002097          	auipc	ra,0x2
    80000f84:	69e080e7          	jalr	1694(ra) # 8000361e <iinit>
    fileinit();      // file table
    80000f88:	00003097          	auipc	ra,0x3
    80000f8c:	644080e7          	jalr	1604(ra) # 800045cc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f90:	00005097          	auipc	ra,0x5
    80000f94:	f48080e7          	jalr	-184(ra) # 80005ed8 <virtio_disk_init>
    userinit();      // first user process
    80000f98:	00001097          	auipc	ra,0x1
    80000f9c:	d12080e7          	jalr	-750(ra) # 80001caa <userinit>
    __sync_synchronize();
    80000fa0:	0ff0000f          	fence
    started = 1;
    80000fa4:	4785                	li	a5,1
    80000fa6:	00008717          	auipc	a4,0x8
    80000faa:	9af72123          	sw	a5,-1630(a4) # 80008948 <started>
    80000fae:	b789                	j	80000ef0 <main+0x56>

0000000080000fb0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fb0:	1141                	addi	sp,sp,-16
    80000fb2:	e422                	sd	s0,8(sp)
    80000fb4:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb6:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fba:	00008797          	auipc	a5,0x8
    80000fbe:	9967b783          	ld	a5,-1642(a5) # 80008950 <kernel_pagetable>
    80000fc2:	83b1                	srli	a5,a5,0xc
    80000fc4:	577d                	li	a4,-1
    80000fc6:	177e                	slli	a4,a4,0x3f
    80000fc8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fca:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fce:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fd2:	6422                	ld	s0,8(sp)
    80000fd4:	0141                	addi	sp,sp,16
    80000fd6:	8082                	ret

0000000080000fd8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd8:	7139                	addi	sp,sp,-64
    80000fda:	fc06                	sd	ra,56(sp)
    80000fdc:	f822                	sd	s0,48(sp)
    80000fde:	f426                	sd	s1,40(sp)
    80000fe0:	f04a                	sd	s2,32(sp)
    80000fe2:	ec4e                	sd	s3,24(sp)
    80000fe4:	e852                	sd	s4,16(sp)
    80000fe6:	e456                	sd	s5,8(sp)
    80000fe8:	e05a                	sd	s6,0(sp)
    80000fea:	0080                	addi	s0,sp,64
    80000fec:	84aa                	mv	s1,a0
    80000fee:	89ae                	mv	s3,a1
    80000ff0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ff2:	57fd                	li	a5,-1
    80000ff4:	83e9                	srli	a5,a5,0x1a
    80000ff6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ffa:	04b7f263          	bgeu	a5,a1,8000103e <walk+0x66>
    panic("walk");
    80000ffe:	00007517          	auipc	a0,0x7
    80001002:	0d250513          	addi	a0,a0,210 # 800080d0 <digits+0x90>
    80001006:	fffff097          	auipc	ra,0xfffff
    8000100a:	53a080e7          	jalr	1338(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000100e:	060a8663          	beqz	s5,8000107a <walk+0xa2>
    80001012:	00000097          	auipc	ra,0x0
    80001016:	ad4080e7          	jalr	-1324(ra) # 80000ae6 <kalloc>
    8000101a:	84aa                	mv	s1,a0
    8000101c:	c529                	beqz	a0,80001066 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000101e:	6605                	lui	a2,0x1
    80001020:	4581                	li	a1,0
    80001022:	00000097          	auipc	ra,0x0
    80001026:	cd2080e7          	jalr	-814(ra) # 80000cf4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000102a:	00c4d793          	srli	a5,s1,0xc
    8000102e:	07aa                	slli	a5,a5,0xa
    80001030:	0017e793          	ori	a5,a5,1
    80001034:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001038:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd017>
    8000103a:	036a0063          	beq	s4,s6,8000105a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000103e:	0149d933          	srl	s2,s3,s4
    80001042:	1ff97913          	andi	s2,s2,511
    80001046:	090e                	slli	s2,s2,0x3
    80001048:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000104a:	00093483          	ld	s1,0(s2)
    8000104e:	0014f793          	andi	a5,s1,1
    80001052:	dfd5                	beqz	a5,8000100e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001054:	80a9                	srli	s1,s1,0xa
    80001056:	04b2                	slli	s1,s1,0xc
    80001058:	b7c5                	j	80001038 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000105a:	00c9d513          	srli	a0,s3,0xc
    8000105e:	1ff57513          	andi	a0,a0,511
    80001062:	050e                	slli	a0,a0,0x3
    80001064:	9526                	add	a0,a0,s1
}
    80001066:	70e2                	ld	ra,56(sp)
    80001068:	7442                	ld	s0,48(sp)
    8000106a:	74a2                	ld	s1,40(sp)
    8000106c:	7902                	ld	s2,32(sp)
    8000106e:	69e2                	ld	s3,24(sp)
    80001070:	6a42                	ld	s4,16(sp)
    80001072:	6aa2                	ld	s5,8(sp)
    80001074:	6b02                	ld	s6,0(sp)
    80001076:	6121                	addi	sp,sp,64
    80001078:	8082                	ret
        return 0;
    8000107a:	4501                	li	a0,0
    8000107c:	b7ed                	j	80001066 <walk+0x8e>

000000008000107e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000107e:	57fd                	li	a5,-1
    80001080:	83e9                	srli	a5,a5,0x1a
    80001082:	00b7f463          	bgeu	a5,a1,8000108a <walkaddr+0xc>
    return 0;
    80001086:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001088:	8082                	ret
{
    8000108a:	1141                	addi	sp,sp,-16
    8000108c:	e406                	sd	ra,8(sp)
    8000108e:	e022                	sd	s0,0(sp)
    80001090:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001092:	4601                	li	a2,0
    80001094:	00000097          	auipc	ra,0x0
    80001098:	f44080e7          	jalr	-188(ra) # 80000fd8 <walk>
  if(pte == 0)
    8000109c:	c105                	beqz	a0,800010bc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000109e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010a0:	0117f693          	andi	a3,a5,17
    800010a4:	4745                	li	a4,17
    return 0;
    800010a6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a8:	00e68663          	beq	a3,a4,800010b4 <walkaddr+0x36>
}
    800010ac:	60a2                	ld	ra,8(sp)
    800010ae:	6402                	ld	s0,0(sp)
    800010b0:	0141                	addi	sp,sp,16
    800010b2:	8082                	ret
  pa = PTE2PA(*pte);
    800010b4:	83a9                	srli	a5,a5,0xa
    800010b6:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010ba:	bfcd                	j	800010ac <walkaddr+0x2e>
    return 0;
    800010bc:	4501                	li	a0,0
    800010be:	b7fd                	j	800010ac <walkaddr+0x2e>

00000000800010c0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010c0:	715d                	addi	sp,sp,-80
    800010c2:	e486                	sd	ra,72(sp)
    800010c4:	e0a2                	sd	s0,64(sp)
    800010c6:	fc26                	sd	s1,56(sp)
    800010c8:	f84a                	sd	s2,48(sp)
    800010ca:	f44e                	sd	s3,40(sp)
    800010cc:	f052                	sd	s4,32(sp)
    800010ce:	ec56                	sd	s5,24(sp)
    800010d0:	e85a                	sd	s6,16(sp)
    800010d2:	e45e                	sd	s7,8(sp)
    800010d4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d6:	c639                	beqz	a2,80001124 <mappages+0x64>
    800010d8:	8aaa                	mv	s5,a0
    800010da:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010dc:	777d                	lui	a4,0xfffff
    800010de:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010e2:	fff58993          	addi	s3,a1,-1
    800010e6:	99b2                	add	s3,s3,a2
    800010e8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ec:	893e                	mv	s2,a5
    800010ee:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010f2:	6b85                	lui	s7,0x1
    800010f4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f8:	4605                	li	a2,1
    800010fa:	85ca                	mv	a1,s2
    800010fc:	8556                	mv	a0,s5
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	eda080e7          	jalr	-294(ra) # 80000fd8 <walk>
    80001106:	cd1d                	beqz	a0,80001144 <mappages+0x84>
    if(*pte & PTE_V)
    80001108:	611c                	ld	a5,0(a0)
    8000110a:	8b85                	andi	a5,a5,1
    8000110c:	e785                	bnez	a5,80001134 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000110e:	80b1                	srli	s1,s1,0xc
    80001110:	04aa                	slli	s1,s1,0xa
    80001112:	0164e4b3          	or	s1,s1,s6
    80001116:	0014e493          	ori	s1,s1,1
    8000111a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000111c:	05390063          	beq	s2,s3,8000115c <mappages+0x9c>
    a += PGSIZE;
    80001120:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001122:	bfc9                	j	800010f4 <mappages+0x34>
    panic("mappages: size");
    80001124:	00007517          	auipc	a0,0x7
    80001128:	fb450513          	addi	a0,a0,-76 # 800080d8 <digits+0x98>
    8000112c:	fffff097          	auipc	ra,0xfffff
    80001130:	414080e7          	jalr	1044(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001134:	00007517          	auipc	a0,0x7
    80001138:	fb450513          	addi	a0,a0,-76 # 800080e8 <digits+0xa8>
    8000113c:	fffff097          	auipc	ra,0xfffff
    80001140:	404080e7          	jalr	1028(ra) # 80000540 <panic>
      return -1;
    80001144:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001146:	60a6                	ld	ra,72(sp)
    80001148:	6406                	ld	s0,64(sp)
    8000114a:	74e2                	ld	s1,56(sp)
    8000114c:	7942                	ld	s2,48(sp)
    8000114e:	79a2                	ld	s3,40(sp)
    80001150:	7a02                	ld	s4,32(sp)
    80001152:	6ae2                	ld	s5,24(sp)
    80001154:	6b42                	ld	s6,16(sp)
    80001156:	6ba2                	ld	s7,8(sp)
    80001158:	6161                	addi	sp,sp,80
    8000115a:	8082                	ret
  return 0;
    8000115c:	4501                	li	a0,0
    8000115e:	b7e5                	j	80001146 <mappages+0x86>

0000000080001160 <kvmmap>:
{
    80001160:	1141                	addi	sp,sp,-16
    80001162:	e406                	sd	ra,8(sp)
    80001164:	e022                	sd	s0,0(sp)
    80001166:	0800                	addi	s0,sp,16
    80001168:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000116a:	86b2                	mv	a3,a2
    8000116c:	863e                	mv	a2,a5
    8000116e:	00000097          	auipc	ra,0x0
    80001172:	f52080e7          	jalr	-174(ra) # 800010c0 <mappages>
    80001176:	e509                	bnez	a0,80001180 <kvmmap+0x20>
}
    80001178:	60a2                	ld	ra,8(sp)
    8000117a:	6402                	ld	s0,0(sp)
    8000117c:	0141                	addi	sp,sp,16
    8000117e:	8082                	ret
    panic("kvmmap");
    80001180:	00007517          	auipc	a0,0x7
    80001184:	f7850513          	addi	a0,a0,-136 # 800080f8 <digits+0xb8>
    80001188:	fffff097          	auipc	ra,0xfffff
    8000118c:	3b8080e7          	jalr	952(ra) # 80000540 <panic>

0000000080001190 <kvmmake>:
{
    80001190:	1101                	addi	sp,sp,-32
    80001192:	ec06                	sd	ra,24(sp)
    80001194:	e822                	sd	s0,16(sp)
    80001196:	e426                	sd	s1,8(sp)
    80001198:	e04a                	sd	s2,0(sp)
    8000119a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119c:	00000097          	auipc	ra,0x0
    800011a0:	94a080e7          	jalr	-1718(ra) # 80000ae6 <kalloc>
    800011a4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	b4a080e7          	jalr	-1206(ra) # 80000cf4 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	6685                	lui	a3,0x1
    800011b6:	10000637          	lui	a2,0x10000
    800011ba:	100005b7          	lui	a1,0x10000
    800011be:	8526                	mv	a0,s1
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	fa0080e7          	jalr	-96(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c8:	4719                	li	a4,6
    800011ca:	6685                	lui	a3,0x1
    800011cc:	10001637          	lui	a2,0x10001
    800011d0:	100015b7          	lui	a1,0x10001
    800011d4:	8526                	mv	a0,s1
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	f8a080e7          	jalr	-118(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011de:	4719                	li	a4,6
    800011e0:	004006b7          	lui	a3,0x400
    800011e4:	0c000637          	lui	a2,0xc000
    800011e8:	0c0005b7          	lui	a1,0xc000
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f72080e7          	jalr	-142(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f6:	00007917          	auipc	s2,0x7
    800011fa:	e0a90913          	addi	s2,s2,-502 # 80008000 <etext>
    800011fe:	4729                	li	a4,10
    80001200:	80007697          	auipc	a3,0x80007
    80001204:	e0068693          	addi	a3,a3,-512 # 8000 <_entry-0x7fff8000>
    80001208:	4605                	li	a2,1
    8000120a:	067e                	slli	a2,a2,0x1f
    8000120c:	85b2                	mv	a1,a2
    8000120e:	8526                	mv	a0,s1
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f50080e7          	jalr	-176(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001218:	4719                	li	a4,6
    8000121a:	46c5                	li	a3,17
    8000121c:	06ee                	slli	a3,a3,0x1b
    8000121e:	412686b3          	sub	a3,a3,s2
    80001222:	864a                	mv	a2,s2
    80001224:	85ca                	mv	a1,s2
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	f38080e7          	jalr	-200(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001230:	4729                	li	a4,10
    80001232:	6685                	lui	a3,0x1
    80001234:	00006617          	auipc	a2,0x6
    80001238:	dcc60613          	addi	a2,a2,-564 # 80007000 <_trampoline>
    8000123c:	040005b7          	lui	a1,0x4000
    80001240:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001242:	05b2                	slli	a1,a1,0xc
    80001244:	8526                	mv	a0,s1
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f1a080e7          	jalr	-230(ra) # 80001160 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	608080e7          	jalr	1544(ra) # 80001858 <proc_mapstacks>
}
    80001258:	8526                	mv	a0,s1
    8000125a:	60e2                	ld	ra,24(sp)
    8000125c:	6442                	ld	s0,16(sp)
    8000125e:	64a2                	ld	s1,8(sp)
    80001260:	6902                	ld	s2,0(sp)
    80001262:	6105                	addi	sp,sp,32
    80001264:	8082                	ret

0000000080001266 <kvminit>:
{
    80001266:	1141                	addi	sp,sp,-16
    80001268:	e406                	sd	ra,8(sp)
    8000126a:	e022                	sd	s0,0(sp)
    8000126c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f22080e7          	jalr	-222(ra) # 80001190 <kvmmake>
    80001276:	00007797          	auipc	a5,0x7
    8000127a:	6ca7bd23          	sd	a0,1754(a5) # 80008950 <kernel_pagetable>
}
    8000127e:	60a2                	ld	ra,8(sp)
    80001280:	6402                	ld	s0,0(sp)
    80001282:	0141                	addi	sp,sp,16
    80001284:	8082                	ret

0000000080001286 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001286:	715d                	addi	sp,sp,-80
    80001288:	e486                	sd	ra,72(sp)
    8000128a:	e0a2                	sd	s0,64(sp)
    8000128c:	fc26                	sd	s1,56(sp)
    8000128e:	f84a                	sd	s2,48(sp)
    80001290:	f44e                	sd	s3,40(sp)
    80001292:	f052                	sd	s4,32(sp)
    80001294:	ec56                	sd	s5,24(sp)
    80001296:	e85a                	sd	s6,16(sp)
    80001298:	e45e                	sd	s7,8(sp)
    8000129a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129c:	03459793          	slli	a5,a1,0x34
    800012a0:	e795                	bnez	a5,800012cc <uvmunmap+0x46>
    800012a2:	8a2a                	mv	s4,a0
    800012a4:	892e                	mv	s2,a1
    800012a6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	0632                	slli	a2,a2,0xc
    800012aa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ae:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012b0:	6b05                	lui	s6,0x1
    800012b2:	0735e263          	bltu	a1,s3,80001316 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b6:	60a6                	ld	ra,72(sp)
    800012b8:	6406                	ld	s0,64(sp)
    800012ba:	74e2                	ld	s1,56(sp)
    800012bc:	7942                	ld	s2,48(sp)
    800012be:	79a2                	ld	s3,40(sp)
    800012c0:	7a02                	ld	s4,32(sp)
    800012c2:	6ae2                	ld	s5,24(sp)
    800012c4:	6b42                	ld	s6,16(sp)
    800012c6:	6ba2                	ld	s7,8(sp)
    800012c8:	6161                	addi	sp,sp,80
    800012ca:	8082                	ret
    panic("uvmunmap: not aligned");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e3450513          	addi	a0,a0,-460 # 80008100 <digits+0xc0>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26c080e7          	jalr	620(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e3c50513          	addi	a0,a0,-452 # 80008118 <digits+0xd8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25c080e7          	jalr	604(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e3c50513          	addi	a0,a0,-452 # 80008128 <digits+0xe8>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24c080e7          	jalr	588(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e4450513          	addi	a0,a0,-444 # 80008140 <digits+0x100>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	23c080e7          	jalr	572(ra) # 80000540 <panic>
    *pte = 0;
    8000130c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001310:	995a                	add	s2,s2,s6
    80001312:	fb3972e3          	bgeu	s2,s3,800012b6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001316:	4601                	li	a2,0
    80001318:	85ca                	mv	a1,s2
    8000131a:	8552                	mv	a0,s4
    8000131c:	00000097          	auipc	ra,0x0
    80001320:	cbc080e7          	jalr	-836(ra) # 80000fd8 <walk>
    80001324:	84aa                	mv	s1,a0
    80001326:	d95d                	beqz	a0,800012dc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001328:	6108                	ld	a0,0(a0)
    8000132a:	00157793          	andi	a5,a0,1
    8000132e:	dfdd                	beqz	a5,800012ec <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001330:	3ff57793          	andi	a5,a0,1023
    80001334:	fd7784e3          	beq	a5,s7,800012fc <uvmunmap+0x76>
    if(do_free){
    80001338:	fc0a8ae3          	beqz	s5,8000130c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000133c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000133e:	0532                	slli	a0,a0,0xc
    80001340:	fffff097          	auipc	ra,0xfffff
    80001344:	6a8080e7          	jalr	1704(ra) # 800009e8 <kfree>
    80001348:	b7d1                	j	8000130c <uvmunmap+0x86>

000000008000134a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000134a:	1101                	addi	sp,sp,-32
    8000134c:	ec06                	sd	ra,24(sp)
    8000134e:	e822                	sd	s0,16(sp)
    80001350:	e426                	sd	s1,8(sp)
    80001352:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	792080e7          	jalr	1938(ra) # 80000ae6 <kalloc>
    8000135c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135e:	c519                	beqz	a0,8000136c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001360:	6605                	lui	a2,0x1
    80001362:	4581                	li	a1,0
    80001364:	00000097          	auipc	ra,0x0
    80001368:	990080e7          	jalr	-1648(ra) # 80000cf4 <memset>
  return pagetable;
}
    8000136c:	8526                	mv	a0,s1
    8000136e:	60e2                	ld	ra,24(sp)
    80001370:	6442                	ld	s0,16(sp)
    80001372:	64a2                	ld	s1,8(sp)
    80001374:	6105                	addi	sp,sp,32
    80001376:	8082                	ret

0000000080001378 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001378:	7179                	addi	sp,sp,-48
    8000137a:	f406                	sd	ra,40(sp)
    8000137c:	f022                	sd	s0,32(sp)
    8000137e:	ec26                	sd	s1,24(sp)
    80001380:	e84a                	sd	s2,16(sp)
    80001382:	e44e                	sd	s3,8(sp)
    80001384:	e052                	sd	s4,0(sp)
    80001386:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001388:	6785                	lui	a5,0x1
    8000138a:	04f67863          	bgeu	a2,a5,800013da <uvmfirst+0x62>
    8000138e:	8a2a                	mv	s4,a0
    80001390:	89ae                	mv	s3,a1
    80001392:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	752080e7          	jalr	1874(ra) # 80000ae6 <kalloc>
    8000139c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	952080e7          	jalr	-1710(ra) # 80000cf4 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013aa:	4779                	li	a4,30
    800013ac:	86ca                	mv	a3,s2
    800013ae:	6605                	lui	a2,0x1
    800013b0:	4581                	li	a1,0
    800013b2:	8552                	mv	a0,s4
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	d0c080e7          	jalr	-756(ra) # 800010c0 <mappages>
  memmove(mem, src, sz);
    800013bc:	8626                	mv	a2,s1
    800013be:	85ce                	mv	a1,s3
    800013c0:	854a                	mv	a0,s2
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	98e080e7          	jalr	-1650(ra) # 80000d50 <memmove>
}
    800013ca:	70a2                	ld	ra,40(sp)
    800013cc:	7402                	ld	s0,32(sp)
    800013ce:	64e2                	ld	s1,24(sp)
    800013d0:	6942                	ld	s2,16(sp)
    800013d2:	69a2                	ld	s3,8(sp)
    800013d4:	6a02                	ld	s4,0(sp)
    800013d6:	6145                	addi	sp,sp,48
    800013d8:	8082                	ret
    panic("uvmfirst: more than a page");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	d7e50513          	addi	a0,a0,-642 # 80008158 <digits+0x118>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	15e080e7          	jalr	350(ra) # 80000540 <panic>

00000000800013ea <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f6:	00b67d63          	bgeu	a2,a1,80001410 <uvmdealloc+0x26>
    800013fa:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fc:	6785                	lui	a5,0x1
    800013fe:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001400:	00f60733          	add	a4,a2,a5
    80001404:	76fd                	lui	a3,0xfffff
    80001406:	8f75                	and	a4,a4,a3
    80001408:	97ae                	add	a5,a5,a1
    8000140a:	8ff5                	and	a5,a5,a3
    8000140c:	00f76863          	bltu	a4,a5,8000141c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001410:	8526                	mv	a0,s1
    80001412:	60e2                	ld	ra,24(sp)
    80001414:	6442                	ld	s0,16(sp)
    80001416:	64a2                	ld	s1,8(sp)
    80001418:	6105                	addi	sp,sp,32
    8000141a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141c:	8f99                	sub	a5,a5,a4
    8000141e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001420:	4685                	li	a3,1
    80001422:	0007861b          	sext.w	a2,a5
    80001426:	85ba                	mv	a1,a4
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	e5e080e7          	jalr	-418(ra) # 80001286 <uvmunmap>
    80001430:	b7c5                	j	80001410 <uvmdealloc+0x26>

0000000080001432 <uvmalloc>:
  if(newsz < oldsz)
    80001432:	0ab66563          	bltu	a2,a1,800014dc <uvmalloc+0xaa>
{
    80001436:	7139                	addi	sp,sp,-64
    80001438:	fc06                	sd	ra,56(sp)
    8000143a:	f822                	sd	s0,48(sp)
    8000143c:	f426                	sd	s1,40(sp)
    8000143e:	f04a                	sd	s2,32(sp)
    80001440:	ec4e                	sd	s3,24(sp)
    80001442:	e852                	sd	s4,16(sp)
    80001444:	e456                	sd	s5,8(sp)
    80001446:	e05a                	sd	s6,0(sp)
    80001448:	0080                	addi	s0,sp,64
    8000144a:	8aaa                	mv	s5,a0
    8000144c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144e:	6785                	lui	a5,0x1
    80001450:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001452:	95be                	add	a1,a1,a5
    80001454:	77fd                	lui	a5,0xfffff
    80001456:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145a:	08c9f363          	bgeu	s3,a2,800014e0 <uvmalloc+0xae>
    8000145e:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001460:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001464:	fffff097          	auipc	ra,0xfffff
    80001468:	682080e7          	jalr	1666(ra) # 80000ae6 <kalloc>
    8000146c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000146e:	c51d                	beqz	a0,8000149c <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001470:	6605                	lui	a2,0x1
    80001472:	4581                	li	a1,0
    80001474:	00000097          	auipc	ra,0x0
    80001478:	880080e7          	jalr	-1920(ra) # 80000cf4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000147c:	875a                	mv	a4,s6
    8000147e:	86a6                	mv	a3,s1
    80001480:	6605                	lui	a2,0x1
    80001482:	85ca                	mv	a1,s2
    80001484:	8556                	mv	a0,s5
    80001486:	00000097          	auipc	ra,0x0
    8000148a:	c3a080e7          	jalr	-966(ra) # 800010c0 <mappages>
    8000148e:	e90d                	bnez	a0,800014c0 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001490:	6785                	lui	a5,0x1
    80001492:	993e                	add	s2,s2,a5
    80001494:	fd4968e3          	bltu	s2,s4,80001464 <uvmalloc+0x32>
  return newsz;
    80001498:	8552                	mv	a0,s4
    8000149a:	a809                	j	800014ac <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000149c:	864e                	mv	a2,s3
    8000149e:	85ca                	mv	a1,s2
    800014a0:	8556                	mv	a0,s5
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	f48080e7          	jalr	-184(ra) # 800013ea <uvmdealloc>
      return 0;
    800014aa:	4501                	li	a0,0
}
    800014ac:	70e2                	ld	ra,56(sp)
    800014ae:	7442                	ld	s0,48(sp)
    800014b0:	74a2                	ld	s1,40(sp)
    800014b2:	7902                	ld	s2,32(sp)
    800014b4:	69e2                	ld	s3,24(sp)
    800014b6:	6a42                	ld	s4,16(sp)
    800014b8:	6aa2                	ld	s5,8(sp)
    800014ba:	6b02                	ld	s6,0(sp)
    800014bc:	6121                	addi	sp,sp,64
    800014be:	8082                	ret
      kfree(mem);
    800014c0:	8526                	mv	a0,s1
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	526080e7          	jalr	1318(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ca:	864e                	mv	a2,s3
    800014cc:	85ca                	mv	a1,s2
    800014ce:	8556                	mv	a0,s5
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	f1a080e7          	jalr	-230(ra) # 800013ea <uvmdealloc>
      return 0;
    800014d8:	4501                	li	a0,0
    800014da:	bfc9                	j	800014ac <uvmalloc+0x7a>
    return oldsz;
    800014dc:	852e                	mv	a0,a1
}
    800014de:	8082                	ret
  return newsz;
    800014e0:	8532                	mv	a0,a2
    800014e2:	b7e9                	j	800014ac <uvmalloc+0x7a>

00000000800014e4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014e4:	7179                	addi	sp,sp,-48
    800014e6:	f406                	sd	ra,40(sp)
    800014e8:	f022                	sd	s0,32(sp)
    800014ea:	ec26                	sd	s1,24(sp)
    800014ec:	e84a                	sd	s2,16(sp)
    800014ee:	e44e                	sd	s3,8(sp)
    800014f0:	e052                	sd	s4,0(sp)
    800014f2:	1800                	addi	s0,sp,48
    800014f4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f6:	84aa                	mv	s1,a0
    800014f8:	6905                	lui	s2,0x1
    800014fa:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fc:	4985                	li	s3,1
    800014fe:	a829                	j	80001518 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001500:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001502:	00c79513          	slli	a0,a5,0xc
    80001506:	00000097          	auipc	ra,0x0
    8000150a:	fde080e7          	jalr	-34(ra) # 800014e4 <freewalk>
      pagetable[i] = 0;
    8000150e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001512:	04a1                	addi	s1,s1,8
    80001514:	03248163          	beq	s1,s2,80001536 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001518:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151a:	00f7f713          	andi	a4,a5,15
    8000151e:	ff3701e3          	beq	a4,s3,80001500 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001522:	8b85                	andi	a5,a5,1
    80001524:	d7fd                	beqz	a5,80001512 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001526:	00007517          	auipc	a0,0x7
    8000152a:	c5250513          	addi	a0,a0,-942 # 80008178 <digits+0x138>
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	012080e7          	jalr	18(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001536:	8552                	mv	a0,s4
    80001538:	fffff097          	auipc	ra,0xfffff
    8000153c:	4b0080e7          	jalr	1200(ra) # 800009e8 <kfree>
}
    80001540:	70a2                	ld	ra,40(sp)
    80001542:	7402                	ld	s0,32(sp)
    80001544:	64e2                	ld	s1,24(sp)
    80001546:	6942                	ld	s2,16(sp)
    80001548:	69a2                	ld	s3,8(sp)
    8000154a:	6a02                	ld	s4,0(sp)
    8000154c:	6145                	addi	sp,sp,48
    8000154e:	8082                	ret

0000000080001550 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001550:	1101                	addi	sp,sp,-32
    80001552:	ec06                	sd	ra,24(sp)
    80001554:	e822                	sd	s0,16(sp)
    80001556:	e426                	sd	s1,8(sp)
    80001558:	1000                	addi	s0,sp,32
    8000155a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000155c:	e999                	bnez	a1,80001572 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000155e:	8526                	mv	a0,s1
    80001560:	00000097          	auipc	ra,0x0
    80001564:	f84080e7          	jalr	-124(ra) # 800014e4 <freewalk>
}
    80001568:	60e2                	ld	ra,24(sp)
    8000156a:	6442                	ld	s0,16(sp)
    8000156c:	64a2                	ld	s1,8(sp)
    8000156e:	6105                	addi	sp,sp,32
    80001570:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001572:	6785                	lui	a5,0x1
    80001574:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001576:	95be                	add	a1,a1,a5
    80001578:	4685                	li	a3,1
    8000157a:	00c5d613          	srli	a2,a1,0xc
    8000157e:	4581                	li	a1,0
    80001580:	00000097          	auipc	ra,0x0
    80001584:	d06080e7          	jalr	-762(ra) # 80001286 <uvmunmap>
    80001588:	bfd9                	j	8000155e <uvmfree+0xe>

000000008000158a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000158a:	c679                	beqz	a2,80001658 <uvmcopy+0xce>
{
    8000158c:	715d                	addi	sp,sp,-80
    8000158e:	e486                	sd	ra,72(sp)
    80001590:	e0a2                	sd	s0,64(sp)
    80001592:	fc26                	sd	s1,56(sp)
    80001594:	f84a                	sd	s2,48(sp)
    80001596:	f44e                	sd	s3,40(sp)
    80001598:	f052                	sd	s4,32(sp)
    8000159a:	ec56                	sd	s5,24(sp)
    8000159c:	e85a                	sd	s6,16(sp)
    8000159e:	e45e                	sd	s7,8(sp)
    800015a0:	0880                	addi	s0,sp,80
    800015a2:	8b2a                	mv	s6,a0
    800015a4:	8aae                	mv	s5,a1
    800015a6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015a8:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015aa:	4601                	li	a2,0
    800015ac:	85ce                	mv	a1,s3
    800015ae:	855a                	mv	a0,s6
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	a28080e7          	jalr	-1496(ra) # 80000fd8 <walk>
    800015b8:	c531                	beqz	a0,80001604 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ba:	6118                	ld	a4,0(a0)
    800015bc:	00177793          	andi	a5,a4,1
    800015c0:	cbb1                	beqz	a5,80001614 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015c2:	00a75593          	srli	a1,a4,0xa
    800015c6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ca:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ce:	fffff097          	auipc	ra,0xfffff
    800015d2:	518080e7          	jalr	1304(ra) # 80000ae6 <kalloc>
    800015d6:	892a                	mv	s2,a0
    800015d8:	c939                	beqz	a0,8000162e <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015da:	6605                	lui	a2,0x1
    800015dc:	85de                	mv	a1,s7
    800015de:	fffff097          	auipc	ra,0xfffff
    800015e2:	772080e7          	jalr	1906(ra) # 80000d50 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015e6:	8726                	mv	a4,s1
    800015e8:	86ca                	mv	a3,s2
    800015ea:	6605                	lui	a2,0x1
    800015ec:	85ce                	mv	a1,s3
    800015ee:	8556                	mv	a0,s5
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	ad0080e7          	jalr	-1328(ra) # 800010c0 <mappages>
    800015f8:	e515                	bnez	a0,80001624 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015fa:	6785                	lui	a5,0x1
    800015fc:	99be                	add	s3,s3,a5
    800015fe:	fb49e6e3          	bltu	s3,s4,800015aa <uvmcopy+0x20>
    80001602:	a081                	j	80001642 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001604:	00007517          	auipc	a0,0x7
    80001608:	b8450513          	addi	a0,a0,-1148 # 80008188 <digits+0x148>
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	f34080e7          	jalr	-204(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001614:	00007517          	auipc	a0,0x7
    80001618:	b9450513          	addi	a0,a0,-1132 # 800081a8 <digits+0x168>
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	f24080e7          	jalr	-220(ra) # 80000540 <panic>
      kfree(mem);
    80001624:	854a                	mv	a0,s2
    80001626:	fffff097          	auipc	ra,0xfffff
    8000162a:	3c2080e7          	jalr	962(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000162e:	4685                	li	a3,1
    80001630:	00c9d613          	srli	a2,s3,0xc
    80001634:	4581                	li	a1,0
    80001636:	8556                	mv	a0,s5
    80001638:	00000097          	auipc	ra,0x0
    8000163c:	c4e080e7          	jalr	-946(ra) # 80001286 <uvmunmap>
  return -1;
    80001640:	557d                	li	a0,-1
}
    80001642:	60a6                	ld	ra,72(sp)
    80001644:	6406                	ld	s0,64(sp)
    80001646:	74e2                	ld	s1,56(sp)
    80001648:	7942                	ld	s2,48(sp)
    8000164a:	79a2                	ld	s3,40(sp)
    8000164c:	7a02                	ld	s4,32(sp)
    8000164e:	6ae2                	ld	s5,24(sp)
    80001650:	6b42                	ld	s6,16(sp)
    80001652:	6ba2                	ld	s7,8(sp)
    80001654:	6161                	addi	sp,sp,80
    80001656:	8082                	ret
  return 0;
    80001658:	4501                	li	a0,0
}
    8000165a:	8082                	ret

000000008000165c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000165c:	1141                	addi	sp,sp,-16
    8000165e:	e406                	sd	ra,8(sp)
    80001660:	e022                	sd	s0,0(sp)
    80001662:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001664:	4601                	li	a2,0
    80001666:	00000097          	auipc	ra,0x0
    8000166a:	972080e7          	jalr	-1678(ra) # 80000fd8 <walk>
  if(pte == 0)
    8000166e:	c901                	beqz	a0,8000167e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001670:	611c                	ld	a5,0(a0)
    80001672:	9bbd                	andi	a5,a5,-17
    80001674:	e11c                	sd	a5,0(a0)
}
    80001676:	60a2                	ld	ra,8(sp)
    80001678:	6402                	ld	s0,0(sp)
    8000167a:	0141                	addi	sp,sp,16
    8000167c:	8082                	ret
    panic("uvmclear");
    8000167e:	00007517          	auipc	a0,0x7
    80001682:	b4a50513          	addi	a0,a0,-1206 # 800081c8 <digits+0x188>
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	eba080e7          	jalr	-326(ra) # 80000540 <panic>

000000008000168e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000168e:	c6bd                	beqz	a3,800016fc <copyout+0x6e>
{
    80001690:	715d                	addi	sp,sp,-80
    80001692:	e486                	sd	ra,72(sp)
    80001694:	e0a2                	sd	s0,64(sp)
    80001696:	fc26                	sd	s1,56(sp)
    80001698:	f84a                	sd	s2,48(sp)
    8000169a:	f44e                	sd	s3,40(sp)
    8000169c:	f052                	sd	s4,32(sp)
    8000169e:	ec56                	sd	s5,24(sp)
    800016a0:	e85a                	sd	s6,16(sp)
    800016a2:	e45e                	sd	s7,8(sp)
    800016a4:	e062                	sd	s8,0(sp)
    800016a6:	0880                	addi	s0,sp,80
    800016a8:	8b2a                	mv	s6,a0
    800016aa:	8c2e                	mv	s8,a1
    800016ac:	8a32                	mv	s4,a2
    800016ae:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016b2:	6a85                	lui	s5,0x1
    800016b4:	a015                	j	800016d8 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016b6:	9562                	add	a0,a0,s8
    800016b8:	0004861b          	sext.w	a2,s1
    800016bc:	85d2                	mv	a1,s4
    800016be:	41250533          	sub	a0,a0,s2
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	68e080e7          	jalr	1678(ra) # 80000d50 <memmove>

    len -= n;
    800016ca:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ce:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016d4:	02098263          	beqz	s3,800016f8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016d8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016dc:	85ca                	mv	a1,s2
    800016de:	855a                	mv	a0,s6
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	99e080e7          	jalr	-1634(ra) # 8000107e <walkaddr>
    if(pa0 == 0)
    800016e8:	cd01                	beqz	a0,80001700 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ea:	418904b3          	sub	s1,s2,s8
    800016ee:	94d6                	add	s1,s1,s5
    800016f0:	fc99f3e3          	bgeu	s3,s1,800016b6 <copyout+0x28>
    800016f4:	84ce                	mv	s1,s3
    800016f6:	b7c1                	j	800016b6 <copyout+0x28>
  }
  return 0;
    800016f8:	4501                	li	a0,0
    800016fa:	a021                	j	80001702 <copyout+0x74>
    800016fc:	4501                	li	a0,0
}
    800016fe:	8082                	ret
      return -1;
    80001700:	557d                	li	a0,-1
}
    80001702:	60a6                	ld	ra,72(sp)
    80001704:	6406                	ld	s0,64(sp)
    80001706:	74e2                	ld	s1,56(sp)
    80001708:	7942                	ld	s2,48(sp)
    8000170a:	79a2                	ld	s3,40(sp)
    8000170c:	7a02                	ld	s4,32(sp)
    8000170e:	6ae2                	ld	s5,24(sp)
    80001710:	6b42                	ld	s6,16(sp)
    80001712:	6ba2                	ld	s7,8(sp)
    80001714:	6c02                	ld	s8,0(sp)
    80001716:	6161                	addi	sp,sp,80
    80001718:	8082                	ret

000000008000171a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171a:	caa5                	beqz	a3,8000178a <copyin+0x70>
{
    8000171c:	715d                	addi	sp,sp,-80
    8000171e:	e486                	sd	ra,72(sp)
    80001720:	e0a2                	sd	s0,64(sp)
    80001722:	fc26                	sd	s1,56(sp)
    80001724:	f84a                	sd	s2,48(sp)
    80001726:	f44e                	sd	s3,40(sp)
    80001728:	f052                	sd	s4,32(sp)
    8000172a:	ec56                	sd	s5,24(sp)
    8000172c:	e85a                	sd	s6,16(sp)
    8000172e:	e45e                	sd	s7,8(sp)
    80001730:	e062                	sd	s8,0(sp)
    80001732:	0880                	addi	s0,sp,80
    80001734:	8b2a                	mv	s6,a0
    80001736:	8a2e                	mv	s4,a1
    80001738:	8c32                	mv	s8,a2
    8000173a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000173c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000173e:	6a85                	lui	s5,0x1
    80001740:	a01d                	j	80001766 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001742:	018505b3          	add	a1,a0,s8
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	412585b3          	sub	a1,a1,s2
    8000174e:	8552                	mv	a0,s4
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	600080e7          	jalr	1536(ra) # 80000d50 <memmove>

    len -= n;
    80001758:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000175c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000175e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001762:	02098263          	beqz	s3,80001786 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001766:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855a                	mv	a0,s6
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	910080e7          	jalr	-1776(ra) # 8000107e <walkaddr>
    if(pa0 == 0)
    80001776:	cd01                	beqz	a0,8000178e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001778:	418904b3          	sub	s1,s2,s8
    8000177c:	94d6                	add	s1,s1,s5
    8000177e:	fc99f2e3          	bgeu	s3,s1,80001742 <copyin+0x28>
    80001782:	84ce                	mv	s1,s3
    80001784:	bf7d                	j	80001742 <copyin+0x28>
  }
  return 0;
    80001786:	4501                	li	a0,0
    80001788:	a021                	j	80001790 <copyin+0x76>
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
      return -1;
    8000178e:	557d                	li	a0,-1
}
    80001790:	60a6                	ld	ra,72(sp)
    80001792:	6406                	ld	s0,64(sp)
    80001794:	74e2                	ld	s1,56(sp)
    80001796:	7942                	ld	s2,48(sp)
    80001798:	79a2                	ld	s3,40(sp)
    8000179a:	7a02                	ld	s4,32(sp)
    8000179c:	6ae2                	ld	s5,24(sp)
    8000179e:	6b42                	ld	s6,16(sp)
    800017a0:	6ba2                	ld	s7,8(sp)
    800017a2:	6c02                	ld	s8,0(sp)
    800017a4:	6161                	addi	sp,sp,80
    800017a6:	8082                	ret

00000000800017a8 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017a8:	c2dd                	beqz	a3,8000184e <copyinstr+0xa6>
{
    800017aa:	715d                	addi	sp,sp,-80
    800017ac:	e486                	sd	ra,72(sp)
    800017ae:	e0a2                	sd	s0,64(sp)
    800017b0:	fc26                	sd	s1,56(sp)
    800017b2:	f84a                	sd	s2,48(sp)
    800017b4:	f44e                	sd	s3,40(sp)
    800017b6:	f052                	sd	s4,32(sp)
    800017b8:	ec56                	sd	s5,24(sp)
    800017ba:	e85a                	sd	s6,16(sp)
    800017bc:	e45e                	sd	s7,8(sp)
    800017be:	0880                	addi	s0,sp,80
    800017c0:	8a2a                	mv	s4,a0
    800017c2:	8b2e                	mv	s6,a1
    800017c4:	8bb2                	mv	s7,a2
    800017c6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017c8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ca:	6985                	lui	s3,0x1
    800017cc:	a02d                	j	800017f6 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ce:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017d4:	37fd                	addiw	a5,a5,-1
    800017d6:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017da:	60a6                	ld	ra,72(sp)
    800017dc:	6406                	ld	s0,64(sp)
    800017de:	74e2                	ld	s1,56(sp)
    800017e0:	7942                	ld	s2,48(sp)
    800017e2:	79a2                	ld	s3,40(sp)
    800017e4:	7a02                	ld	s4,32(sp)
    800017e6:	6ae2                	ld	s5,24(sp)
    800017e8:	6b42                	ld	s6,16(sp)
    800017ea:	6ba2                	ld	s7,8(sp)
    800017ec:	6161                	addi	sp,sp,80
    800017ee:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017f4:	c8a9                	beqz	s1,80001846 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017f6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017fa:	85ca                	mv	a1,s2
    800017fc:	8552                	mv	a0,s4
    800017fe:	00000097          	auipc	ra,0x0
    80001802:	880080e7          	jalr	-1920(ra) # 8000107e <walkaddr>
    if(pa0 == 0)
    80001806:	c131                	beqz	a0,8000184a <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001808:	417906b3          	sub	a3,s2,s7
    8000180c:	96ce                	add	a3,a3,s3
    8000180e:	00d4f363          	bgeu	s1,a3,80001814 <copyinstr+0x6c>
    80001812:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001814:	955e                	add	a0,a0,s7
    80001816:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000181a:	daf9                	beqz	a3,800017f0 <copyinstr+0x48>
    8000181c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000181e:	41650633          	sub	a2,a0,s6
    80001822:	fff48593          	addi	a1,s1,-1
    80001826:	95da                	add	a1,a1,s6
    while(n > 0){
    80001828:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    8000182a:	00f60733          	add	a4,a2,a5
    8000182e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd020>
    80001832:	df51                	beqz	a4,800017ce <copyinstr+0x26>
        *dst = *p;
    80001834:	00e78023          	sb	a4,0(a5)
      --max;
    80001838:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000183c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000183e:	fed796e3          	bne	a5,a3,8000182a <copyinstr+0x82>
      dst++;
    80001842:	8b3e                	mv	s6,a5
    80001844:	b775                	j	800017f0 <copyinstr+0x48>
    80001846:	4781                	li	a5,0
    80001848:	b771                	j	800017d4 <copyinstr+0x2c>
      return -1;
    8000184a:	557d                	li	a0,-1
    8000184c:	b779                	j	800017da <copyinstr+0x32>
  int got_null = 0;
    8000184e:	4781                	li	a5,0
  if(got_null){
    80001850:	37fd                	addiw	a5,a5,-1
    80001852:	0007851b          	sext.w	a0,a5
}
    80001856:	8082                	ret

0000000080001858 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001858:	7139                	addi	sp,sp,-64
    8000185a:	fc06                	sd	ra,56(sp)
    8000185c:	f822                	sd	s0,48(sp)
    8000185e:	f426                	sd	s1,40(sp)
    80001860:	f04a                	sd	s2,32(sp)
    80001862:	ec4e                	sd	s3,24(sp)
    80001864:	e852                	sd	s4,16(sp)
    80001866:	e456                	sd	s5,8(sp)
    80001868:	e05a                	sd	s6,0(sp)
    8000186a:	0080                	addi	s0,sp,64
    8000186c:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	0000f497          	auipc	s1,0xf
    80001872:	79248493          	addi	s1,s1,1938 # 80011000 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001876:	8b26                	mv	s6,s1
    80001878:	00006a97          	auipc	s5,0x6
    8000187c:	788a8a93          	addi	s5,s5,1928 # 80008000 <etext>
    80001880:	04000937          	lui	s2,0x4000
    80001884:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001886:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001888:	00015a17          	auipc	s4,0x15
    8000188c:	378a0a13          	addi	s4,s4,888 # 80016c00 <tickslock>
    char *pa = kalloc();
    80001890:	fffff097          	auipc	ra,0xfffff
    80001894:	256080e7          	jalr	598(ra) # 80000ae6 <kalloc>
    80001898:	862a                	mv	a2,a0
    if(pa == 0)
    8000189a:	c131                	beqz	a0,800018de <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000189c:	416485b3          	sub	a1,s1,s6
    800018a0:	8591                	srai	a1,a1,0x4
    800018a2:	000ab783          	ld	a5,0(s5)
    800018a6:	02f585b3          	mul	a1,a1,a5
    800018aa:	2585                	addiw	a1,a1,1
    800018ac:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b0:	4719                	li	a4,6
    800018b2:	6685                	lui	a3,0x1
    800018b4:	40b905b3          	sub	a1,s2,a1
    800018b8:	854e                	mv	a0,s3
    800018ba:	00000097          	auipc	ra,0x0
    800018be:	8a6080e7          	jalr	-1882(ra) # 80001160 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c2:	17048493          	addi	s1,s1,368
    800018c6:	fd4495e3          	bne	s1,s4,80001890 <proc_mapstacks+0x38>
  }
}
    800018ca:	70e2                	ld	ra,56(sp)
    800018cc:	7442                	ld	s0,48(sp)
    800018ce:	74a2                	ld	s1,40(sp)
    800018d0:	7902                	ld	s2,32(sp)
    800018d2:	69e2                	ld	s3,24(sp)
    800018d4:	6a42                	ld	s4,16(sp)
    800018d6:	6aa2                	ld	s5,8(sp)
    800018d8:	6b02                	ld	s6,0(sp)
    800018da:	6121                	addi	sp,sp,64
    800018dc:	8082                	ret
      panic("kalloc");
    800018de:	00007517          	auipc	a0,0x7
    800018e2:	8fa50513          	addi	a0,a0,-1798 # 800081d8 <digits+0x198>
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	c5a080e7          	jalr	-934(ra) # 80000540 <panic>

00000000800018ee <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018ee:	7139                	addi	sp,sp,-64
    800018f0:	fc06                	sd	ra,56(sp)
    800018f2:	f822                	sd	s0,48(sp)
    800018f4:	f426                	sd	s1,40(sp)
    800018f6:	f04a                	sd	s2,32(sp)
    800018f8:	ec4e                	sd	s3,24(sp)
    800018fa:	e852                	sd	s4,16(sp)
    800018fc:	e456                	sd	s5,8(sp)
    800018fe:	e05a                	sd	s6,0(sp)
    80001900:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001902:	00007597          	auipc	a1,0x7
    80001906:	8de58593          	addi	a1,a1,-1826 # 800081e0 <digits+0x1a0>
    8000190a:	0000f517          	auipc	a0,0xf
    8000190e:	2c650513          	addi	a0,a0,710 # 80010bd0 <pid_lock>
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	256080e7          	jalr	598(ra) # 80000b68 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000191a:	00007597          	auipc	a1,0x7
    8000191e:	8ce58593          	addi	a1,a1,-1842 # 800081e8 <digits+0x1a8>
    80001922:	0000f517          	auipc	a0,0xf
    80001926:	2c650513          	addi	a0,a0,710 # 80010be8 <wait_lock>
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	23e080e7          	jalr	574(ra) # 80000b68 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	0000f497          	auipc	s1,0xf
    80001936:	6ce48493          	addi	s1,s1,1742 # 80011000 <proc>
      initlock(&p->lock, "proc");
    8000193a:	00007b17          	auipc	s6,0x7
    8000193e:	8beb0b13          	addi	s6,s6,-1858 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001942:	8aa6                	mv	s5,s1
    80001944:	00006a17          	auipc	s4,0x6
    80001948:	6bca0a13          	addi	s4,s4,1724 # 80008000 <etext>
    8000194c:	04000937          	lui	s2,0x4000
    80001950:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001952:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001954:	00015997          	auipc	s3,0x15
    80001958:	2ac98993          	addi	s3,s3,684 # 80016c00 <tickslock>
      initlock(&p->lock, "proc");
    8000195c:	85da                	mv	a1,s6
    8000195e:	8526                	mv	a0,s1
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	208080e7          	jalr	520(ra) # 80000b68 <initlock>
      p->state = UNUSED;
    80001968:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000196c:	415487b3          	sub	a5,s1,s5
    80001970:	8791                	srai	a5,a5,0x4
    80001972:	000a3703          	ld	a4,0(s4)
    80001976:	02e787b3          	mul	a5,a5,a4
    8000197a:	2785                	addiw	a5,a5,1
    8000197c:	00d7979b          	slliw	a5,a5,0xd
    80001980:	40f907b3          	sub	a5,s2,a5
    80001984:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001986:	17048493          	addi	s1,s1,368
    8000198a:	fd3499e3          	bne	s1,s3,8000195c <procinit+0x6e>
  }
}
    8000198e:	70e2                	ld	ra,56(sp)
    80001990:	7442                	ld	s0,48(sp)
    80001992:	74a2                	ld	s1,40(sp)
    80001994:	7902                	ld	s2,32(sp)
    80001996:	69e2                	ld	s3,24(sp)
    80001998:	6a42                	ld	s4,16(sp)
    8000199a:	6aa2                	ld	s5,8(sp)
    8000199c:	6b02                	ld	s6,0(sp)
    8000199e:	6121                	addi	sp,sp,64
    800019a0:	8082                	ret

00000000800019a2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a2:	1141                	addi	sp,sp,-16
    800019a4:	e422                	sd	s0,8(sp)
    800019a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019aa:	2501                	sext.w	a0,a0
    800019ac:	6422                	ld	s0,8(sp)
    800019ae:	0141                	addi	sp,sp,16
    800019b0:	8082                	ret

00000000800019b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
    800019b8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
  return c;
}
    800019be:	0000f517          	auipc	a0,0xf
    800019c2:	24250513          	addi	a0,a0,578 # 80010c00 <cpus>
    800019c6:	953e                	add	a0,a0,a5
    800019c8:	6422                	ld	s0,8(sp)
    800019ca:	0141                	addi	sp,sp,16
    800019cc:	8082                	ret

00000000800019ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	1000                	addi	s0,sp,32
  push_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	1d4080e7          	jalr	468(ra) # 80000bac <push_off>
    800019e0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
    800019e6:	0000f717          	auipc	a4,0xf
    800019ea:	1ea70713          	addi	a4,a4,490 # 80010bd0 <pid_lock>
    800019ee:	97ba                	add	a5,a5,a4
    800019f0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	25a080e7          	jalr	602(ra) # 80000c4c <pop_off>
  return p;
}
    800019fa:	8526                	mv	a0,s1
    800019fc:	60e2                	ld	ra,24(sp)
    800019fe:	6442                	ld	s0,16(sp)
    80001a00:	64a2                	ld	s1,8(sp)
    80001a02:	6105                	addi	sp,sp,32
    80001a04:	8082                	ret

0000000080001a06 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a06:	1141                	addi	sp,sp,-16
    80001a08:	e406                	sd	ra,8(sp)
    80001a0a:	e022                	sd	s0,0(sp)
    80001a0c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a0e:	00000097          	auipc	ra,0x0
    80001a12:	fc0080e7          	jalr	-64(ra) # 800019ce <myproc>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	296080e7          	jalr	662(ra) # 80000cac <release>

  if (first) {
    80001a1e:	00007797          	auipc	a5,0x7
    80001a22:	ea27a783          	lw	a5,-350(a5) # 800088c0 <first.1>
    80001a26:	eb89                	bnez	a5,80001a38 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a28:	00001097          	auipc	ra,0x1
    80001a2c:	da8080e7          	jalr	-600(ra) # 800027d0 <usertrapret>
}
    80001a30:	60a2                	ld	ra,8(sp)
    80001a32:	6402                	ld	s0,0(sp)
    80001a34:	0141                	addi	sp,sp,16
    80001a36:	8082                	ret
    first = 0;
    80001a38:	00007797          	auipc	a5,0x7
    80001a3c:	e807a423          	sw	zero,-376(a5) # 800088c0 <first.1>
    fsinit(ROOTDEV);
    80001a40:	4505                	li	a0,1
    80001a42:	00002097          	auipc	ra,0x2
    80001a46:	b5c080e7          	jalr	-1188(ra) # 8000359e <fsinit>
    80001a4a:	bff9                	j	80001a28 <forkret+0x22>

0000000080001a4c <allocpid>:
{
    80001a4c:	1101                	addi	sp,sp,-32
    80001a4e:	ec06                	sd	ra,24(sp)
    80001a50:	e822                	sd	s0,16(sp)
    80001a52:	e426                	sd	s1,8(sp)
    80001a54:	e04a                	sd	s2,0(sp)
    80001a56:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a58:	0000f917          	auipc	s2,0xf
    80001a5c:	17890913          	addi	s2,s2,376 # 80010bd0 <pid_lock>
    80001a60:	854a                	mv	a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	196080e7          	jalr	406(ra) # 80000bf8 <acquire>
  pid = nextpid;
    80001a6a:	00007797          	auipc	a5,0x7
    80001a6e:	e5a78793          	addi	a5,a5,-422 # 800088c4 <nextpid>
    80001a72:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a74:	0014871b          	addiw	a4,s1,1
    80001a78:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7a:	854a                	mv	a0,s2
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	230080e7          	jalr	560(ra) # 80000cac <release>
}
    80001a84:	8526                	mv	a0,s1
    80001a86:	60e2                	ld	ra,24(sp)
    80001a88:	6442                	ld	s0,16(sp)
    80001a8a:	64a2                	ld	s1,8(sp)
    80001a8c:	6902                	ld	s2,0(sp)
    80001a8e:	6105                	addi	sp,sp,32
    80001a90:	8082                	ret

0000000080001a92 <proc_pagetable>:
{
    80001a92:	1101                	addi	sp,sp,-32
    80001a94:	ec06                	sd	ra,24(sp)
    80001a96:	e822                	sd	s0,16(sp)
    80001a98:	e426                	sd	s1,8(sp)
    80001a9a:	e04a                	sd	s2,0(sp)
    80001a9c:	1000                	addi	s0,sp,32
    80001a9e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa0:	00000097          	auipc	ra,0x0
    80001aa4:	8aa080e7          	jalr	-1878(ra) # 8000134a <uvmcreate>
    80001aa8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aaa:	c121                	beqz	a0,80001aea <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aac:	4729                	li	a4,10
    80001aae:	00005697          	auipc	a3,0x5
    80001ab2:	55268693          	addi	a3,a3,1362 # 80007000 <_trampoline>
    80001ab6:	6605                	lui	a2,0x1
    80001ab8:	040005b7          	lui	a1,0x4000
    80001abc:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001abe:	05b2                	slli	a1,a1,0xc
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	600080e7          	jalr	1536(ra) # 800010c0 <mappages>
    80001ac8:	02054863          	bltz	a0,80001af8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001acc:	4719                	li	a4,6
    80001ace:	05893683          	ld	a3,88(s2)
    80001ad2:	6605                	lui	a2,0x1
    80001ad4:	020005b7          	lui	a1,0x2000
    80001ad8:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ada:	05b6                	slli	a1,a1,0xd
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	5e2080e7          	jalr	1506(ra) # 800010c0 <mappages>
    80001ae6:	02054163          	bltz	a0,80001b08 <proc_pagetable+0x76>
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6902                	ld	s2,0(sp)
    80001af4:	6105                	addi	sp,sp,32
    80001af6:	8082                	ret
    uvmfree(pagetable, 0);
    80001af8:	4581                	li	a1,0
    80001afa:	8526                	mv	a0,s1
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	a54080e7          	jalr	-1452(ra) # 80001550 <uvmfree>
    return 0;
    80001b04:	4481                	li	s1,0
    80001b06:	b7d5                	j	80001aea <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b08:	4681                	li	a3,0
    80001b0a:	4605                	li	a2,1
    80001b0c:	040005b7          	lui	a1,0x4000
    80001b10:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b12:	05b2                	slli	a1,a1,0xc
    80001b14:	8526                	mv	a0,s1
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	770080e7          	jalr	1904(ra) # 80001286 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1e:	4581                	li	a1,0
    80001b20:	8526                	mv	a0,s1
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	a2e080e7          	jalr	-1490(ra) # 80001550 <uvmfree>
    return 0;
    80001b2a:	4481                	li	s1,0
    80001b2c:	bf7d                	j	80001aea <proc_pagetable+0x58>

0000000080001b2e <proc_freepagetable>:
{
    80001b2e:	1101                	addi	sp,sp,-32
    80001b30:	ec06                	sd	ra,24(sp)
    80001b32:	e822                	sd	s0,16(sp)
    80001b34:	e426                	sd	s1,8(sp)
    80001b36:	e04a                	sd	s2,0(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
    80001b3c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3e:	4681                	li	a3,0
    80001b40:	4605                	li	a2,1
    80001b42:	040005b7          	lui	a1,0x4000
    80001b46:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b48:	05b2                	slli	a1,a1,0xc
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	73c080e7          	jalr	1852(ra) # 80001286 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b52:	4681                	li	a3,0
    80001b54:	4605                	li	a2,1
    80001b56:	020005b7          	lui	a1,0x2000
    80001b5a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b5c:	05b6                	slli	a1,a1,0xd
    80001b5e:	8526                	mv	a0,s1
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	726080e7          	jalr	1830(ra) # 80001286 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b68:	85ca                	mv	a1,s2
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	9e4080e7          	jalr	-1564(ra) # 80001550 <uvmfree>
}
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	64a2                	ld	s1,8(sp)
    80001b7a:	6902                	ld	s2,0(sp)
    80001b7c:	6105                	addi	sp,sp,32
    80001b7e:	8082                	ret

0000000080001b80 <freeproc>:
{
    80001b80:	1101                	addi	sp,sp,-32
    80001b82:	ec06                	sd	ra,24(sp)
    80001b84:	e822                	sd	s0,16(sp)
    80001b86:	e426                	sd	s1,8(sp)
    80001b88:	1000                	addi	s0,sp,32
    80001b8a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8c:	6d28                	ld	a0,88(a0)
    80001b8e:	c509                	beqz	a0,80001b98 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	e58080e7          	jalr	-424(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b98:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b9c:	68a8                	ld	a0,80(s1)
    80001b9e:	c511                	beqz	a0,80001baa <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba0:	64ac                	ld	a1,72(s1)
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	f8c080e7          	jalr	-116(ra) # 80001b2e <proc_freepagetable>
  p->pagetable = 0;
    80001baa:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bae:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bba:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bbe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bca:	0004ac23          	sw	zero,24(s1)
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <allocproc>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	e04a                	sd	s2,0(sp)
    80001be2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	0000f497          	auipc	s1,0xf
    80001be8:	41c48493          	addi	s1,s1,1052 # 80011000 <proc>
    80001bec:	00015917          	auipc	s2,0x15
    80001bf0:	01490913          	addi	s2,s2,20 # 80016c00 <tickslock>
    acquire(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	002080e7          	jalr	2(ra) # 80000bf8 <acquire>
    if(p->state == UNUSED) {
    80001bfe:	4c9c                	lw	a5,24(s1)
    80001c00:	cf81                	beqz	a5,80001c18 <allocproc+0x40>
      release(&p->lock);
    80001c02:	8526                	mv	a0,s1
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	0a8080e7          	jalr	168(ra) # 80000cac <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0c:	17048493          	addi	s1,s1,368
    80001c10:	ff2492e3          	bne	s1,s2,80001bf4 <allocproc+0x1c>
  return 0;
    80001c14:	4481                	li	s1,0
    80001c16:	a899                	j	80001c6c <allocproc+0x94>
  p->pid = allocpid();
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e34080e7          	jalr	-460(ra) # 80001a4c <allocpid>
    80001c20:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c22:	4785                	li	a5,1
    80001c24:	cc9c                	sw	a5,24(s1)
  p->sys_call_count = 0;
    80001c26:	1604b423          	sd	zero,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	ebc080e7          	jalr	-324(ra) # 80000ae6 <kalloc>
    80001c32:	892a                	mv	s2,a0
    80001c34:	eca8                	sd	a0,88(s1)
    80001c36:	c131                	beqz	a0,80001c7a <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	e58080e7          	jalr	-424(ra) # 80001a92 <proc_pagetable>
    80001c42:	892a                	mv	s2,a0
    80001c44:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c46:	c531                	beqz	a0,80001c92 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001c48:	07000613          	li	a2,112
    80001c4c:	4581                	li	a1,0
    80001c4e:	06048513          	addi	a0,s1,96
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	0a2080e7          	jalr	162(ra) # 80000cf4 <memset>
  p->context.ra = (uint64)forkret;
    80001c5a:	00000797          	auipc	a5,0x0
    80001c5e:	dac78793          	addi	a5,a5,-596 # 80001a06 <forkret>
    80001c62:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c64:	60bc                	ld	a5,64(s1)
    80001c66:	6705                	lui	a4,0x1
    80001c68:	97ba                	add	a5,a5,a4
    80001c6a:	f4bc                	sd	a5,104(s1)
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret
    freeproc(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	f04080e7          	jalr	-252(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	026080e7          	jalr	38(ra) # 80000cac <release>
    return 0;
    80001c8e:	84ca                	mv	s1,s2
    80001c90:	bff1                	j	80001c6c <allocproc+0x94>
    freeproc(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	eec080e7          	jalr	-276(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	00e080e7          	jalr	14(ra) # 80000cac <release>
    return 0;
    80001ca6:	84ca                	mv	s1,s2
    80001ca8:	b7d1                	j	80001c6c <allocproc+0x94>

0000000080001caa <userinit>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	f24080e7          	jalr	-220(ra) # 80001bd8 <allocproc>
    80001cbc:	84aa                	mv	s1,a0
  initproc = p;
    80001cbe:	00007797          	auipc	a5,0x7
    80001cc2:	c8a7bd23          	sd	a0,-870(a5) # 80008958 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc6:	03400613          	li	a2,52
    80001cca:	00007597          	auipc	a1,0x7
    80001cce:	c0658593          	addi	a1,a1,-1018 # 800088d0 <initcode>
    80001cd2:	6928                	ld	a0,80(a0)
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	6a4080e7          	jalr	1700(ra) # 80001378 <uvmfirst>
  p->sz = PGSIZE;
    80001cdc:	6785                	lui	a5,0x1
    80001cde:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cea:	4641                	li	a2,16
    80001cec:	00006597          	auipc	a1,0x6
    80001cf0:	51458593          	addi	a1,a1,1300 # 80008200 <digits+0x1c0>
    80001cf4:	15848513          	addi	a0,s1,344
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	146080e7          	jalr	326(ra) # 80000e3e <safestrcpy>
  p->cwd = namei("/");
    80001d00:	00006517          	auipc	a0,0x6
    80001d04:	51050513          	addi	a0,a0,1296 # 80008210 <digits+0x1d0>
    80001d08:	00002097          	auipc	ra,0x2
    80001d0c:	2c0080e7          	jalr	704(ra) # 80003fc8 <namei>
    80001d10:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d14:	478d                	li	a5,3
    80001d16:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	f92080e7          	jalr	-110(ra) # 80000cac <release>
}
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret

0000000080001d2c <growproc>:
{
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	e04a                	sd	s2,0(sp)
    80001d36:	1000                	addi	s0,sp,32
    80001d38:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	c94080e7          	jalr	-876(ra) # 800019ce <myproc>
    80001d42:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d44:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d46:	01204c63          	bgtz	s2,80001d5e <growproc+0x32>
  } else if(n < 0){
    80001d4a:	02094663          	bltz	s2,80001d76 <growproc+0x4a>
  p->sz = sz;
    80001d4e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d50:	4501                	li	a0,0
}
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6902                	ld	s2,0(sp)
    80001d5a:	6105                	addi	sp,sp,32
    80001d5c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d5e:	4691                	li	a3,4
    80001d60:	00b90633          	add	a2,s2,a1
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	6cc080e7          	jalr	1740(ra) # 80001432 <uvmalloc>
    80001d6e:	85aa                	mv	a1,a0
    80001d70:	fd79                	bnez	a0,80001d4e <growproc+0x22>
      return -1;
    80001d72:	557d                	li	a0,-1
    80001d74:	bff9                	j	80001d52 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d76:	00b90633          	add	a2,s2,a1
    80001d7a:	6928                	ld	a0,80(a0)
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	66e080e7          	jalr	1646(ra) # 800013ea <uvmdealloc>
    80001d84:	85aa                	mv	a1,a0
    80001d86:	b7e1                	j	80001d4e <growproc+0x22>

0000000080001d88 <fork>:
{
    80001d88:	7139                	addi	sp,sp,-64
    80001d8a:	fc06                	sd	ra,56(sp)
    80001d8c:	f822                	sd	s0,48(sp)
    80001d8e:	f426                	sd	s1,40(sp)
    80001d90:	f04a                	sd	s2,32(sp)
    80001d92:	ec4e                	sd	s3,24(sp)
    80001d94:	e852                	sd	s4,16(sp)
    80001d96:	e456                	sd	s5,8(sp)
    80001d98:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	c34080e7          	jalr	-972(ra) # 800019ce <myproc>
    80001da2:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	e34080e7          	jalr	-460(ra) # 80001bd8 <allocproc>
    80001dac:	10050c63          	beqz	a0,80001ec4 <fork+0x13c>
    80001db0:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db2:	048ab603          	ld	a2,72(s5)
    80001db6:	692c                	ld	a1,80(a0)
    80001db8:	050ab503          	ld	a0,80(s5)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	7ce080e7          	jalr	1998(ra) # 8000158a <uvmcopy>
    80001dc4:	04054863          	bltz	a0,80001e14 <fork+0x8c>
  np->sz = p->sz;
    80001dc8:	048ab783          	ld	a5,72(s5)
    80001dcc:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dd0:	058ab683          	ld	a3,88(s5)
    80001dd4:	87b6                	mv	a5,a3
    80001dd6:	058a3703          	ld	a4,88(s4)
    80001dda:	12068693          	addi	a3,a3,288
    80001dde:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de2:	6788                	ld	a0,8(a5)
    80001de4:	6b8c                	ld	a1,16(a5)
    80001de6:	6f90                	ld	a2,24(a5)
    80001de8:	01073023          	sd	a6,0(a4)
    80001dec:	e708                	sd	a0,8(a4)
    80001dee:	eb0c                	sd	a1,16(a4)
    80001df0:	ef10                	sd	a2,24(a4)
    80001df2:	02078793          	addi	a5,a5,32
    80001df6:	02070713          	addi	a4,a4,32
    80001dfa:	fed792e3          	bne	a5,a3,80001dde <fork+0x56>
  np->trapframe->a0 = 0;
    80001dfe:	058a3783          	ld	a5,88(s4)
    80001e02:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e06:	0d0a8493          	addi	s1,s5,208
    80001e0a:	0d0a0913          	addi	s2,s4,208
    80001e0e:	150a8993          	addi	s3,s5,336
    80001e12:	a00d                	j	80001e34 <fork+0xac>
    freeproc(np);
    80001e14:	8552                	mv	a0,s4
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	d6a080e7          	jalr	-662(ra) # 80001b80 <freeproc>
    release(&np->lock);
    80001e1e:	8552                	mv	a0,s4
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	e8c080e7          	jalr	-372(ra) # 80000cac <release>
    return -1;
    80001e28:	597d                	li	s2,-1
    80001e2a:	a059                	j	80001eb0 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e2c:	04a1                	addi	s1,s1,8
    80001e2e:	0921                	addi	s2,s2,8
    80001e30:	01348b63          	beq	s1,s3,80001e46 <fork+0xbe>
    if(p->ofile[i])
    80001e34:	6088                	ld	a0,0(s1)
    80001e36:	d97d                	beqz	a0,80001e2c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e38:	00003097          	auipc	ra,0x3
    80001e3c:	826080e7          	jalr	-2010(ra) # 8000465e <filedup>
    80001e40:	00a93023          	sd	a0,0(s2)
    80001e44:	b7e5                	j	80001e2c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e46:	150ab503          	ld	a0,336(s5)
    80001e4a:	00002097          	auipc	ra,0x2
    80001e4e:	994080e7          	jalr	-1644(ra) # 800037de <idup>
    80001e52:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e56:	4641                	li	a2,16
    80001e58:	158a8593          	addi	a1,s5,344
    80001e5c:	158a0513          	addi	a0,s4,344
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	fde080e7          	jalr	-34(ra) # 80000e3e <safestrcpy>
  pid = np->pid;
    80001e68:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e6c:	8552                	mv	a0,s4
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e3e080e7          	jalr	-450(ra) # 80000cac <release>
  acquire(&wait_lock);
    80001e76:	0000f497          	auipc	s1,0xf
    80001e7a:	d7248493          	addi	s1,s1,-654 # 80010be8 <wait_lock>
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	d78080e7          	jalr	-648(ra) # 80000bf8 <acquire>
  np->parent = p;
    80001e88:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	e1e080e7          	jalr	-482(ra) # 80000cac <release>
  acquire(&np->lock);
    80001e96:	8552                	mv	a0,s4
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	d60080e7          	jalr	-672(ra) # 80000bf8 <acquire>
  np->state = RUNNABLE;
    80001ea0:	478d                	li	a5,3
    80001ea2:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea6:	8552                	mv	a0,s4
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	e04080e7          	jalr	-508(ra) # 80000cac <release>
}
    80001eb0:	854a                	mv	a0,s2
    80001eb2:	70e2                	ld	ra,56(sp)
    80001eb4:	7442                	ld	s0,48(sp)
    80001eb6:	74a2                	ld	s1,40(sp)
    80001eb8:	7902                	ld	s2,32(sp)
    80001eba:	69e2                	ld	s3,24(sp)
    80001ebc:	6a42                	ld	s4,16(sp)
    80001ebe:	6aa2                	ld	s5,8(sp)
    80001ec0:	6121                	addi	sp,sp,64
    80001ec2:	8082                	ret
    return -1;
    80001ec4:	597d                	li	s2,-1
    80001ec6:	b7ed                	j	80001eb0 <fork+0x128>

0000000080001ec8 <scheduler>:
{
    80001ec8:	7139                	addi	sp,sp,-64
    80001eca:	fc06                	sd	ra,56(sp)
    80001ecc:	f822                	sd	s0,48(sp)
    80001ece:	f426                	sd	s1,40(sp)
    80001ed0:	f04a                	sd	s2,32(sp)
    80001ed2:	ec4e                	sd	s3,24(sp)
    80001ed4:	e852                	sd	s4,16(sp)
    80001ed6:	e456                	sd	s5,8(sp)
    80001ed8:	e05a                	sd	s6,0(sp)
    80001eda:	0080                	addi	s0,sp,64
    80001edc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ede:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee0:	00779a93          	slli	s5,a5,0x7
    80001ee4:	0000f717          	auipc	a4,0xf
    80001ee8:	cec70713          	addi	a4,a4,-788 # 80010bd0 <pid_lock>
    80001eec:	9756                	add	a4,a4,s5
    80001eee:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ef2:	0000f717          	auipc	a4,0xf
    80001ef6:	d1670713          	addi	a4,a4,-746 # 80010c08 <cpus+0x8>
    80001efa:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001efc:	498d                	li	s3,3
        p->state = RUNNING;
    80001efe:	4b11                	li	s6,4
        c->proc = p;
    80001f00:	079e                	slli	a5,a5,0x7
    80001f02:	0000fa17          	auipc	s4,0xf
    80001f06:	ccea0a13          	addi	s4,s4,-818 # 80010bd0 <pid_lock>
    80001f0a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0c:	00015917          	auipc	s2,0x15
    80001f10:	cf490913          	addi	s2,s2,-780 # 80016c00 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f14:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f18:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f1c:	10079073          	csrw	sstatus,a5
    80001f20:	0000f497          	auipc	s1,0xf
    80001f24:	0e048493          	addi	s1,s1,224 # 80011000 <proc>
    80001f28:	a811                	j	80001f3c <scheduler+0x74>
      release(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	d80080e7          	jalr	-640(ra) # 80000cac <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f34:	17048493          	addi	s1,s1,368
    80001f38:	fd248ee3          	beq	s1,s2,80001f14 <scheduler+0x4c>
      acquire(&p->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	cba080e7          	jalr	-838(ra) # 80000bf8 <acquire>
      if(p->state == RUNNABLE) {
    80001f46:	4c9c                	lw	a5,24(s1)
    80001f48:	ff3791e3          	bne	a5,s3,80001f2a <scheduler+0x62>
        p->state = RUNNING;
    80001f4c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f50:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f54:	06048593          	addi	a1,s1,96
    80001f58:	8556                	mv	a0,s5
    80001f5a:	00000097          	auipc	ra,0x0
    80001f5e:	7cc080e7          	jalr	1996(ra) # 80002726 <swtch>
        c->proc = 0;
    80001f62:	020a3823          	sd	zero,48(s4)
    80001f66:	b7d1                	j	80001f2a <scheduler+0x62>

0000000080001f68 <sched>:
{
    80001f68:	7179                	addi	sp,sp,-48
    80001f6a:	f406                	sd	ra,40(sp)
    80001f6c:	f022                	sd	s0,32(sp)
    80001f6e:	ec26                	sd	s1,24(sp)
    80001f70:	e84a                	sd	s2,16(sp)
    80001f72:	e44e                	sd	s3,8(sp)
    80001f74:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	a58080e7          	jalr	-1448(ra) # 800019ce <myproc>
    80001f7e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	bfe080e7          	jalr	-1026(ra) # 80000b7e <holding>
    80001f88:	c93d                	beqz	a0,80001ffe <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f8c:	2781                	sext.w	a5,a5
    80001f8e:	079e                	slli	a5,a5,0x7
    80001f90:	0000f717          	auipc	a4,0xf
    80001f94:	c4070713          	addi	a4,a4,-960 # 80010bd0 <pid_lock>
    80001f98:	97ba                	add	a5,a5,a4
    80001f9a:	0a87a703          	lw	a4,168(a5)
    80001f9e:	4785                	li	a5,1
    80001fa0:	06f71763          	bne	a4,a5,8000200e <sched+0xa6>
  if(p->state == RUNNING)
    80001fa4:	4c98                	lw	a4,24(s1)
    80001fa6:	4791                	li	a5,4
    80001fa8:	06f70b63          	beq	a4,a5,8000201e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fb0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fb2:	efb5                	bnez	a5,8000202e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb6:	0000f917          	auipc	s2,0xf
    80001fba:	c1a90913          	addi	s2,s2,-998 # 80010bd0 <pid_lock>
    80001fbe:	2781                	sext.w	a5,a5
    80001fc0:	079e                	slli	a5,a5,0x7
    80001fc2:	97ca                	add	a5,a5,s2
    80001fc4:	0ac7a983          	lw	s3,172(a5)
    80001fc8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fca:	2781                	sext.w	a5,a5
    80001fcc:	079e                	slli	a5,a5,0x7
    80001fce:	0000f597          	auipc	a1,0xf
    80001fd2:	c3a58593          	addi	a1,a1,-966 # 80010c08 <cpus+0x8>
    80001fd6:	95be                	add	a1,a1,a5
    80001fd8:	06048513          	addi	a0,s1,96
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	74a080e7          	jalr	1866(ra) # 80002726 <swtch>
    80001fe4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe6:	2781                	sext.w	a5,a5
    80001fe8:	079e                	slli	a5,a5,0x7
    80001fea:	993e                	add	s2,s2,a5
    80001fec:	0b392623          	sw	s3,172(s2)
}
    80001ff0:	70a2                	ld	ra,40(sp)
    80001ff2:	7402                	ld	s0,32(sp)
    80001ff4:	64e2                	ld	s1,24(sp)
    80001ff6:	6942                	ld	s2,16(sp)
    80001ff8:	69a2                	ld	s3,8(sp)
    80001ffa:	6145                	addi	sp,sp,48
    80001ffc:	8082                	ret
    panic("sched p->lock");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	21a50513          	addi	a0,a0,538 # 80008218 <digits+0x1d8>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	53a080e7          	jalr	1338(ra) # 80000540 <panic>
    panic("sched locks");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	21a50513          	addi	a0,a0,538 # 80008228 <digits+0x1e8>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	52a080e7          	jalr	1322(ra) # 80000540 <panic>
    panic("sched running");
    8000201e:	00006517          	auipc	a0,0x6
    80002022:	21a50513          	addi	a0,a0,538 # 80008238 <digits+0x1f8>
    80002026:	ffffe097          	auipc	ra,0xffffe
    8000202a:	51a080e7          	jalr	1306(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000202e:	00006517          	auipc	a0,0x6
    80002032:	21a50513          	addi	a0,a0,538 # 80008248 <digits+0x208>
    80002036:	ffffe097          	auipc	ra,0xffffe
    8000203a:	50a080e7          	jalr	1290(ra) # 80000540 <panic>

000000008000203e <yield>:
{
    8000203e:	1101                	addi	sp,sp,-32
    80002040:	ec06                	sd	ra,24(sp)
    80002042:	e822                	sd	s0,16(sp)
    80002044:	e426                	sd	s1,8(sp)
    80002046:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002048:	00000097          	auipc	ra,0x0
    8000204c:	986080e7          	jalr	-1658(ra) # 800019ce <myproc>
    80002050:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	ba6080e7          	jalr	-1114(ra) # 80000bf8 <acquire>
  p->state = RUNNABLE;
    8000205a:	478d                	li	a5,3
    8000205c:	cc9c                	sw	a5,24(s1)
  sched();
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	f0a080e7          	jalr	-246(ra) # 80001f68 <sched>
  release(&p->lock);
    80002066:	8526                	mv	a0,s1
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	c44080e7          	jalr	-956(ra) # 80000cac <release>
}
    80002070:	60e2                	ld	ra,24(sp)
    80002072:	6442                	ld	s0,16(sp)
    80002074:	64a2                	ld	s1,8(sp)
    80002076:	6105                	addi	sp,sp,32
    80002078:	8082                	ret

000000008000207a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000207a:	7179                	addi	sp,sp,-48
    8000207c:	f406                	sd	ra,40(sp)
    8000207e:	f022                	sd	s0,32(sp)
    80002080:	ec26                	sd	s1,24(sp)
    80002082:	e84a                	sd	s2,16(sp)
    80002084:	e44e                	sd	s3,8(sp)
    80002086:	1800                	addi	s0,sp,48
    80002088:	89aa                	mv	s3,a0
    8000208a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	942080e7          	jalr	-1726(ra) # 800019ce <myproc>
    80002094:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	b62080e7          	jalr	-1182(ra) # 80000bf8 <acquire>
  release(lk);
    8000209e:	854a                	mv	a0,s2
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	c0c080e7          	jalr	-1012(ra) # 80000cac <release>

  // Go to sleep.
  p->chan = chan;
    800020a8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ac:	4789                	li	a5,2
    800020ae:	cc9c                	sw	a5,24(s1)

  sched();
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	eb8080e7          	jalr	-328(ra) # 80001f68 <sched>

  // Tidy up.
  p->chan = 0;
    800020b8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	bee080e7          	jalr	-1042(ra) # 80000cac <release>
  acquire(lk);
    800020c6:	854a                	mv	a0,s2
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	b30080e7          	jalr	-1232(ra) # 80000bf8 <acquire>
}
    800020d0:	70a2                	ld	ra,40(sp)
    800020d2:	7402                	ld	s0,32(sp)
    800020d4:	64e2                	ld	s1,24(sp)
    800020d6:	6942                	ld	s2,16(sp)
    800020d8:	69a2                	ld	s3,8(sp)
    800020da:	6145                	addi	sp,sp,48
    800020dc:	8082                	ret

00000000800020de <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020de:	7139                	addi	sp,sp,-64
    800020e0:	fc06                	sd	ra,56(sp)
    800020e2:	f822                	sd	s0,48(sp)
    800020e4:	f426                	sd	s1,40(sp)
    800020e6:	f04a                	sd	s2,32(sp)
    800020e8:	ec4e                	sd	s3,24(sp)
    800020ea:	e852                	sd	s4,16(sp)
    800020ec:	e456                	sd	s5,8(sp)
    800020ee:	0080                	addi	s0,sp,64
    800020f0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020f2:	0000f497          	auipc	s1,0xf
    800020f6:	f0e48493          	addi	s1,s1,-242 # 80011000 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020fa:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020fc:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020fe:	00015917          	auipc	s2,0x15
    80002102:	b0290913          	addi	s2,s2,-1278 # 80016c00 <tickslock>
    80002106:	a811                	j	8000211a <wakeup+0x3c>
      }
      release(&p->lock);
    80002108:	8526                	mv	a0,s1
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	ba2080e7          	jalr	-1118(ra) # 80000cac <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002112:	17048493          	addi	s1,s1,368
    80002116:	03248663          	beq	s1,s2,80002142 <wakeup+0x64>
    if(p != myproc()){
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	8b4080e7          	jalr	-1868(ra) # 800019ce <myproc>
    80002122:	fea488e3          	beq	s1,a0,80002112 <wakeup+0x34>
      acquire(&p->lock);
    80002126:	8526                	mv	a0,s1
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	ad0080e7          	jalr	-1328(ra) # 80000bf8 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002130:	4c9c                	lw	a5,24(s1)
    80002132:	fd379be3          	bne	a5,s3,80002108 <wakeup+0x2a>
    80002136:	709c                	ld	a5,32(s1)
    80002138:	fd4798e3          	bne	a5,s4,80002108 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000213c:	0154ac23          	sw	s5,24(s1)
    80002140:	b7e1                	j	80002108 <wakeup+0x2a>
    }
  }
}
    80002142:	70e2                	ld	ra,56(sp)
    80002144:	7442                	ld	s0,48(sp)
    80002146:	74a2                	ld	s1,40(sp)
    80002148:	7902                	ld	s2,32(sp)
    8000214a:	69e2                	ld	s3,24(sp)
    8000214c:	6a42                	ld	s4,16(sp)
    8000214e:	6aa2                	ld	s5,8(sp)
    80002150:	6121                	addi	sp,sp,64
    80002152:	8082                	ret

0000000080002154 <reparent>:
{
    80002154:	7179                	addi	sp,sp,-48
    80002156:	f406                	sd	ra,40(sp)
    80002158:	f022                	sd	s0,32(sp)
    8000215a:	ec26                	sd	s1,24(sp)
    8000215c:	e84a                	sd	s2,16(sp)
    8000215e:	e44e                	sd	s3,8(sp)
    80002160:	e052                	sd	s4,0(sp)
    80002162:	1800                	addi	s0,sp,48
    80002164:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002166:	0000f497          	auipc	s1,0xf
    8000216a:	e9a48493          	addi	s1,s1,-358 # 80011000 <proc>
      pp->parent = initproc;
    8000216e:	00006a17          	auipc	s4,0x6
    80002172:	7eaa0a13          	addi	s4,s4,2026 # 80008958 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002176:	00015997          	auipc	s3,0x15
    8000217a:	a8a98993          	addi	s3,s3,-1398 # 80016c00 <tickslock>
    8000217e:	a029                	j	80002188 <reparent+0x34>
    80002180:	17048493          	addi	s1,s1,368
    80002184:	01348d63          	beq	s1,s3,8000219e <reparent+0x4a>
    if(pp->parent == p){
    80002188:	7c9c                	ld	a5,56(s1)
    8000218a:	ff279be3          	bne	a5,s2,80002180 <reparent+0x2c>
      pp->parent = initproc;
    8000218e:	000a3503          	ld	a0,0(s4)
    80002192:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002194:	00000097          	auipc	ra,0x0
    80002198:	f4a080e7          	jalr	-182(ra) # 800020de <wakeup>
    8000219c:	b7d5                	j	80002180 <reparent+0x2c>
}
    8000219e:	70a2                	ld	ra,40(sp)
    800021a0:	7402                	ld	s0,32(sp)
    800021a2:	64e2                	ld	s1,24(sp)
    800021a4:	6942                	ld	s2,16(sp)
    800021a6:	69a2                	ld	s3,8(sp)
    800021a8:	6a02                	ld	s4,0(sp)
    800021aa:	6145                	addi	sp,sp,48
    800021ac:	8082                	ret

00000000800021ae <exit>:
{
    800021ae:	7179                	addi	sp,sp,-48
    800021b0:	f406                	sd	ra,40(sp)
    800021b2:	f022                	sd	s0,32(sp)
    800021b4:	ec26                	sd	s1,24(sp)
    800021b6:	e84a                	sd	s2,16(sp)
    800021b8:	e44e                	sd	s3,8(sp)
    800021ba:	e052                	sd	s4,0(sp)
    800021bc:	1800                	addi	s0,sp,48
    800021be:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	80e080e7          	jalr	-2034(ra) # 800019ce <myproc>
    800021c8:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ca:	00006797          	auipc	a5,0x6
    800021ce:	78e7b783          	ld	a5,1934(a5) # 80008958 <initproc>
    800021d2:	0d050493          	addi	s1,a0,208
    800021d6:	15050913          	addi	s2,a0,336
    800021da:	02a79363          	bne	a5,a0,80002200 <exit+0x52>
    panic("init exiting");
    800021de:	00006517          	auipc	a0,0x6
    800021e2:	08250513          	addi	a0,a0,130 # 80008260 <digits+0x220>
    800021e6:	ffffe097          	auipc	ra,0xffffe
    800021ea:	35a080e7          	jalr	858(ra) # 80000540 <panic>
      fileclose(f);
    800021ee:	00002097          	auipc	ra,0x2
    800021f2:	4c2080e7          	jalr	1218(ra) # 800046b0 <fileclose>
      p->ofile[fd] = 0;
    800021f6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021fa:	04a1                	addi	s1,s1,8
    800021fc:	01248563          	beq	s1,s2,80002206 <exit+0x58>
    if(p->ofile[fd]){
    80002200:	6088                	ld	a0,0(s1)
    80002202:	f575                	bnez	a0,800021ee <exit+0x40>
    80002204:	bfdd                	j	800021fa <exit+0x4c>
  begin_op();
    80002206:	00002097          	auipc	ra,0x2
    8000220a:	fe2080e7          	jalr	-30(ra) # 800041e8 <begin_op>
  iput(p->cwd);
    8000220e:	1509b503          	ld	a0,336(s3)
    80002212:	00001097          	auipc	ra,0x1
    80002216:	7c4080e7          	jalr	1988(ra) # 800039d6 <iput>
  end_op();
    8000221a:	00002097          	auipc	ra,0x2
    8000221e:	04c080e7          	jalr	76(ra) # 80004266 <end_op>
  p->cwd = 0;
    80002222:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002226:	0000f497          	auipc	s1,0xf
    8000222a:	9c248493          	addi	s1,s1,-1598 # 80010be8 <wait_lock>
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	9c8080e7          	jalr	-1592(ra) # 80000bf8 <acquire>
  reparent(p);
    80002238:	854e                	mv	a0,s3
    8000223a:	00000097          	auipc	ra,0x0
    8000223e:	f1a080e7          	jalr	-230(ra) # 80002154 <reparent>
  wakeup(p->parent);
    80002242:	0389b503          	ld	a0,56(s3)
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	e98080e7          	jalr	-360(ra) # 800020de <wakeup>
  acquire(&p->lock);
    8000224e:	854e                	mv	a0,s3
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	9a8080e7          	jalr	-1624(ra) # 80000bf8 <acquire>
  p->xstate = status;
    80002258:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000225c:	4795                	li	a5,5
    8000225e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a48080e7          	jalr	-1464(ra) # 80000cac <release>
  sched();
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	cfc080e7          	jalr	-772(ra) # 80001f68 <sched>
  panic("zombie exit");
    80002274:	00006517          	auipc	a0,0x6
    80002278:	ffc50513          	addi	a0,a0,-4 # 80008270 <digits+0x230>
    8000227c:	ffffe097          	auipc	ra,0xffffe
    80002280:	2c4080e7          	jalr	708(ra) # 80000540 <panic>

0000000080002284 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002284:	7179                	addi	sp,sp,-48
    80002286:	f406                	sd	ra,40(sp)
    80002288:	f022                	sd	s0,32(sp)
    8000228a:	ec26                	sd	s1,24(sp)
    8000228c:	e84a                	sd	s2,16(sp)
    8000228e:	e44e                	sd	s3,8(sp)
    80002290:	1800                	addi	s0,sp,48
    80002292:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002294:	0000f497          	auipc	s1,0xf
    80002298:	d6c48493          	addi	s1,s1,-660 # 80011000 <proc>
    8000229c:	00015997          	auipc	s3,0x15
    800022a0:	96498993          	addi	s3,s3,-1692 # 80016c00 <tickslock>
    acquire(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	952080e7          	jalr	-1710(ra) # 80000bf8 <acquire>
    if(p->pid == pid){
    800022ae:	589c                	lw	a5,48(s1)
    800022b0:	01278d63          	beq	a5,s2,800022ca <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	9f6080e7          	jalr	-1546(ra) # 80000cac <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022be:	17048493          	addi	s1,s1,368
    800022c2:	ff3491e3          	bne	s1,s3,800022a4 <kill+0x20>
  }
  return -1;
    800022c6:	557d                	li	a0,-1
    800022c8:	a829                	j	800022e2 <kill+0x5e>
      p->killed = 1;
    800022ca:	4785                	li	a5,1
    800022cc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022ce:	4c98                	lw	a4,24(s1)
    800022d0:	4789                	li	a5,2
    800022d2:	00f70f63          	beq	a4,a5,800022f0 <kill+0x6c>
      release(&p->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	9d4080e7          	jalr	-1580(ra) # 80000cac <release>
      return 0;
    800022e0:	4501                	li	a0,0
}
    800022e2:	70a2                	ld	ra,40(sp)
    800022e4:	7402                	ld	s0,32(sp)
    800022e6:	64e2                	ld	s1,24(sp)
    800022e8:	6942                	ld	s2,16(sp)
    800022ea:	69a2                	ld	s3,8(sp)
    800022ec:	6145                	addi	sp,sp,48
    800022ee:	8082                	ret
        p->state = RUNNABLE;
    800022f0:	478d                	li	a5,3
    800022f2:	cc9c                	sw	a5,24(s1)
    800022f4:	b7cd                	j	800022d6 <kill+0x52>

00000000800022f6 <setkilled>:

void
setkilled(struct proc *p)
{
    800022f6:	1101                	addi	sp,sp,-32
    800022f8:	ec06                	sd	ra,24(sp)
    800022fa:	e822                	sd	s0,16(sp)
    800022fc:	e426                	sd	s1,8(sp)
    800022fe:	1000                	addi	s0,sp,32
    80002300:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	8f6080e7          	jalr	-1802(ra) # 80000bf8 <acquire>
  p->killed = 1;
    8000230a:	4785                	li	a5,1
    8000230c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000230e:	8526                	mv	a0,s1
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	99c080e7          	jalr	-1636(ra) # 80000cac <release>
}
    80002318:	60e2                	ld	ra,24(sp)
    8000231a:	6442                	ld	s0,16(sp)
    8000231c:	64a2                	ld	s1,8(sp)
    8000231e:	6105                	addi	sp,sp,32
    80002320:	8082                	ret

0000000080002322 <killed>:

int
killed(struct proc *p)
{
    80002322:	1101                	addi	sp,sp,-32
    80002324:	ec06                	sd	ra,24(sp)
    80002326:	e822                	sd	s0,16(sp)
    80002328:	e426                	sd	s1,8(sp)
    8000232a:	e04a                	sd	s2,0(sp)
    8000232c:	1000                	addi	s0,sp,32
    8000232e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8c8080e7          	jalr	-1848(ra) # 80000bf8 <acquire>
  k = p->killed;
    80002338:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	96e080e7          	jalr	-1682(ra) # 80000cac <release>
  return k;
}
    80002346:	854a                	mv	a0,s2
    80002348:	60e2                	ld	ra,24(sp)
    8000234a:	6442                	ld	s0,16(sp)
    8000234c:	64a2                	ld	s1,8(sp)
    8000234e:	6902                	ld	s2,0(sp)
    80002350:	6105                	addi	sp,sp,32
    80002352:	8082                	ret

0000000080002354 <wait>:
{
    80002354:	715d                	addi	sp,sp,-80
    80002356:	e486                	sd	ra,72(sp)
    80002358:	e0a2                	sd	s0,64(sp)
    8000235a:	fc26                	sd	s1,56(sp)
    8000235c:	f84a                	sd	s2,48(sp)
    8000235e:	f44e                	sd	s3,40(sp)
    80002360:	f052                	sd	s4,32(sp)
    80002362:	ec56                	sd	s5,24(sp)
    80002364:	e85a                	sd	s6,16(sp)
    80002366:	e45e                	sd	s7,8(sp)
    80002368:	e062                	sd	s8,0(sp)
    8000236a:	0880                	addi	s0,sp,80
    8000236c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	660080e7          	jalr	1632(ra) # 800019ce <myproc>
    80002376:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002378:	0000f517          	auipc	a0,0xf
    8000237c:	87050513          	addi	a0,a0,-1936 # 80010be8 <wait_lock>
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	878080e7          	jalr	-1928(ra) # 80000bf8 <acquire>
    havekids = 0;
    80002388:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000238a:	4a15                	li	s4,5
        havekids = 1;
    8000238c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000238e:	00015997          	auipc	s3,0x15
    80002392:	87298993          	addi	s3,s3,-1934 # 80016c00 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002396:	0000fc17          	auipc	s8,0xf
    8000239a:	852c0c13          	addi	s8,s8,-1966 # 80010be8 <wait_lock>
    havekids = 0;
    8000239e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023a0:	0000f497          	auipc	s1,0xf
    800023a4:	c6048493          	addi	s1,s1,-928 # 80011000 <proc>
    800023a8:	a0bd                	j	80002416 <wait+0xc2>
          pid = pp->pid;
    800023aa:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023ae:	000b0e63          	beqz	s6,800023ca <wait+0x76>
    800023b2:	4691                	li	a3,4
    800023b4:	02c48613          	addi	a2,s1,44
    800023b8:	85da                	mv	a1,s6
    800023ba:	05093503          	ld	a0,80(s2)
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	2d0080e7          	jalr	720(ra) # 8000168e <copyout>
    800023c6:	02054563          	bltz	a0,800023f0 <wait+0x9c>
          freeproc(pp);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	7b4080e7          	jalr	1972(ra) # 80001b80 <freeproc>
          release(&pp->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8d6080e7          	jalr	-1834(ra) # 80000cac <release>
          release(&wait_lock);
    800023de:	0000f517          	auipc	a0,0xf
    800023e2:	80a50513          	addi	a0,a0,-2038 # 80010be8 <wait_lock>
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8c6080e7          	jalr	-1850(ra) # 80000cac <release>
          return pid;
    800023ee:	a0b5                	j	8000245a <wait+0x106>
            release(&pp->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8ba080e7          	jalr	-1862(ra) # 80000cac <release>
            release(&wait_lock);
    800023fa:	0000e517          	auipc	a0,0xe
    800023fe:	7ee50513          	addi	a0,a0,2030 # 80010be8 <wait_lock>
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	8aa080e7          	jalr	-1878(ra) # 80000cac <release>
            return -1;
    8000240a:	59fd                	li	s3,-1
    8000240c:	a0b9                	j	8000245a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	17048493          	addi	s1,s1,368
    80002412:	03348463          	beq	s1,s3,8000243a <wait+0xe6>
      if(pp->parent == p){
    80002416:	7c9c                	ld	a5,56(s1)
    80002418:	ff279be3          	bne	a5,s2,8000240e <wait+0xba>
        acquire(&pp->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	7da080e7          	jalr	2010(ra) # 80000bf8 <acquire>
        if(pp->state == ZOMBIE){
    80002426:	4c9c                	lw	a5,24(s1)
    80002428:	f94781e3          	beq	a5,s4,800023aa <wait+0x56>
        release(&pp->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	87e080e7          	jalr	-1922(ra) # 80000cac <release>
        havekids = 1;
    80002436:	8756                	mv	a4,s5
    80002438:	bfd9                	j	8000240e <wait+0xba>
    if(!havekids || killed(p)){
    8000243a:	c719                	beqz	a4,80002448 <wait+0xf4>
    8000243c:	854a                	mv	a0,s2
    8000243e:	00000097          	auipc	ra,0x0
    80002442:	ee4080e7          	jalr	-284(ra) # 80002322 <killed>
    80002446:	c51d                	beqz	a0,80002474 <wait+0x120>
      release(&wait_lock);
    80002448:	0000e517          	auipc	a0,0xe
    8000244c:	7a050513          	addi	a0,a0,1952 # 80010be8 <wait_lock>
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	85c080e7          	jalr	-1956(ra) # 80000cac <release>
      return -1;
    80002458:	59fd                	li	s3,-1
}
    8000245a:	854e                	mv	a0,s3
    8000245c:	60a6                	ld	ra,72(sp)
    8000245e:	6406                	ld	s0,64(sp)
    80002460:	74e2                	ld	s1,56(sp)
    80002462:	7942                	ld	s2,48(sp)
    80002464:	79a2                	ld	s3,40(sp)
    80002466:	7a02                	ld	s4,32(sp)
    80002468:	6ae2                	ld	s5,24(sp)
    8000246a:	6b42                	ld	s6,16(sp)
    8000246c:	6ba2                	ld	s7,8(sp)
    8000246e:	6c02                	ld	s8,0(sp)
    80002470:	6161                	addi	sp,sp,80
    80002472:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002474:	85e2                	mv	a1,s8
    80002476:	854a                	mv	a0,s2
    80002478:	00000097          	auipc	ra,0x0
    8000247c:	c02080e7          	jalr	-1022(ra) # 8000207a <sleep>
    havekids = 0;
    80002480:	bf39                	j	8000239e <wait+0x4a>

0000000080002482 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002482:	7179                	addi	sp,sp,-48
    80002484:	f406                	sd	ra,40(sp)
    80002486:	f022                	sd	s0,32(sp)
    80002488:	ec26                	sd	s1,24(sp)
    8000248a:	e84a                	sd	s2,16(sp)
    8000248c:	e44e                	sd	s3,8(sp)
    8000248e:	e052                	sd	s4,0(sp)
    80002490:	1800                	addi	s0,sp,48
    80002492:	84aa                	mv	s1,a0
    80002494:	892e                	mv	s2,a1
    80002496:	89b2                	mv	s3,a2
    80002498:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	534080e7          	jalr	1332(ra) # 800019ce <myproc>
  if(user_dst){
    800024a2:	c08d                	beqz	s1,800024c4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024a4:	86d2                	mv	a3,s4
    800024a6:	864e                	mv	a2,s3
    800024a8:	85ca                	mv	a1,s2
    800024aa:	6928                	ld	a0,80(a0)
    800024ac:	fffff097          	auipc	ra,0xfffff
    800024b0:	1e2080e7          	jalr	482(ra) # 8000168e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024b4:	70a2                	ld	ra,40(sp)
    800024b6:	7402                	ld	s0,32(sp)
    800024b8:	64e2                	ld	s1,24(sp)
    800024ba:	6942                	ld	s2,16(sp)
    800024bc:	69a2                	ld	s3,8(sp)
    800024be:	6a02                	ld	s4,0(sp)
    800024c0:	6145                	addi	sp,sp,48
    800024c2:	8082                	ret
    memmove((char *)dst, src, len);
    800024c4:	000a061b          	sext.w	a2,s4
    800024c8:	85ce                	mv	a1,s3
    800024ca:	854a                	mv	a0,s2
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	884080e7          	jalr	-1916(ra) # 80000d50 <memmove>
    return 0;
    800024d4:	8526                	mv	a0,s1
    800024d6:	bff9                	j	800024b4 <either_copyout+0x32>

00000000800024d8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d8:	7179                	addi	sp,sp,-48
    800024da:	f406                	sd	ra,40(sp)
    800024dc:	f022                	sd	s0,32(sp)
    800024de:	ec26                	sd	s1,24(sp)
    800024e0:	e84a                	sd	s2,16(sp)
    800024e2:	e44e                	sd	s3,8(sp)
    800024e4:	e052                	sd	s4,0(sp)
    800024e6:	1800                	addi	s0,sp,48
    800024e8:	892a                	mv	s2,a0
    800024ea:	84ae                	mv	s1,a1
    800024ec:	89b2                	mv	s3,a2
    800024ee:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	4de080e7          	jalr	1246(ra) # 800019ce <myproc>
  if(user_src){
    800024f8:	c08d                	beqz	s1,8000251a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024fa:	86d2                	mv	a3,s4
    800024fc:	864e                	mv	a2,s3
    800024fe:	85ca                	mv	a1,s2
    80002500:	6928                	ld	a0,80(a0)
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	218080e7          	jalr	536(ra) # 8000171a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000250a:	70a2                	ld	ra,40(sp)
    8000250c:	7402                	ld	s0,32(sp)
    8000250e:	64e2                	ld	s1,24(sp)
    80002510:	6942                	ld	s2,16(sp)
    80002512:	69a2                	ld	s3,8(sp)
    80002514:	6a02                	ld	s4,0(sp)
    80002516:	6145                	addi	sp,sp,48
    80002518:	8082                	ret
    memmove(dst, (char*)src, len);
    8000251a:	000a061b          	sext.w	a2,s4
    8000251e:	85ce                	mv	a1,s3
    80002520:	854a                	mv	a0,s2
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	82e080e7          	jalr	-2002(ra) # 80000d50 <memmove>
    return 0;
    8000252a:	8526                	mv	a0,s1
    8000252c:	bff9                	j	8000250a <either_copyin+0x32>

000000008000252e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000252e:	715d                	addi	sp,sp,-80
    80002530:	e486                	sd	ra,72(sp)
    80002532:	e0a2                	sd	s0,64(sp)
    80002534:	fc26                	sd	s1,56(sp)
    80002536:	f84a                	sd	s2,48(sp)
    80002538:	f44e                	sd	s3,40(sp)
    8000253a:	f052                	sd	s4,32(sp)
    8000253c:	ec56                	sd	s5,24(sp)
    8000253e:	e85a                	sd	s6,16(sp)
    80002540:	e45e                	sd	s7,8(sp)
    80002542:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002544:	00006517          	auipc	a0,0x6
    80002548:	b8450513          	addi	a0,a0,-1148 # 800080c8 <digits+0x88>
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	03e080e7          	jalr	62(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002554:	0000f497          	auipc	s1,0xf
    80002558:	c0448493          	addi	s1,s1,-1020 # 80011158 <proc+0x158>
    8000255c:	00014917          	auipc	s2,0x14
    80002560:	7fc90913          	addi	s2,s2,2044 # 80016d58 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002564:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002566:	00006997          	auipc	s3,0x6
    8000256a:	d1a98993          	addi	s3,s3,-742 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000256e:	00006a97          	auipc	s5,0x6
    80002572:	d1aa8a93          	addi	s5,s5,-742 # 80008288 <digits+0x248>
    printf("\n");
    80002576:	00006a17          	auipc	s4,0x6
    8000257a:	b52a0a13          	addi	s4,s4,-1198 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257e:	00006b97          	auipc	s7,0x6
    80002582:	db2b8b93          	addi	s7,s7,-590 # 80008330 <states.0>
    80002586:	a00d                	j	800025a8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002588:	ed86a583          	lw	a1,-296(a3)
    8000258c:	8556                	mv	a0,s5
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	ffc080e7          	jalr	-4(ra) # 8000058a <printf>
    printf("\n");
    80002596:	8552                	mv	a0,s4
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	ff2080e7          	jalr	-14(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a0:	17048493          	addi	s1,s1,368
    800025a4:	03248263          	beq	s1,s2,800025c8 <procdump+0x9a>
    if(p->state == UNUSED)
    800025a8:	86a6                	mv	a3,s1
    800025aa:	ec04a783          	lw	a5,-320(s1)
    800025ae:	dbed                	beqz	a5,800025a0 <procdump+0x72>
      state = "???";
    800025b0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b2:	fcfb6be3          	bltu	s6,a5,80002588 <procdump+0x5a>
    800025b6:	02079713          	slli	a4,a5,0x20
    800025ba:	01d75793          	srli	a5,a4,0x1d
    800025be:	97de                	add	a5,a5,s7
    800025c0:	6390                	ld	a2,0(a5)
    800025c2:	f279                	bnez	a2,80002588 <procdump+0x5a>
      state = "???";
    800025c4:	864e                	mv	a2,s3
    800025c6:	b7c9                	j	80002588 <procdump+0x5a>
  }
}
    800025c8:	60a6                	ld	ra,72(sp)
    800025ca:	6406                	ld	s0,64(sp)
    800025cc:	74e2                	ld	s1,56(sp)
    800025ce:	7942                	ld	s2,48(sp)
    800025d0:	79a2                	ld	s3,40(sp)
    800025d2:	7a02                	ld	s4,32(sp)
    800025d4:	6ae2                	ld	s5,24(sp)
    800025d6:	6b42                	ld	s6,16(sp)
    800025d8:	6ba2                	ld	s7,8(sp)
    800025da:	6161                	addi	sp,sp,80
    800025dc:	8082                	ret

00000000800025de <total_active_processes>:

// The total_active_process is defined here 
int
total_active_processes(void) {
    800025de:	1141                	addi	sp,sp,-16
    800025e0:	e422                	sd	s0,8(sp)
    800025e2:	0800                	addi	s0,sp,16
    struct proc *process;
    int active_process_count = 0;
    int i;

    for (i = 0; i < NPROC; i++) {
    800025e4:	0000f797          	auipc	a5,0xf
    800025e8:	a3478793          	addi	a5,a5,-1484 # 80011018 <proc+0x18>
    800025ec:	00014617          	auipc	a2,0x14
    800025f0:	62c60613          	addi	a2,a2,1580 # 80016c18 <bcache>
    int active_process_count = 0;
    800025f4:	4501                	li	a0,0
        process = &proc[i];

        if (process->state >= 0 && process->state != UNUSED && process->state != USED) {
    800025f6:	4685                	li	a3,1
    800025f8:	a031                	j	80002604 <total_active_processes+0x26>
            active_process_count++;
    800025fa:	2505                	addiw	a0,a0,1
    for (i = 0; i < NPROC; i++) {
    800025fc:	17078793          	addi	a5,a5,368
    80002600:	00c78663          	beq	a5,a2,8000260c <total_active_processes+0x2e>
        if (process->state >= 0 && process->state != UNUSED && process->state != USED) {
    80002604:	4398                	lw	a4,0(a5)
    80002606:	fee6eae3          	bltu	a3,a4,800025fa <total_active_processes+0x1c>
    8000260a:	bfcd                	j	800025fc <total_active_processes+0x1e>
        }
    }

    return active_process_count;
}
    8000260c:	6422                	ld	s0,8(sp)
    8000260e:	0141                	addi	sp,sp,16
    80002610:	8082                	ret

0000000080002612 <print_sysinfo>:
//param = 2 outputs total number of free pages
//else outputs -1.
int print_sysinfo(int n) {
    int result;

    switch (n) {
    80002612:	4705                	li	a4,1
    80002614:	02e50563          	beq	a0,a4,8000263e <print_sysinfo+0x2c>
int print_sysinfo(int n) {
    80002618:	1141                	addi	sp,sp,-16
    8000261a:	e406                	sd	ra,8(sp)
    8000261c:	e022                	sd	s0,0(sp)
    8000261e:	0800                	addi	s0,sp,16
    80002620:	87aa                	mv	a5,a0
    switch (n) {
    80002622:	4709                	li	a4,2
    80002624:	02e50363          	beq	a0,a4,8000264a <print_sysinfo+0x38>
    80002628:	557d                	li	a0,-1
    8000262a:	c789                	beqz	a5,80002634 <print_sysinfo+0x22>
            result = -1;
            break;
    }

    return result;
}
    8000262c:	60a2                	ld	ra,8(sp)
    8000262e:	6402                	ld	s0,0(sp)
    80002630:	0141                	addi	sp,sp,16
    80002632:	8082                	ret
            result = total_active_processes();
    80002634:	00000097          	auipc	ra,0x0
    80002638:	faa080e7          	jalr	-86(ra) # 800025de <total_active_processes>
            break;
    8000263c:	bfc5                	j	8000262c <print_sysinfo+0x1a>
            result = syscallcount - 1;
    8000263e:	00006517          	auipc	a0,0x6
    80002642:	32652503          	lw	a0,806(a0) # 80008964 <syscallcount>
    80002646:	357d                	addiw	a0,a0,-1
}
    80002648:	8082                	ret
            result = free_memory_pages();
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	4fc080e7          	jalr	1276(ra) # 80000b46 <free_memory_pages>
            break;
    80002652:	bfe9                	j	8000262c <print_sysinfo+0x1a>

0000000080002654 <procinfo>:

// Implementation of procinfo function
int
procinfo(struct pinfo* info) {
    80002654:	7179                	addi	sp,sp,-48
    80002656:	f406                	sd	ra,40(sp)
    80002658:	f022                	sd	s0,32(sp)
    8000265a:	ec26                	sd	s1,24(sp)
    8000265c:	e84a                	sd	s2,16(sp)
    8000265e:	1800                	addi	s0,sp,48
    80002660:	892a                	mv	s2,a0
 	struct proc* p = myproc();
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	36c080e7          	jalr	876(ra) # 800019ce <myproc>
    8000266a:	84aa                	mv	s1,a0
  	// Get PID of parent
 	int temp_ppid = p->parent->pid;
    8000266c:	7d1c                	ld	a5,56(a0)
    8000266e:	5b9c                	lw	a5,48(a5)
    80002670:	fcf42e23          	sw	a5,-36(s0)
	// Get number of total system call invoked by the process
	int temp_syscall_count = p->sys_call_count - 1;
    80002674:	16853783          	ld	a5,360(a0)
    80002678:	37fd                	addiw	a5,a5,-1
    8000267a:	fcf42c23          	sw	a5,-40(s0)
	// Get the total page usage by the process
	int temp_page_usage = (PGROUNDUP(p->sz)/PGSIZE);
    8000267e:	653c                	ld	a5,72(a0)
    80002680:	6705                	lui	a4,0x1
    80002682:	177d                	addi	a4,a4,-1 # fff <_entry-0x7ffff001>
    80002684:	97ba                	add	a5,a5,a4
    80002686:	83b1                	srli	a5,a5,0xc
    80002688:	fcf42a23          	sw	a5,-44(s0)

	//Trying to write the parent processid, if fails the function returns -1
	if (copyout(p->pagetable, (uint64)&info->ppid, (char *)&temp_ppid, sizeof(int)) < 0) {
    8000268c:	4691                	li	a3,4
    8000268e:	fdc40613          	addi	a2,s0,-36
    80002692:	85ca                	mv	a1,s2
    80002694:	6928                	ld	a0,80(a0)
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	ff8080e7          	jalr	-8(ra) # 8000168e <copyout>
    8000269e:	04054663          	bltz	a0,800026ea <procinfo+0x96>
		printf("Not able to write parent id\n");
		return -1;
  	}
	//Trying to write the system call count, if fails the function returns -1
	if (copyout(p->pagetable, (uint64)&info->syscall_count, (char *)&temp_syscall_count, sizeof(int)) < 0) {
    800026a2:	4691                	li	a3,4
    800026a4:	fd840613          	addi	a2,s0,-40
    800026a8:	00490593          	addi	a1,s2,4
    800026ac:	68a8                	ld	a0,80(s1)
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	fe0080e7          	jalr	-32(ra) # 8000168e <copyout>
    800026b6:	04054463          	bltz	a0,800026fe <procinfo+0xaa>
   		printf("Not able to write system call count\n");
		return -1;
  	}
	// Trying to write the page usage count , if fails the function returns -1
 	if( copyout(myproc()->pagetable, (uint64) &info->page_usage, (char*)&temp_page_usage, sizeof(int)) < 0){
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	314080e7          	jalr	788(ra) # 800019ce <myproc>
    800026c2:	4691                	li	a3,4
    800026c4:	fd440613          	addi	a2,s0,-44
    800026c8:	00890593          	addi	a1,s2,8
    800026cc:	6928                	ld	a0,80(a0)
    800026ce:	fffff097          	auipc	ra,0xfffff
    800026d2:	fc0080e7          	jalr	-64(ra) # 8000168e <copyout>
    800026d6:	87aa                	mv	a5,a0
 		printf("Not able to write page usage\n");
		return -1;
  }
	return 0;
    800026d8:	4501                	li	a0,0
 	if( copyout(myproc()->pagetable, (uint64) &info->page_usage, (char*)&temp_page_usage, sizeof(int)) < 0){
    800026da:	0207cc63          	bltz	a5,80002712 <procinfo+0xbe>
 }
    800026de:	70a2                	ld	ra,40(sp)
    800026e0:	7402                	ld	s0,32(sp)
    800026e2:	64e2                	ld	s1,24(sp)
    800026e4:	6942                	ld	s2,16(sp)
    800026e6:	6145                	addi	sp,sp,48
    800026e8:	8082                	ret
		printf("Not able to write parent id\n");
    800026ea:	00006517          	auipc	a0,0x6
    800026ee:	bae50513          	addi	a0,a0,-1106 # 80008298 <digits+0x258>
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	e98080e7          	jalr	-360(ra) # 8000058a <printf>
		return -1;
    800026fa:	557d                	li	a0,-1
    800026fc:	b7cd                	j	800026de <procinfo+0x8a>
   		printf("Not able to write system call count\n");
    800026fe:	00006517          	auipc	a0,0x6
    80002702:	bba50513          	addi	a0,a0,-1094 # 800082b8 <digits+0x278>
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	e84080e7          	jalr	-380(ra) # 8000058a <printf>
		return -1;
    8000270e:	557d                	li	a0,-1
    80002710:	b7f9                	j	800026de <procinfo+0x8a>
 		printf("Not able to write page usage\n");
    80002712:	00006517          	auipc	a0,0x6
    80002716:	bce50513          	addi	a0,a0,-1074 # 800082e0 <digits+0x2a0>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	e70080e7          	jalr	-400(ra) # 8000058a <printf>
		return -1;
    80002722:	557d                	li	a0,-1
    80002724:	bf6d                	j	800026de <procinfo+0x8a>

0000000080002726 <swtch>:
    80002726:	00153023          	sd	ra,0(a0)
    8000272a:	00253423          	sd	sp,8(a0)
    8000272e:	e900                	sd	s0,16(a0)
    80002730:	ed04                	sd	s1,24(a0)
    80002732:	03253023          	sd	s2,32(a0)
    80002736:	03353423          	sd	s3,40(a0)
    8000273a:	03453823          	sd	s4,48(a0)
    8000273e:	03553c23          	sd	s5,56(a0)
    80002742:	05653023          	sd	s6,64(a0)
    80002746:	05753423          	sd	s7,72(a0)
    8000274a:	05853823          	sd	s8,80(a0)
    8000274e:	05953c23          	sd	s9,88(a0)
    80002752:	07a53023          	sd	s10,96(a0)
    80002756:	07b53423          	sd	s11,104(a0)
    8000275a:	0005b083          	ld	ra,0(a1)
    8000275e:	0085b103          	ld	sp,8(a1)
    80002762:	6980                	ld	s0,16(a1)
    80002764:	6d84                	ld	s1,24(a1)
    80002766:	0205b903          	ld	s2,32(a1)
    8000276a:	0285b983          	ld	s3,40(a1)
    8000276e:	0305ba03          	ld	s4,48(a1)
    80002772:	0385ba83          	ld	s5,56(a1)
    80002776:	0405bb03          	ld	s6,64(a1)
    8000277a:	0485bb83          	ld	s7,72(a1)
    8000277e:	0505bc03          	ld	s8,80(a1)
    80002782:	0585bc83          	ld	s9,88(a1)
    80002786:	0605bd03          	ld	s10,96(a1)
    8000278a:	0685bd83          	ld	s11,104(a1)
    8000278e:	8082                	ret

0000000080002790 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002790:	1141                	addi	sp,sp,-16
    80002792:	e406                	sd	ra,8(sp)
    80002794:	e022                	sd	s0,0(sp)
    80002796:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002798:	00006597          	auipc	a1,0x6
    8000279c:	bc858593          	addi	a1,a1,-1080 # 80008360 <states.0+0x30>
    800027a0:	00014517          	auipc	a0,0x14
    800027a4:	46050513          	addi	a0,a0,1120 # 80016c00 <tickslock>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	3c0080e7          	jalr	960(ra) # 80000b68 <initlock>
}
    800027b0:	60a2                	ld	ra,8(sp)
    800027b2:	6402                	ld	s0,0(sp)
    800027b4:	0141                	addi	sp,sp,16
    800027b6:	8082                	ret

00000000800027b8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027b8:	1141                	addi	sp,sp,-16
    800027ba:	e422                	sd	s0,8(sp)
    800027bc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027be:	00003797          	auipc	a5,0x3
    800027c2:	54278793          	addi	a5,a5,1346 # 80005d00 <kernelvec>
    800027c6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027ca:	6422                	ld	s0,8(sp)
    800027cc:	0141                	addi	sp,sp,16
    800027ce:	8082                	ret

00000000800027d0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027d0:	1141                	addi	sp,sp,-16
    800027d2:	e406                	sd	ra,8(sp)
    800027d4:	e022                	sd	s0,0(sp)
    800027d6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027d8:	fffff097          	auipc	ra,0xfffff
    800027dc:	1f6080e7          	jalr	502(ra) # 800019ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027e6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027ea:	00005697          	auipc	a3,0x5
    800027ee:	81668693          	addi	a3,a3,-2026 # 80007000 <_trampoline>
    800027f2:	00005717          	auipc	a4,0x5
    800027f6:	80e70713          	addi	a4,a4,-2034 # 80007000 <_trampoline>
    800027fa:	8f15                	sub	a4,a4,a3
    800027fc:	040007b7          	lui	a5,0x4000
    80002800:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002802:	07b2                	slli	a5,a5,0xc
    80002804:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002806:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000280a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000280c:	18002673          	csrr	a2,satp
    80002810:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002812:	6d30                	ld	a2,88(a0)
    80002814:	6138                	ld	a4,64(a0)
    80002816:	6585                	lui	a1,0x1
    80002818:	972e                	add	a4,a4,a1
    8000281a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000281c:	6d38                	ld	a4,88(a0)
    8000281e:	00000617          	auipc	a2,0x0
    80002822:	13060613          	addi	a2,a2,304 # 8000294e <usertrap>
    80002826:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002828:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000282a:	8612                	mv	a2,tp
    8000282c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000282e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002832:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002836:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000283a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000283e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002840:	6f18                	ld	a4,24(a4)
    80002842:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002846:	6928                	ld	a0,80(a0)
    80002848:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000284a:	00005717          	auipc	a4,0x5
    8000284e:	85270713          	addi	a4,a4,-1966 # 8000709c <userret>
    80002852:	8f15                	sub	a4,a4,a3
    80002854:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002856:	577d                	li	a4,-1
    80002858:	177e                	slli	a4,a4,0x3f
    8000285a:	8d59                	or	a0,a0,a4
    8000285c:	9782                	jalr	a5
}
    8000285e:	60a2                	ld	ra,8(sp)
    80002860:	6402                	ld	s0,0(sp)
    80002862:	0141                	addi	sp,sp,16
    80002864:	8082                	ret

0000000080002866 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002866:	1101                	addi	sp,sp,-32
    80002868:	ec06                	sd	ra,24(sp)
    8000286a:	e822                	sd	s0,16(sp)
    8000286c:	e426                	sd	s1,8(sp)
    8000286e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002870:	00014497          	auipc	s1,0x14
    80002874:	39048493          	addi	s1,s1,912 # 80016c00 <tickslock>
    80002878:	8526                	mv	a0,s1
    8000287a:	ffffe097          	auipc	ra,0xffffe
    8000287e:	37e080e7          	jalr	894(ra) # 80000bf8 <acquire>
  ticks++;
    80002882:	00006517          	auipc	a0,0x6
    80002886:	0de50513          	addi	a0,a0,222 # 80008960 <ticks>
    8000288a:	411c                	lw	a5,0(a0)
    8000288c:	2785                	addiw	a5,a5,1
    8000288e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002890:	00000097          	auipc	ra,0x0
    80002894:	84e080e7          	jalr	-1970(ra) # 800020de <wakeup>
  release(&tickslock);
    80002898:	8526                	mv	a0,s1
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	412080e7          	jalr	1042(ra) # 80000cac <release>
}
    800028a2:	60e2                	ld	ra,24(sp)
    800028a4:	6442                	ld	s0,16(sp)
    800028a6:	64a2                	ld	s1,8(sp)
    800028a8:	6105                	addi	sp,sp,32
    800028aa:	8082                	ret

00000000800028ac <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028ac:	1101                	addi	sp,sp,-32
    800028ae:	ec06                	sd	ra,24(sp)
    800028b0:	e822                	sd	s0,16(sp)
    800028b2:	e426                	sd	s1,8(sp)
    800028b4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028ba:	00074d63          	bltz	a4,800028d4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028be:	57fd                	li	a5,-1
    800028c0:	17fe                	slli	a5,a5,0x3f
    800028c2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028c4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028c6:	06f70363          	beq	a4,a5,8000292c <devintr+0x80>
  }
}
    800028ca:	60e2                	ld	ra,24(sp)
    800028cc:	6442                	ld	s0,16(sp)
    800028ce:	64a2                	ld	s1,8(sp)
    800028d0:	6105                	addi	sp,sp,32
    800028d2:	8082                	ret
     (scause & 0xff) == 9){
    800028d4:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800028d8:	46a5                	li	a3,9
    800028da:	fed792e3          	bne	a5,a3,800028be <devintr+0x12>
    int irq = plic_claim();
    800028de:	00003097          	auipc	ra,0x3
    800028e2:	52a080e7          	jalr	1322(ra) # 80005e08 <plic_claim>
    800028e6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028e8:	47a9                	li	a5,10
    800028ea:	02f50763          	beq	a0,a5,80002918 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028ee:	4785                	li	a5,1
    800028f0:	02f50963          	beq	a0,a5,80002922 <devintr+0x76>
    return 1;
    800028f4:	4505                	li	a0,1
    } else if(irq){
    800028f6:	d8f1                	beqz	s1,800028ca <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028f8:	85a6                	mv	a1,s1
    800028fa:	00006517          	auipc	a0,0x6
    800028fe:	a6e50513          	addi	a0,a0,-1426 # 80008368 <states.0+0x38>
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	c88080e7          	jalr	-888(ra) # 8000058a <printf>
      plic_complete(irq);
    8000290a:	8526                	mv	a0,s1
    8000290c:	00003097          	auipc	ra,0x3
    80002910:	520080e7          	jalr	1312(ra) # 80005e2c <plic_complete>
    return 1;
    80002914:	4505                	li	a0,1
    80002916:	bf55                	j	800028ca <devintr+0x1e>
      uartintr();
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	080080e7          	jalr	128(ra) # 80000998 <uartintr>
    80002920:	b7ed                	j	8000290a <devintr+0x5e>
      virtio_disk_intr();
    80002922:	00004097          	auipc	ra,0x4
    80002926:	9d2080e7          	jalr	-1582(ra) # 800062f4 <virtio_disk_intr>
    8000292a:	b7c5                	j	8000290a <devintr+0x5e>
    if(cpuid() == 0){
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	076080e7          	jalr	118(ra) # 800019a2 <cpuid>
    80002934:	c901                	beqz	a0,80002944 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002936:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000293a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000293c:	14479073          	csrw	sip,a5
    return 2;
    80002940:	4509                	li	a0,2
    80002942:	b761                	j	800028ca <devintr+0x1e>
      clockintr();
    80002944:	00000097          	auipc	ra,0x0
    80002948:	f22080e7          	jalr	-222(ra) # 80002866 <clockintr>
    8000294c:	b7ed                	j	80002936 <devintr+0x8a>

000000008000294e <usertrap>:
{
    8000294e:	1101                	addi	sp,sp,-32
    80002950:	ec06                	sd	ra,24(sp)
    80002952:	e822                	sd	s0,16(sp)
    80002954:	e426                	sd	s1,8(sp)
    80002956:	e04a                	sd	s2,0(sp)
    80002958:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000295e:	1007f793          	andi	a5,a5,256
    80002962:	e3b1                	bnez	a5,800029a6 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002964:	00003797          	auipc	a5,0x3
    80002968:	39c78793          	addi	a5,a5,924 # 80005d00 <kernelvec>
    8000296c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002970:	fffff097          	auipc	ra,0xfffff
    80002974:	05e080e7          	jalr	94(ra) # 800019ce <myproc>
    80002978:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000297a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297c:	14102773          	csrr	a4,sepc
    80002980:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002982:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002986:	47a1                	li	a5,8
    80002988:	02f70763          	beq	a4,a5,800029b6 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000298c:	00000097          	auipc	ra,0x0
    80002990:	f20080e7          	jalr	-224(ra) # 800028ac <devintr>
    80002994:	892a                	mv	s2,a0
    80002996:	c151                	beqz	a0,80002a1a <usertrap+0xcc>
  if(killed(p))
    80002998:	8526                	mv	a0,s1
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	988080e7          	jalr	-1656(ra) # 80002322 <killed>
    800029a2:	c929                	beqz	a0,800029f4 <usertrap+0xa6>
    800029a4:	a099                	j	800029ea <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800029a6:	00006517          	auipc	a0,0x6
    800029aa:	9e250513          	addi	a0,a0,-1566 # 80008388 <states.0+0x58>
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	b92080e7          	jalr	-1134(ra) # 80000540 <panic>
    if(killed(p))
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	96c080e7          	jalr	-1684(ra) # 80002322 <killed>
    800029be:	e921                	bnez	a0,80002a0e <usertrap+0xc0>
    p->trapframe->epc += 4;
    800029c0:	6cb8                	ld	a4,88(s1)
    800029c2:	6f1c                	ld	a5,24(a4)
    800029c4:	0791                	addi	a5,a5,4
    800029c6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d0:	10079073          	csrw	sstatus,a5
    syscall();
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	2d4080e7          	jalr	724(ra) # 80002ca8 <syscall>
  if(killed(p))
    800029dc:	8526                	mv	a0,s1
    800029de:	00000097          	auipc	ra,0x0
    800029e2:	944080e7          	jalr	-1724(ra) # 80002322 <killed>
    800029e6:	c911                	beqz	a0,800029fa <usertrap+0xac>
    800029e8:	4901                	li	s2,0
    exit(-1);
    800029ea:	557d                	li	a0,-1
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	7c2080e7          	jalr	1986(ra) # 800021ae <exit>
  if(which_dev == 2)
    800029f4:	4789                	li	a5,2
    800029f6:	04f90f63          	beq	s2,a5,80002a54 <usertrap+0x106>
  usertrapret();
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	dd6080e7          	jalr	-554(ra) # 800027d0 <usertrapret>
}
    80002a02:	60e2                	ld	ra,24(sp)
    80002a04:	6442                	ld	s0,16(sp)
    80002a06:	64a2                	ld	s1,8(sp)
    80002a08:	6902                	ld	s2,0(sp)
    80002a0a:	6105                	addi	sp,sp,32
    80002a0c:	8082                	ret
      exit(-1);
    80002a0e:	557d                	li	a0,-1
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	79e080e7          	jalr	1950(ra) # 800021ae <exit>
    80002a18:	b765                	j	800029c0 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a1e:	5890                	lw	a2,48(s1)
    80002a20:	00006517          	auipc	a0,0x6
    80002a24:	98850513          	addi	a0,a0,-1656 # 800083a8 <states.0+0x78>
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	b62080e7          	jalr	-1182(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a30:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a34:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a38:	00006517          	auipc	a0,0x6
    80002a3c:	9a050513          	addi	a0,a0,-1632 # 800083d8 <states.0+0xa8>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b4a080e7          	jalr	-1206(ra) # 8000058a <printf>
    setkilled(p);
    80002a48:	8526                	mv	a0,s1
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	8ac080e7          	jalr	-1876(ra) # 800022f6 <setkilled>
    80002a52:	b769                	j	800029dc <usertrap+0x8e>
    yield();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	5ea080e7          	jalr	1514(ra) # 8000203e <yield>
    80002a5c:	bf79                	j	800029fa <usertrap+0xac>

0000000080002a5e <kerneltrap>:
{
    80002a5e:	7179                	addi	sp,sp,-48
    80002a60:	f406                	sd	ra,40(sp)
    80002a62:	f022                	sd	s0,32(sp)
    80002a64:	ec26                	sd	s1,24(sp)
    80002a66:	e84a                	sd	s2,16(sp)
    80002a68:	e44e                	sd	s3,8(sp)
    80002a6a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a70:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a74:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a78:	1004f793          	andi	a5,s1,256
    80002a7c:	cb85                	beqz	a5,80002aac <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a82:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a84:	ef85                	bnez	a5,80002abc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a86:	00000097          	auipc	ra,0x0
    80002a8a:	e26080e7          	jalr	-474(ra) # 800028ac <devintr>
    80002a8e:	cd1d                	beqz	a0,80002acc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a90:	4789                	li	a5,2
    80002a92:	06f50a63          	beq	a0,a5,80002b06 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a96:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a9a:	10049073          	csrw	sstatus,s1
}
    80002a9e:	70a2                	ld	ra,40(sp)
    80002aa0:	7402                	ld	s0,32(sp)
    80002aa2:	64e2                	ld	s1,24(sp)
    80002aa4:	6942                	ld	s2,16(sp)
    80002aa6:	69a2                	ld	s3,8(sp)
    80002aa8:	6145                	addi	sp,sp,48
    80002aaa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002aac:	00006517          	auipc	a0,0x6
    80002ab0:	94c50513          	addi	a0,a0,-1716 # 800083f8 <states.0+0xc8>
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	a8c080e7          	jalr	-1396(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002abc:	00006517          	auipc	a0,0x6
    80002ac0:	96450513          	addi	a0,a0,-1692 # 80008420 <states.0+0xf0>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	a7c080e7          	jalr	-1412(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002acc:	85ce                	mv	a1,s3
    80002ace:	00006517          	auipc	a0,0x6
    80002ad2:	97250513          	addi	a0,a0,-1678 # 80008440 <states.0+0x110>
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	ab4080e7          	jalr	-1356(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ade:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	96a50513          	addi	a0,a0,-1686 # 80008450 <states.0+0x120>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a9c080e7          	jalr	-1380(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002af6:	00006517          	auipc	a0,0x6
    80002afa:	97250513          	addi	a0,a0,-1678 # 80008468 <states.0+0x138>
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a42080e7          	jalr	-1470(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	ec8080e7          	jalr	-312(ra) # 800019ce <myproc>
    80002b0e:	d541                	beqz	a0,80002a96 <kerneltrap+0x38>
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	ebe080e7          	jalr	-322(ra) # 800019ce <myproc>
    80002b18:	4d18                	lw	a4,24(a0)
    80002b1a:	4791                	li	a5,4
    80002b1c:	f6f71de3          	bne	a4,a5,80002a96 <kerneltrap+0x38>
    yield();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	51e080e7          	jalr	1310(ra) # 8000203e <yield>
    80002b28:	b7bd                	j	80002a96 <kerneltrap+0x38>

0000000080002b2a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b2a:	1101                	addi	sp,sp,-32
    80002b2c:	ec06                	sd	ra,24(sp)
    80002b2e:	e822                	sd	s0,16(sp)
    80002b30:	e426                	sd	s1,8(sp)
    80002b32:	1000                	addi	s0,sp,32
    80002b34:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	e98080e7          	jalr	-360(ra) # 800019ce <myproc>
  switch (n) {
    80002b3e:	4795                	li	a5,5
    80002b40:	0497e163          	bltu	a5,s1,80002b82 <argraw+0x58>
    80002b44:	048a                	slli	s1,s1,0x2
    80002b46:	00006717          	auipc	a4,0x6
    80002b4a:	95a70713          	addi	a4,a4,-1702 # 800084a0 <states.0+0x170>
    80002b4e:	94ba                	add	s1,s1,a4
    80002b50:	409c                	lw	a5,0(s1)
    80002b52:	97ba                	add	a5,a5,a4
    80002b54:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b56:	6d3c                	ld	a5,88(a0)
    80002b58:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	64a2                	ld	s1,8(sp)
    80002b60:	6105                	addi	sp,sp,32
    80002b62:	8082                	ret
    return p->trapframe->a1;
    80002b64:	6d3c                	ld	a5,88(a0)
    80002b66:	7fa8                	ld	a0,120(a5)
    80002b68:	bfcd                	j	80002b5a <argraw+0x30>
    return p->trapframe->a2;
    80002b6a:	6d3c                	ld	a5,88(a0)
    80002b6c:	63c8                	ld	a0,128(a5)
    80002b6e:	b7f5                	j	80002b5a <argraw+0x30>
    return p->trapframe->a3;
    80002b70:	6d3c                	ld	a5,88(a0)
    80002b72:	67c8                	ld	a0,136(a5)
    80002b74:	b7dd                	j	80002b5a <argraw+0x30>
    return p->trapframe->a4;
    80002b76:	6d3c                	ld	a5,88(a0)
    80002b78:	6bc8                	ld	a0,144(a5)
    80002b7a:	b7c5                	j	80002b5a <argraw+0x30>
    return p->trapframe->a5;
    80002b7c:	6d3c                	ld	a5,88(a0)
    80002b7e:	6fc8                	ld	a0,152(a5)
    80002b80:	bfe9                	j	80002b5a <argraw+0x30>
  panic("argraw");
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	8f650513          	addi	a0,a0,-1802 # 80008478 <states.0+0x148>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9b6080e7          	jalr	-1610(ra) # 80000540 <panic>

0000000080002b92 <fetchaddr>:
{
    80002b92:	1101                	addi	sp,sp,-32
    80002b94:	ec06                	sd	ra,24(sp)
    80002b96:	e822                	sd	s0,16(sp)
    80002b98:	e426                	sd	s1,8(sp)
    80002b9a:	e04a                	sd	s2,0(sp)
    80002b9c:	1000                	addi	s0,sp,32
    80002b9e:	84aa                	mv	s1,a0
    80002ba0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	e2c080e7          	jalr	-468(ra) # 800019ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002baa:	653c                	ld	a5,72(a0)
    80002bac:	02f4f863          	bgeu	s1,a5,80002bdc <fetchaddr+0x4a>
    80002bb0:	00848713          	addi	a4,s1,8
    80002bb4:	02e7e663          	bltu	a5,a4,80002be0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bb8:	46a1                	li	a3,8
    80002bba:	8626                	mv	a2,s1
    80002bbc:	85ca                	mv	a1,s2
    80002bbe:	6928                	ld	a0,80(a0)
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	b5a080e7          	jalr	-1190(ra) # 8000171a <copyin>
    80002bc8:	00a03533          	snez	a0,a0
    80002bcc:	40a00533          	neg	a0,a0
}
    80002bd0:	60e2                	ld	ra,24(sp)
    80002bd2:	6442                	ld	s0,16(sp)
    80002bd4:	64a2                	ld	s1,8(sp)
    80002bd6:	6902                	ld	s2,0(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret
    return -1;
    80002bdc:	557d                	li	a0,-1
    80002bde:	bfcd                	j	80002bd0 <fetchaddr+0x3e>
    80002be0:	557d                	li	a0,-1
    80002be2:	b7fd                	j	80002bd0 <fetchaddr+0x3e>

0000000080002be4 <fetchstr>:
{
    80002be4:	7179                	addi	sp,sp,-48
    80002be6:	f406                	sd	ra,40(sp)
    80002be8:	f022                	sd	s0,32(sp)
    80002bea:	ec26                	sd	s1,24(sp)
    80002bec:	e84a                	sd	s2,16(sp)
    80002bee:	e44e                	sd	s3,8(sp)
    80002bf0:	1800                	addi	s0,sp,48
    80002bf2:	892a                	mv	s2,a0
    80002bf4:	84ae                	mv	s1,a1
    80002bf6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bf8:	fffff097          	auipc	ra,0xfffff
    80002bfc:	dd6080e7          	jalr	-554(ra) # 800019ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c00:	86ce                	mv	a3,s3
    80002c02:	864a                	mv	a2,s2
    80002c04:	85a6                	mv	a1,s1
    80002c06:	6928                	ld	a0,80(a0)
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	ba0080e7          	jalr	-1120(ra) # 800017a8 <copyinstr>
    80002c10:	00054e63          	bltz	a0,80002c2c <fetchstr+0x48>
  return strlen(buf);
    80002c14:	8526                	mv	a0,s1
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	25a080e7          	jalr	602(ra) # 80000e70 <strlen>
}
    80002c1e:	70a2                	ld	ra,40(sp)
    80002c20:	7402                	ld	s0,32(sp)
    80002c22:	64e2                	ld	s1,24(sp)
    80002c24:	6942                	ld	s2,16(sp)
    80002c26:	69a2                	ld	s3,8(sp)
    80002c28:	6145                	addi	sp,sp,48
    80002c2a:	8082                	ret
    return -1;
    80002c2c:	557d                	li	a0,-1
    80002c2e:	bfc5                	j	80002c1e <fetchstr+0x3a>

0000000080002c30 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c30:	1101                	addi	sp,sp,-32
    80002c32:	ec06                	sd	ra,24(sp)
    80002c34:	e822                	sd	s0,16(sp)
    80002c36:	e426                	sd	s1,8(sp)
    80002c38:	1000                	addi	s0,sp,32
    80002c3a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	eee080e7          	jalr	-274(ra) # 80002b2a <argraw>
    80002c44:	c088                	sw	a0,0(s1)
}
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	64a2                	ld	s1,8(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret

0000000080002c50 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	e426                	sd	s1,8(sp)
    80002c58:	1000                	addi	s0,sp,32
    80002c5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	ece080e7          	jalr	-306(ra) # 80002b2a <argraw>
    80002c64:	e088                	sd	a0,0(s1)
}
    80002c66:	60e2                	ld	ra,24(sp)
    80002c68:	6442                	ld	s0,16(sp)
    80002c6a:	64a2                	ld	s1,8(sp)
    80002c6c:	6105                	addi	sp,sp,32
    80002c6e:	8082                	ret

0000000080002c70 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c70:	7179                	addi	sp,sp,-48
    80002c72:	f406                	sd	ra,40(sp)
    80002c74:	f022                	sd	s0,32(sp)
    80002c76:	ec26                	sd	s1,24(sp)
    80002c78:	e84a                	sd	s2,16(sp)
    80002c7a:	1800                	addi	s0,sp,48
    80002c7c:	84ae                	mv	s1,a1
    80002c7e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c80:	fd840593          	addi	a1,s0,-40
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	fcc080e7          	jalr	-52(ra) # 80002c50 <argaddr>
  return fetchstr(addr, buf, max);
    80002c8c:	864a                	mv	a2,s2
    80002c8e:	85a6                	mv	a1,s1
    80002c90:	fd843503          	ld	a0,-40(s0)
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	f50080e7          	jalr	-176(ra) # 80002be4 <fetchstr>
}
    80002c9c:	70a2                	ld	ra,40(sp)
    80002c9e:	7402                	ld	s0,32(sp)
    80002ca0:	64e2                	ld	s1,24(sp)
    80002ca2:	6942                	ld	s2,16(sp)
    80002ca4:	6145                	addi	sp,sp,48
    80002ca6:	8082                	ret

0000000080002ca8 <syscall>:
[SYS_sysinfo]   sys_sysinfo, //sysinfo added to the syscall array
[SYS_procinfo]	sys_procinfo, //procinfo added to the syscall array
};

void
syscall(void) {
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	e426                	sd	s1,8(sp)
    80002cb0:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	d1c080e7          	jalr	-740(ra) # 800019ce <myproc>
    80002cba:	84aa                	mv	s1,a0
    p->sys_call_count += 1; // system call count for the process is incremented here
    80002cbc:	16853783          	ld	a5,360(a0)
    80002cc0:	0785                	addi	a5,a5,1
    80002cc2:	16f53423          	sd	a5,360(a0)

    num = p->trapframe->a7;
    80002cc6:	6d3c                	ld	a5,88(a0)
    80002cc8:	77dc                	ld	a5,168(a5)
    80002cca:	0007869b          	sext.w	a3,a5
    syscallcount++; // we increment the system call count everytime syscall function is invoked.
    80002cce:	00006617          	auipc	a2,0x6
    80002cd2:	c9660613          	addi	a2,a2,-874 # 80008964 <syscallcount>
    80002cd6:	4218                	lw	a4,0(a2)
    80002cd8:	2705                	addiw	a4,a4,1
    80002cda:	c218                	sw	a4,0(a2)

    if (num > 0 && num < NELEM(syscalls)) {
    80002cdc:	37fd                	addiw	a5,a5,-1
    80002cde:	4759                	li	a4,22
    80002ce0:	04f76263          	bltu	a4,a5,80002d24 <syscall+0x7c>
        void *(*syscall_func)(void) = syscalls[num];
    80002ce4:	00369713          	slli	a4,a3,0x3
    80002ce8:	00005797          	auipc	a5,0x5
    80002cec:	7d078793          	addi	a5,a5,2000 # 800084b8 <syscalls>
    80002cf0:	97ba                	add	a5,a5,a4
    80002cf2:	639c                	ld	a5,0(a5)
        if (syscall_func) {
    80002cf4:	cb89                	beqz	a5,80002d06 <syscall+0x5e>
            // Use num to lookup the system call function for num, call it,
            // and store its return value in p->trapframe->a0
            p->trapframe->a0 = syscall_func();
    80002cf6:	9782                	jalr	a5
    80002cf8:	6cbc                	ld	a5,88(s1)
    80002cfa:	fba8                	sd	a0,112(a5)
    } else {
        printf("%d %s: unknown sys call %d\n",
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    }
}
    80002cfc:	60e2                	ld	ra,24(sp)
    80002cfe:	6442                	ld	s0,16(sp)
    80002d00:	64a2                	ld	s1,8(sp)
    80002d02:	6105                	addi	sp,sp,32
    80002d04:	8082                	ret
            printf("%d %s: unknown sys call %d\n",
    80002d06:	15850613          	addi	a2,a0,344
    80002d0a:	590c                	lw	a1,48(a0)
    80002d0c:	00005517          	auipc	a0,0x5
    80002d10:	77450513          	addi	a0,a0,1908 # 80008480 <states.0+0x150>
    80002d14:	ffffe097          	auipc	ra,0xffffe
    80002d18:	876080e7          	jalr	-1930(ra) # 8000058a <printf>
            p->trapframe->a0 = -1;
    80002d1c:	6cbc                	ld	a5,88(s1)
    80002d1e:	577d                	li	a4,-1
    80002d20:	fbb8                	sd	a4,112(a5)
    80002d22:	bfe9                	j	80002cfc <syscall+0x54>
        printf("%d %s: unknown sys call %d\n",
    80002d24:	15850613          	addi	a2,a0,344
    80002d28:	590c                	lw	a1,48(a0)
    80002d2a:	00005517          	auipc	a0,0x5
    80002d2e:	75650513          	addi	a0,a0,1878 # 80008480 <states.0+0x150>
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	858080e7          	jalr	-1960(ra) # 8000058a <printf>
        p->trapframe->a0 = -1;
    80002d3a:	6cbc                	ld	a5,88(s1)
    80002d3c:	577d                	li	a4,-1
    80002d3e:	fbb8                	sd	a4,112(a5)
}
    80002d40:	bf75                	j	80002cfc <syscall+0x54>

0000000080002d42 <sys_exit>:
#include "proc.h"
#include "pinfo.h"

uint64
sys_exit(void)
{
    80002d42:	1101                	addi	sp,sp,-32
    80002d44:	ec06                	sd	ra,24(sp)
    80002d46:	e822                	sd	s0,16(sp)
    80002d48:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d4a:	fec40593          	addi	a1,s0,-20
    80002d4e:	4501                	li	a0,0
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	ee0080e7          	jalr	-288(ra) # 80002c30 <argint>
  exit(n);
    80002d58:	fec42503          	lw	a0,-20(s0)
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	452080e7          	jalr	1106(ra) # 800021ae <exit>
  return 0;  // not reached
}
    80002d64:	4501                	li	a0,0
    80002d66:	60e2                	ld	ra,24(sp)
    80002d68:	6442                	ld	s0,16(sp)
    80002d6a:	6105                	addi	sp,sp,32
    80002d6c:	8082                	ret

0000000080002d6e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d6e:	1141                	addi	sp,sp,-16
    80002d70:	e406                	sd	ra,8(sp)
    80002d72:	e022                	sd	s0,0(sp)
    80002d74:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c58080e7          	jalr	-936(ra) # 800019ce <myproc>
}
    80002d7e:	5908                	lw	a0,48(a0)
    80002d80:	60a2                	ld	ra,8(sp)
    80002d82:	6402                	ld	s0,0(sp)
    80002d84:	0141                	addi	sp,sp,16
    80002d86:	8082                	ret

0000000080002d88 <sys_fork>:

uint64
sys_fork(void)
{
    80002d88:	1141                	addi	sp,sp,-16
    80002d8a:	e406                	sd	ra,8(sp)
    80002d8c:	e022                	sd	s0,0(sp)
    80002d8e:	0800                	addi	s0,sp,16
  return fork();
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	ff8080e7          	jalr	-8(ra) # 80001d88 <fork>
}
    80002d98:	60a2                	ld	ra,8(sp)
    80002d9a:	6402                	ld	s0,0(sp)
    80002d9c:	0141                	addi	sp,sp,16
    80002d9e:	8082                	ret

0000000080002da0 <sys_wait>:

uint64
sys_wait(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002da8:	fe840593          	addi	a1,s0,-24
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	ea2080e7          	jalr	-350(ra) # 80002c50 <argaddr>
  return wait(p);
    80002db6:	fe843503          	ld	a0,-24(s0)
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	59a080e7          	jalr	1434(ra) # 80002354 <wait>
}
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dca:	7179                	addi	sp,sp,-48
    80002dcc:	f406                	sd	ra,40(sp)
    80002dce:	f022                	sd	s0,32(sp)
    80002dd0:	ec26                	sd	s1,24(sp)
    80002dd2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002dd4:	fdc40593          	addi	a1,s0,-36
    80002dd8:	4501                	li	a0,0
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	e56080e7          	jalr	-426(ra) # 80002c30 <argint>
  addr = myproc()->sz;
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	bec080e7          	jalr	-1044(ra) # 800019ce <myproc>
    80002dea:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002dec:	fdc42503          	lw	a0,-36(s0)
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	f3c080e7          	jalr	-196(ra) # 80001d2c <growproc>
    80002df8:	00054863          	bltz	a0,80002e08 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dfc:	8526                	mv	a0,s1
    80002dfe:	70a2                	ld	ra,40(sp)
    80002e00:	7402                	ld	s0,32(sp)
    80002e02:	64e2                	ld	s1,24(sp)
    80002e04:	6145                	addi	sp,sp,48
    80002e06:	8082                	ret
    return -1;
    80002e08:	54fd                	li	s1,-1
    80002e0a:	bfcd                	j	80002dfc <sys_sbrk+0x32>

0000000080002e0c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e0c:	7139                	addi	sp,sp,-64
    80002e0e:	fc06                	sd	ra,56(sp)
    80002e10:	f822                	sd	s0,48(sp)
    80002e12:	f426                	sd	s1,40(sp)
    80002e14:	f04a                	sd	s2,32(sp)
    80002e16:	ec4e                	sd	s3,24(sp)
    80002e18:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e1a:	fcc40593          	addi	a1,s0,-52
    80002e1e:	4501                	li	a0,0
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	e10080e7          	jalr	-496(ra) # 80002c30 <argint>
  acquire(&tickslock);
    80002e28:	00014517          	auipc	a0,0x14
    80002e2c:	dd850513          	addi	a0,a0,-552 # 80016c00 <tickslock>
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	dc8080e7          	jalr	-568(ra) # 80000bf8 <acquire>
  ticks0 = ticks;
    80002e38:	00006917          	auipc	s2,0x6
    80002e3c:	b2892903          	lw	s2,-1240(s2) # 80008960 <ticks>
  while(ticks - ticks0 < n){
    80002e40:	fcc42783          	lw	a5,-52(s0)
    80002e44:	cf9d                	beqz	a5,80002e82 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e46:	00014997          	auipc	s3,0x14
    80002e4a:	dba98993          	addi	s3,s3,-582 # 80016c00 <tickslock>
    80002e4e:	00006497          	auipc	s1,0x6
    80002e52:	b1248493          	addi	s1,s1,-1262 # 80008960 <ticks>
    if(killed(myproc())){
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	b78080e7          	jalr	-1160(ra) # 800019ce <myproc>
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	4c4080e7          	jalr	1220(ra) # 80002322 <killed>
    80002e66:	ed15                	bnez	a0,80002ea2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e68:	85ce                	mv	a1,s3
    80002e6a:	8526                	mv	a0,s1
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	20e080e7          	jalr	526(ra) # 8000207a <sleep>
  while(ticks - ticks0 < n){
    80002e74:	409c                	lw	a5,0(s1)
    80002e76:	412787bb          	subw	a5,a5,s2
    80002e7a:	fcc42703          	lw	a4,-52(s0)
    80002e7e:	fce7ece3          	bltu	a5,a4,80002e56 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e82:	00014517          	auipc	a0,0x14
    80002e86:	d7e50513          	addi	a0,a0,-642 # 80016c00 <tickslock>
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	e22080e7          	jalr	-478(ra) # 80000cac <release>
  return 0;
    80002e92:	4501                	li	a0,0
}
    80002e94:	70e2                	ld	ra,56(sp)
    80002e96:	7442                	ld	s0,48(sp)
    80002e98:	74a2                	ld	s1,40(sp)
    80002e9a:	7902                	ld	s2,32(sp)
    80002e9c:	69e2                	ld	s3,24(sp)
    80002e9e:	6121                	addi	sp,sp,64
    80002ea0:	8082                	ret
      release(&tickslock);
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	d5e50513          	addi	a0,a0,-674 # 80016c00 <tickslock>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	e02080e7          	jalr	-510(ra) # 80000cac <release>
      return -1;
    80002eb2:	557d                	li	a0,-1
    80002eb4:	b7c5                	j	80002e94 <sys_sleep+0x88>

0000000080002eb6 <sys_kill>:

uint64
sys_kill(void)
{
    80002eb6:	1101                	addi	sp,sp,-32
    80002eb8:	ec06                	sd	ra,24(sp)
    80002eba:	e822                	sd	s0,16(sp)
    80002ebc:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ebe:	fec40593          	addi	a1,s0,-20
    80002ec2:	4501                	li	a0,0
    80002ec4:	00000097          	auipc	ra,0x0
    80002ec8:	d6c080e7          	jalr	-660(ra) # 80002c30 <argint>
  return kill(pid);
    80002ecc:	fec42503          	lw	a0,-20(s0)
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	3b4080e7          	jalr	948(ra) # 80002284 <kill>
}
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	6105                	addi	sp,sp,32
    80002ede:	8082                	ret

0000000080002ee0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	e426                	sd	s1,8(sp)
    80002ee8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eea:	00014517          	auipc	a0,0x14
    80002eee:	d1650513          	addi	a0,a0,-746 # 80016c00 <tickslock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	d06080e7          	jalr	-762(ra) # 80000bf8 <acquire>
  xticks = ticks;
    80002efa:	00006497          	auipc	s1,0x6
    80002efe:	a664a483          	lw	s1,-1434(s1) # 80008960 <ticks>
  release(&tickslock);
    80002f02:	00014517          	auipc	a0,0x14
    80002f06:	cfe50513          	addi	a0,a0,-770 # 80016c00 <tickslock>
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	da2080e7          	jalr	-606(ra) # 80000cac <release>
  return xticks;
}
    80002f12:	02049513          	slli	a0,s1,0x20
    80002f16:	9101                	srli	a0,a0,0x20
    80002f18:	60e2                	ld	ra,24(sp)
    80002f1a:	6442                	ld	s0,16(sp)
    80002f1c:	64a2                	ld	s1,8(sp)
    80002f1e:	6105                	addi	sp,sp,32
    80002f20:	8082                	ret

0000000080002f22 <sys_sysinfo>:

//sysinfo syscall def
uint64 sys_sysinfo(void)
{
    80002f22:	1101                	addi	sp,sp,-32
    80002f24:	ec06                	sd	ra,24(sp)
    80002f26:	e822                	sd	s0,16(sp)
    80002f28:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002f2a:	fec40593          	addi	a1,s0,-20
    80002f2e:	4501                	li	a0,0
    80002f30:	00000097          	auipc	ra,0x0
    80002f34:	d00080e7          	jalr	-768(ra) # 80002c30 <argint>
  return print_sysinfo(n);
    80002f38:	fec42503          	lw	a0,-20(s0)
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	6d6080e7          	jalr	1750(ra) # 80002612 <print_sysinfo>
}
    80002f44:	60e2                	ld	ra,24(sp)
    80002f46:	6442                	ld	s0,16(sp)
    80002f48:	6105                	addi	sp,sp,32
    80002f4a:	8082                	ret

0000000080002f4c <sys_procinfo>:

//procinfo syscall def. Lab1
uint64 sys_procinfo(void) {
    80002f4c:	1101                	addi	sp,sp,-32
    80002f4e:	ec06                	sd	ra,24(sp)
    80002f50:	e822                	sd	s0,16(sp)
    80002f52:	1000                	addi	s0,sp,32
	struct pinfo* addr;
	argaddr(0, (uint64*) &addr);
    80002f54:	fe840593          	addi	a1,s0,-24
    80002f58:	4501                	li	a0,0
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	cf6080e7          	jalr	-778(ra) # 80002c50 <argaddr>
	return procinfo(addr);
    80002f62:	fe843503          	ld	a0,-24(s0)
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	6ee080e7          	jalr	1774(ra) # 80002654 <procinfo>
}
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	6105                	addi	sp,sp,32
    80002f74:	8082                	ret

0000000080002f76 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f76:	7179                	addi	sp,sp,-48
    80002f78:	f406                	sd	ra,40(sp)
    80002f7a:	f022                	sd	s0,32(sp)
    80002f7c:	ec26                	sd	s1,24(sp)
    80002f7e:	e84a                	sd	s2,16(sp)
    80002f80:	e44e                	sd	s3,8(sp)
    80002f82:	e052                	sd	s4,0(sp)
    80002f84:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f86:	00005597          	auipc	a1,0x5
    80002f8a:	5f258593          	addi	a1,a1,1522 # 80008578 <syscalls+0xc0>
    80002f8e:	00014517          	auipc	a0,0x14
    80002f92:	c8a50513          	addi	a0,a0,-886 # 80016c18 <bcache>
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	bd2080e7          	jalr	-1070(ra) # 80000b68 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f9e:	0001c797          	auipc	a5,0x1c
    80002fa2:	c7a78793          	addi	a5,a5,-902 # 8001ec18 <bcache+0x8000>
    80002fa6:	0001c717          	auipc	a4,0x1c
    80002faa:	eda70713          	addi	a4,a4,-294 # 8001ee80 <bcache+0x8268>
    80002fae:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fb2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fb6:	00014497          	auipc	s1,0x14
    80002fba:	c7a48493          	addi	s1,s1,-902 # 80016c30 <bcache+0x18>
    b->next = bcache.head.next;
    80002fbe:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fc0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fc2:	00005a17          	auipc	s4,0x5
    80002fc6:	5bea0a13          	addi	s4,s4,1470 # 80008580 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002fca:	2b893783          	ld	a5,696(s2)
    80002fce:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fd0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fd4:	85d2                	mv	a1,s4
    80002fd6:	01048513          	addi	a0,s1,16
    80002fda:	00001097          	auipc	ra,0x1
    80002fde:	4c8080e7          	jalr	1224(ra) # 800044a2 <initsleeplock>
    bcache.head.next->prev = b;
    80002fe2:	2b893783          	ld	a5,696(s2)
    80002fe6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fe8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fec:	45848493          	addi	s1,s1,1112
    80002ff0:	fd349de3          	bne	s1,s3,80002fca <binit+0x54>
  }
}
    80002ff4:	70a2                	ld	ra,40(sp)
    80002ff6:	7402                	ld	s0,32(sp)
    80002ff8:	64e2                	ld	s1,24(sp)
    80002ffa:	6942                	ld	s2,16(sp)
    80002ffc:	69a2                	ld	s3,8(sp)
    80002ffe:	6a02                	ld	s4,0(sp)
    80003000:	6145                	addi	sp,sp,48
    80003002:	8082                	ret

0000000080003004 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003004:	7179                	addi	sp,sp,-48
    80003006:	f406                	sd	ra,40(sp)
    80003008:	f022                	sd	s0,32(sp)
    8000300a:	ec26                	sd	s1,24(sp)
    8000300c:	e84a                	sd	s2,16(sp)
    8000300e:	e44e                	sd	s3,8(sp)
    80003010:	1800                	addi	s0,sp,48
    80003012:	892a                	mv	s2,a0
    80003014:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003016:	00014517          	auipc	a0,0x14
    8000301a:	c0250513          	addi	a0,a0,-1022 # 80016c18 <bcache>
    8000301e:	ffffe097          	auipc	ra,0xffffe
    80003022:	bda080e7          	jalr	-1062(ra) # 80000bf8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003026:	0001c497          	auipc	s1,0x1c
    8000302a:	eaa4b483          	ld	s1,-342(s1) # 8001eed0 <bcache+0x82b8>
    8000302e:	0001c797          	auipc	a5,0x1c
    80003032:	e5278793          	addi	a5,a5,-430 # 8001ee80 <bcache+0x8268>
    80003036:	02f48f63          	beq	s1,a5,80003074 <bread+0x70>
    8000303a:	873e                	mv	a4,a5
    8000303c:	a021                	j	80003044 <bread+0x40>
    8000303e:	68a4                	ld	s1,80(s1)
    80003040:	02e48a63          	beq	s1,a4,80003074 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003044:	449c                	lw	a5,8(s1)
    80003046:	ff279ce3          	bne	a5,s2,8000303e <bread+0x3a>
    8000304a:	44dc                	lw	a5,12(s1)
    8000304c:	ff3799e3          	bne	a5,s3,8000303e <bread+0x3a>
      b->refcnt++;
    80003050:	40bc                	lw	a5,64(s1)
    80003052:	2785                	addiw	a5,a5,1
    80003054:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003056:	00014517          	auipc	a0,0x14
    8000305a:	bc250513          	addi	a0,a0,-1086 # 80016c18 <bcache>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	c4e080e7          	jalr	-946(ra) # 80000cac <release>
      acquiresleep(&b->lock);
    80003066:	01048513          	addi	a0,s1,16
    8000306a:	00001097          	auipc	ra,0x1
    8000306e:	472080e7          	jalr	1138(ra) # 800044dc <acquiresleep>
      return b;
    80003072:	a8b9                	j	800030d0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003074:	0001c497          	auipc	s1,0x1c
    80003078:	e544b483          	ld	s1,-428(s1) # 8001eec8 <bcache+0x82b0>
    8000307c:	0001c797          	auipc	a5,0x1c
    80003080:	e0478793          	addi	a5,a5,-508 # 8001ee80 <bcache+0x8268>
    80003084:	00f48863          	beq	s1,a5,80003094 <bread+0x90>
    80003088:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000308a:	40bc                	lw	a5,64(s1)
    8000308c:	cf81                	beqz	a5,800030a4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000308e:	64a4                	ld	s1,72(s1)
    80003090:	fee49de3          	bne	s1,a4,8000308a <bread+0x86>
  panic("bget: no buffers");
    80003094:	00005517          	auipc	a0,0x5
    80003098:	4f450513          	addi	a0,a0,1268 # 80008588 <syscalls+0xd0>
    8000309c:	ffffd097          	auipc	ra,0xffffd
    800030a0:	4a4080e7          	jalr	1188(ra) # 80000540 <panic>
      b->dev = dev;
    800030a4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030a8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030ac:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030b0:	4785                	li	a5,1
    800030b2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030b4:	00014517          	auipc	a0,0x14
    800030b8:	b6450513          	addi	a0,a0,-1180 # 80016c18 <bcache>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	bf0080e7          	jalr	-1040(ra) # 80000cac <release>
      acquiresleep(&b->lock);
    800030c4:	01048513          	addi	a0,s1,16
    800030c8:	00001097          	auipc	ra,0x1
    800030cc:	414080e7          	jalr	1044(ra) # 800044dc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030d0:	409c                	lw	a5,0(s1)
    800030d2:	cb89                	beqz	a5,800030e4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030d4:	8526                	mv	a0,s1
    800030d6:	70a2                	ld	ra,40(sp)
    800030d8:	7402                	ld	s0,32(sp)
    800030da:	64e2                	ld	s1,24(sp)
    800030dc:	6942                	ld	s2,16(sp)
    800030de:	69a2                	ld	s3,8(sp)
    800030e0:	6145                	addi	sp,sp,48
    800030e2:	8082                	ret
    virtio_disk_rw(b, 0);
    800030e4:	4581                	li	a1,0
    800030e6:	8526                	mv	a0,s1
    800030e8:	00003097          	auipc	ra,0x3
    800030ec:	fda080e7          	jalr	-38(ra) # 800060c2 <virtio_disk_rw>
    b->valid = 1;
    800030f0:	4785                	li	a5,1
    800030f2:	c09c                	sw	a5,0(s1)
  return b;
    800030f4:	b7c5                	j	800030d4 <bread+0xd0>

00000000800030f6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030f6:	1101                	addi	sp,sp,-32
    800030f8:	ec06                	sd	ra,24(sp)
    800030fa:	e822                	sd	s0,16(sp)
    800030fc:	e426                	sd	s1,8(sp)
    800030fe:	1000                	addi	s0,sp,32
    80003100:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003102:	0541                	addi	a0,a0,16
    80003104:	00001097          	auipc	ra,0x1
    80003108:	472080e7          	jalr	1138(ra) # 80004576 <holdingsleep>
    8000310c:	cd01                	beqz	a0,80003124 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000310e:	4585                	li	a1,1
    80003110:	8526                	mv	a0,s1
    80003112:	00003097          	auipc	ra,0x3
    80003116:	fb0080e7          	jalr	-80(ra) # 800060c2 <virtio_disk_rw>
}
    8000311a:	60e2                	ld	ra,24(sp)
    8000311c:	6442                	ld	s0,16(sp)
    8000311e:	64a2                	ld	s1,8(sp)
    80003120:	6105                	addi	sp,sp,32
    80003122:	8082                	ret
    panic("bwrite");
    80003124:	00005517          	auipc	a0,0x5
    80003128:	47c50513          	addi	a0,a0,1148 # 800085a0 <syscalls+0xe8>
    8000312c:	ffffd097          	auipc	ra,0xffffd
    80003130:	414080e7          	jalr	1044(ra) # 80000540 <panic>

0000000080003134 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	e426                	sd	s1,8(sp)
    8000313c:	e04a                	sd	s2,0(sp)
    8000313e:	1000                	addi	s0,sp,32
    80003140:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003142:	01050913          	addi	s2,a0,16
    80003146:	854a                	mv	a0,s2
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	42e080e7          	jalr	1070(ra) # 80004576 <holdingsleep>
    80003150:	c92d                	beqz	a0,800031c2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003152:	854a                	mv	a0,s2
    80003154:	00001097          	auipc	ra,0x1
    80003158:	3de080e7          	jalr	990(ra) # 80004532 <releasesleep>

  acquire(&bcache.lock);
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	abc50513          	addi	a0,a0,-1348 # 80016c18 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	a94080e7          	jalr	-1388(ra) # 80000bf8 <acquire>
  b->refcnt--;
    8000316c:	40bc                	lw	a5,64(s1)
    8000316e:	37fd                	addiw	a5,a5,-1
    80003170:	0007871b          	sext.w	a4,a5
    80003174:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003176:	eb05                	bnez	a4,800031a6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003178:	68bc                	ld	a5,80(s1)
    8000317a:	64b8                	ld	a4,72(s1)
    8000317c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000317e:	64bc                	ld	a5,72(s1)
    80003180:	68b8                	ld	a4,80(s1)
    80003182:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003184:	0001c797          	auipc	a5,0x1c
    80003188:	a9478793          	addi	a5,a5,-1388 # 8001ec18 <bcache+0x8000>
    8000318c:	2b87b703          	ld	a4,696(a5)
    80003190:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003192:	0001c717          	auipc	a4,0x1c
    80003196:	cee70713          	addi	a4,a4,-786 # 8001ee80 <bcache+0x8268>
    8000319a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000319c:	2b87b703          	ld	a4,696(a5)
    800031a0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031a2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031a6:	00014517          	auipc	a0,0x14
    800031aa:	a7250513          	addi	a0,a0,-1422 # 80016c18 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	afe080e7          	jalr	-1282(ra) # 80000cac <release>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6902                	ld	s2,0(sp)
    800031be:	6105                	addi	sp,sp,32
    800031c0:	8082                	ret
    panic("brelse");
    800031c2:	00005517          	auipc	a0,0x5
    800031c6:	3e650513          	addi	a0,a0,998 # 800085a8 <syscalls+0xf0>
    800031ca:	ffffd097          	auipc	ra,0xffffd
    800031ce:	376080e7          	jalr	886(ra) # 80000540 <panic>

00000000800031d2 <bpin>:

void
bpin(struct buf *b) {
    800031d2:	1101                	addi	sp,sp,-32
    800031d4:	ec06                	sd	ra,24(sp)
    800031d6:	e822                	sd	s0,16(sp)
    800031d8:	e426                	sd	s1,8(sp)
    800031da:	1000                	addi	s0,sp,32
    800031dc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	a3a50513          	addi	a0,a0,-1478 # 80016c18 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	a12080e7          	jalr	-1518(ra) # 80000bf8 <acquire>
  b->refcnt++;
    800031ee:	40bc                	lw	a5,64(s1)
    800031f0:	2785                	addiw	a5,a5,1
    800031f2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031f4:	00014517          	auipc	a0,0x14
    800031f8:	a2450513          	addi	a0,a0,-1500 # 80016c18 <bcache>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	ab0080e7          	jalr	-1360(ra) # 80000cac <release>
}
    80003204:	60e2                	ld	ra,24(sp)
    80003206:	6442                	ld	s0,16(sp)
    80003208:	64a2                	ld	s1,8(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret

000000008000320e <bunpin>:

void
bunpin(struct buf *b) {
    8000320e:	1101                	addi	sp,sp,-32
    80003210:	ec06                	sd	ra,24(sp)
    80003212:	e822                	sd	s0,16(sp)
    80003214:	e426                	sd	s1,8(sp)
    80003216:	1000                	addi	s0,sp,32
    80003218:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	9fe50513          	addi	a0,a0,-1538 # 80016c18 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	9d6080e7          	jalr	-1578(ra) # 80000bf8 <acquire>
  b->refcnt--;
    8000322a:	40bc                	lw	a5,64(s1)
    8000322c:	37fd                	addiw	a5,a5,-1
    8000322e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003230:	00014517          	auipc	a0,0x14
    80003234:	9e850513          	addi	a0,a0,-1560 # 80016c18 <bcache>
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	a74080e7          	jalr	-1420(ra) # 80000cac <release>
}
    80003240:	60e2                	ld	ra,24(sp)
    80003242:	6442                	ld	s0,16(sp)
    80003244:	64a2                	ld	s1,8(sp)
    80003246:	6105                	addi	sp,sp,32
    80003248:	8082                	ret

000000008000324a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000324a:	1101                	addi	sp,sp,-32
    8000324c:	ec06                	sd	ra,24(sp)
    8000324e:	e822                	sd	s0,16(sp)
    80003250:	e426                	sd	s1,8(sp)
    80003252:	e04a                	sd	s2,0(sp)
    80003254:	1000                	addi	s0,sp,32
    80003256:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003258:	00d5d59b          	srliw	a1,a1,0xd
    8000325c:	0001c797          	auipc	a5,0x1c
    80003260:	0987a783          	lw	a5,152(a5) # 8001f2f4 <sb+0x1c>
    80003264:	9dbd                	addw	a1,a1,a5
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	d9e080e7          	jalr	-610(ra) # 80003004 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000326e:	0074f713          	andi	a4,s1,7
    80003272:	4785                	li	a5,1
    80003274:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003278:	14ce                	slli	s1,s1,0x33
    8000327a:	90d9                	srli	s1,s1,0x36
    8000327c:	00950733          	add	a4,a0,s1
    80003280:	05874703          	lbu	a4,88(a4)
    80003284:	00e7f6b3          	and	a3,a5,a4
    80003288:	c69d                	beqz	a3,800032b6 <bfree+0x6c>
    8000328a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000328c:	94aa                	add	s1,s1,a0
    8000328e:	fff7c793          	not	a5,a5
    80003292:	8f7d                	and	a4,a4,a5
    80003294:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003298:	00001097          	auipc	ra,0x1
    8000329c:	126080e7          	jalr	294(ra) # 800043be <log_write>
  brelse(bp);
    800032a0:	854a                	mv	a0,s2
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	e92080e7          	jalr	-366(ra) # 80003134 <brelse>
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6902                	ld	s2,0(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret
    panic("freeing free block");
    800032b6:	00005517          	auipc	a0,0x5
    800032ba:	2fa50513          	addi	a0,a0,762 # 800085b0 <syscalls+0xf8>
    800032be:	ffffd097          	auipc	ra,0xffffd
    800032c2:	282080e7          	jalr	642(ra) # 80000540 <panic>

00000000800032c6 <balloc>:
{
    800032c6:	711d                	addi	sp,sp,-96
    800032c8:	ec86                	sd	ra,88(sp)
    800032ca:	e8a2                	sd	s0,80(sp)
    800032cc:	e4a6                	sd	s1,72(sp)
    800032ce:	e0ca                	sd	s2,64(sp)
    800032d0:	fc4e                	sd	s3,56(sp)
    800032d2:	f852                	sd	s4,48(sp)
    800032d4:	f456                	sd	s5,40(sp)
    800032d6:	f05a                	sd	s6,32(sp)
    800032d8:	ec5e                	sd	s7,24(sp)
    800032da:	e862                	sd	s8,16(sp)
    800032dc:	e466                	sd	s9,8(sp)
    800032de:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032e0:	0001c797          	auipc	a5,0x1c
    800032e4:	ffc7a783          	lw	a5,-4(a5) # 8001f2dc <sb+0x4>
    800032e8:	cff5                	beqz	a5,800033e4 <balloc+0x11e>
    800032ea:	8baa                	mv	s7,a0
    800032ec:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032ee:	0001cb17          	auipc	s6,0x1c
    800032f2:	feab0b13          	addi	s6,s6,-22 # 8001f2d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032f8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032fa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032fc:	6c89                	lui	s9,0x2
    800032fe:	a061                	j	80003386 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003300:	97ca                	add	a5,a5,s2
    80003302:	8e55                	or	a2,a2,a3
    80003304:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003308:	854a                	mv	a0,s2
    8000330a:	00001097          	auipc	ra,0x1
    8000330e:	0b4080e7          	jalr	180(ra) # 800043be <log_write>
        brelse(bp);
    80003312:	854a                	mv	a0,s2
    80003314:	00000097          	auipc	ra,0x0
    80003318:	e20080e7          	jalr	-480(ra) # 80003134 <brelse>
  bp = bread(dev, bno);
    8000331c:	85a6                	mv	a1,s1
    8000331e:	855e                	mv	a0,s7
    80003320:	00000097          	auipc	ra,0x0
    80003324:	ce4080e7          	jalr	-796(ra) # 80003004 <bread>
    80003328:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000332a:	40000613          	li	a2,1024
    8000332e:	4581                	li	a1,0
    80003330:	05850513          	addi	a0,a0,88
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	9c0080e7          	jalr	-1600(ra) # 80000cf4 <memset>
  log_write(bp);
    8000333c:	854a                	mv	a0,s2
    8000333e:	00001097          	auipc	ra,0x1
    80003342:	080080e7          	jalr	128(ra) # 800043be <log_write>
  brelse(bp);
    80003346:	854a                	mv	a0,s2
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	dec080e7          	jalr	-532(ra) # 80003134 <brelse>
}
    80003350:	8526                	mv	a0,s1
    80003352:	60e6                	ld	ra,88(sp)
    80003354:	6446                	ld	s0,80(sp)
    80003356:	64a6                	ld	s1,72(sp)
    80003358:	6906                	ld	s2,64(sp)
    8000335a:	79e2                	ld	s3,56(sp)
    8000335c:	7a42                	ld	s4,48(sp)
    8000335e:	7aa2                	ld	s5,40(sp)
    80003360:	7b02                	ld	s6,32(sp)
    80003362:	6be2                	ld	s7,24(sp)
    80003364:	6c42                	ld	s8,16(sp)
    80003366:	6ca2                	ld	s9,8(sp)
    80003368:	6125                	addi	sp,sp,96
    8000336a:	8082                	ret
    brelse(bp);
    8000336c:	854a                	mv	a0,s2
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	dc6080e7          	jalr	-570(ra) # 80003134 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003376:	015c87bb          	addw	a5,s9,s5
    8000337a:	00078a9b          	sext.w	s5,a5
    8000337e:	004b2703          	lw	a4,4(s6)
    80003382:	06eaf163          	bgeu	s5,a4,800033e4 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003386:	41fad79b          	sraiw	a5,s5,0x1f
    8000338a:	0137d79b          	srliw	a5,a5,0x13
    8000338e:	015787bb          	addw	a5,a5,s5
    80003392:	40d7d79b          	sraiw	a5,a5,0xd
    80003396:	01cb2583          	lw	a1,28(s6)
    8000339a:	9dbd                	addw	a1,a1,a5
    8000339c:	855e                	mv	a0,s7
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	c66080e7          	jalr	-922(ra) # 80003004 <bread>
    800033a6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033a8:	004b2503          	lw	a0,4(s6)
    800033ac:	000a849b          	sext.w	s1,s5
    800033b0:	8762                	mv	a4,s8
    800033b2:	faa4fde3          	bgeu	s1,a0,8000336c <balloc+0xa6>
      m = 1 << (bi % 8);
    800033b6:	00777693          	andi	a3,a4,7
    800033ba:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033be:	41f7579b          	sraiw	a5,a4,0x1f
    800033c2:	01d7d79b          	srliw	a5,a5,0x1d
    800033c6:	9fb9                	addw	a5,a5,a4
    800033c8:	4037d79b          	sraiw	a5,a5,0x3
    800033cc:	00f90633          	add	a2,s2,a5
    800033d0:	05864603          	lbu	a2,88(a2)
    800033d4:	00c6f5b3          	and	a1,a3,a2
    800033d8:	d585                	beqz	a1,80003300 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033da:	2705                	addiw	a4,a4,1
    800033dc:	2485                	addiw	s1,s1,1
    800033de:	fd471ae3          	bne	a4,s4,800033b2 <balloc+0xec>
    800033e2:	b769                	j	8000336c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800033e4:	00005517          	auipc	a0,0x5
    800033e8:	1e450513          	addi	a0,a0,484 # 800085c8 <syscalls+0x110>
    800033ec:	ffffd097          	auipc	ra,0xffffd
    800033f0:	19e080e7          	jalr	414(ra) # 8000058a <printf>
  return 0;
    800033f4:	4481                	li	s1,0
    800033f6:	bfa9                	j	80003350 <balloc+0x8a>

00000000800033f8 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033f8:	7179                	addi	sp,sp,-48
    800033fa:	f406                	sd	ra,40(sp)
    800033fc:	f022                	sd	s0,32(sp)
    800033fe:	ec26                	sd	s1,24(sp)
    80003400:	e84a                	sd	s2,16(sp)
    80003402:	e44e                	sd	s3,8(sp)
    80003404:	e052                	sd	s4,0(sp)
    80003406:	1800                	addi	s0,sp,48
    80003408:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000340a:	47ad                	li	a5,11
    8000340c:	02b7e863          	bltu	a5,a1,8000343c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003410:	02059793          	slli	a5,a1,0x20
    80003414:	01e7d593          	srli	a1,a5,0x1e
    80003418:	00b504b3          	add	s1,a0,a1
    8000341c:	0504a903          	lw	s2,80(s1)
    80003420:	06091e63          	bnez	s2,8000349c <bmap+0xa4>
      addr = balloc(ip->dev);
    80003424:	4108                	lw	a0,0(a0)
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	ea0080e7          	jalr	-352(ra) # 800032c6 <balloc>
    8000342e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003432:	06090563          	beqz	s2,8000349c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003436:	0524a823          	sw	s2,80(s1)
    8000343a:	a08d                	j	8000349c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000343c:	ff45849b          	addiw	s1,a1,-12
    80003440:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003444:	0ff00793          	li	a5,255
    80003448:	08e7e563          	bltu	a5,a4,800034d2 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000344c:	08052903          	lw	s2,128(a0)
    80003450:	00091d63          	bnez	s2,8000346a <bmap+0x72>
      addr = balloc(ip->dev);
    80003454:	4108                	lw	a0,0(a0)
    80003456:	00000097          	auipc	ra,0x0
    8000345a:	e70080e7          	jalr	-400(ra) # 800032c6 <balloc>
    8000345e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003462:	02090d63          	beqz	s2,8000349c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003466:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000346a:	85ca                	mv	a1,s2
    8000346c:	0009a503          	lw	a0,0(s3)
    80003470:	00000097          	auipc	ra,0x0
    80003474:	b94080e7          	jalr	-1132(ra) # 80003004 <bread>
    80003478:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000347a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000347e:	02049713          	slli	a4,s1,0x20
    80003482:	01e75593          	srli	a1,a4,0x1e
    80003486:	00b784b3          	add	s1,a5,a1
    8000348a:	0004a903          	lw	s2,0(s1)
    8000348e:	02090063          	beqz	s2,800034ae <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003492:	8552                	mv	a0,s4
    80003494:	00000097          	auipc	ra,0x0
    80003498:	ca0080e7          	jalr	-864(ra) # 80003134 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000349c:	854a                	mv	a0,s2
    8000349e:	70a2                	ld	ra,40(sp)
    800034a0:	7402                	ld	s0,32(sp)
    800034a2:	64e2                	ld	s1,24(sp)
    800034a4:	6942                	ld	s2,16(sp)
    800034a6:	69a2                	ld	s3,8(sp)
    800034a8:	6a02                	ld	s4,0(sp)
    800034aa:	6145                	addi	sp,sp,48
    800034ac:	8082                	ret
      addr = balloc(ip->dev);
    800034ae:	0009a503          	lw	a0,0(s3)
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	e14080e7          	jalr	-492(ra) # 800032c6 <balloc>
    800034ba:	0005091b          	sext.w	s2,a0
      if(addr){
    800034be:	fc090ae3          	beqz	s2,80003492 <bmap+0x9a>
        a[bn] = addr;
    800034c2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800034c6:	8552                	mv	a0,s4
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	ef6080e7          	jalr	-266(ra) # 800043be <log_write>
    800034d0:	b7c9                	j	80003492 <bmap+0x9a>
  panic("bmap: out of range");
    800034d2:	00005517          	auipc	a0,0x5
    800034d6:	10e50513          	addi	a0,a0,270 # 800085e0 <syscalls+0x128>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	066080e7          	jalr	102(ra) # 80000540 <panic>

00000000800034e2 <iget>:
{
    800034e2:	7179                	addi	sp,sp,-48
    800034e4:	f406                	sd	ra,40(sp)
    800034e6:	f022                	sd	s0,32(sp)
    800034e8:	ec26                	sd	s1,24(sp)
    800034ea:	e84a                	sd	s2,16(sp)
    800034ec:	e44e                	sd	s3,8(sp)
    800034ee:	e052                	sd	s4,0(sp)
    800034f0:	1800                	addi	s0,sp,48
    800034f2:	89aa                	mv	s3,a0
    800034f4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034f6:	0001c517          	auipc	a0,0x1c
    800034fa:	e0250513          	addi	a0,a0,-510 # 8001f2f8 <itable>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	6fa080e7          	jalr	1786(ra) # 80000bf8 <acquire>
  empty = 0;
    80003506:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003508:	0001c497          	auipc	s1,0x1c
    8000350c:	e0848493          	addi	s1,s1,-504 # 8001f310 <itable+0x18>
    80003510:	0001e697          	auipc	a3,0x1e
    80003514:	89068693          	addi	a3,a3,-1904 # 80020da0 <log>
    80003518:	a039                	j	80003526 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000351a:	02090b63          	beqz	s2,80003550 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000351e:	08848493          	addi	s1,s1,136
    80003522:	02d48a63          	beq	s1,a3,80003556 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003526:	449c                	lw	a5,8(s1)
    80003528:	fef059e3          	blez	a5,8000351a <iget+0x38>
    8000352c:	4098                	lw	a4,0(s1)
    8000352e:	ff3716e3          	bne	a4,s3,8000351a <iget+0x38>
    80003532:	40d8                	lw	a4,4(s1)
    80003534:	ff4713e3          	bne	a4,s4,8000351a <iget+0x38>
      ip->ref++;
    80003538:	2785                	addiw	a5,a5,1
    8000353a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000353c:	0001c517          	auipc	a0,0x1c
    80003540:	dbc50513          	addi	a0,a0,-580 # 8001f2f8 <itable>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	768080e7          	jalr	1896(ra) # 80000cac <release>
      return ip;
    8000354c:	8926                	mv	s2,s1
    8000354e:	a03d                	j	8000357c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003550:	f7f9                	bnez	a5,8000351e <iget+0x3c>
    80003552:	8926                	mv	s2,s1
    80003554:	b7e9                	j	8000351e <iget+0x3c>
  if(empty == 0)
    80003556:	02090c63          	beqz	s2,8000358e <iget+0xac>
  ip->dev = dev;
    8000355a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000355e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003562:	4785                	li	a5,1
    80003564:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003568:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000356c:	0001c517          	auipc	a0,0x1c
    80003570:	d8c50513          	addi	a0,a0,-628 # 8001f2f8 <itable>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	738080e7          	jalr	1848(ra) # 80000cac <release>
}
    8000357c:	854a                	mv	a0,s2
    8000357e:	70a2                	ld	ra,40(sp)
    80003580:	7402                	ld	s0,32(sp)
    80003582:	64e2                	ld	s1,24(sp)
    80003584:	6942                	ld	s2,16(sp)
    80003586:	69a2                	ld	s3,8(sp)
    80003588:	6a02                	ld	s4,0(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret
    panic("iget: no inodes");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	06a50513          	addi	a0,a0,106 # 800085f8 <syscalls+0x140>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	faa080e7          	jalr	-86(ra) # 80000540 <panic>

000000008000359e <fsinit>:
fsinit(int dev) {
    8000359e:	7179                	addi	sp,sp,-48
    800035a0:	f406                	sd	ra,40(sp)
    800035a2:	f022                	sd	s0,32(sp)
    800035a4:	ec26                	sd	s1,24(sp)
    800035a6:	e84a                	sd	s2,16(sp)
    800035a8:	e44e                	sd	s3,8(sp)
    800035aa:	1800                	addi	s0,sp,48
    800035ac:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ae:	4585                	li	a1,1
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	a54080e7          	jalr	-1452(ra) # 80003004 <bread>
    800035b8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035ba:	0001c997          	auipc	s3,0x1c
    800035be:	d1e98993          	addi	s3,s3,-738 # 8001f2d8 <sb>
    800035c2:	02000613          	li	a2,32
    800035c6:	05850593          	addi	a1,a0,88
    800035ca:	854e                	mv	a0,s3
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	784080e7          	jalr	1924(ra) # 80000d50 <memmove>
  brelse(bp);
    800035d4:	8526                	mv	a0,s1
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	b5e080e7          	jalr	-1186(ra) # 80003134 <brelse>
  if(sb.magic != FSMAGIC)
    800035de:	0009a703          	lw	a4,0(s3)
    800035e2:	102037b7          	lui	a5,0x10203
    800035e6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035ea:	02f71263          	bne	a4,a5,8000360e <fsinit+0x70>
  initlog(dev, &sb);
    800035ee:	0001c597          	auipc	a1,0x1c
    800035f2:	cea58593          	addi	a1,a1,-790 # 8001f2d8 <sb>
    800035f6:	854a                	mv	a0,s2
    800035f8:	00001097          	auipc	ra,0x1
    800035fc:	b4a080e7          	jalr	-1206(ra) # 80004142 <initlog>
}
    80003600:	70a2                	ld	ra,40(sp)
    80003602:	7402                	ld	s0,32(sp)
    80003604:	64e2                	ld	s1,24(sp)
    80003606:	6942                	ld	s2,16(sp)
    80003608:	69a2                	ld	s3,8(sp)
    8000360a:	6145                	addi	sp,sp,48
    8000360c:	8082                	ret
    panic("invalid file system");
    8000360e:	00005517          	auipc	a0,0x5
    80003612:	ffa50513          	addi	a0,a0,-6 # 80008608 <syscalls+0x150>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	f2a080e7          	jalr	-214(ra) # 80000540 <panic>

000000008000361e <iinit>:
{
    8000361e:	7179                	addi	sp,sp,-48
    80003620:	f406                	sd	ra,40(sp)
    80003622:	f022                	sd	s0,32(sp)
    80003624:	ec26                	sd	s1,24(sp)
    80003626:	e84a                	sd	s2,16(sp)
    80003628:	e44e                	sd	s3,8(sp)
    8000362a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000362c:	00005597          	auipc	a1,0x5
    80003630:	ff458593          	addi	a1,a1,-12 # 80008620 <syscalls+0x168>
    80003634:	0001c517          	auipc	a0,0x1c
    80003638:	cc450513          	addi	a0,a0,-828 # 8001f2f8 <itable>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	52c080e7          	jalr	1324(ra) # 80000b68 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003644:	0001c497          	auipc	s1,0x1c
    80003648:	cdc48493          	addi	s1,s1,-804 # 8001f320 <itable+0x28>
    8000364c:	0001d997          	auipc	s3,0x1d
    80003650:	76498993          	addi	s3,s3,1892 # 80020db0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003654:	00005917          	auipc	s2,0x5
    80003658:	fd490913          	addi	s2,s2,-44 # 80008628 <syscalls+0x170>
    8000365c:	85ca                	mv	a1,s2
    8000365e:	8526                	mv	a0,s1
    80003660:	00001097          	auipc	ra,0x1
    80003664:	e42080e7          	jalr	-446(ra) # 800044a2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003668:	08848493          	addi	s1,s1,136
    8000366c:	ff3498e3          	bne	s1,s3,8000365c <iinit+0x3e>
}
    80003670:	70a2                	ld	ra,40(sp)
    80003672:	7402                	ld	s0,32(sp)
    80003674:	64e2                	ld	s1,24(sp)
    80003676:	6942                	ld	s2,16(sp)
    80003678:	69a2                	ld	s3,8(sp)
    8000367a:	6145                	addi	sp,sp,48
    8000367c:	8082                	ret

000000008000367e <ialloc>:
{
    8000367e:	715d                	addi	sp,sp,-80
    80003680:	e486                	sd	ra,72(sp)
    80003682:	e0a2                	sd	s0,64(sp)
    80003684:	fc26                	sd	s1,56(sp)
    80003686:	f84a                	sd	s2,48(sp)
    80003688:	f44e                	sd	s3,40(sp)
    8000368a:	f052                	sd	s4,32(sp)
    8000368c:	ec56                	sd	s5,24(sp)
    8000368e:	e85a                	sd	s6,16(sp)
    80003690:	e45e                	sd	s7,8(sp)
    80003692:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003694:	0001c717          	auipc	a4,0x1c
    80003698:	c5072703          	lw	a4,-944(a4) # 8001f2e4 <sb+0xc>
    8000369c:	4785                	li	a5,1
    8000369e:	04e7fa63          	bgeu	a5,a4,800036f2 <ialloc+0x74>
    800036a2:	8aaa                	mv	s5,a0
    800036a4:	8bae                	mv	s7,a1
    800036a6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036a8:	0001ca17          	auipc	s4,0x1c
    800036ac:	c30a0a13          	addi	s4,s4,-976 # 8001f2d8 <sb>
    800036b0:	00048b1b          	sext.w	s6,s1
    800036b4:	0044d593          	srli	a1,s1,0x4
    800036b8:	018a2783          	lw	a5,24(s4)
    800036bc:	9dbd                	addw	a1,a1,a5
    800036be:	8556                	mv	a0,s5
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	944080e7          	jalr	-1724(ra) # 80003004 <bread>
    800036c8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036ca:	05850993          	addi	s3,a0,88
    800036ce:	00f4f793          	andi	a5,s1,15
    800036d2:	079a                	slli	a5,a5,0x6
    800036d4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036d6:	00099783          	lh	a5,0(s3)
    800036da:	c3a1                	beqz	a5,8000371a <ialloc+0x9c>
    brelse(bp);
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	a58080e7          	jalr	-1448(ra) # 80003134 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036e4:	0485                	addi	s1,s1,1
    800036e6:	00ca2703          	lw	a4,12(s4)
    800036ea:	0004879b          	sext.w	a5,s1
    800036ee:	fce7e1e3          	bltu	a5,a4,800036b0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036f2:	00005517          	auipc	a0,0x5
    800036f6:	f3e50513          	addi	a0,a0,-194 # 80008630 <syscalls+0x178>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	e90080e7          	jalr	-368(ra) # 8000058a <printf>
  return 0;
    80003702:	4501                	li	a0,0
}
    80003704:	60a6                	ld	ra,72(sp)
    80003706:	6406                	ld	s0,64(sp)
    80003708:	74e2                	ld	s1,56(sp)
    8000370a:	7942                	ld	s2,48(sp)
    8000370c:	79a2                	ld	s3,40(sp)
    8000370e:	7a02                	ld	s4,32(sp)
    80003710:	6ae2                	ld	s5,24(sp)
    80003712:	6b42                	ld	s6,16(sp)
    80003714:	6ba2                	ld	s7,8(sp)
    80003716:	6161                	addi	sp,sp,80
    80003718:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000371a:	04000613          	li	a2,64
    8000371e:	4581                	li	a1,0
    80003720:	854e                	mv	a0,s3
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	5d2080e7          	jalr	1490(ra) # 80000cf4 <memset>
      dip->type = type;
    8000372a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000372e:	854a                	mv	a0,s2
    80003730:	00001097          	auipc	ra,0x1
    80003734:	c8e080e7          	jalr	-882(ra) # 800043be <log_write>
      brelse(bp);
    80003738:	854a                	mv	a0,s2
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	9fa080e7          	jalr	-1542(ra) # 80003134 <brelse>
      return iget(dev, inum);
    80003742:	85da                	mv	a1,s6
    80003744:	8556                	mv	a0,s5
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	d9c080e7          	jalr	-612(ra) # 800034e2 <iget>
    8000374e:	bf5d                	j	80003704 <ialloc+0x86>

0000000080003750 <iupdate>:
{
    80003750:	1101                	addi	sp,sp,-32
    80003752:	ec06                	sd	ra,24(sp)
    80003754:	e822                	sd	s0,16(sp)
    80003756:	e426                	sd	s1,8(sp)
    80003758:	e04a                	sd	s2,0(sp)
    8000375a:	1000                	addi	s0,sp,32
    8000375c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000375e:	415c                	lw	a5,4(a0)
    80003760:	0047d79b          	srliw	a5,a5,0x4
    80003764:	0001c597          	auipc	a1,0x1c
    80003768:	b8c5a583          	lw	a1,-1140(a1) # 8001f2f0 <sb+0x18>
    8000376c:	9dbd                	addw	a1,a1,a5
    8000376e:	4108                	lw	a0,0(a0)
    80003770:	00000097          	auipc	ra,0x0
    80003774:	894080e7          	jalr	-1900(ra) # 80003004 <bread>
    80003778:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000377a:	05850793          	addi	a5,a0,88
    8000377e:	40d8                	lw	a4,4(s1)
    80003780:	8b3d                	andi	a4,a4,15
    80003782:	071a                	slli	a4,a4,0x6
    80003784:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003786:	04449703          	lh	a4,68(s1)
    8000378a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000378e:	04649703          	lh	a4,70(s1)
    80003792:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003796:	04849703          	lh	a4,72(s1)
    8000379a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000379e:	04a49703          	lh	a4,74(s1)
    800037a2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800037a6:	44f8                	lw	a4,76(s1)
    800037a8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037aa:	03400613          	li	a2,52
    800037ae:	05048593          	addi	a1,s1,80
    800037b2:	00c78513          	addi	a0,a5,12
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	59a080e7          	jalr	1434(ra) # 80000d50 <memmove>
  log_write(bp);
    800037be:	854a                	mv	a0,s2
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	bfe080e7          	jalr	-1026(ra) # 800043be <log_write>
  brelse(bp);
    800037c8:	854a                	mv	a0,s2
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	96a080e7          	jalr	-1686(ra) # 80003134 <brelse>
}
    800037d2:	60e2                	ld	ra,24(sp)
    800037d4:	6442                	ld	s0,16(sp)
    800037d6:	64a2                	ld	s1,8(sp)
    800037d8:	6902                	ld	s2,0(sp)
    800037da:	6105                	addi	sp,sp,32
    800037dc:	8082                	ret

00000000800037de <idup>:
{
    800037de:	1101                	addi	sp,sp,-32
    800037e0:	ec06                	sd	ra,24(sp)
    800037e2:	e822                	sd	s0,16(sp)
    800037e4:	e426                	sd	s1,8(sp)
    800037e6:	1000                	addi	s0,sp,32
    800037e8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037ea:	0001c517          	auipc	a0,0x1c
    800037ee:	b0e50513          	addi	a0,a0,-1266 # 8001f2f8 <itable>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	406080e7          	jalr	1030(ra) # 80000bf8 <acquire>
  ip->ref++;
    800037fa:	449c                	lw	a5,8(s1)
    800037fc:	2785                	addiw	a5,a5,1
    800037fe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003800:	0001c517          	auipc	a0,0x1c
    80003804:	af850513          	addi	a0,a0,-1288 # 8001f2f8 <itable>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	4a4080e7          	jalr	1188(ra) # 80000cac <release>
}
    80003810:	8526                	mv	a0,s1
    80003812:	60e2                	ld	ra,24(sp)
    80003814:	6442                	ld	s0,16(sp)
    80003816:	64a2                	ld	s1,8(sp)
    80003818:	6105                	addi	sp,sp,32
    8000381a:	8082                	ret

000000008000381c <ilock>:
{
    8000381c:	1101                	addi	sp,sp,-32
    8000381e:	ec06                	sd	ra,24(sp)
    80003820:	e822                	sd	s0,16(sp)
    80003822:	e426                	sd	s1,8(sp)
    80003824:	e04a                	sd	s2,0(sp)
    80003826:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003828:	c115                	beqz	a0,8000384c <ilock+0x30>
    8000382a:	84aa                	mv	s1,a0
    8000382c:	451c                	lw	a5,8(a0)
    8000382e:	00f05f63          	blez	a5,8000384c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003832:	0541                	addi	a0,a0,16
    80003834:	00001097          	auipc	ra,0x1
    80003838:	ca8080e7          	jalr	-856(ra) # 800044dc <acquiresleep>
  if(ip->valid == 0){
    8000383c:	40bc                	lw	a5,64(s1)
    8000383e:	cf99                	beqz	a5,8000385c <ilock+0x40>
}
    80003840:	60e2                	ld	ra,24(sp)
    80003842:	6442                	ld	s0,16(sp)
    80003844:	64a2                	ld	s1,8(sp)
    80003846:	6902                	ld	s2,0(sp)
    80003848:	6105                	addi	sp,sp,32
    8000384a:	8082                	ret
    panic("ilock");
    8000384c:	00005517          	auipc	a0,0x5
    80003850:	dfc50513          	addi	a0,a0,-516 # 80008648 <syscalls+0x190>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	cec080e7          	jalr	-788(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000385c:	40dc                	lw	a5,4(s1)
    8000385e:	0047d79b          	srliw	a5,a5,0x4
    80003862:	0001c597          	auipc	a1,0x1c
    80003866:	a8e5a583          	lw	a1,-1394(a1) # 8001f2f0 <sb+0x18>
    8000386a:	9dbd                	addw	a1,a1,a5
    8000386c:	4088                	lw	a0,0(s1)
    8000386e:	fffff097          	auipc	ra,0xfffff
    80003872:	796080e7          	jalr	1942(ra) # 80003004 <bread>
    80003876:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003878:	05850593          	addi	a1,a0,88
    8000387c:	40dc                	lw	a5,4(s1)
    8000387e:	8bbd                	andi	a5,a5,15
    80003880:	079a                	slli	a5,a5,0x6
    80003882:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003884:	00059783          	lh	a5,0(a1)
    80003888:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000388c:	00259783          	lh	a5,2(a1)
    80003890:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003894:	00459783          	lh	a5,4(a1)
    80003898:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000389c:	00659783          	lh	a5,6(a1)
    800038a0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038a4:	459c                	lw	a5,8(a1)
    800038a6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038a8:	03400613          	li	a2,52
    800038ac:	05b1                	addi	a1,a1,12
    800038ae:	05048513          	addi	a0,s1,80
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	49e080e7          	jalr	1182(ra) # 80000d50 <memmove>
    brelse(bp);
    800038ba:	854a                	mv	a0,s2
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	878080e7          	jalr	-1928(ra) # 80003134 <brelse>
    ip->valid = 1;
    800038c4:	4785                	li	a5,1
    800038c6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038c8:	04449783          	lh	a5,68(s1)
    800038cc:	fbb5                	bnez	a5,80003840 <ilock+0x24>
      panic("ilock: no type");
    800038ce:	00005517          	auipc	a0,0x5
    800038d2:	d8250513          	addi	a0,a0,-638 # 80008650 <syscalls+0x198>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	c6a080e7          	jalr	-918(ra) # 80000540 <panic>

00000000800038de <iunlock>:
{
    800038de:	1101                	addi	sp,sp,-32
    800038e0:	ec06                	sd	ra,24(sp)
    800038e2:	e822                	sd	s0,16(sp)
    800038e4:	e426                	sd	s1,8(sp)
    800038e6:	e04a                	sd	s2,0(sp)
    800038e8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038ea:	c905                	beqz	a0,8000391a <iunlock+0x3c>
    800038ec:	84aa                	mv	s1,a0
    800038ee:	01050913          	addi	s2,a0,16
    800038f2:	854a                	mv	a0,s2
    800038f4:	00001097          	auipc	ra,0x1
    800038f8:	c82080e7          	jalr	-894(ra) # 80004576 <holdingsleep>
    800038fc:	cd19                	beqz	a0,8000391a <iunlock+0x3c>
    800038fe:	449c                	lw	a5,8(s1)
    80003900:	00f05d63          	blez	a5,8000391a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003904:	854a                	mv	a0,s2
    80003906:	00001097          	auipc	ra,0x1
    8000390a:	c2c080e7          	jalr	-980(ra) # 80004532 <releasesleep>
}
    8000390e:	60e2                	ld	ra,24(sp)
    80003910:	6442                	ld	s0,16(sp)
    80003912:	64a2                	ld	s1,8(sp)
    80003914:	6902                	ld	s2,0(sp)
    80003916:	6105                	addi	sp,sp,32
    80003918:	8082                	ret
    panic("iunlock");
    8000391a:	00005517          	auipc	a0,0x5
    8000391e:	d4650513          	addi	a0,a0,-698 # 80008660 <syscalls+0x1a8>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	c1e080e7          	jalr	-994(ra) # 80000540 <panic>

000000008000392a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000392a:	7179                	addi	sp,sp,-48
    8000392c:	f406                	sd	ra,40(sp)
    8000392e:	f022                	sd	s0,32(sp)
    80003930:	ec26                	sd	s1,24(sp)
    80003932:	e84a                	sd	s2,16(sp)
    80003934:	e44e                	sd	s3,8(sp)
    80003936:	e052                	sd	s4,0(sp)
    80003938:	1800                	addi	s0,sp,48
    8000393a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000393c:	05050493          	addi	s1,a0,80
    80003940:	08050913          	addi	s2,a0,128
    80003944:	a021                	j	8000394c <itrunc+0x22>
    80003946:	0491                	addi	s1,s1,4
    80003948:	01248d63          	beq	s1,s2,80003962 <itrunc+0x38>
    if(ip->addrs[i]){
    8000394c:	408c                	lw	a1,0(s1)
    8000394e:	dde5                	beqz	a1,80003946 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003950:	0009a503          	lw	a0,0(s3)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	8f6080e7          	jalr	-1802(ra) # 8000324a <bfree>
      ip->addrs[i] = 0;
    8000395c:	0004a023          	sw	zero,0(s1)
    80003960:	b7dd                	j	80003946 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003962:	0809a583          	lw	a1,128(s3)
    80003966:	e185                	bnez	a1,80003986 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003968:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000396c:	854e                	mv	a0,s3
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	de2080e7          	jalr	-542(ra) # 80003750 <iupdate>
}
    80003976:	70a2                	ld	ra,40(sp)
    80003978:	7402                	ld	s0,32(sp)
    8000397a:	64e2                	ld	s1,24(sp)
    8000397c:	6942                	ld	s2,16(sp)
    8000397e:	69a2                	ld	s3,8(sp)
    80003980:	6a02                	ld	s4,0(sp)
    80003982:	6145                	addi	sp,sp,48
    80003984:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003986:	0009a503          	lw	a0,0(s3)
    8000398a:	fffff097          	auipc	ra,0xfffff
    8000398e:	67a080e7          	jalr	1658(ra) # 80003004 <bread>
    80003992:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003994:	05850493          	addi	s1,a0,88
    80003998:	45850913          	addi	s2,a0,1112
    8000399c:	a021                	j	800039a4 <itrunc+0x7a>
    8000399e:	0491                	addi	s1,s1,4
    800039a0:	01248b63          	beq	s1,s2,800039b6 <itrunc+0x8c>
      if(a[j])
    800039a4:	408c                	lw	a1,0(s1)
    800039a6:	dde5                	beqz	a1,8000399e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039a8:	0009a503          	lw	a0,0(s3)
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	89e080e7          	jalr	-1890(ra) # 8000324a <bfree>
    800039b4:	b7ed                	j	8000399e <itrunc+0x74>
    brelse(bp);
    800039b6:	8552                	mv	a0,s4
    800039b8:	fffff097          	auipc	ra,0xfffff
    800039bc:	77c080e7          	jalr	1916(ra) # 80003134 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039c0:	0809a583          	lw	a1,128(s3)
    800039c4:	0009a503          	lw	a0,0(s3)
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	882080e7          	jalr	-1918(ra) # 8000324a <bfree>
    ip->addrs[NDIRECT] = 0;
    800039d0:	0809a023          	sw	zero,128(s3)
    800039d4:	bf51                	j	80003968 <itrunc+0x3e>

00000000800039d6 <iput>:
{
    800039d6:	1101                	addi	sp,sp,-32
    800039d8:	ec06                	sd	ra,24(sp)
    800039da:	e822                	sd	s0,16(sp)
    800039dc:	e426                	sd	s1,8(sp)
    800039de:	e04a                	sd	s2,0(sp)
    800039e0:	1000                	addi	s0,sp,32
    800039e2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039e4:	0001c517          	auipc	a0,0x1c
    800039e8:	91450513          	addi	a0,a0,-1772 # 8001f2f8 <itable>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	20c080e7          	jalr	524(ra) # 80000bf8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039f4:	4498                	lw	a4,8(s1)
    800039f6:	4785                	li	a5,1
    800039f8:	02f70363          	beq	a4,a5,80003a1e <iput+0x48>
  ip->ref--;
    800039fc:	449c                	lw	a5,8(s1)
    800039fe:	37fd                	addiw	a5,a5,-1
    80003a00:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a02:	0001c517          	auipc	a0,0x1c
    80003a06:	8f650513          	addi	a0,a0,-1802 # 8001f2f8 <itable>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	2a2080e7          	jalr	674(ra) # 80000cac <release>
}
    80003a12:	60e2                	ld	ra,24(sp)
    80003a14:	6442                	ld	s0,16(sp)
    80003a16:	64a2                	ld	s1,8(sp)
    80003a18:	6902                	ld	s2,0(sp)
    80003a1a:	6105                	addi	sp,sp,32
    80003a1c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a1e:	40bc                	lw	a5,64(s1)
    80003a20:	dff1                	beqz	a5,800039fc <iput+0x26>
    80003a22:	04a49783          	lh	a5,74(s1)
    80003a26:	fbf9                	bnez	a5,800039fc <iput+0x26>
    acquiresleep(&ip->lock);
    80003a28:	01048913          	addi	s2,s1,16
    80003a2c:	854a                	mv	a0,s2
    80003a2e:	00001097          	auipc	ra,0x1
    80003a32:	aae080e7          	jalr	-1362(ra) # 800044dc <acquiresleep>
    release(&itable.lock);
    80003a36:	0001c517          	auipc	a0,0x1c
    80003a3a:	8c250513          	addi	a0,a0,-1854 # 8001f2f8 <itable>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	26e080e7          	jalr	622(ra) # 80000cac <release>
    itrunc(ip);
    80003a46:	8526                	mv	a0,s1
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	ee2080e7          	jalr	-286(ra) # 8000392a <itrunc>
    ip->type = 0;
    80003a50:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a54:	8526                	mv	a0,s1
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	cfa080e7          	jalr	-774(ra) # 80003750 <iupdate>
    ip->valid = 0;
    80003a5e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	ace080e7          	jalr	-1330(ra) # 80004532 <releasesleep>
    acquire(&itable.lock);
    80003a6c:	0001c517          	auipc	a0,0x1c
    80003a70:	88c50513          	addi	a0,a0,-1908 # 8001f2f8 <itable>
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	184080e7          	jalr	388(ra) # 80000bf8 <acquire>
    80003a7c:	b741                	j	800039fc <iput+0x26>

0000000080003a7e <iunlockput>:
{
    80003a7e:	1101                	addi	sp,sp,-32
    80003a80:	ec06                	sd	ra,24(sp)
    80003a82:	e822                	sd	s0,16(sp)
    80003a84:	e426                	sd	s1,8(sp)
    80003a86:	1000                	addi	s0,sp,32
    80003a88:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	e54080e7          	jalr	-428(ra) # 800038de <iunlock>
  iput(ip);
    80003a92:	8526                	mv	a0,s1
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	f42080e7          	jalr	-190(ra) # 800039d6 <iput>
}
    80003a9c:	60e2                	ld	ra,24(sp)
    80003a9e:	6442                	ld	s0,16(sp)
    80003aa0:	64a2                	ld	s1,8(sp)
    80003aa2:	6105                	addi	sp,sp,32
    80003aa4:	8082                	ret

0000000080003aa6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aa6:	1141                	addi	sp,sp,-16
    80003aa8:	e422                	sd	s0,8(sp)
    80003aaa:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003aac:	411c                	lw	a5,0(a0)
    80003aae:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ab0:	415c                	lw	a5,4(a0)
    80003ab2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ab4:	04451783          	lh	a5,68(a0)
    80003ab8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003abc:	04a51783          	lh	a5,74(a0)
    80003ac0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ac4:	04c56783          	lwu	a5,76(a0)
    80003ac8:	e99c                	sd	a5,16(a1)
}
    80003aca:	6422                	ld	s0,8(sp)
    80003acc:	0141                	addi	sp,sp,16
    80003ace:	8082                	ret

0000000080003ad0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ad0:	457c                	lw	a5,76(a0)
    80003ad2:	0ed7e963          	bltu	a5,a3,80003bc4 <readi+0xf4>
{
    80003ad6:	7159                	addi	sp,sp,-112
    80003ad8:	f486                	sd	ra,104(sp)
    80003ada:	f0a2                	sd	s0,96(sp)
    80003adc:	eca6                	sd	s1,88(sp)
    80003ade:	e8ca                	sd	s2,80(sp)
    80003ae0:	e4ce                	sd	s3,72(sp)
    80003ae2:	e0d2                	sd	s4,64(sp)
    80003ae4:	fc56                	sd	s5,56(sp)
    80003ae6:	f85a                	sd	s6,48(sp)
    80003ae8:	f45e                	sd	s7,40(sp)
    80003aea:	f062                	sd	s8,32(sp)
    80003aec:	ec66                	sd	s9,24(sp)
    80003aee:	e86a                	sd	s10,16(sp)
    80003af0:	e46e                	sd	s11,8(sp)
    80003af2:	1880                	addi	s0,sp,112
    80003af4:	8b2a                	mv	s6,a0
    80003af6:	8bae                	mv	s7,a1
    80003af8:	8a32                	mv	s4,a2
    80003afa:	84b6                	mv	s1,a3
    80003afc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003afe:	9f35                	addw	a4,a4,a3
    return 0;
    80003b00:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b02:	0ad76063          	bltu	a4,a3,80003ba2 <readi+0xd2>
  if(off + n > ip->size)
    80003b06:	00e7f463          	bgeu	a5,a4,80003b0e <readi+0x3e>
    n = ip->size - off;
    80003b0a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0e:	0a0a8963          	beqz	s5,80003bc0 <readi+0xf0>
    80003b12:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b14:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b18:	5c7d                	li	s8,-1
    80003b1a:	a82d                	j	80003b54 <readi+0x84>
    80003b1c:	020d1d93          	slli	s11,s10,0x20
    80003b20:	020ddd93          	srli	s11,s11,0x20
    80003b24:	05890613          	addi	a2,s2,88
    80003b28:	86ee                	mv	a3,s11
    80003b2a:	963a                	add	a2,a2,a4
    80003b2c:	85d2                	mv	a1,s4
    80003b2e:	855e                	mv	a0,s7
    80003b30:	fffff097          	auipc	ra,0xfffff
    80003b34:	952080e7          	jalr	-1710(ra) # 80002482 <either_copyout>
    80003b38:	05850d63          	beq	a0,s8,80003b92 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b3c:	854a                	mv	a0,s2
    80003b3e:	fffff097          	auipc	ra,0xfffff
    80003b42:	5f6080e7          	jalr	1526(ra) # 80003134 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b46:	013d09bb          	addw	s3,s10,s3
    80003b4a:	009d04bb          	addw	s1,s10,s1
    80003b4e:	9a6e                	add	s4,s4,s11
    80003b50:	0559f763          	bgeu	s3,s5,80003b9e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b54:	00a4d59b          	srliw	a1,s1,0xa
    80003b58:	855a                	mv	a0,s6
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	89e080e7          	jalr	-1890(ra) # 800033f8 <bmap>
    80003b62:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b66:	cd85                	beqz	a1,80003b9e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b68:	000b2503          	lw	a0,0(s6)
    80003b6c:	fffff097          	auipc	ra,0xfffff
    80003b70:	498080e7          	jalr	1176(ra) # 80003004 <bread>
    80003b74:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b76:	3ff4f713          	andi	a4,s1,1023
    80003b7a:	40ec87bb          	subw	a5,s9,a4
    80003b7e:	413a86bb          	subw	a3,s5,s3
    80003b82:	8d3e                	mv	s10,a5
    80003b84:	2781                	sext.w	a5,a5
    80003b86:	0006861b          	sext.w	a2,a3
    80003b8a:	f8f679e3          	bgeu	a2,a5,80003b1c <readi+0x4c>
    80003b8e:	8d36                	mv	s10,a3
    80003b90:	b771                	j	80003b1c <readi+0x4c>
      brelse(bp);
    80003b92:	854a                	mv	a0,s2
    80003b94:	fffff097          	auipc	ra,0xfffff
    80003b98:	5a0080e7          	jalr	1440(ra) # 80003134 <brelse>
      tot = -1;
    80003b9c:	59fd                	li	s3,-1
  }
  return tot;
    80003b9e:	0009851b          	sext.w	a0,s3
}
    80003ba2:	70a6                	ld	ra,104(sp)
    80003ba4:	7406                	ld	s0,96(sp)
    80003ba6:	64e6                	ld	s1,88(sp)
    80003ba8:	6946                	ld	s2,80(sp)
    80003baa:	69a6                	ld	s3,72(sp)
    80003bac:	6a06                	ld	s4,64(sp)
    80003bae:	7ae2                	ld	s5,56(sp)
    80003bb0:	7b42                	ld	s6,48(sp)
    80003bb2:	7ba2                	ld	s7,40(sp)
    80003bb4:	7c02                	ld	s8,32(sp)
    80003bb6:	6ce2                	ld	s9,24(sp)
    80003bb8:	6d42                	ld	s10,16(sp)
    80003bba:	6da2                	ld	s11,8(sp)
    80003bbc:	6165                	addi	sp,sp,112
    80003bbe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc0:	89d6                	mv	s3,s5
    80003bc2:	bff1                	j	80003b9e <readi+0xce>
    return 0;
    80003bc4:	4501                	li	a0,0
}
    80003bc6:	8082                	ret

0000000080003bc8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bc8:	457c                	lw	a5,76(a0)
    80003bca:	10d7e863          	bltu	a5,a3,80003cda <writei+0x112>
{
    80003bce:	7159                	addi	sp,sp,-112
    80003bd0:	f486                	sd	ra,104(sp)
    80003bd2:	f0a2                	sd	s0,96(sp)
    80003bd4:	eca6                	sd	s1,88(sp)
    80003bd6:	e8ca                	sd	s2,80(sp)
    80003bd8:	e4ce                	sd	s3,72(sp)
    80003bda:	e0d2                	sd	s4,64(sp)
    80003bdc:	fc56                	sd	s5,56(sp)
    80003bde:	f85a                	sd	s6,48(sp)
    80003be0:	f45e                	sd	s7,40(sp)
    80003be2:	f062                	sd	s8,32(sp)
    80003be4:	ec66                	sd	s9,24(sp)
    80003be6:	e86a                	sd	s10,16(sp)
    80003be8:	e46e                	sd	s11,8(sp)
    80003bea:	1880                	addi	s0,sp,112
    80003bec:	8aaa                	mv	s5,a0
    80003bee:	8bae                	mv	s7,a1
    80003bf0:	8a32                	mv	s4,a2
    80003bf2:	8936                	mv	s2,a3
    80003bf4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bf6:	00e687bb          	addw	a5,a3,a4
    80003bfa:	0ed7e263          	bltu	a5,a3,80003cde <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bfe:	00043737          	lui	a4,0x43
    80003c02:	0ef76063          	bltu	a4,a5,80003ce2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c06:	0c0b0863          	beqz	s6,80003cd6 <writei+0x10e>
    80003c0a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c0c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c10:	5c7d                	li	s8,-1
    80003c12:	a091                	j	80003c56 <writei+0x8e>
    80003c14:	020d1d93          	slli	s11,s10,0x20
    80003c18:	020ddd93          	srli	s11,s11,0x20
    80003c1c:	05848513          	addi	a0,s1,88
    80003c20:	86ee                	mv	a3,s11
    80003c22:	8652                	mv	a2,s4
    80003c24:	85de                	mv	a1,s7
    80003c26:	953a                	add	a0,a0,a4
    80003c28:	fffff097          	auipc	ra,0xfffff
    80003c2c:	8b0080e7          	jalr	-1872(ra) # 800024d8 <either_copyin>
    80003c30:	07850263          	beq	a0,s8,80003c94 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c34:	8526                	mv	a0,s1
    80003c36:	00000097          	auipc	ra,0x0
    80003c3a:	788080e7          	jalr	1928(ra) # 800043be <log_write>
    brelse(bp);
    80003c3e:	8526                	mv	a0,s1
    80003c40:	fffff097          	auipc	ra,0xfffff
    80003c44:	4f4080e7          	jalr	1268(ra) # 80003134 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c48:	013d09bb          	addw	s3,s10,s3
    80003c4c:	012d093b          	addw	s2,s10,s2
    80003c50:	9a6e                	add	s4,s4,s11
    80003c52:	0569f663          	bgeu	s3,s6,80003c9e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c56:	00a9559b          	srliw	a1,s2,0xa
    80003c5a:	8556                	mv	a0,s5
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	79c080e7          	jalr	1948(ra) # 800033f8 <bmap>
    80003c64:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c68:	c99d                	beqz	a1,80003c9e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c6a:	000aa503          	lw	a0,0(s5)
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	396080e7          	jalr	918(ra) # 80003004 <bread>
    80003c76:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c78:	3ff97713          	andi	a4,s2,1023
    80003c7c:	40ec87bb          	subw	a5,s9,a4
    80003c80:	413b06bb          	subw	a3,s6,s3
    80003c84:	8d3e                	mv	s10,a5
    80003c86:	2781                	sext.w	a5,a5
    80003c88:	0006861b          	sext.w	a2,a3
    80003c8c:	f8f674e3          	bgeu	a2,a5,80003c14 <writei+0x4c>
    80003c90:	8d36                	mv	s10,a3
    80003c92:	b749                	j	80003c14 <writei+0x4c>
      brelse(bp);
    80003c94:	8526                	mv	a0,s1
    80003c96:	fffff097          	auipc	ra,0xfffff
    80003c9a:	49e080e7          	jalr	1182(ra) # 80003134 <brelse>
  }

  if(off > ip->size)
    80003c9e:	04caa783          	lw	a5,76(s5)
    80003ca2:	0127f463          	bgeu	a5,s2,80003caa <writei+0xe2>
    ip->size = off;
    80003ca6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003caa:	8556                	mv	a0,s5
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	aa4080e7          	jalr	-1372(ra) # 80003750 <iupdate>

  return tot;
    80003cb4:	0009851b          	sext.w	a0,s3
}
    80003cb8:	70a6                	ld	ra,104(sp)
    80003cba:	7406                	ld	s0,96(sp)
    80003cbc:	64e6                	ld	s1,88(sp)
    80003cbe:	6946                	ld	s2,80(sp)
    80003cc0:	69a6                	ld	s3,72(sp)
    80003cc2:	6a06                	ld	s4,64(sp)
    80003cc4:	7ae2                	ld	s5,56(sp)
    80003cc6:	7b42                	ld	s6,48(sp)
    80003cc8:	7ba2                	ld	s7,40(sp)
    80003cca:	7c02                	ld	s8,32(sp)
    80003ccc:	6ce2                	ld	s9,24(sp)
    80003cce:	6d42                	ld	s10,16(sp)
    80003cd0:	6da2                	ld	s11,8(sp)
    80003cd2:	6165                	addi	sp,sp,112
    80003cd4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cd6:	89da                	mv	s3,s6
    80003cd8:	bfc9                	j	80003caa <writei+0xe2>
    return -1;
    80003cda:	557d                	li	a0,-1
}
    80003cdc:	8082                	ret
    return -1;
    80003cde:	557d                	li	a0,-1
    80003ce0:	bfe1                	j	80003cb8 <writei+0xf0>
    return -1;
    80003ce2:	557d                	li	a0,-1
    80003ce4:	bfd1                	j	80003cb8 <writei+0xf0>

0000000080003ce6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ce6:	1141                	addi	sp,sp,-16
    80003ce8:	e406                	sd	ra,8(sp)
    80003cea:	e022                	sd	s0,0(sp)
    80003cec:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cee:	4639                	li	a2,14
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	0d4080e7          	jalr	212(ra) # 80000dc4 <strncmp>
}
    80003cf8:	60a2                	ld	ra,8(sp)
    80003cfa:	6402                	ld	s0,0(sp)
    80003cfc:	0141                	addi	sp,sp,16
    80003cfe:	8082                	ret

0000000080003d00 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d00:	7139                	addi	sp,sp,-64
    80003d02:	fc06                	sd	ra,56(sp)
    80003d04:	f822                	sd	s0,48(sp)
    80003d06:	f426                	sd	s1,40(sp)
    80003d08:	f04a                	sd	s2,32(sp)
    80003d0a:	ec4e                	sd	s3,24(sp)
    80003d0c:	e852                	sd	s4,16(sp)
    80003d0e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d10:	04451703          	lh	a4,68(a0)
    80003d14:	4785                	li	a5,1
    80003d16:	00f71a63          	bne	a4,a5,80003d2a <dirlookup+0x2a>
    80003d1a:	892a                	mv	s2,a0
    80003d1c:	89ae                	mv	s3,a1
    80003d1e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d20:	457c                	lw	a5,76(a0)
    80003d22:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d24:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d26:	e79d                	bnez	a5,80003d54 <dirlookup+0x54>
    80003d28:	a8a5                	j	80003da0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d2a:	00005517          	auipc	a0,0x5
    80003d2e:	93e50513          	addi	a0,a0,-1730 # 80008668 <syscalls+0x1b0>
    80003d32:	ffffd097          	auipc	ra,0xffffd
    80003d36:	80e080e7          	jalr	-2034(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003d3a:	00005517          	auipc	a0,0x5
    80003d3e:	94650513          	addi	a0,a0,-1722 # 80008680 <syscalls+0x1c8>
    80003d42:	ffffc097          	auipc	ra,0xffffc
    80003d46:	7fe080e7          	jalr	2046(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4a:	24c1                	addiw	s1,s1,16
    80003d4c:	04c92783          	lw	a5,76(s2)
    80003d50:	04f4f763          	bgeu	s1,a5,80003d9e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d54:	4741                	li	a4,16
    80003d56:	86a6                	mv	a3,s1
    80003d58:	fc040613          	addi	a2,s0,-64
    80003d5c:	4581                	li	a1,0
    80003d5e:	854a                	mv	a0,s2
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	d70080e7          	jalr	-656(ra) # 80003ad0 <readi>
    80003d68:	47c1                	li	a5,16
    80003d6a:	fcf518e3          	bne	a0,a5,80003d3a <dirlookup+0x3a>
    if(de.inum == 0)
    80003d6e:	fc045783          	lhu	a5,-64(s0)
    80003d72:	dfe1                	beqz	a5,80003d4a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d74:	fc240593          	addi	a1,s0,-62
    80003d78:	854e                	mv	a0,s3
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	f6c080e7          	jalr	-148(ra) # 80003ce6 <namecmp>
    80003d82:	f561                	bnez	a0,80003d4a <dirlookup+0x4a>
      if(poff)
    80003d84:	000a0463          	beqz	s4,80003d8c <dirlookup+0x8c>
        *poff = off;
    80003d88:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d8c:	fc045583          	lhu	a1,-64(s0)
    80003d90:	00092503          	lw	a0,0(s2)
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	74e080e7          	jalr	1870(ra) # 800034e2 <iget>
    80003d9c:	a011                	j	80003da0 <dirlookup+0xa0>
  return 0;
    80003d9e:	4501                	li	a0,0
}
    80003da0:	70e2                	ld	ra,56(sp)
    80003da2:	7442                	ld	s0,48(sp)
    80003da4:	74a2                	ld	s1,40(sp)
    80003da6:	7902                	ld	s2,32(sp)
    80003da8:	69e2                	ld	s3,24(sp)
    80003daa:	6a42                	ld	s4,16(sp)
    80003dac:	6121                	addi	sp,sp,64
    80003dae:	8082                	ret

0000000080003db0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003db0:	711d                	addi	sp,sp,-96
    80003db2:	ec86                	sd	ra,88(sp)
    80003db4:	e8a2                	sd	s0,80(sp)
    80003db6:	e4a6                	sd	s1,72(sp)
    80003db8:	e0ca                	sd	s2,64(sp)
    80003dba:	fc4e                	sd	s3,56(sp)
    80003dbc:	f852                	sd	s4,48(sp)
    80003dbe:	f456                	sd	s5,40(sp)
    80003dc0:	f05a                	sd	s6,32(sp)
    80003dc2:	ec5e                	sd	s7,24(sp)
    80003dc4:	e862                	sd	s8,16(sp)
    80003dc6:	e466                	sd	s9,8(sp)
    80003dc8:	e06a                	sd	s10,0(sp)
    80003dca:	1080                	addi	s0,sp,96
    80003dcc:	84aa                	mv	s1,a0
    80003dce:	8b2e                	mv	s6,a1
    80003dd0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dd2:	00054703          	lbu	a4,0(a0)
    80003dd6:	02f00793          	li	a5,47
    80003dda:	02f70363          	beq	a4,a5,80003e00 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dde:	ffffe097          	auipc	ra,0xffffe
    80003de2:	bf0080e7          	jalr	-1040(ra) # 800019ce <myproc>
    80003de6:	15053503          	ld	a0,336(a0)
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	9f4080e7          	jalr	-1548(ra) # 800037de <idup>
    80003df2:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003df4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003df8:	4cb5                	li	s9,13
  len = path - s;
    80003dfa:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dfc:	4c05                	li	s8,1
    80003dfe:	a87d                	j	80003ebc <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003e00:	4585                	li	a1,1
    80003e02:	4505                	li	a0,1
    80003e04:	fffff097          	auipc	ra,0xfffff
    80003e08:	6de080e7          	jalr	1758(ra) # 800034e2 <iget>
    80003e0c:	8a2a                	mv	s4,a0
    80003e0e:	b7dd                	j	80003df4 <namex+0x44>
      iunlockput(ip);
    80003e10:	8552                	mv	a0,s4
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	c6c080e7          	jalr	-916(ra) # 80003a7e <iunlockput>
      return 0;
    80003e1a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e1c:	8552                	mv	a0,s4
    80003e1e:	60e6                	ld	ra,88(sp)
    80003e20:	6446                	ld	s0,80(sp)
    80003e22:	64a6                	ld	s1,72(sp)
    80003e24:	6906                	ld	s2,64(sp)
    80003e26:	79e2                	ld	s3,56(sp)
    80003e28:	7a42                	ld	s4,48(sp)
    80003e2a:	7aa2                	ld	s5,40(sp)
    80003e2c:	7b02                	ld	s6,32(sp)
    80003e2e:	6be2                	ld	s7,24(sp)
    80003e30:	6c42                	ld	s8,16(sp)
    80003e32:	6ca2                	ld	s9,8(sp)
    80003e34:	6d02                	ld	s10,0(sp)
    80003e36:	6125                	addi	sp,sp,96
    80003e38:	8082                	ret
      iunlock(ip);
    80003e3a:	8552                	mv	a0,s4
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	aa2080e7          	jalr	-1374(ra) # 800038de <iunlock>
      return ip;
    80003e44:	bfe1                	j	80003e1c <namex+0x6c>
      iunlockput(ip);
    80003e46:	8552                	mv	a0,s4
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	c36080e7          	jalr	-970(ra) # 80003a7e <iunlockput>
      return 0;
    80003e50:	8a4e                	mv	s4,s3
    80003e52:	b7e9                	j	80003e1c <namex+0x6c>
  len = path - s;
    80003e54:	40998633          	sub	a2,s3,s1
    80003e58:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e5c:	09acd863          	bge	s9,s10,80003eec <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e60:	4639                	li	a2,14
    80003e62:	85a6                	mv	a1,s1
    80003e64:	8556                	mv	a0,s5
    80003e66:	ffffd097          	auipc	ra,0xffffd
    80003e6a:	eea080e7          	jalr	-278(ra) # 80000d50 <memmove>
    80003e6e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	01279763          	bne	a5,s2,80003e82 <namex+0xd2>
    path++;
    80003e78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e7a:	0004c783          	lbu	a5,0(s1)
    80003e7e:	ff278de3          	beq	a5,s2,80003e78 <namex+0xc8>
    ilock(ip);
    80003e82:	8552                	mv	a0,s4
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	998080e7          	jalr	-1640(ra) # 8000381c <ilock>
    if(ip->type != T_DIR){
    80003e8c:	044a1783          	lh	a5,68(s4)
    80003e90:	f98790e3          	bne	a5,s8,80003e10 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e94:	000b0563          	beqz	s6,80003e9e <namex+0xee>
    80003e98:	0004c783          	lbu	a5,0(s1)
    80003e9c:	dfd9                	beqz	a5,80003e3a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e9e:	865e                	mv	a2,s7
    80003ea0:	85d6                	mv	a1,s5
    80003ea2:	8552                	mv	a0,s4
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	e5c080e7          	jalr	-420(ra) # 80003d00 <dirlookup>
    80003eac:	89aa                	mv	s3,a0
    80003eae:	dd41                	beqz	a0,80003e46 <namex+0x96>
    iunlockput(ip);
    80003eb0:	8552                	mv	a0,s4
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	bcc080e7          	jalr	-1076(ra) # 80003a7e <iunlockput>
    ip = next;
    80003eba:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	01279763          	bne	a5,s2,80003ece <namex+0x11e>
    path++;
    80003ec4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ec6:	0004c783          	lbu	a5,0(s1)
    80003eca:	ff278de3          	beq	a5,s2,80003ec4 <namex+0x114>
  if(*path == 0)
    80003ece:	cb9d                	beqz	a5,80003f04 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003ed0:	0004c783          	lbu	a5,0(s1)
    80003ed4:	89a6                	mv	s3,s1
  len = path - s;
    80003ed6:	8d5e                	mv	s10,s7
    80003ed8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003eda:	01278963          	beq	a5,s2,80003eec <namex+0x13c>
    80003ede:	dbbd                	beqz	a5,80003e54 <namex+0xa4>
    path++;
    80003ee0:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ee2:	0009c783          	lbu	a5,0(s3)
    80003ee6:	ff279ce3          	bne	a5,s2,80003ede <namex+0x12e>
    80003eea:	b7ad                	j	80003e54 <namex+0xa4>
    memmove(name, s, len);
    80003eec:	2601                	sext.w	a2,a2
    80003eee:	85a6                	mv	a1,s1
    80003ef0:	8556                	mv	a0,s5
    80003ef2:	ffffd097          	auipc	ra,0xffffd
    80003ef6:	e5e080e7          	jalr	-418(ra) # 80000d50 <memmove>
    name[len] = 0;
    80003efa:	9d56                	add	s10,s10,s5
    80003efc:	000d0023          	sb	zero,0(s10)
    80003f00:	84ce                	mv	s1,s3
    80003f02:	b7bd                	j	80003e70 <namex+0xc0>
  if(nameiparent){
    80003f04:	f00b0ce3          	beqz	s6,80003e1c <namex+0x6c>
    iput(ip);
    80003f08:	8552                	mv	a0,s4
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	acc080e7          	jalr	-1332(ra) # 800039d6 <iput>
    return 0;
    80003f12:	4a01                	li	s4,0
    80003f14:	b721                	j	80003e1c <namex+0x6c>

0000000080003f16 <dirlink>:
{
    80003f16:	7139                	addi	sp,sp,-64
    80003f18:	fc06                	sd	ra,56(sp)
    80003f1a:	f822                	sd	s0,48(sp)
    80003f1c:	f426                	sd	s1,40(sp)
    80003f1e:	f04a                	sd	s2,32(sp)
    80003f20:	ec4e                	sd	s3,24(sp)
    80003f22:	e852                	sd	s4,16(sp)
    80003f24:	0080                	addi	s0,sp,64
    80003f26:	892a                	mv	s2,a0
    80003f28:	8a2e                	mv	s4,a1
    80003f2a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f2c:	4601                	li	a2,0
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	dd2080e7          	jalr	-558(ra) # 80003d00 <dirlookup>
    80003f36:	e93d                	bnez	a0,80003fac <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f38:	04c92483          	lw	s1,76(s2)
    80003f3c:	c49d                	beqz	s1,80003f6a <dirlink+0x54>
    80003f3e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f40:	4741                	li	a4,16
    80003f42:	86a6                	mv	a3,s1
    80003f44:	fc040613          	addi	a2,s0,-64
    80003f48:	4581                	li	a1,0
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	b84080e7          	jalr	-1148(ra) # 80003ad0 <readi>
    80003f54:	47c1                	li	a5,16
    80003f56:	06f51163          	bne	a0,a5,80003fb8 <dirlink+0xa2>
    if(de.inum == 0)
    80003f5a:	fc045783          	lhu	a5,-64(s0)
    80003f5e:	c791                	beqz	a5,80003f6a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f60:	24c1                	addiw	s1,s1,16
    80003f62:	04c92783          	lw	a5,76(s2)
    80003f66:	fcf4ede3          	bltu	s1,a5,80003f40 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f6a:	4639                	li	a2,14
    80003f6c:	85d2                	mv	a1,s4
    80003f6e:	fc240513          	addi	a0,s0,-62
    80003f72:	ffffd097          	auipc	ra,0xffffd
    80003f76:	e8e080e7          	jalr	-370(ra) # 80000e00 <strncpy>
  de.inum = inum;
    80003f7a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7e:	4741                	li	a4,16
    80003f80:	86a6                	mv	a3,s1
    80003f82:	fc040613          	addi	a2,s0,-64
    80003f86:	4581                	li	a1,0
    80003f88:	854a                	mv	a0,s2
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	c3e080e7          	jalr	-962(ra) # 80003bc8 <writei>
    80003f92:	1541                	addi	a0,a0,-16
    80003f94:	00a03533          	snez	a0,a0
    80003f98:	40a00533          	neg	a0,a0
}
    80003f9c:	70e2                	ld	ra,56(sp)
    80003f9e:	7442                	ld	s0,48(sp)
    80003fa0:	74a2                	ld	s1,40(sp)
    80003fa2:	7902                	ld	s2,32(sp)
    80003fa4:	69e2                	ld	s3,24(sp)
    80003fa6:	6a42                	ld	s4,16(sp)
    80003fa8:	6121                	addi	sp,sp,64
    80003faa:	8082                	ret
    iput(ip);
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	a2a080e7          	jalr	-1494(ra) # 800039d6 <iput>
    return -1;
    80003fb4:	557d                	li	a0,-1
    80003fb6:	b7dd                	j	80003f9c <dirlink+0x86>
      panic("dirlink read");
    80003fb8:	00004517          	auipc	a0,0x4
    80003fbc:	6d850513          	addi	a0,a0,1752 # 80008690 <syscalls+0x1d8>
    80003fc0:	ffffc097          	auipc	ra,0xffffc
    80003fc4:	580080e7          	jalr	1408(ra) # 80000540 <panic>

0000000080003fc8 <namei>:

struct inode*
namei(char *path)
{
    80003fc8:	1101                	addi	sp,sp,-32
    80003fca:	ec06                	sd	ra,24(sp)
    80003fcc:	e822                	sd	s0,16(sp)
    80003fce:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fd0:	fe040613          	addi	a2,s0,-32
    80003fd4:	4581                	li	a1,0
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	dda080e7          	jalr	-550(ra) # 80003db0 <namex>
}
    80003fde:	60e2                	ld	ra,24(sp)
    80003fe0:	6442                	ld	s0,16(sp)
    80003fe2:	6105                	addi	sp,sp,32
    80003fe4:	8082                	ret

0000000080003fe6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fe6:	1141                	addi	sp,sp,-16
    80003fe8:	e406                	sd	ra,8(sp)
    80003fea:	e022                	sd	s0,0(sp)
    80003fec:	0800                	addi	s0,sp,16
    80003fee:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ff0:	4585                	li	a1,1
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	dbe080e7          	jalr	-578(ra) # 80003db0 <namex>
}
    80003ffa:	60a2                	ld	ra,8(sp)
    80003ffc:	6402                	ld	s0,0(sp)
    80003ffe:	0141                	addi	sp,sp,16
    80004000:	8082                	ret

0000000080004002 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004002:	1101                	addi	sp,sp,-32
    80004004:	ec06                	sd	ra,24(sp)
    80004006:	e822                	sd	s0,16(sp)
    80004008:	e426                	sd	s1,8(sp)
    8000400a:	e04a                	sd	s2,0(sp)
    8000400c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000400e:	0001d917          	auipc	s2,0x1d
    80004012:	d9290913          	addi	s2,s2,-622 # 80020da0 <log>
    80004016:	01892583          	lw	a1,24(s2)
    8000401a:	02892503          	lw	a0,40(s2)
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	fe6080e7          	jalr	-26(ra) # 80003004 <bread>
    80004026:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004028:	02c92683          	lw	a3,44(s2)
    8000402c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000402e:	02d05863          	blez	a3,8000405e <write_head+0x5c>
    80004032:	0001d797          	auipc	a5,0x1d
    80004036:	d9e78793          	addi	a5,a5,-610 # 80020dd0 <log+0x30>
    8000403a:	05c50713          	addi	a4,a0,92
    8000403e:	36fd                	addiw	a3,a3,-1
    80004040:	02069613          	slli	a2,a3,0x20
    80004044:	01e65693          	srli	a3,a2,0x1e
    80004048:	0001d617          	auipc	a2,0x1d
    8000404c:	d8c60613          	addi	a2,a2,-628 # 80020dd4 <log+0x34>
    80004050:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004052:	4390                	lw	a2,0(a5)
    80004054:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004056:	0791                	addi	a5,a5,4
    80004058:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000405a:	fed79ce3          	bne	a5,a3,80004052 <write_head+0x50>
  }
  bwrite(buf);
    8000405e:	8526                	mv	a0,s1
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	096080e7          	jalr	150(ra) # 800030f6 <bwrite>
  brelse(buf);
    80004068:	8526                	mv	a0,s1
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	0ca080e7          	jalr	202(ra) # 80003134 <brelse>
}
    80004072:	60e2                	ld	ra,24(sp)
    80004074:	6442                	ld	s0,16(sp)
    80004076:	64a2                	ld	s1,8(sp)
    80004078:	6902                	ld	s2,0(sp)
    8000407a:	6105                	addi	sp,sp,32
    8000407c:	8082                	ret

000000008000407e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407e:	0001d797          	auipc	a5,0x1d
    80004082:	d4e7a783          	lw	a5,-690(a5) # 80020dcc <log+0x2c>
    80004086:	0af05d63          	blez	a5,80004140 <install_trans+0xc2>
{
    8000408a:	7139                	addi	sp,sp,-64
    8000408c:	fc06                	sd	ra,56(sp)
    8000408e:	f822                	sd	s0,48(sp)
    80004090:	f426                	sd	s1,40(sp)
    80004092:	f04a                	sd	s2,32(sp)
    80004094:	ec4e                	sd	s3,24(sp)
    80004096:	e852                	sd	s4,16(sp)
    80004098:	e456                	sd	s5,8(sp)
    8000409a:	e05a                	sd	s6,0(sp)
    8000409c:	0080                	addi	s0,sp,64
    8000409e:	8b2a                	mv	s6,a0
    800040a0:	0001da97          	auipc	s5,0x1d
    800040a4:	d30a8a93          	addi	s5,s5,-720 # 80020dd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040aa:	0001d997          	auipc	s3,0x1d
    800040ae:	cf698993          	addi	s3,s3,-778 # 80020da0 <log>
    800040b2:	a00d                	j	800040d4 <install_trans+0x56>
    brelse(lbuf);
    800040b4:	854a                	mv	a0,s2
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	07e080e7          	jalr	126(ra) # 80003134 <brelse>
    brelse(dbuf);
    800040be:	8526                	mv	a0,s1
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	074080e7          	jalr	116(ra) # 80003134 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c8:	2a05                	addiw	s4,s4,1
    800040ca:	0a91                	addi	s5,s5,4
    800040cc:	02c9a783          	lw	a5,44(s3)
    800040d0:	04fa5e63          	bge	s4,a5,8000412c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040d4:	0189a583          	lw	a1,24(s3)
    800040d8:	014585bb          	addw	a1,a1,s4
    800040dc:	2585                	addiw	a1,a1,1
    800040de:	0289a503          	lw	a0,40(s3)
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	f22080e7          	jalr	-222(ra) # 80003004 <bread>
    800040ea:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040ec:	000aa583          	lw	a1,0(s5)
    800040f0:	0289a503          	lw	a0,40(s3)
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	f10080e7          	jalr	-240(ra) # 80003004 <bread>
    800040fc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040fe:	40000613          	li	a2,1024
    80004102:	05890593          	addi	a1,s2,88
    80004106:	05850513          	addi	a0,a0,88
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	c46080e7          	jalr	-954(ra) # 80000d50 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004112:	8526                	mv	a0,s1
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	fe2080e7          	jalr	-30(ra) # 800030f6 <bwrite>
    if(recovering == 0)
    8000411c:	f80b1ce3          	bnez	s6,800040b4 <install_trans+0x36>
      bunpin(dbuf);
    80004120:	8526                	mv	a0,s1
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	0ec080e7          	jalr	236(ra) # 8000320e <bunpin>
    8000412a:	b769                	j	800040b4 <install_trans+0x36>
}
    8000412c:	70e2                	ld	ra,56(sp)
    8000412e:	7442                	ld	s0,48(sp)
    80004130:	74a2                	ld	s1,40(sp)
    80004132:	7902                	ld	s2,32(sp)
    80004134:	69e2                	ld	s3,24(sp)
    80004136:	6a42                	ld	s4,16(sp)
    80004138:	6aa2                	ld	s5,8(sp)
    8000413a:	6b02                	ld	s6,0(sp)
    8000413c:	6121                	addi	sp,sp,64
    8000413e:	8082                	ret
    80004140:	8082                	ret

0000000080004142 <initlog>:
{
    80004142:	7179                	addi	sp,sp,-48
    80004144:	f406                	sd	ra,40(sp)
    80004146:	f022                	sd	s0,32(sp)
    80004148:	ec26                	sd	s1,24(sp)
    8000414a:	e84a                	sd	s2,16(sp)
    8000414c:	e44e                	sd	s3,8(sp)
    8000414e:	1800                	addi	s0,sp,48
    80004150:	892a                	mv	s2,a0
    80004152:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004154:	0001d497          	auipc	s1,0x1d
    80004158:	c4c48493          	addi	s1,s1,-948 # 80020da0 <log>
    8000415c:	00004597          	auipc	a1,0x4
    80004160:	54458593          	addi	a1,a1,1348 # 800086a0 <syscalls+0x1e8>
    80004164:	8526                	mv	a0,s1
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	a02080e7          	jalr	-1534(ra) # 80000b68 <initlock>
  log.start = sb->logstart;
    8000416e:	0149a583          	lw	a1,20(s3)
    80004172:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004174:	0109a783          	lw	a5,16(s3)
    80004178:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000417a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000417e:	854a                	mv	a0,s2
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	e84080e7          	jalr	-380(ra) # 80003004 <bread>
  log.lh.n = lh->n;
    80004188:	4d34                	lw	a3,88(a0)
    8000418a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000418c:	02d05663          	blez	a3,800041b8 <initlog+0x76>
    80004190:	05c50793          	addi	a5,a0,92
    80004194:	0001d717          	auipc	a4,0x1d
    80004198:	c3c70713          	addi	a4,a4,-964 # 80020dd0 <log+0x30>
    8000419c:	36fd                	addiw	a3,a3,-1
    8000419e:	02069613          	slli	a2,a3,0x20
    800041a2:	01e65693          	srli	a3,a2,0x1e
    800041a6:	06050613          	addi	a2,a0,96
    800041aa:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041ac:	4390                	lw	a2,0(a5)
    800041ae:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041b0:	0791                	addi	a5,a5,4
    800041b2:	0711                	addi	a4,a4,4
    800041b4:	fed79ce3          	bne	a5,a3,800041ac <initlog+0x6a>
  brelse(buf);
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	f7c080e7          	jalr	-132(ra) # 80003134 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041c0:	4505                	li	a0,1
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	ebc080e7          	jalr	-324(ra) # 8000407e <install_trans>
  log.lh.n = 0;
    800041ca:	0001d797          	auipc	a5,0x1d
    800041ce:	c007a123          	sw	zero,-1022(a5) # 80020dcc <log+0x2c>
  write_head(); // clear the log
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	e30080e7          	jalr	-464(ra) # 80004002 <write_head>
}
    800041da:	70a2                	ld	ra,40(sp)
    800041dc:	7402                	ld	s0,32(sp)
    800041de:	64e2                	ld	s1,24(sp)
    800041e0:	6942                	ld	s2,16(sp)
    800041e2:	69a2                	ld	s3,8(sp)
    800041e4:	6145                	addi	sp,sp,48
    800041e6:	8082                	ret

00000000800041e8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041e8:	1101                	addi	sp,sp,-32
    800041ea:	ec06                	sd	ra,24(sp)
    800041ec:	e822                	sd	s0,16(sp)
    800041ee:	e426                	sd	s1,8(sp)
    800041f0:	e04a                	sd	s2,0(sp)
    800041f2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041f4:	0001d517          	auipc	a0,0x1d
    800041f8:	bac50513          	addi	a0,a0,-1108 # 80020da0 <log>
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	9fc080e7          	jalr	-1540(ra) # 80000bf8 <acquire>
  while(1){
    if(log.committing){
    80004204:	0001d497          	auipc	s1,0x1d
    80004208:	b9c48493          	addi	s1,s1,-1124 # 80020da0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000420c:	4979                	li	s2,30
    8000420e:	a039                	j	8000421c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004210:	85a6                	mv	a1,s1
    80004212:	8526                	mv	a0,s1
    80004214:	ffffe097          	auipc	ra,0xffffe
    80004218:	e66080e7          	jalr	-410(ra) # 8000207a <sleep>
    if(log.committing){
    8000421c:	50dc                	lw	a5,36(s1)
    8000421e:	fbed                	bnez	a5,80004210 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004220:	5098                	lw	a4,32(s1)
    80004222:	2705                	addiw	a4,a4,1
    80004224:	0007069b          	sext.w	a3,a4
    80004228:	0027179b          	slliw	a5,a4,0x2
    8000422c:	9fb9                	addw	a5,a5,a4
    8000422e:	0017979b          	slliw	a5,a5,0x1
    80004232:	54d8                	lw	a4,44(s1)
    80004234:	9fb9                	addw	a5,a5,a4
    80004236:	00f95963          	bge	s2,a5,80004248 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000423a:	85a6                	mv	a1,s1
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffe097          	auipc	ra,0xffffe
    80004242:	e3c080e7          	jalr	-452(ra) # 8000207a <sleep>
    80004246:	bfd9                	j	8000421c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004248:	0001d517          	auipc	a0,0x1d
    8000424c:	b5850513          	addi	a0,a0,-1192 # 80020da0 <log>
    80004250:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	a5a080e7          	jalr	-1446(ra) # 80000cac <release>
      break;
    }
  }
}
    8000425a:	60e2                	ld	ra,24(sp)
    8000425c:	6442                	ld	s0,16(sp)
    8000425e:	64a2                	ld	s1,8(sp)
    80004260:	6902                	ld	s2,0(sp)
    80004262:	6105                	addi	sp,sp,32
    80004264:	8082                	ret

0000000080004266 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004266:	7139                	addi	sp,sp,-64
    80004268:	fc06                	sd	ra,56(sp)
    8000426a:	f822                	sd	s0,48(sp)
    8000426c:	f426                	sd	s1,40(sp)
    8000426e:	f04a                	sd	s2,32(sp)
    80004270:	ec4e                	sd	s3,24(sp)
    80004272:	e852                	sd	s4,16(sp)
    80004274:	e456                	sd	s5,8(sp)
    80004276:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004278:	0001d497          	auipc	s1,0x1d
    8000427c:	b2848493          	addi	s1,s1,-1240 # 80020da0 <log>
    80004280:	8526                	mv	a0,s1
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	976080e7          	jalr	-1674(ra) # 80000bf8 <acquire>
  log.outstanding -= 1;
    8000428a:	509c                	lw	a5,32(s1)
    8000428c:	37fd                	addiw	a5,a5,-1
    8000428e:	0007891b          	sext.w	s2,a5
    80004292:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004294:	50dc                	lw	a5,36(s1)
    80004296:	e7b9                	bnez	a5,800042e4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004298:	04091e63          	bnez	s2,800042f4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000429c:	0001d497          	auipc	s1,0x1d
    800042a0:	b0448493          	addi	s1,s1,-1276 # 80020da0 <log>
    800042a4:	4785                	li	a5,1
    800042a6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042a8:	8526                	mv	a0,s1
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	a02080e7          	jalr	-1534(ra) # 80000cac <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042b2:	54dc                	lw	a5,44(s1)
    800042b4:	06f04763          	bgtz	a5,80004322 <end_op+0xbc>
    acquire(&log.lock);
    800042b8:	0001d497          	auipc	s1,0x1d
    800042bc:	ae848493          	addi	s1,s1,-1304 # 80020da0 <log>
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	936080e7          	jalr	-1738(ra) # 80000bf8 <acquire>
    log.committing = 0;
    800042ca:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffe097          	auipc	ra,0xffffe
    800042d4:	e0e080e7          	jalr	-498(ra) # 800020de <wakeup>
    release(&log.lock);
    800042d8:	8526                	mv	a0,s1
    800042da:	ffffd097          	auipc	ra,0xffffd
    800042de:	9d2080e7          	jalr	-1582(ra) # 80000cac <release>
}
    800042e2:	a03d                	j	80004310 <end_op+0xaa>
    panic("log.committing");
    800042e4:	00004517          	auipc	a0,0x4
    800042e8:	3c450513          	addi	a0,a0,964 # 800086a8 <syscalls+0x1f0>
    800042ec:	ffffc097          	auipc	ra,0xffffc
    800042f0:	254080e7          	jalr	596(ra) # 80000540 <panic>
    wakeup(&log);
    800042f4:	0001d497          	auipc	s1,0x1d
    800042f8:	aac48493          	addi	s1,s1,-1364 # 80020da0 <log>
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffe097          	auipc	ra,0xffffe
    80004302:	de0080e7          	jalr	-544(ra) # 800020de <wakeup>
  release(&log.lock);
    80004306:	8526                	mv	a0,s1
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	9a4080e7          	jalr	-1628(ra) # 80000cac <release>
}
    80004310:	70e2                	ld	ra,56(sp)
    80004312:	7442                	ld	s0,48(sp)
    80004314:	74a2                	ld	s1,40(sp)
    80004316:	7902                	ld	s2,32(sp)
    80004318:	69e2                	ld	s3,24(sp)
    8000431a:	6a42                	ld	s4,16(sp)
    8000431c:	6aa2                	ld	s5,8(sp)
    8000431e:	6121                	addi	sp,sp,64
    80004320:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004322:	0001da97          	auipc	s5,0x1d
    80004326:	aaea8a93          	addi	s5,s5,-1362 # 80020dd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000432a:	0001da17          	auipc	s4,0x1d
    8000432e:	a76a0a13          	addi	s4,s4,-1418 # 80020da0 <log>
    80004332:	018a2583          	lw	a1,24(s4)
    80004336:	012585bb          	addw	a1,a1,s2
    8000433a:	2585                	addiw	a1,a1,1
    8000433c:	028a2503          	lw	a0,40(s4)
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	cc4080e7          	jalr	-828(ra) # 80003004 <bread>
    80004348:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000434a:	000aa583          	lw	a1,0(s5)
    8000434e:	028a2503          	lw	a0,40(s4)
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	cb2080e7          	jalr	-846(ra) # 80003004 <bread>
    8000435a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000435c:	40000613          	li	a2,1024
    80004360:	05850593          	addi	a1,a0,88
    80004364:	05848513          	addi	a0,s1,88
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	9e8080e7          	jalr	-1560(ra) # 80000d50 <memmove>
    bwrite(to);  // write the log
    80004370:	8526                	mv	a0,s1
    80004372:	fffff097          	auipc	ra,0xfffff
    80004376:	d84080e7          	jalr	-636(ra) # 800030f6 <bwrite>
    brelse(from);
    8000437a:	854e                	mv	a0,s3
    8000437c:	fffff097          	auipc	ra,0xfffff
    80004380:	db8080e7          	jalr	-584(ra) # 80003134 <brelse>
    brelse(to);
    80004384:	8526                	mv	a0,s1
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	dae080e7          	jalr	-594(ra) # 80003134 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000438e:	2905                	addiw	s2,s2,1
    80004390:	0a91                	addi	s5,s5,4
    80004392:	02ca2783          	lw	a5,44(s4)
    80004396:	f8f94ee3          	blt	s2,a5,80004332 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000439a:	00000097          	auipc	ra,0x0
    8000439e:	c68080e7          	jalr	-920(ra) # 80004002 <write_head>
    install_trans(0); // Now install writes to home locations
    800043a2:	4501                	li	a0,0
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	cda080e7          	jalr	-806(ra) # 8000407e <install_trans>
    log.lh.n = 0;
    800043ac:	0001d797          	auipc	a5,0x1d
    800043b0:	a207a023          	sw	zero,-1504(a5) # 80020dcc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	c4e080e7          	jalr	-946(ra) # 80004002 <write_head>
    800043bc:	bdf5                	j	800042b8 <end_op+0x52>

00000000800043be <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043be:	1101                	addi	sp,sp,-32
    800043c0:	ec06                	sd	ra,24(sp)
    800043c2:	e822                	sd	s0,16(sp)
    800043c4:	e426                	sd	s1,8(sp)
    800043c6:	e04a                	sd	s2,0(sp)
    800043c8:	1000                	addi	s0,sp,32
    800043ca:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043cc:	0001d917          	auipc	s2,0x1d
    800043d0:	9d490913          	addi	s2,s2,-1580 # 80020da0 <log>
    800043d4:	854a                	mv	a0,s2
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	822080e7          	jalr	-2014(ra) # 80000bf8 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043de:	02c92603          	lw	a2,44(s2)
    800043e2:	47f5                	li	a5,29
    800043e4:	06c7c563          	blt	a5,a2,8000444e <log_write+0x90>
    800043e8:	0001d797          	auipc	a5,0x1d
    800043ec:	9d47a783          	lw	a5,-1580(a5) # 80020dbc <log+0x1c>
    800043f0:	37fd                	addiw	a5,a5,-1
    800043f2:	04f65e63          	bge	a2,a5,8000444e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043f6:	0001d797          	auipc	a5,0x1d
    800043fa:	9ca7a783          	lw	a5,-1590(a5) # 80020dc0 <log+0x20>
    800043fe:	06f05063          	blez	a5,8000445e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004402:	4781                	li	a5,0
    80004404:	06c05563          	blez	a2,8000446e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004408:	44cc                	lw	a1,12(s1)
    8000440a:	0001d717          	auipc	a4,0x1d
    8000440e:	9c670713          	addi	a4,a4,-1594 # 80020dd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004412:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004414:	4314                	lw	a3,0(a4)
    80004416:	04b68c63          	beq	a3,a1,8000446e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000441a:	2785                	addiw	a5,a5,1
    8000441c:	0711                	addi	a4,a4,4
    8000441e:	fef61be3          	bne	a2,a5,80004414 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004422:	0621                	addi	a2,a2,8
    80004424:	060a                	slli	a2,a2,0x2
    80004426:	0001d797          	auipc	a5,0x1d
    8000442a:	97a78793          	addi	a5,a5,-1670 # 80020da0 <log>
    8000442e:	97b2                	add	a5,a5,a2
    80004430:	44d8                	lw	a4,12(s1)
    80004432:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	d9c080e7          	jalr	-612(ra) # 800031d2 <bpin>
    log.lh.n++;
    8000443e:	0001d717          	auipc	a4,0x1d
    80004442:	96270713          	addi	a4,a4,-1694 # 80020da0 <log>
    80004446:	575c                	lw	a5,44(a4)
    80004448:	2785                	addiw	a5,a5,1
    8000444a:	d75c                	sw	a5,44(a4)
    8000444c:	a82d                	j	80004486 <log_write+0xc8>
    panic("too big a transaction");
    8000444e:	00004517          	auipc	a0,0x4
    80004452:	26a50513          	addi	a0,a0,618 # 800086b8 <syscalls+0x200>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	0ea080e7          	jalr	234(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000445e:	00004517          	auipc	a0,0x4
    80004462:	27250513          	addi	a0,a0,626 # 800086d0 <syscalls+0x218>
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	0da080e7          	jalr	218(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000446e:	00878693          	addi	a3,a5,8
    80004472:	068a                	slli	a3,a3,0x2
    80004474:	0001d717          	auipc	a4,0x1d
    80004478:	92c70713          	addi	a4,a4,-1748 # 80020da0 <log>
    8000447c:	9736                	add	a4,a4,a3
    8000447e:	44d4                	lw	a3,12(s1)
    80004480:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004482:	faf609e3          	beq	a2,a5,80004434 <log_write+0x76>
  }
  release(&log.lock);
    80004486:	0001d517          	auipc	a0,0x1d
    8000448a:	91a50513          	addi	a0,a0,-1766 # 80020da0 <log>
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	81e080e7          	jalr	-2018(ra) # 80000cac <release>
}
    80004496:	60e2                	ld	ra,24(sp)
    80004498:	6442                	ld	s0,16(sp)
    8000449a:	64a2                	ld	s1,8(sp)
    8000449c:	6902                	ld	s2,0(sp)
    8000449e:	6105                	addi	sp,sp,32
    800044a0:	8082                	ret

00000000800044a2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044a2:	1101                	addi	sp,sp,-32
    800044a4:	ec06                	sd	ra,24(sp)
    800044a6:	e822                	sd	s0,16(sp)
    800044a8:	e426                	sd	s1,8(sp)
    800044aa:	e04a                	sd	s2,0(sp)
    800044ac:	1000                	addi	s0,sp,32
    800044ae:	84aa                	mv	s1,a0
    800044b0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044b2:	00004597          	auipc	a1,0x4
    800044b6:	23e58593          	addi	a1,a1,574 # 800086f0 <syscalls+0x238>
    800044ba:	0521                	addi	a0,a0,8
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	6ac080e7          	jalr	1708(ra) # 80000b68 <initlock>
  lk->name = name;
    800044c4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044c8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044cc:	0204a423          	sw	zero,40(s1)
}
    800044d0:	60e2                	ld	ra,24(sp)
    800044d2:	6442                	ld	s0,16(sp)
    800044d4:	64a2                	ld	s1,8(sp)
    800044d6:	6902                	ld	s2,0(sp)
    800044d8:	6105                	addi	sp,sp,32
    800044da:	8082                	ret

00000000800044dc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044dc:	1101                	addi	sp,sp,-32
    800044de:	ec06                	sd	ra,24(sp)
    800044e0:	e822                	sd	s0,16(sp)
    800044e2:	e426                	sd	s1,8(sp)
    800044e4:	e04a                	sd	s2,0(sp)
    800044e6:	1000                	addi	s0,sp,32
    800044e8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ea:	00850913          	addi	s2,a0,8
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	708080e7          	jalr	1800(ra) # 80000bf8 <acquire>
  while (lk->locked) {
    800044f8:	409c                	lw	a5,0(s1)
    800044fa:	cb89                	beqz	a5,8000450c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044fc:	85ca                	mv	a1,s2
    800044fe:	8526                	mv	a0,s1
    80004500:	ffffe097          	auipc	ra,0xffffe
    80004504:	b7a080e7          	jalr	-1158(ra) # 8000207a <sleep>
  while (lk->locked) {
    80004508:	409c                	lw	a5,0(s1)
    8000450a:	fbed                	bnez	a5,800044fc <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000450c:	4785                	li	a5,1
    8000450e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004510:	ffffd097          	auipc	ra,0xffffd
    80004514:	4be080e7          	jalr	1214(ra) # 800019ce <myproc>
    80004518:	591c                	lw	a5,48(a0)
    8000451a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	78e080e7          	jalr	1934(ra) # 80000cac <release>
}
    80004526:	60e2                	ld	ra,24(sp)
    80004528:	6442                	ld	s0,16(sp)
    8000452a:	64a2                	ld	s1,8(sp)
    8000452c:	6902                	ld	s2,0(sp)
    8000452e:	6105                	addi	sp,sp,32
    80004530:	8082                	ret

0000000080004532 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	e04a                	sd	s2,0(sp)
    8000453c:	1000                	addi	s0,sp,32
    8000453e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004540:	00850913          	addi	s2,a0,8
    80004544:	854a                	mv	a0,s2
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	6b2080e7          	jalr	1714(ra) # 80000bf8 <acquire>
  lk->locked = 0;
    8000454e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004552:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004556:	8526                	mv	a0,s1
    80004558:	ffffe097          	auipc	ra,0xffffe
    8000455c:	b86080e7          	jalr	-1146(ra) # 800020de <wakeup>
  release(&lk->lk);
    80004560:	854a                	mv	a0,s2
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	74a080e7          	jalr	1866(ra) # 80000cac <release>
}
    8000456a:	60e2                	ld	ra,24(sp)
    8000456c:	6442                	ld	s0,16(sp)
    8000456e:	64a2                	ld	s1,8(sp)
    80004570:	6902                	ld	s2,0(sp)
    80004572:	6105                	addi	sp,sp,32
    80004574:	8082                	ret

0000000080004576 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004576:	7179                	addi	sp,sp,-48
    80004578:	f406                	sd	ra,40(sp)
    8000457a:	f022                	sd	s0,32(sp)
    8000457c:	ec26                	sd	s1,24(sp)
    8000457e:	e84a                	sd	s2,16(sp)
    80004580:	e44e                	sd	s3,8(sp)
    80004582:	1800                	addi	s0,sp,48
    80004584:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004586:	00850913          	addi	s2,a0,8
    8000458a:	854a                	mv	a0,s2
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	66c080e7          	jalr	1644(ra) # 80000bf8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004594:	409c                	lw	a5,0(s1)
    80004596:	ef99                	bnez	a5,800045b4 <holdingsleep+0x3e>
    80004598:	4481                	li	s1,0
  release(&lk->lk);
    8000459a:	854a                	mv	a0,s2
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	710080e7          	jalr	1808(ra) # 80000cac <release>
  return r;
}
    800045a4:	8526                	mv	a0,s1
    800045a6:	70a2                	ld	ra,40(sp)
    800045a8:	7402                	ld	s0,32(sp)
    800045aa:	64e2                	ld	s1,24(sp)
    800045ac:	6942                	ld	s2,16(sp)
    800045ae:	69a2                	ld	s3,8(sp)
    800045b0:	6145                	addi	sp,sp,48
    800045b2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b4:	0284a983          	lw	s3,40(s1)
    800045b8:	ffffd097          	auipc	ra,0xffffd
    800045bc:	416080e7          	jalr	1046(ra) # 800019ce <myproc>
    800045c0:	5904                	lw	s1,48(a0)
    800045c2:	413484b3          	sub	s1,s1,s3
    800045c6:	0014b493          	seqz	s1,s1
    800045ca:	bfc1                	j	8000459a <holdingsleep+0x24>

00000000800045cc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045cc:	1141                	addi	sp,sp,-16
    800045ce:	e406                	sd	ra,8(sp)
    800045d0:	e022                	sd	s0,0(sp)
    800045d2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045d4:	00004597          	auipc	a1,0x4
    800045d8:	12c58593          	addi	a1,a1,300 # 80008700 <syscalls+0x248>
    800045dc:	0001d517          	auipc	a0,0x1d
    800045e0:	90c50513          	addi	a0,a0,-1780 # 80020ee8 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	584080e7          	jalr	1412(ra) # 80000b68 <initlock>
}
    800045ec:	60a2                	ld	ra,8(sp)
    800045ee:	6402                	ld	s0,0(sp)
    800045f0:	0141                	addi	sp,sp,16
    800045f2:	8082                	ret

00000000800045f4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045f4:	1101                	addi	sp,sp,-32
    800045f6:	ec06                	sd	ra,24(sp)
    800045f8:	e822                	sd	s0,16(sp)
    800045fa:	e426                	sd	s1,8(sp)
    800045fc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045fe:	0001d517          	auipc	a0,0x1d
    80004602:	8ea50513          	addi	a0,a0,-1814 # 80020ee8 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	5f2080e7          	jalr	1522(ra) # 80000bf8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000460e:	0001d497          	auipc	s1,0x1d
    80004612:	8f248493          	addi	s1,s1,-1806 # 80020f00 <ftable+0x18>
    80004616:	0001e717          	auipc	a4,0x1e
    8000461a:	88a70713          	addi	a4,a4,-1910 # 80021ea0 <disk>
    if(f->ref == 0){
    8000461e:	40dc                	lw	a5,4(s1)
    80004620:	cf99                	beqz	a5,8000463e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004622:	02848493          	addi	s1,s1,40
    80004626:	fee49ce3          	bne	s1,a4,8000461e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000462a:	0001d517          	auipc	a0,0x1d
    8000462e:	8be50513          	addi	a0,a0,-1858 # 80020ee8 <ftable>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	67a080e7          	jalr	1658(ra) # 80000cac <release>
  return 0;
    8000463a:	4481                	li	s1,0
    8000463c:	a819                	j	80004652 <filealloc+0x5e>
      f->ref = 1;
    8000463e:	4785                	li	a5,1
    80004640:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004642:	0001d517          	auipc	a0,0x1d
    80004646:	8a650513          	addi	a0,a0,-1882 # 80020ee8 <ftable>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	662080e7          	jalr	1634(ra) # 80000cac <release>
}
    80004652:	8526                	mv	a0,s1
    80004654:	60e2                	ld	ra,24(sp)
    80004656:	6442                	ld	s0,16(sp)
    80004658:	64a2                	ld	s1,8(sp)
    8000465a:	6105                	addi	sp,sp,32
    8000465c:	8082                	ret

000000008000465e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000465e:	1101                	addi	sp,sp,-32
    80004660:	ec06                	sd	ra,24(sp)
    80004662:	e822                	sd	s0,16(sp)
    80004664:	e426                	sd	s1,8(sp)
    80004666:	1000                	addi	s0,sp,32
    80004668:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000466a:	0001d517          	auipc	a0,0x1d
    8000466e:	87e50513          	addi	a0,a0,-1922 # 80020ee8 <ftable>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	586080e7          	jalr	1414(ra) # 80000bf8 <acquire>
  if(f->ref < 1)
    8000467a:	40dc                	lw	a5,4(s1)
    8000467c:	02f05263          	blez	a5,800046a0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004680:	2785                	addiw	a5,a5,1
    80004682:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004684:	0001d517          	auipc	a0,0x1d
    80004688:	86450513          	addi	a0,a0,-1948 # 80020ee8 <ftable>
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	620080e7          	jalr	1568(ra) # 80000cac <release>
  return f;
}
    80004694:	8526                	mv	a0,s1
    80004696:	60e2                	ld	ra,24(sp)
    80004698:	6442                	ld	s0,16(sp)
    8000469a:	64a2                	ld	s1,8(sp)
    8000469c:	6105                	addi	sp,sp,32
    8000469e:	8082                	ret
    panic("filedup");
    800046a0:	00004517          	auipc	a0,0x4
    800046a4:	06850513          	addi	a0,a0,104 # 80008708 <syscalls+0x250>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	e98080e7          	jalr	-360(ra) # 80000540 <panic>

00000000800046b0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046b0:	7139                	addi	sp,sp,-64
    800046b2:	fc06                	sd	ra,56(sp)
    800046b4:	f822                	sd	s0,48(sp)
    800046b6:	f426                	sd	s1,40(sp)
    800046b8:	f04a                	sd	s2,32(sp)
    800046ba:	ec4e                	sd	s3,24(sp)
    800046bc:	e852                	sd	s4,16(sp)
    800046be:	e456                	sd	s5,8(sp)
    800046c0:	0080                	addi	s0,sp,64
    800046c2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046c4:	0001d517          	auipc	a0,0x1d
    800046c8:	82450513          	addi	a0,a0,-2012 # 80020ee8 <ftable>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	52c080e7          	jalr	1324(ra) # 80000bf8 <acquire>
  if(f->ref < 1)
    800046d4:	40dc                	lw	a5,4(s1)
    800046d6:	06f05163          	blez	a5,80004738 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046da:	37fd                	addiw	a5,a5,-1
    800046dc:	0007871b          	sext.w	a4,a5
    800046e0:	c0dc                	sw	a5,4(s1)
    800046e2:	06e04363          	bgtz	a4,80004748 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046e6:	0004a903          	lw	s2,0(s1)
    800046ea:	0094ca83          	lbu	s5,9(s1)
    800046ee:	0104ba03          	ld	s4,16(s1)
    800046f2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046f6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046fa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046fe:	0001c517          	auipc	a0,0x1c
    80004702:	7ea50513          	addi	a0,a0,2026 # 80020ee8 <ftable>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	5a6080e7          	jalr	1446(ra) # 80000cac <release>

  if(ff.type == FD_PIPE){
    8000470e:	4785                	li	a5,1
    80004710:	04f90d63          	beq	s2,a5,8000476a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004714:	3979                	addiw	s2,s2,-2
    80004716:	4785                	li	a5,1
    80004718:	0527e063          	bltu	a5,s2,80004758 <fileclose+0xa8>
    begin_op();
    8000471c:	00000097          	auipc	ra,0x0
    80004720:	acc080e7          	jalr	-1332(ra) # 800041e8 <begin_op>
    iput(ff.ip);
    80004724:	854e                	mv	a0,s3
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	2b0080e7          	jalr	688(ra) # 800039d6 <iput>
    end_op();
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	b38080e7          	jalr	-1224(ra) # 80004266 <end_op>
    80004736:	a00d                	j	80004758 <fileclose+0xa8>
    panic("fileclose");
    80004738:	00004517          	auipc	a0,0x4
    8000473c:	fd850513          	addi	a0,a0,-40 # 80008710 <syscalls+0x258>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	e00080e7          	jalr	-512(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004748:	0001c517          	auipc	a0,0x1c
    8000474c:	7a050513          	addi	a0,a0,1952 # 80020ee8 <ftable>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	55c080e7          	jalr	1372(ra) # 80000cac <release>
  }
}
    80004758:	70e2                	ld	ra,56(sp)
    8000475a:	7442                	ld	s0,48(sp)
    8000475c:	74a2                	ld	s1,40(sp)
    8000475e:	7902                	ld	s2,32(sp)
    80004760:	69e2                	ld	s3,24(sp)
    80004762:	6a42                	ld	s4,16(sp)
    80004764:	6aa2                	ld	s5,8(sp)
    80004766:	6121                	addi	sp,sp,64
    80004768:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000476a:	85d6                	mv	a1,s5
    8000476c:	8552                	mv	a0,s4
    8000476e:	00000097          	auipc	ra,0x0
    80004772:	34c080e7          	jalr	844(ra) # 80004aba <pipeclose>
    80004776:	b7cd                	j	80004758 <fileclose+0xa8>

0000000080004778 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004778:	715d                	addi	sp,sp,-80
    8000477a:	e486                	sd	ra,72(sp)
    8000477c:	e0a2                	sd	s0,64(sp)
    8000477e:	fc26                	sd	s1,56(sp)
    80004780:	f84a                	sd	s2,48(sp)
    80004782:	f44e                	sd	s3,40(sp)
    80004784:	0880                	addi	s0,sp,80
    80004786:	84aa                	mv	s1,a0
    80004788:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000478a:	ffffd097          	auipc	ra,0xffffd
    8000478e:	244080e7          	jalr	580(ra) # 800019ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004792:	409c                	lw	a5,0(s1)
    80004794:	37f9                	addiw	a5,a5,-2
    80004796:	4705                	li	a4,1
    80004798:	04f76763          	bltu	a4,a5,800047e6 <filestat+0x6e>
    8000479c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000479e:	6c88                	ld	a0,24(s1)
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	07c080e7          	jalr	124(ra) # 8000381c <ilock>
    stati(f->ip, &st);
    800047a8:	fb840593          	addi	a1,s0,-72
    800047ac:	6c88                	ld	a0,24(s1)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	2f8080e7          	jalr	760(ra) # 80003aa6 <stati>
    iunlock(f->ip);
    800047b6:	6c88                	ld	a0,24(s1)
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	126080e7          	jalr	294(ra) # 800038de <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047c0:	46e1                	li	a3,24
    800047c2:	fb840613          	addi	a2,s0,-72
    800047c6:	85ce                	mv	a1,s3
    800047c8:	05093503          	ld	a0,80(s2)
    800047cc:	ffffd097          	auipc	ra,0xffffd
    800047d0:	ec2080e7          	jalr	-318(ra) # 8000168e <copyout>
    800047d4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047d8:	60a6                	ld	ra,72(sp)
    800047da:	6406                	ld	s0,64(sp)
    800047dc:	74e2                	ld	s1,56(sp)
    800047de:	7942                	ld	s2,48(sp)
    800047e0:	79a2                	ld	s3,40(sp)
    800047e2:	6161                	addi	sp,sp,80
    800047e4:	8082                	ret
  return -1;
    800047e6:	557d                	li	a0,-1
    800047e8:	bfc5                	j	800047d8 <filestat+0x60>

00000000800047ea <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047ea:	7179                	addi	sp,sp,-48
    800047ec:	f406                	sd	ra,40(sp)
    800047ee:	f022                	sd	s0,32(sp)
    800047f0:	ec26                	sd	s1,24(sp)
    800047f2:	e84a                	sd	s2,16(sp)
    800047f4:	e44e                	sd	s3,8(sp)
    800047f6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047f8:	00854783          	lbu	a5,8(a0)
    800047fc:	c3d5                	beqz	a5,800048a0 <fileread+0xb6>
    800047fe:	84aa                	mv	s1,a0
    80004800:	89ae                	mv	s3,a1
    80004802:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004804:	411c                	lw	a5,0(a0)
    80004806:	4705                	li	a4,1
    80004808:	04e78963          	beq	a5,a4,8000485a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000480c:	470d                	li	a4,3
    8000480e:	04e78d63          	beq	a5,a4,80004868 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004812:	4709                	li	a4,2
    80004814:	06e79e63          	bne	a5,a4,80004890 <fileread+0xa6>
    ilock(f->ip);
    80004818:	6d08                	ld	a0,24(a0)
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	002080e7          	jalr	2(ra) # 8000381c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004822:	874a                	mv	a4,s2
    80004824:	5094                	lw	a3,32(s1)
    80004826:	864e                	mv	a2,s3
    80004828:	4585                	li	a1,1
    8000482a:	6c88                	ld	a0,24(s1)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	2a4080e7          	jalr	676(ra) # 80003ad0 <readi>
    80004834:	892a                	mv	s2,a0
    80004836:	00a05563          	blez	a0,80004840 <fileread+0x56>
      f->off += r;
    8000483a:	509c                	lw	a5,32(s1)
    8000483c:	9fa9                	addw	a5,a5,a0
    8000483e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004840:	6c88                	ld	a0,24(s1)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	09c080e7          	jalr	156(ra) # 800038de <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000484a:	854a                	mv	a0,s2
    8000484c:	70a2                	ld	ra,40(sp)
    8000484e:	7402                	ld	s0,32(sp)
    80004850:	64e2                	ld	s1,24(sp)
    80004852:	6942                	ld	s2,16(sp)
    80004854:	69a2                	ld	s3,8(sp)
    80004856:	6145                	addi	sp,sp,48
    80004858:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000485a:	6908                	ld	a0,16(a0)
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	3c6080e7          	jalr	966(ra) # 80004c22 <piperead>
    80004864:	892a                	mv	s2,a0
    80004866:	b7d5                	j	8000484a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004868:	02451783          	lh	a5,36(a0)
    8000486c:	03079693          	slli	a3,a5,0x30
    80004870:	92c1                	srli	a3,a3,0x30
    80004872:	4725                	li	a4,9
    80004874:	02d76863          	bltu	a4,a3,800048a4 <fileread+0xba>
    80004878:	0792                	slli	a5,a5,0x4
    8000487a:	0001c717          	auipc	a4,0x1c
    8000487e:	5ce70713          	addi	a4,a4,1486 # 80020e48 <devsw>
    80004882:	97ba                	add	a5,a5,a4
    80004884:	639c                	ld	a5,0(a5)
    80004886:	c38d                	beqz	a5,800048a8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004888:	4505                	li	a0,1
    8000488a:	9782                	jalr	a5
    8000488c:	892a                	mv	s2,a0
    8000488e:	bf75                	j	8000484a <fileread+0x60>
    panic("fileread");
    80004890:	00004517          	auipc	a0,0x4
    80004894:	e9050513          	addi	a0,a0,-368 # 80008720 <syscalls+0x268>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	ca8080e7          	jalr	-856(ra) # 80000540 <panic>
    return -1;
    800048a0:	597d                	li	s2,-1
    800048a2:	b765                	j	8000484a <fileread+0x60>
      return -1;
    800048a4:	597d                	li	s2,-1
    800048a6:	b755                	j	8000484a <fileread+0x60>
    800048a8:	597d                	li	s2,-1
    800048aa:	b745                	j	8000484a <fileread+0x60>

00000000800048ac <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048ac:	715d                	addi	sp,sp,-80
    800048ae:	e486                	sd	ra,72(sp)
    800048b0:	e0a2                	sd	s0,64(sp)
    800048b2:	fc26                	sd	s1,56(sp)
    800048b4:	f84a                	sd	s2,48(sp)
    800048b6:	f44e                	sd	s3,40(sp)
    800048b8:	f052                	sd	s4,32(sp)
    800048ba:	ec56                	sd	s5,24(sp)
    800048bc:	e85a                	sd	s6,16(sp)
    800048be:	e45e                	sd	s7,8(sp)
    800048c0:	e062                	sd	s8,0(sp)
    800048c2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048c4:	00954783          	lbu	a5,9(a0)
    800048c8:	10078663          	beqz	a5,800049d4 <filewrite+0x128>
    800048cc:	892a                	mv	s2,a0
    800048ce:	8b2e                	mv	s6,a1
    800048d0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d2:	411c                	lw	a5,0(a0)
    800048d4:	4705                	li	a4,1
    800048d6:	02e78263          	beq	a5,a4,800048fa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048da:	470d                	li	a4,3
    800048dc:	02e78663          	beq	a5,a4,80004908 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048e0:	4709                	li	a4,2
    800048e2:	0ee79163          	bne	a5,a4,800049c4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048e6:	0ac05d63          	blez	a2,800049a0 <filewrite+0xf4>
    int i = 0;
    800048ea:	4981                	li	s3,0
    800048ec:	6b85                	lui	s7,0x1
    800048ee:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048f2:	6c05                	lui	s8,0x1
    800048f4:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048f8:	a861                	j	80004990 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048fa:	6908                	ld	a0,16(a0)
    800048fc:	00000097          	auipc	ra,0x0
    80004900:	22e080e7          	jalr	558(ra) # 80004b2a <pipewrite>
    80004904:	8a2a                	mv	s4,a0
    80004906:	a045                	j	800049a6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004908:	02451783          	lh	a5,36(a0)
    8000490c:	03079693          	slli	a3,a5,0x30
    80004910:	92c1                	srli	a3,a3,0x30
    80004912:	4725                	li	a4,9
    80004914:	0cd76263          	bltu	a4,a3,800049d8 <filewrite+0x12c>
    80004918:	0792                	slli	a5,a5,0x4
    8000491a:	0001c717          	auipc	a4,0x1c
    8000491e:	52e70713          	addi	a4,a4,1326 # 80020e48 <devsw>
    80004922:	97ba                	add	a5,a5,a4
    80004924:	679c                	ld	a5,8(a5)
    80004926:	cbdd                	beqz	a5,800049dc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004928:	4505                	li	a0,1
    8000492a:	9782                	jalr	a5
    8000492c:	8a2a                	mv	s4,a0
    8000492e:	a8a5                	j	800049a6 <filewrite+0xfa>
    80004930:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004934:	00000097          	auipc	ra,0x0
    80004938:	8b4080e7          	jalr	-1868(ra) # 800041e8 <begin_op>
      ilock(f->ip);
    8000493c:	01893503          	ld	a0,24(s2)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	edc080e7          	jalr	-292(ra) # 8000381c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004948:	8756                	mv	a4,s5
    8000494a:	02092683          	lw	a3,32(s2)
    8000494e:	01698633          	add	a2,s3,s6
    80004952:	4585                	li	a1,1
    80004954:	01893503          	ld	a0,24(s2)
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	270080e7          	jalr	624(ra) # 80003bc8 <writei>
    80004960:	84aa                	mv	s1,a0
    80004962:	00a05763          	blez	a0,80004970 <filewrite+0xc4>
        f->off += r;
    80004966:	02092783          	lw	a5,32(s2)
    8000496a:	9fa9                	addw	a5,a5,a0
    8000496c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004970:	01893503          	ld	a0,24(s2)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	f6a080e7          	jalr	-150(ra) # 800038de <iunlock>
      end_op();
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	8ea080e7          	jalr	-1814(ra) # 80004266 <end_op>

      if(r != n1){
    80004984:	009a9f63          	bne	s5,s1,800049a2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004988:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000498c:	0149db63          	bge	s3,s4,800049a2 <filewrite+0xf6>
      int n1 = n - i;
    80004990:	413a04bb          	subw	s1,s4,s3
    80004994:	0004879b          	sext.w	a5,s1
    80004998:	f8fbdce3          	bge	s7,a5,80004930 <filewrite+0x84>
    8000499c:	84e2                	mv	s1,s8
    8000499e:	bf49                	j	80004930 <filewrite+0x84>
    int i = 0;
    800049a0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049a2:	013a1f63          	bne	s4,s3,800049c0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049a6:	8552                	mv	a0,s4
    800049a8:	60a6                	ld	ra,72(sp)
    800049aa:	6406                	ld	s0,64(sp)
    800049ac:	74e2                	ld	s1,56(sp)
    800049ae:	7942                	ld	s2,48(sp)
    800049b0:	79a2                	ld	s3,40(sp)
    800049b2:	7a02                	ld	s4,32(sp)
    800049b4:	6ae2                	ld	s5,24(sp)
    800049b6:	6b42                	ld	s6,16(sp)
    800049b8:	6ba2                	ld	s7,8(sp)
    800049ba:	6c02                	ld	s8,0(sp)
    800049bc:	6161                	addi	sp,sp,80
    800049be:	8082                	ret
    ret = (i == n ? n : -1);
    800049c0:	5a7d                	li	s4,-1
    800049c2:	b7d5                	j	800049a6 <filewrite+0xfa>
    panic("filewrite");
    800049c4:	00004517          	auipc	a0,0x4
    800049c8:	d6c50513          	addi	a0,a0,-660 # 80008730 <syscalls+0x278>
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	b74080e7          	jalr	-1164(ra) # 80000540 <panic>
    return -1;
    800049d4:	5a7d                	li	s4,-1
    800049d6:	bfc1                	j	800049a6 <filewrite+0xfa>
      return -1;
    800049d8:	5a7d                	li	s4,-1
    800049da:	b7f1                	j	800049a6 <filewrite+0xfa>
    800049dc:	5a7d                	li	s4,-1
    800049de:	b7e1                	j	800049a6 <filewrite+0xfa>

00000000800049e0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049e0:	7179                	addi	sp,sp,-48
    800049e2:	f406                	sd	ra,40(sp)
    800049e4:	f022                	sd	s0,32(sp)
    800049e6:	ec26                	sd	s1,24(sp)
    800049e8:	e84a                	sd	s2,16(sp)
    800049ea:	e44e                	sd	s3,8(sp)
    800049ec:	e052                	sd	s4,0(sp)
    800049ee:	1800                	addi	s0,sp,48
    800049f0:	84aa                	mv	s1,a0
    800049f2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049f4:	0005b023          	sd	zero,0(a1)
    800049f8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049fc:	00000097          	auipc	ra,0x0
    80004a00:	bf8080e7          	jalr	-1032(ra) # 800045f4 <filealloc>
    80004a04:	e088                	sd	a0,0(s1)
    80004a06:	c551                	beqz	a0,80004a92 <pipealloc+0xb2>
    80004a08:	00000097          	auipc	ra,0x0
    80004a0c:	bec080e7          	jalr	-1044(ra) # 800045f4 <filealloc>
    80004a10:	00aa3023          	sd	a0,0(s4)
    80004a14:	c92d                	beqz	a0,80004a86 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	0d0080e7          	jalr	208(ra) # 80000ae6 <kalloc>
    80004a1e:	892a                	mv	s2,a0
    80004a20:	c125                	beqz	a0,80004a80 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a22:	4985                	li	s3,1
    80004a24:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a28:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a2c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a30:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a34:	00004597          	auipc	a1,0x4
    80004a38:	d0c58593          	addi	a1,a1,-756 # 80008740 <syscalls+0x288>
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	12c080e7          	jalr	300(ra) # 80000b68 <initlock>
  (*f0)->type = FD_PIPE;
    80004a44:	609c                	ld	a5,0(s1)
    80004a46:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a4a:	609c                	ld	a5,0(s1)
    80004a4c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a50:	609c                	ld	a5,0(s1)
    80004a52:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a56:	609c                	ld	a5,0(s1)
    80004a58:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a5c:	000a3783          	ld	a5,0(s4)
    80004a60:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a64:	000a3783          	ld	a5,0(s4)
    80004a68:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a6c:	000a3783          	ld	a5,0(s4)
    80004a70:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a74:	000a3783          	ld	a5,0(s4)
    80004a78:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a7c:	4501                	li	a0,0
    80004a7e:	a025                	j	80004aa6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a80:	6088                	ld	a0,0(s1)
    80004a82:	e501                	bnez	a0,80004a8a <pipealloc+0xaa>
    80004a84:	a039                	j	80004a92 <pipealloc+0xb2>
    80004a86:	6088                	ld	a0,0(s1)
    80004a88:	c51d                	beqz	a0,80004ab6 <pipealloc+0xd6>
    fileclose(*f0);
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	c26080e7          	jalr	-986(ra) # 800046b0 <fileclose>
  if(*f1)
    80004a92:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a96:	557d                	li	a0,-1
  if(*f1)
    80004a98:	c799                	beqz	a5,80004aa6 <pipealloc+0xc6>
    fileclose(*f1);
    80004a9a:	853e                	mv	a0,a5
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	c14080e7          	jalr	-1004(ra) # 800046b0 <fileclose>
  return -1;
    80004aa4:	557d                	li	a0,-1
}
    80004aa6:	70a2                	ld	ra,40(sp)
    80004aa8:	7402                	ld	s0,32(sp)
    80004aaa:	64e2                	ld	s1,24(sp)
    80004aac:	6942                	ld	s2,16(sp)
    80004aae:	69a2                	ld	s3,8(sp)
    80004ab0:	6a02                	ld	s4,0(sp)
    80004ab2:	6145                	addi	sp,sp,48
    80004ab4:	8082                	ret
  return -1;
    80004ab6:	557d                	li	a0,-1
    80004ab8:	b7fd                	j	80004aa6 <pipealloc+0xc6>

0000000080004aba <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aba:	1101                	addi	sp,sp,-32
    80004abc:	ec06                	sd	ra,24(sp)
    80004abe:	e822                	sd	s0,16(sp)
    80004ac0:	e426                	sd	s1,8(sp)
    80004ac2:	e04a                	sd	s2,0(sp)
    80004ac4:	1000                	addi	s0,sp,32
    80004ac6:	84aa                	mv	s1,a0
    80004ac8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	12e080e7          	jalr	302(ra) # 80000bf8 <acquire>
  if(writable){
    80004ad2:	02090d63          	beqz	s2,80004b0c <pipeclose+0x52>
    pi->writeopen = 0;
    80004ad6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ada:	21848513          	addi	a0,s1,536
    80004ade:	ffffd097          	auipc	ra,0xffffd
    80004ae2:	600080e7          	jalr	1536(ra) # 800020de <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ae6:	2204b783          	ld	a5,544(s1)
    80004aea:	eb95                	bnez	a5,80004b1e <pipeclose+0x64>
    release(&pi->lock);
    80004aec:	8526                	mv	a0,s1
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	1be080e7          	jalr	446(ra) # 80000cac <release>
    kfree((char*)pi);
    80004af6:	8526                	mv	a0,s1
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	ef0080e7          	jalr	-272(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004b00:	60e2                	ld	ra,24(sp)
    80004b02:	6442                	ld	s0,16(sp)
    80004b04:	64a2                	ld	s1,8(sp)
    80004b06:	6902                	ld	s2,0(sp)
    80004b08:	6105                	addi	sp,sp,32
    80004b0a:	8082                	ret
    pi->readopen = 0;
    80004b0c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b10:	21c48513          	addi	a0,s1,540
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	5ca080e7          	jalr	1482(ra) # 800020de <wakeup>
    80004b1c:	b7e9                	j	80004ae6 <pipeclose+0x2c>
    release(&pi->lock);
    80004b1e:	8526                	mv	a0,s1
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	18c080e7          	jalr	396(ra) # 80000cac <release>
}
    80004b28:	bfe1                	j	80004b00 <pipeclose+0x46>

0000000080004b2a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b2a:	711d                	addi	sp,sp,-96
    80004b2c:	ec86                	sd	ra,88(sp)
    80004b2e:	e8a2                	sd	s0,80(sp)
    80004b30:	e4a6                	sd	s1,72(sp)
    80004b32:	e0ca                	sd	s2,64(sp)
    80004b34:	fc4e                	sd	s3,56(sp)
    80004b36:	f852                	sd	s4,48(sp)
    80004b38:	f456                	sd	s5,40(sp)
    80004b3a:	f05a                	sd	s6,32(sp)
    80004b3c:	ec5e                	sd	s7,24(sp)
    80004b3e:	e862                	sd	s8,16(sp)
    80004b40:	1080                	addi	s0,sp,96
    80004b42:	84aa                	mv	s1,a0
    80004b44:	8aae                	mv	s5,a1
    80004b46:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	e86080e7          	jalr	-378(ra) # 800019ce <myproc>
    80004b50:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b52:	8526                	mv	a0,s1
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	0a4080e7          	jalr	164(ra) # 80000bf8 <acquire>
  while(i < n){
    80004b5c:	0b405663          	blez	s4,80004c08 <pipewrite+0xde>
  int i = 0;
    80004b60:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b62:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b64:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b68:	21c48b93          	addi	s7,s1,540
    80004b6c:	a089                	j	80004bae <pipewrite+0x84>
      release(&pi->lock);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	13c080e7          	jalr	316(ra) # 80000cac <release>
      return -1;
    80004b78:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b7a:	854a                	mv	a0,s2
    80004b7c:	60e6                	ld	ra,88(sp)
    80004b7e:	6446                	ld	s0,80(sp)
    80004b80:	64a6                	ld	s1,72(sp)
    80004b82:	6906                	ld	s2,64(sp)
    80004b84:	79e2                	ld	s3,56(sp)
    80004b86:	7a42                	ld	s4,48(sp)
    80004b88:	7aa2                	ld	s5,40(sp)
    80004b8a:	7b02                	ld	s6,32(sp)
    80004b8c:	6be2                	ld	s7,24(sp)
    80004b8e:	6c42                	ld	s8,16(sp)
    80004b90:	6125                	addi	sp,sp,96
    80004b92:	8082                	ret
      wakeup(&pi->nread);
    80004b94:	8562                	mv	a0,s8
    80004b96:	ffffd097          	auipc	ra,0xffffd
    80004b9a:	548080e7          	jalr	1352(ra) # 800020de <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b9e:	85a6                	mv	a1,s1
    80004ba0:	855e                	mv	a0,s7
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	4d8080e7          	jalr	1240(ra) # 8000207a <sleep>
  while(i < n){
    80004baa:	07495063          	bge	s2,s4,80004c0a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004bae:	2204a783          	lw	a5,544(s1)
    80004bb2:	dfd5                	beqz	a5,80004b6e <pipewrite+0x44>
    80004bb4:	854e                	mv	a0,s3
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	76c080e7          	jalr	1900(ra) # 80002322 <killed>
    80004bbe:	f945                	bnez	a0,80004b6e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bc0:	2184a783          	lw	a5,536(s1)
    80004bc4:	21c4a703          	lw	a4,540(s1)
    80004bc8:	2007879b          	addiw	a5,a5,512
    80004bcc:	fcf704e3          	beq	a4,a5,80004b94 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bd0:	4685                	li	a3,1
    80004bd2:	01590633          	add	a2,s2,s5
    80004bd6:	faf40593          	addi	a1,s0,-81
    80004bda:	0509b503          	ld	a0,80(s3)
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	b3c080e7          	jalr	-1220(ra) # 8000171a <copyin>
    80004be6:	03650263          	beq	a0,s6,80004c0a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bea:	21c4a783          	lw	a5,540(s1)
    80004bee:	0017871b          	addiw	a4,a5,1
    80004bf2:	20e4ae23          	sw	a4,540(s1)
    80004bf6:	1ff7f793          	andi	a5,a5,511
    80004bfa:	97a6                	add	a5,a5,s1
    80004bfc:	faf44703          	lbu	a4,-81(s0)
    80004c00:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c04:	2905                	addiw	s2,s2,1
    80004c06:	b755                	j	80004baa <pipewrite+0x80>
  int i = 0;
    80004c08:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c0a:	21848513          	addi	a0,s1,536
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	4d0080e7          	jalr	1232(ra) # 800020de <wakeup>
  release(&pi->lock);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	094080e7          	jalr	148(ra) # 80000cac <release>
  return i;
    80004c20:	bfa9                	j	80004b7a <pipewrite+0x50>

0000000080004c22 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c22:	715d                	addi	sp,sp,-80
    80004c24:	e486                	sd	ra,72(sp)
    80004c26:	e0a2                	sd	s0,64(sp)
    80004c28:	fc26                	sd	s1,56(sp)
    80004c2a:	f84a                	sd	s2,48(sp)
    80004c2c:	f44e                	sd	s3,40(sp)
    80004c2e:	f052                	sd	s4,32(sp)
    80004c30:	ec56                	sd	s5,24(sp)
    80004c32:	e85a                	sd	s6,16(sp)
    80004c34:	0880                	addi	s0,sp,80
    80004c36:	84aa                	mv	s1,a0
    80004c38:	892e                	mv	s2,a1
    80004c3a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	d92080e7          	jalr	-622(ra) # 800019ce <myproc>
    80004c44:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c46:	8526                	mv	a0,s1
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	fb0080e7          	jalr	-80(ra) # 80000bf8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c50:	2184a703          	lw	a4,536(s1)
    80004c54:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c58:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c5c:	02f71763          	bne	a4,a5,80004c8a <piperead+0x68>
    80004c60:	2244a783          	lw	a5,548(s1)
    80004c64:	c39d                	beqz	a5,80004c8a <piperead+0x68>
    if(killed(pr)){
    80004c66:	8552                	mv	a0,s4
    80004c68:	ffffd097          	auipc	ra,0xffffd
    80004c6c:	6ba080e7          	jalr	1722(ra) # 80002322 <killed>
    80004c70:	e949                	bnez	a0,80004d02 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c72:	85a6                	mv	a1,s1
    80004c74:	854e                	mv	a0,s3
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	404080e7          	jalr	1028(ra) # 8000207a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c7e:	2184a703          	lw	a4,536(s1)
    80004c82:	21c4a783          	lw	a5,540(s1)
    80004c86:	fcf70de3          	beq	a4,a5,80004c60 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c8a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c8c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c8e:	05505463          	blez	s5,80004cd6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c92:	2184a783          	lw	a5,536(s1)
    80004c96:	21c4a703          	lw	a4,540(s1)
    80004c9a:	02f70e63          	beq	a4,a5,80004cd6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c9e:	0017871b          	addiw	a4,a5,1
    80004ca2:	20e4ac23          	sw	a4,536(s1)
    80004ca6:	1ff7f793          	andi	a5,a5,511
    80004caa:	97a6                	add	a5,a5,s1
    80004cac:	0187c783          	lbu	a5,24(a5)
    80004cb0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cb4:	4685                	li	a3,1
    80004cb6:	fbf40613          	addi	a2,s0,-65
    80004cba:	85ca                	mv	a1,s2
    80004cbc:	050a3503          	ld	a0,80(s4)
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	9ce080e7          	jalr	-1586(ra) # 8000168e <copyout>
    80004cc8:	01650763          	beq	a0,s6,80004cd6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ccc:	2985                	addiw	s3,s3,1
    80004cce:	0905                	addi	s2,s2,1
    80004cd0:	fd3a91e3          	bne	s5,s3,80004c92 <piperead+0x70>
    80004cd4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cd6:	21c48513          	addi	a0,s1,540
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	404080e7          	jalr	1028(ra) # 800020de <wakeup>
  release(&pi->lock);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	fc8080e7          	jalr	-56(ra) # 80000cac <release>
  return i;
}
    80004cec:	854e                	mv	a0,s3
    80004cee:	60a6                	ld	ra,72(sp)
    80004cf0:	6406                	ld	s0,64(sp)
    80004cf2:	74e2                	ld	s1,56(sp)
    80004cf4:	7942                	ld	s2,48(sp)
    80004cf6:	79a2                	ld	s3,40(sp)
    80004cf8:	7a02                	ld	s4,32(sp)
    80004cfa:	6ae2                	ld	s5,24(sp)
    80004cfc:	6b42                	ld	s6,16(sp)
    80004cfe:	6161                	addi	sp,sp,80
    80004d00:	8082                	ret
      release(&pi->lock);
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	fa8080e7          	jalr	-88(ra) # 80000cac <release>
      return -1;
    80004d0c:	59fd                	li	s3,-1
    80004d0e:	bff9                	j	80004cec <piperead+0xca>

0000000080004d10 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d10:	1141                	addi	sp,sp,-16
    80004d12:	e422                	sd	s0,8(sp)
    80004d14:	0800                	addi	s0,sp,16
    80004d16:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d18:	8905                	andi	a0,a0,1
    80004d1a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004d1c:	8b89                	andi	a5,a5,2
    80004d1e:	c399                	beqz	a5,80004d24 <flags2perm+0x14>
      perm |= PTE_W;
    80004d20:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d24:	6422                	ld	s0,8(sp)
    80004d26:	0141                	addi	sp,sp,16
    80004d28:	8082                	ret

0000000080004d2a <exec>:

int
exec(char *path, char **argv)
{
    80004d2a:	de010113          	addi	sp,sp,-544
    80004d2e:	20113c23          	sd	ra,536(sp)
    80004d32:	20813823          	sd	s0,528(sp)
    80004d36:	20913423          	sd	s1,520(sp)
    80004d3a:	21213023          	sd	s2,512(sp)
    80004d3e:	ffce                	sd	s3,504(sp)
    80004d40:	fbd2                	sd	s4,496(sp)
    80004d42:	f7d6                	sd	s5,488(sp)
    80004d44:	f3da                	sd	s6,480(sp)
    80004d46:	efde                	sd	s7,472(sp)
    80004d48:	ebe2                	sd	s8,464(sp)
    80004d4a:	e7e6                	sd	s9,456(sp)
    80004d4c:	e3ea                	sd	s10,448(sp)
    80004d4e:	ff6e                	sd	s11,440(sp)
    80004d50:	1400                	addi	s0,sp,544
    80004d52:	892a                	mv	s2,a0
    80004d54:	dea43423          	sd	a0,-536(s0)
    80004d58:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	c72080e7          	jalr	-910(ra) # 800019ce <myproc>
    80004d64:	84aa                	mv	s1,a0

  begin_op();
    80004d66:	fffff097          	auipc	ra,0xfffff
    80004d6a:	482080e7          	jalr	1154(ra) # 800041e8 <begin_op>

  if((ip = namei(path)) == 0){
    80004d6e:	854a                	mv	a0,s2
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	258080e7          	jalr	600(ra) # 80003fc8 <namei>
    80004d78:	c93d                	beqz	a0,80004dee <exec+0xc4>
    80004d7a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d7c:	fffff097          	auipc	ra,0xfffff
    80004d80:	aa0080e7          	jalr	-1376(ra) # 8000381c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d84:	04000713          	li	a4,64
    80004d88:	4681                	li	a3,0
    80004d8a:	e5040613          	addi	a2,s0,-432
    80004d8e:	4581                	li	a1,0
    80004d90:	8556                	mv	a0,s5
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	d3e080e7          	jalr	-706(ra) # 80003ad0 <readi>
    80004d9a:	04000793          	li	a5,64
    80004d9e:	00f51a63          	bne	a0,a5,80004db2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004da2:	e5042703          	lw	a4,-432(s0)
    80004da6:	464c47b7          	lui	a5,0x464c4
    80004daa:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dae:	04f70663          	beq	a4,a5,80004dfa <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004db2:	8556                	mv	a0,s5
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	cca080e7          	jalr	-822(ra) # 80003a7e <iunlockput>
    end_op();
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	4aa080e7          	jalr	1194(ra) # 80004266 <end_op>
  }
  return -1;
    80004dc4:	557d                	li	a0,-1
}
    80004dc6:	21813083          	ld	ra,536(sp)
    80004dca:	21013403          	ld	s0,528(sp)
    80004dce:	20813483          	ld	s1,520(sp)
    80004dd2:	20013903          	ld	s2,512(sp)
    80004dd6:	79fe                	ld	s3,504(sp)
    80004dd8:	7a5e                	ld	s4,496(sp)
    80004dda:	7abe                	ld	s5,488(sp)
    80004ddc:	7b1e                	ld	s6,480(sp)
    80004dde:	6bfe                	ld	s7,472(sp)
    80004de0:	6c5e                	ld	s8,464(sp)
    80004de2:	6cbe                	ld	s9,456(sp)
    80004de4:	6d1e                	ld	s10,448(sp)
    80004de6:	7dfa                	ld	s11,440(sp)
    80004de8:	22010113          	addi	sp,sp,544
    80004dec:	8082                	ret
    end_op();
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	478080e7          	jalr	1144(ra) # 80004266 <end_op>
    return -1;
    80004df6:	557d                	li	a0,-1
    80004df8:	b7f9                	j	80004dc6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dfa:	8526                	mv	a0,s1
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	c96080e7          	jalr	-874(ra) # 80001a92 <proc_pagetable>
    80004e04:	8b2a                	mv	s6,a0
    80004e06:	d555                	beqz	a0,80004db2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e08:	e7042783          	lw	a5,-400(s0)
    80004e0c:	e8845703          	lhu	a4,-376(s0)
    80004e10:	c735                	beqz	a4,80004e7c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e12:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e14:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e18:	6a05                	lui	s4,0x1
    80004e1a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e1e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e22:	6d85                	lui	s11,0x1
    80004e24:	7d7d                	lui	s10,0xfffff
    80004e26:	ac3d                	j	80005064 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e28:	00004517          	auipc	a0,0x4
    80004e2c:	92050513          	addi	a0,a0,-1760 # 80008748 <syscalls+0x290>
    80004e30:	ffffb097          	auipc	ra,0xffffb
    80004e34:	710080e7          	jalr	1808(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e38:	874a                	mv	a4,s2
    80004e3a:	009c86bb          	addw	a3,s9,s1
    80004e3e:	4581                	li	a1,0
    80004e40:	8556                	mv	a0,s5
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	c8e080e7          	jalr	-882(ra) # 80003ad0 <readi>
    80004e4a:	2501                	sext.w	a0,a0
    80004e4c:	1aa91963          	bne	s2,a0,80004ffe <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004e50:	009d84bb          	addw	s1,s11,s1
    80004e54:	013d09bb          	addw	s3,s10,s3
    80004e58:	1f74f663          	bgeu	s1,s7,80005044 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004e5c:	02049593          	slli	a1,s1,0x20
    80004e60:	9181                	srli	a1,a1,0x20
    80004e62:	95e2                	add	a1,a1,s8
    80004e64:	855a                	mv	a0,s6
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	218080e7          	jalr	536(ra) # 8000107e <walkaddr>
    80004e6e:	862a                	mv	a2,a0
    if(pa == 0)
    80004e70:	dd45                	beqz	a0,80004e28 <exec+0xfe>
      n = PGSIZE;
    80004e72:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e74:	fd49f2e3          	bgeu	s3,s4,80004e38 <exec+0x10e>
      n = sz - i;
    80004e78:	894e                	mv	s2,s3
    80004e7a:	bf7d                	j	80004e38 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e7c:	4901                	li	s2,0
  iunlockput(ip);
    80004e7e:	8556                	mv	a0,s5
    80004e80:	fffff097          	auipc	ra,0xfffff
    80004e84:	bfe080e7          	jalr	-1026(ra) # 80003a7e <iunlockput>
  end_op();
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	3de080e7          	jalr	990(ra) # 80004266 <end_op>
  p = myproc();
    80004e90:	ffffd097          	auipc	ra,0xffffd
    80004e94:	b3e080e7          	jalr	-1218(ra) # 800019ce <myproc>
    80004e98:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e9a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e9e:	6785                	lui	a5,0x1
    80004ea0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004ea2:	97ca                	add	a5,a5,s2
    80004ea4:	777d                	lui	a4,0xfffff
    80004ea6:	8ff9                	and	a5,a5,a4
    80004ea8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004eac:	4691                	li	a3,4
    80004eae:	6609                	lui	a2,0x2
    80004eb0:	963e                	add	a2,a2,a5
    80004eb2:	85be                	mv	a1,a5
    80004eb4:	855a                	mv	a0,s6
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	57c080e7          	jalr	1404(ra) # 80001432 <uvmalloc>
    80004ebe:	8c2a                	mv	s8,a0
  ip = 0;
    80004ec0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ec2:	12050e63          	beqz	a0,80004ffe <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ec6:	75f9                	lui	a1,0xffffe
    80004ec8:	95aa                	add	a1,a1,a0
    80004eca:	855a                	mv	a0,s6
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	790080e7          	jalr	1936(ra) # 8000165c <uvmclear>
  stackbase = sp - PGSIZE;
    80004ed4:	7afd                	lui	s5,0xfffff
    80004ed6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ed8:	df043783          	ld	a5,-528(s0)
    80004edc:	6388                	ld	a0,0(a5)
    80004ede:	c925                	beqz	a0,80004f4e <exec+0x224>
    80004ee0:	e9040993          	addi	s3,s0,-368
    80004ee4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ee8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eea:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	f84080e7          	jalr	-124(ra) # 80000e70 <strlen>
    80004ef4:	0015079b          	addiw	a5,a0,1
    80004ef8:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004efc:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004f00:	13596663          	bltu	s2,s5,8000502c <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f04:	df043d83          	ld	s11,-528(s0)
    80004f08:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f0c:	8552                	mv	a0,s4
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	f62080e7          	jalr	-158(ra) # 80000e70 <strlen>
    80004f16:	0015069b          	addiw	a3,a0,1
    80004f1a:	8652                	mv	a2,s4
    80004f1c:	85ca                	mv	a1,s2
    80004f1e:	855a                	mv	a0,s6
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	76e080e7          	jalr	1902(ra) # 8000168e <copyout>
    80004f28:	10054663          	bltz	a0,80005034 <exec+0x30a>
    ustack[argc] = sp;
    80004f2c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f30:	0485                	addi	s1,s1,1
    80004f32:	008d8793          	addi	a5,s11,8
    80004f36:	def43823          	sd	a5,-528(s0)
    80004f3a:	008db503          	ld	a0,8(s11)
    80004f3e:	c911                	beqz	a0,80004f52 <exec+0x228>
    if(argc >= MAXARG)
    80004f40:	09a1                	addi	s3,s3,8
    80004f42:	fb3c95e3          	bne	s9,s3,80004eec <exec+0x1c2>
  sz = sz1;
    80004f46:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f4a:	4a81                	li	s5,0
    80004f4c:	a84d                	j	80004ffe <exec+0x2d4>
  sp = sz;
    80004f4e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f50:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f52:	00349793          	slli	a5,s1,0x3
    80004f56:	f9078793          	addi	a5,a5,-112
    80004f5a:	97a2                	add	a5,a5,s0
    80004f5c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f60:	00148693          	addi	a3,s1,1
    80004f64:	068e                	slli	a3,a3,0x3
    80004f66:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f6a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f6e:	01597663          	bgeu	s2,s5,80004f7a <exec+0x250>
  sz = sz1;
    80004f72:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f76:	4a81                	li	s5,0
    80004f78:	a059                	j	80004ffe <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f7a:	e9040613          	addi	a2,s0,-368
    80004f7e:	85ca                	mv	a1,s2
    80004f80:	855a                	mv	a0,s6
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	70c080e7          	jalr	1804(ra) # 8000168e <copyout>
    80004f8a:	0a054963          	bltz	a0,8000503c <exec+0x312>
  p->trapframe->a1 = sp;
    80004f8e:	058bb783          	ld	a5,88(s7)
    80004f92:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f96:	de843783          	ld	a5,-536(s0)
    80004f9a:	0007c703          	lbu	a4,0(a5)
    80004f9e:	cf11                	beqz	a4,80004fba <exec+0x290>
    80004fa0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fa2:	02f00693          	li	a3,47
    80004fa6:	a039                	j	80004fb4 <exec+0x28a>
      last = s+1;
    80004fa8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004fac:	0785                	addi	a5,a5,1
    80004fae:	fff7c703          	lbu	a4,-1(a5)
    80004fb2:	c701                	beqz	a4,80004fba <exec+0x290>
    if(*s == '/')
    80004fb4:	fed71ce3          	bne	a4,a3,80004fac <exec+0x282>
    80004fb8:	bfc5                	j	80004fa8 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fba:	4641                	li	a2,16
    80004fbc:	de843583          	ld	a1,-536(s0)
    80004fc0:	158b8513          	addi	a0,s7,344
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	e7a080e7          	jalr	-390(ra) # 80000e3e <safestrcpy>
  oldpagetable = p->pagetable;
    80004fcc:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fd0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004fd4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fd8:	058bb783          	ld	a5,88(s7)
    80004fdc:	e6843703          	ld	a4,-408(s0)
    80004fe0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fe2:	058bb783          	ld	a5,88(s7)
    80004fe6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fea:	85ea                	mv	a1,s10
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	b42080e7          	jalr	-1214(ra) # 80001b2e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ff4:	0004851b          	sext.w	a0,s1
    80004ff8:	b3f9                	j	80004dc6 <exec+0x9c>
    80004ffa:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ffe:	df843583          	ld	a1,-520(s0)
    80005002:	855a                	mv	a0,s6
    80005004:	ffffd097          	auipc	ra,0xffffd
    80005008:	b2a080e7          	jalr	-1238(ra) # 80001b2e <proc_freepagetable>
  if(ip){
    8000500c:	da0a93e3          	bnez	s5,80004db2 <exec+0x88>
  return -1;
    80005010:	557d                	li	a0,-1
    80005012:	bb55                	j	80004dc6 <exec+0x9c>
    80005014:	df243c23          	sd	s2,-520(s0)
    80005018:	b7dd                	j	80004ffe <exec+0x2d4>
    8000501a:	df243c23          	sd	s2,-520(s0)
    8000501e:	b7c5                	j	80004ffe <exec+0x2d4>
    80005020:	df243c23          	sd	s2,-520(s0)
    80005024:	bfe9                	j	80004ffe <exec+0x2d4>
    80005026:	df243c23          	sd	s2,-520(s0)
    8000502a:	bfd1                	j	80004ffe <exec+0x2d4>
  sz = sz1;
    8000502c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005030:	4a81                	li	s5,0
    80005032:	b7f1                	j	80004ffe <exec+0x2d4>
  sz = sz1;
    80005034:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005038:	4a81                	li	s5,0
    8000503a:	b7d1                	j	80004ffe <exec+0x2d4>
  sz = sz1;
    8000503c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005040:	4a81                	li	s5,0
    80005042:	bf75                	j	80004ffe <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005044:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005048:	e0843783          	ld	a5,-504(s0)
    8000504c:	0017869b          	addiw	a3,a5,1
    80005050:	e0d43423          	sd	a3,-504(s0)
    80005054:	e0043783          	ld	a5,-512(s0)
    80005058:	0387879b          	addiw	a5,a5,56
    8000505c:	e8845703          	lhu	a4,-376(s0)
    80005060:	e0e6dfe3          	bge	a3,a4,80004e7e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005064:	2781                	sext.w	a5,a5
    80005066:	e0f43023          	sd	a5,-512(s0)
    8000506a:	03800713          	li	a4,56
    8000506e:	86be                	mv	a3,a5
    80005070:	e1840613          	addi	a2,s0,-488
    80005074:	4581                	li	a1,0
    80005076:	8556                	mv	a0,s5
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	a58080e7          	jalr	-1448(ra) # 80003ad0 <readi>
    80005080:	03800793          	li	a5,56
    80005084:	f6f51be3          	bne	a0,a5,80004ffa <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005088:	e1842783          	lw	a5,-488(s0)
    8000508c:	4705                	li	a4,1
    8000508e:	fae79de3          	bne	a5,a4,80005048 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005092:	e4043483          	ld	s1,-448(s0)
    80005096:	e3843783          	ld	a5,-456(s0)
    8000509a:	f6f4ede3          	bltu	s1,a5,80005014 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000509e:	e2843783          	ld	a5,-472(s0)
    800050a2:	94be                	add	s1,s1,a5
    800050a4:	f6f4ebe3          	bltu	s1,a5,8000501a <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800050a8:	de043703          	ld	a4,-544(s0)
    800050ac:	8ff9                	and	a5,a5,a4
    800050ae:	fbad                	bnez	a5,80005020 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050b0:	e1c42503          	lw	a0,-484(s0)
    800050b4:	00000097          	auipc	ra,0x0
    800050b8:	c5c080e7          	jalr	-932(ra) # 80004d10 <flags2perm>
    800050bc:	86aa                	mv	a3,a0
    800050be:	8626                	mv	a2,s1
    800050c0:	85ca                	mv	a1,s2
    800050c2:	855a                	mv	a0,s6
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	36e080e7          	jalr	878(ra) # 80001432 <uvmalloc>
    800050cc:	dea43c23          	sd	a0,-520(s0)
    800050d0:	d939                	beqz	a0,80005026 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050d2:	e2843c03          	ld	s8,-472(s0)
    800050d6:	e2042c83          	lw	s9,-480(s0)
    800050da:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050de:	f60b83e3          	beqz	s7,80005044 <exec+0x31a>
    800050e2:	89de                	mv	s3,s7
    800050e4:	4481                	li	s1,0
    800050e6:	bb9d                	j	80004e5c <exec+0x132>

00000000800050e8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050e8:	7179                	addi	sp,sp,-48
    800050ea:	f406                	sd	ra,40(sp)
    800050ec:	f022                	sd	s0,32(sp)
    800050ee:	ec26                	sd	s1,24(sp)
    800050f0:	e84a                	sd	s2,16(sp)
    800050f2:	1800                	addi	s0,sp,48
    800050f4:	892e                	mv	s2,a1
    800050f6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050f8:	fdc40593          	addi	a1,s0,-36
    800050fc:	ffffe097          	auipc	ra,0xffffe
    80005100:	b34080e7          	jalr	-1228(ra) # 80002c30 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005104:	fdc42703          	lw	a4,-36(s0)
    80005108:	47bd                	li	a5,15
    8000510a:	02e7eb63          	bltu	a5,a4,80005140 <argfd+0x58>
    8000510e:	ffffd097          	auipc	ra,0xffffd
    80005112:	8c0080e7          	jalr	-1856(ra) # 800019ce <myproc>
    80005116:	fdc42703          	lw	a4,-36(s0)
    8000511a:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd03a>
    8000511e:	078e                	slli	a5,a5,0x3
    80005120:	953e                	add	a0,a0,a5
    80005122:	611c                	ld	a5,0(a0)
    80005124:	c385                	beqz	a5,80005144 <argfd+0x5c>
    return -1;
  if(pfd)
    80005126:	00090463          	beqz	s2,8000512e <argfd+0x46>
    *pfd = fd;
    8000512a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000512e:	4501                	li	a0,0
  if(pf)
    80005130:	c091                	beqz	s1,80005134 <argfd+0x4c>
    *pf = f;
    80005132:	e09c                	sd	a5,0(s1)
}
    80005134:	70a2                	ld	ra,40(sp)
    80005136:	7402                	ld	s0,32(sp)
    80005138:	64e2                	ld	s1,24(sp)
    8000513a:	6942                	ld	s2,16(sp)
    8000513c:	6145                	addi	sp,sp,48
    8000513e:	8082                	ret
    return -1;
    80005140:	557d                	li	a0,-1
    80005142:	bfcd                	j	80005134 <argfd+0x4c>
    80005144:	557d                	li	a0,-1
    80005146:	b7fd                	j	80005134 <argfd+0x4c>

0000000080005148 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005148:	1101                	addi	sp,sp,-32
    8000514a:	ec06                	sd	ra,24(sp)
    8000514c:	e822                	sd	s0,16(sp)
    8000514e:	e426                	sd	s1,8(sp)
    80005150:	1000                	addi	s0,sp,32
    80005152:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005154:	ffffd097          	auipc	ra,0xffffd
    80005158:	87a080e7          	jalr	-1926(ra) # 800019ce <myproc>
    8000515c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000515e:	0d050793          	addi	a5,a0,208
    80005162:	4501                	li	a0,0
    80005164:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005166:	6398                	ld	a4,0(a5)
    80005168:	cb19                	beqz	a4,8000517e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000516a:	2505                	addiw	a0,a0,1
    8000516c:	07a1                	addi	a5,a5,8
    8000516e:	fed51ce3          	bne	a0,a3,80005166 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005172:	557d                	li	a0,-1
}
    80005174:	60e2                	ld	ra,24(sp)
    80005176:	6442                	ld	s0,16(sp)
    80005178:	64a2                	ld	s1,8(sp)
    8000517a:	6105                	addi	sp,sp,32
    8000517c:	8082                	ret
      p->ofile[fd] = f;
    8000517e:	01a50793          	addi	a5,a0,26
    80005182:	078e                	slli	a5,a5,0x3
    80005184:	963e                	add	a2,a2,a5
    80005186:	e204                	sd	s1,0(a2)
      return fd;
    80005188:	b7f5                	j	80005174 <fdalloc+0x2c>

000000008000518a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000518a:	715d                	addi	sp,sp,-80
    8000518c:	e486                	sd	ra,72(sp)
    8000518e:	e0a2                	sd	s0,64(sp)
    80005190:	fc26                	sd	s1,56(sp)
    80005192:	f84a                	sd	s2,48(sp)
    80005194:	f44e                	sd	s3,40(sp)
    80005196:	f052                	sd	s4,32(sp)
    80005198:	ec56                	sd	s5,24(sp)
    8000519a:	e85a                	sd	s6,16(sp)
    8000519c:	0880                	addi	s0,sp,80
    8000519e:	8b2e                	mv	s6,a1
    800051a0:	89b2                	mv	s3,a2
    800051a2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051a4:	fb040593          	addi	a1,s0,-80
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	e3e080e7          	jalr	-450(ra) # 80003fe6 <nameiparent>
    800051b0:	84aa                	mv	s1,a0
    800051b2:	14050f63          	beqz	a0,80005310 <create+0x186>
    return 0;

  ilock(dp);
    800051b6:	ffffe097          	auipc	ra,0xffffe
    800051ba:	666080e7          	jalr	1638(ra) # 8000381c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051be:	4601                	li	a2,0
    800051c0:	fb040593          	addi	a1,s0,-80
    800051c4:	8526                	mv	a0,s1
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	b3a080e7          	jalr	-1222(ra) # 80003d00 <dirlookup>
    800051ce:	8aaa                	mv	s5,a0
    800051d0:	c931                	beqz	a0,80005224 <create+0x9a>
    iunlockput(dp);
    800051d2:	8526                	mv	a0,s1
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	8aa080e7          	jalr	-1878(ra) # 80003a7e <iunlockput>
    ilock(ip);
    800051dc:	8556                	mv	a0,s5
    800051de:	ffffe097          	auipc	ra,0xffffe
    800051e2:	63e080e7          	jalr	1598(ra) # 8000381c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051e6:	000b059b          	sext.w	a1,s6
    800051ea:	4789                	li	a5,2
    800051ec:	02f59563          	bne	a1,a5,80005216 <create+0x8c>
    800051f0:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd064>
    800051f4:	37f9                	addiw	a5,a5,-2
    800051f6:	17c2                	slli	a5,a5,0x30
    800051f8:	93c1                	srli	a5,a5,0x30
    800051fa:	4705                	li	a4,1
    800051fc:	00f76d63          	bltu	a4,a5,80005216 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005200:	8556                	mv	a0,s5
    80005202:	60a6                	ld	ra,72(sp)
    80005204:	6406                	ld	s0,64(sp)
    80005206:	74e2                	ld	s1,56(sp)
    80005208:	7942                	ld	s2,48(sp)
    8000520a:	79a2                	ld	s3,40(sp)
    8000520c:	7a02                	ld	s4,32(sp)
    8000520e:	6ae2                	ld	s5,24(sp)
    80005210:	6b42                	ld	s6,16(sp)
    80005212:	6161                	addi	sp,sp,80
    80005214:	8082                	ret
    iunlockput(ip);
    80005216:	8556                	mv	a0,s5
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	866080e7          	jalr	-1946(ra) # 80003a7e <iunlockput>
    return 0;
    80005220:	4a81                	li	s5,0
    80005222:	bff9                	j	80005200 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005224:	85da                	mv	a1,s6
    80005226:	4088                	lw	a0,0(s1)
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	456080e7          	jalr	1110(ra) # 8000367e <ialloc>
    80005230:	8a2a                	mv	s4,a0
    80005232:	c539                	beqz	a0,80005280 <create+0xf6>
  ilock(ip);
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	5e8080e7          	jalr	1512(ra) # 8000381c <ilock>
  ip->major = major;
    8000523c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005240:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005244:	4905                	li	s2,1
    80005246:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000524a:	8552                	mv	a0,s4
    8000524c:	ffffe097          	auipc	ra,0xffffe
    80005250:	504080e7          	jalr	1284(ra) # 80003750 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005254:	000b059b          	sext.w	a1,s6
    80005258:	03258b63          	beq	a1,s2,8000528e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000525c:	004a2603          	lw	a2,4(s4)
    80005260:	fb040593          	addi	a1,s0,-80
    80005264:	8526                	mv	a0,s1
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	cb0080e7          	jalr	-848(ra) # 80003f16 <dirlink>
    8000526e:	06054f63          	bltz	a0,800052ec <create+0x162>
  iunlockput(dp);
    80005272:	8526                	mv	a0,s1
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	80a080e7          	jalr	-2038(ra) # 80003a7e <iunlockput>
  return ip;
    8000527c:	8ad2                	mv	s5,s4
    8000527e:	b749                	j	80005200 <create+0x76>
    iunlockput(dp);
    80005280:	8526                	mv	a0,s1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	7fc080e7          	jalr	2044(ra) # 80003a7e <iunlockput>
    return 0;
    8000528a:	8ad2                	mv	s5,s4
    8000528c:	bf95                	j	80005200 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000528e:	004a2603          	lw	a2,4(s4)
    80005292:	00003597          	auipc	a1,0x3
    80005296:	4d658593          	addi	a1,a1,1238 # 80008768 <syscalls+0x2b0>
    8000529a:	8552                	mv	a0,s4
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	c7a080e7          	jalr	-902(ra) # 80003f16 <dirlink>
    800052a4:	04054463          	bltz	a0,800052ec <create+0x162>
    800052a8:	40d0                	lw	a2,4(s1)
    800052aa:	00003597          	auipc	a1,0x3
    800052ae:	4c658593          	addi	a1,a1,1222 # 80008770 <syscalls+0x2b8>
    800052b2:	8552                	mv	a0,s4
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	c62080e7          	jalr	-926(ra) # 80003f16 <dirlink>
    800052bc:	02054863          	bltz	a0,800052ec <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800052c0:	004a2603          	lw	a2,4(s4)
    800052c4:	fb040593          	addi	a1,s0,-80
    800052c8:	8526                	mv	a0,s1
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	c4c080e7          	jalr	-948(ra) # 80003f16 <dirlink>
    800052d2:	00054d63          	bltz	a0,800052ec <create+0x162>
    dp->nlink++;  // for ".."
    800052d6:	04a4d783          	lhu	a5,74(s1)
    800052da:	2785                	addiw	a5,a5,1
    800052dc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052e0:	8526                	mv	a0,s1
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	46e080e7          	jalr	1134(ra) # 80003750 <iupdate>
    800052ea:	b761                	j	80005272 <create+0xe8>
  ip->nlink = 0;
    800052ec:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052f0:	8552                	mv	a0,s4
    800052f2:	ffffe097          	auipc	ra,0xffffe
    800052f6:	45e080e7          	jalr	1118(ra) # 80003750 <iupdate>
  iunlockput(ip);
    800052fa:	8552                	mv	a0,s4
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	782080e7          	jalr	1922(ra) # 80003a7e <iunlockput>
  iunlockput(dp);
    80005304:	8526                	mv	a0,s1
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	778080e7          	jalr	1912(ra) # 80003a7e <iunlockput>
  return 0;
    8000530e:	bdcd                	j	80005200 <create+0x76>
    return 0;
    80005310:	8aaa                	mv	s5,a0
    80005312:	b5fd                	j	80005200 <create+0x76>

0000000080005314 <sys_dup>:
{
    80005314:	7179                	addi	sp,sp,-48
    80005316:	f406                	sd	ra,40(sp)
    80005318:	f022                	sd	s0,32(sp)
    8000531a:	ec26                	sd	s1,24(sp)
    8000531c:	e84a                	sd	s2,16(sp)
    8000531e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005320:	fd840613          	addi	a2,s0,-40
    80005324:	4581                	li	a1,0
    80005326:	4501                	li	a0,0
    80005328:	00000097          	auipc	ra,0x0
    8000532c:	dc0080e7          	jalr	-576(ra) # 800050e8 <argfd>
    return -1;
    80005330:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005332:	02054363          	bltz	a0,80005358 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005336:	fd843903          	ld	s2,-40(s0)
    8000533a:	854a                	mv	a0,s2
    8000533c:	00000097          	auipc	ra,0x0
    80005340:	e0c080e7          	jalr	-500(ra) # 80005148 <fdalloc>
    80005344:	84aa                	mv	s1,a0
    return -1;
    80005346:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005348:	00054863          	bltz	a0,80005358 <sys_dup+0x44>
  filedup(f);
    8000534c:	854a                	mv	a0,s2
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	310080e7          	jalr	784(ra) # 8000465e <filedup>
  return fd;
    80005356:	87a6                	mv	a5,s1
}
    80005358:	853e                	mv	a0,a5
    8000535a:	70a2                	ld	ra,40(sp)
    8000535c:	7402                	ld	s0,32(sp)
    8000535e:	64e2                	ld	s1,24(sp)
    80005360:	6942                	ld	s2,16(sp)
    80005362:	6145                	addi	sp,sp,48
    80005364:	8082                	ret

0000000080005366 <sys_read>:
{
    80005366:	7179                	addi	sp,sp,-48
    80005368:	f406                	sd	ra,40(sp)
    8000536a:	f022                	sd	s0,32(sp)
    8000536c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000536e:	fd840593          	addi	a1,s0,-40
    80005372:	4505                	li	a0,1
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	8dc080e7          	jalr	-1828(ra) # 80002c50 <argaddr>
  argint(2, &n);
    8000537c:	fe440593          	addi	a1,s0,-28
    80005380:	4509                	li	a0,2
    80005382:	ffffe097          	auipc	ra,0xffffe
    80005386:	8ae080e7          	jalr	-1874(ra) # 80002c30 <argint>
  if(argfd(0, 0, &f) < 0)
    8000538a:	fe840613          	addi	a2,s0,-24
    8000538e:	4581                	li	a1,0
    80005390:	4501                	li	a0,0
    80005392:	00000097          	auipc	ra,0x0
    80005396:	d56080e7          	jalr	-682(ra) # 800050e8 <argfd>
    8000539a:	87aa                	mv	a5,a0
    return -1;
    8000539c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000539e:	0007cc63          	bltz	a5,800053b6 <sys_read+0x50>
  return fileread(f, p, n);
    800053a2:	fe442603          	lw	a2,-28(s0)
    800053a6:	fd843583          	ld	a1,-40(s0)
    800053aa:	fe843503          	ld	a0,-24(s0)
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	43c080e7          	jalr	1084(ra) # 800047ea <fileread>
}
    800053b6:	70a2                	ld	ra,40(sp)
    800053b8:	7402                	ld	s0,32(sp)
    800053ba:	6145                	addi	sp,sp,48
    800053bc:	8082                	ret

00000000800053be <sys_write>:
{
    800053be:	7179                	addi	sp,sp,-48
    800053c0:	f406                	sd	ra,40(sp)
    800053c2:	f022                	sd	s0,32(sp)
    800053c4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053c6:	fd840593          	addi	a1,s0,-40
    800053ca:	4505                	li	a0,1
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	884080e7          	jalr	-1916(ra) # 80002c50 <argaddr>
  argint(2, &n);
    800053d4:	fe440593          	addi	a1,s0,-28
    800053d8:	4509                	li	a0,2
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	856080e7          	jalr	-1962(ra) # 80002c30 <argint>
  if(argfd(0, 0, &f) < 0)
    800053e2:	fe840613          	addi	a2,s0,-24
    800053e6:	4581                	li	a1,0
    800053e8:	4501                	li	a0,0
    800053ea:	00000097          	auipc	ra,0x0
    800053ee:	cfe080e7          	jalr	-770(ra) # 800050e8 <argfd>
    800053f2:	87aa                	mv	a5,a0
    return -1;
    800053f4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053f6:	0007cc63          	bltz	a5,8000540e <sys_write+0x50>
  return filewrite(f, p, n);
    800053fa:	fe442603          	lw	a2,-28(s0)
    800053fe:	fd843583          	ld	a1,-40(s0)
    80005402:	fe843503          	ld	a0,-24(s0)
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	4a6080e7          	jalr	1190(ra) # 800048ac <filewrite>
}
    8000540e:	70a2                	ld	ra,40(sp)
    80005410:	7402                	ld	s0,32(sp)
    80005412:	6145                	addi	sp,sp,48
    80005414:	8082                	ret

0000000080005416 <sys_close>:
{
    80005416:	1101                	addi	sp,sp,-32
    80005418:	ec06                	sd	ra,24(sp)
    8000541a:	e822                	sd	s0,16(sp)
    8000541c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000541e:	fe040613          	addi	a2,s0,-32
    80005422:	fec40593          	addi	a1,s0,-20
    80005426:	4501                	li	a0,0
    80005428:	00000097          	auipc	ra,0x0
    8000542c:	cc0080e7          	jalr	-832(ra) # 800050e8 <argfd>
    return -1;
    80005430:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005432:	02054463          	bltz	a0,8000545a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005436:	ffffc097          	auipc	ra,0xffffc
    8000543a:	598080e7          	jalr	1432(ra) # 800019ce <myproc>
    8000543e:	fec42783          	lw	a5,-20(s0)
    80005442:	07e9                	addi	a5,a5,26
    80005444:	078e                	slli	a5,a5,0x3
    80005446:	953e                	add	a0,a0,a5
    80005448:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000544c:	fe043503          	ld	a0,-32(s0)
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	260080e7          	jalr	608(ra) # 800046b0 <fileclose>
  return 0;
    80005458:	4781                	li	a5,0
}
    8000545a:	853e                	mv	a0,a5
    8000545c:	60e2                	ld	ra,24(sp)
    8000545e:	6442                	ld	s0,16(sp)
    80005460:	6105                	addi	sp,sp,32
    80005462:	8082                	ret

0000000080005464 <sys_fstat>:
{
    80005464:	1101                	addi	sp,sp,-32
    80005466:	ec06                	sd	ra,24(sp)
    80005468:	e822                	sd	s0,16(sp)
    8000546a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000546c:	fe040593          	addi	a1,s0,-32
    80005470:	4505                	li	a0,1
    80005472:	ffffd097          	auipc	ra,0xffffd
    80005476:	7de080e7          	jalr	2014(ra) # 80002c50 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000547a:	fe840613          	addi	a2,s0,-24
    8000547e:	4581                	li	a1,0
    80005480:	4501                	li	a0,0
    80005482:	00000097          	auipc	ra,0x0
    80005486:	c66080e7          	jalr	-922(ra) # 800050e8 <argfd>
    8000548a:	87aa                	mv	a5,a0
    return -1;
    8000548c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000548e:	0007ca63          	bltz	a5,800054a2 <sys_fstat+0x3e>
  return filestat(f, st);
    80005492:	fe043583          	ld	a1,-32(s0)
    80005496:	fe843503          	ld	a0,-24(s0)
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	2de080e7          	jalr	734(ra) # 80004778 <filestat>
}
    800054a2:	60e2                	ld	ra,24(sp)
    800054a4:	6442                	ld	s0,16(sp)
    800054a6:	6105                	addi	sp,sp,32
    800054a8:	8082                	ret

00000000800054aa <sys_link>:
{
    800054aa:	7169                	addi	sp,sp,-304
    800054ac:	f606                	sd	ra,296(sp)
    800054ae:	f222                	sd	s0,288(sp)
    800054b0:	ee26                	sd	s1,280(sp)
    800054b2:	ea4a                	sd	s2,272(sp)
    800054b4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b6:	08000613          	li	a2,128
    800054ba:	ed040593          	addi	a1,s0,-304
    800054be:	4501                	li	a0,0
    800054c0:	ffffd097          	auipc	ra,0xffffd
    800054c4:	7b0080e7          	jalr	1968(ra) # 80002c70 <argstr>
    return -1;
    800054c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ca:	10054e63          	bltz	a0,800055e6 <sys_link+0x13c>
    800054ce:	08000613          	li	a2,128
    800054d2:	f5040593          	addi	a1,s0,-176
    800054d6:	4505                	li	a0,1
    800054d8:	ffffd097          	auipc	ra,0xffffd
    800054dc:	798080e7          	jalr	1944(ra) # 80002c70 <argstr>
    return -1;
    800054e0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e2:	10054263          	bltz	a0,800055e6 <sys_link+0x13c>
  begin_op();
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	d02080e7          	jalr	-766(ra) # 800041e8 <begin_op>
  if((ip = namei(old)) == 0){
    800054ee:	ed040513          	addi	a0,s0,-304
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	ad6080e7          	jalr	-1322(ra) # 80003fc8 <namei>
    800054fa:	84aa                	mv	s1,a0
    800054fc:	c551                	beqz	a0,80005588 <sys_link+0xde>
  ilock(ip);
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	31e080e7          	jalr	798(ra) # 8000381c <ilock>
  if(ip->type == T_DIR){
    80005506:	04449703          	lh	a4,68(s1)
    8000550a:	4785                	li	a5,1
    8000550c:	08f70463          	beq	a4,a5,80005594 <sys_link+0xea>
  ip->nlink++;
    80005510:	04a4d783          	lhu	a5,74(s1)
    80005514:	2785                	addiw	a5,a5,1
    80005516:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	234080e7          	jalr	564(ra) # 80003750 <iupdate>
  iunlock(ip);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	3b8080e7          	jalr	952(ra) # 800038de <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000552e:	fd040593          	addi	a1,s0,-48
    80005532:	f5040513          	addi	a0,s0,-176
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	ab0080e7          	jalr	-1360(ra) # 80003fe6 <nameiparent>
    8000553e:	892a                	mv	s2,a0
    80005540:	c935                	beqz	a0,800055b4 <sys_link+0x10a>
  ilock(dp);
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	2da080e7          	jalr	730(ra) # 8000381c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000554a:	00092703          	lw	a4,0(s2)
    8000554e:	409c                	lw	a5,0(s1)
    80005550:	04f71d63          	bne	a4,a5,800055aa <sys_link+0x100>
    80005554:	40d0                	lw	a2,4(s1)
    80005556:	fd040593          	addi	a1,s0,-48
    8000555a:	854a                	mv	a0,s2
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	9ba080e7          	jalr	-1606(ra) # 80003f16 <dirlink>
    80005564:	04054363          	bltz	a0,800055aa <sys_link+0x100>
  iunlockput(dp);
    80005568:	854a                	mv	a0,s2
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	514080e7          	jalr	1300(ra) # 80003a7e <iunlockput>
  iput(ip);
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	462080e7          	jalr	1122(ra) # 800039d6 <iput>
  end_op();
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	cea080e7          	jalr	-790(ra) # 80004266 <end_op>
  return 0;
    80005584:	4781                	li	a5,0
    80005586:	a085                	j	800055e6 <sys_link+0x13c>
    end_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	cde080e7          	jalr	-802(ra) # 80004266 <end_op>
    return -1;
    80005590:	57fd                	li	a5,-1
    80005592:	a891                	j	800055e6 <sys_link+0x13c>
    iunlockput(ip);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	4e8080e7          	jalr	1256(ra) # 80003a7e <iunlockput>
    end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	cc8080e7          	jalr	-824(ra) # 80004266 <end_op>
    return -1;
    800055a6:	57fd                	li	a5,-1
    800055a8:	a83d                	j	800055e6 <sys_link+0x13c>
    iunlockput(dp);
    800055aa:	854a                	mv	a0,s2
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	4d2080e7          	jalr	1234(ra) # 80003a7e <iunlockput>
  ilock(ip);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	266080e7          	jalr	614(ra) # 8000381c <ilock>
  ip->nlink--;
    800055be:	04a4d783          	lhu	a5,74(s1)
    800055c2:	37fd                	addiw	a5,a5,-1
    800055c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	186080e7          	jalr	390(ra) # 80003750 <iupdate>
  iunlockput(ip);
    800055d2:	8526                	mv	a0,s1
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	4aa080e7          	jalr	1194(ra) # 80003a7e <iunlockput>
  end_op();
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	c8a080e7          	jalr	-886(ra) # 80004266 <end_op>
  return -1;
    800055e4:	57fd                	li	a5,-1
}
    800055e6:	853e                	mv	a0,a5
    800055e8:	70b2                	ld	ra,296(sp)
    800055ea:	7412                	ld	s0,288(sp)
    800055ec:	64f2                	ld	s1,280(sp)
    800055ee:	6952                	ld	s2,272(sp)
    800055f0:	6155                	addi	sp,sp,304
    800055f2:	8082                	ret

00000000800055f4 <sys_unlink>:
{
    800055f4:	7151                	addi	sp,sp,-240
    800055f6:	f586                	sd	ra,232(sp)
    800055f8:	f1a2                	sd	s0,224(sp)
    800055fa:	eda6                	sd	s1,216(sp)
    800055fc:	e9ca                	sd	s2,208(sp)
    800055fe:	e5ce                	sd	s3,200(sp)
    80005600:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005602:	08000613          	li	a2,128
    80005606:	f3040593          	addi	a1,s0,-208
    8000560a:	4501                	li	a0,0
    8000560c:	ffffd097          	auipc	ra,0xffffd
    80005610:	664080e7          	jalr	1636(ra) # 80002c70 <argstr>
    80005614:	18054163          	bltz	a0,80005796 <sys_unlink+0x1a2>
  begin_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	bd0080e7          	jalr	-1072(ra) # 800041e8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005620:	fb040593          	addi	a1,s0,-80
    80005624:	f3040513          	addi	a0,s0,-208
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	9be080e7          	jalr	-1602(ra) # 80003fe6 <nameiparent>
    80005630:	84aa                	mv	s1,a0
    80005632:	c979                	beqz	a0,80005708 <sys_unlink+0x114>
  ilock(dp);
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	1e8080e7          	jalr	488(ra) # 8000381c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000563c:	00003597          	auipc	a1,0x3
    80005640:	12c58593          	addi	a1,a1,300 # 80008768 <syscalls+0x2b0>
    80005644:	fb040513          	addi	a0,s0,-80
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	69e080e7          	jalr	1694(ra) # 80003ce6 <namecmp>
    80005650:	14050a63          	beqz	a0,800057a4 <sys_unlink+0x1b0>
    80005654:	00003597          	auipc	a1,0x3
    80005658:	11c58593          	addi	a1,a1,284 # 80008770 <syscalls+0x2b8>
    8000565c:	fb040513          	addi	a0,s0,-80
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	686080e7          	jalr	1670(ra) # 80003ce6 <namecmp>
    80005668:	12050e63          	beqz	a0,800057a4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000566c:	f2c40613          	addi	a2,s0,-212
    80005670:	fb040593          	addi	a1,s0,-80
    80005674:	8526                	mv	a0,s1
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	68a080e7          	jalr	1674(ra) # 80003d00 <dirlookup>
    8000567e:	892a                	mv	s2,a0
    80005680:	12050263          	beqz	a0,800057a4 <sys_unlink+0x1b0>
  ilock(ip);
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	198080e7          	jalr	408(ra) # 8000381c <ilock>
  if(ip->nlink < 1)
    8000568c:	04a91783          	lh	a5,74(s2)
    80005690:	08f05263          	blez	a5,80005714 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005694:	04491703          	lh	a4,68(s2)
    80005698:	4785                	li	a5,1
    8000569a:	08f70563          	beq	a4,a5,80005724 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000569e:	4641                	li	a2,16
    800056a0:	4581                	li	a1,0
    800056a2:	fc040513          	addi	a0,s0,-64
    800056a6:	ffffb097          	auipc	ra,0xffffb
    800056aa:	64e080e7          	jalr	1614(ra) # 80000cf4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ae:	4741                	li	a4,16
    800056b0:	f2c42683          	lw	a3,-212(s0)
    800056b4:	fc040613          	addi	a2,s0,-64
    800056b8:	4581                	li	a1,0
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	50c080e7          	jalr	1292(ra) # 80003bc8 <writei>
    800056c4:	47c1                	li	a5,16
    800056c6:	0af51563          	bne	a0,a5,80005770 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056ca:	04491703          	lh	a4,68(s2)
    800056ce:	4785                	li	a5,1
    800056d0:	0af70863          	beq	a4,a5,80005780 <sys_unlink+0x18c>
  iunlockput(dp);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	3a8080e7          	jalr	936(ra) # 80003a7e <iunlockput>
  ip->nlink--;
    800056de:	04a95783          	lhu	a5,74(s2)
    800056e2:	37fd                	addiw	a5,a5,-1
    800056e4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056e8:	854a                	mv	a0,s2
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	066080e7          	jalr	102(ra) # 80003750 <iupdate>
  iunlockput(ip);
    800056f2:	854a                	mv	a0,s2
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	38a080e7          	jalr	906(ra) # 80003a7e <iunlockput>
  end_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	b6a080e7          	jalr	-1174(ra) # 80004266 <end_op>
  return 0;
    80005704:	4501                	li	a0,0
    80005706:	a84d                	j	800057b8 <sys_unlink+0x1c4>
    end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	b5e080e7          	jalr	-1186(ra) # 80004266 <end_op>
    return -1;
    80005710:	557d                	li	a0,-1
    80005712:	a05d                	j	800057b8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005714:	00003517          	auipc	a0,0x3
    80005718:	06450513          	addi	a0,a0,100 # 80008778 <syscalls+0x2c0>
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	e24080e7          	jalr	-476(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005724:	04c92703          	lw	a4,76(s2)
    80005728:	02000793          	li	a5,32
    8000572c:	f6e7f9e3          	bgeu	a5,a4,8000569e <sys_unlink+0xaa>
    80005730:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005734:	4741                	li	a4,16
    80005736:	86ce                	mv	a3,s3
    80005738:	f1840613          	addi	a2,s0,-232
    8000573c:	4581                	li	a1,0
    8000573e:	854a                	mv	a0,s2
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	390080e7          	jalr	912(ra) # 80003ad0 <readi>
    80005748:	47c1                	li	a5,16
    8000574a:	00f51b63          	bne	a0,a5,80005760 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000574e:	f1845783          	lhu	a5,-232(s0)
    80005752:	e7a1                	bnez	a5,8000579a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005754:	29c1                	addiw	s3,s3,16
    80005756:	04c92783          	lw	a5,76(s2)
    8000575a:	fcf9ede3          	bltu	s3,a5,80005734 <sys_unlink+0x140>
    8000575e:	b781                	j	8000569e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005760:	00003517          	auipc	a0,0x3
    80005764:	03050513          	addi	a0,a0,48 # 80008790 <syscalls+0x2d8>
    80005768:	ffffb097          	auipc	ra,0xffffb
    8000576c:	dd8080e7          	jalr	-552(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005770:	00003517          	auipc	a0,0x3
    80005774:	03850513          	addi	a0,a0,56 # 800087a8 <syscalls+0x2f0>
    80005778:	ffffb097          	auipc	ra,0xffffb
    8000577c:	dc8080e7          	jalr	-568(ra) # 80000540 <panic>
    dp->nlink--;
    80005780:	04a4d783          	lhu	a5,74(s1)
    80005784:	37fd                	addiw	a5,a5,-1
    80005786:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	fc4080e7          	jalr	-60(ra) # 80003750 <iupdate>
    80005794:	b781                	j	800056d4 <sys_unlink+0xe0>
    return -1;
    80005796:	557d                	li	a0,-1
    80005798:	a005                	j	800057b8 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000579a:	854a                	mv	a0,s2
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	2e2080e7          	jalr	738(ra) # 80003a7e <iunlockput>
  iunlockput(dp);
    800057a4:	8526                	mv	a0,s1
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	2d8080e7          	jalr	728(ra) # 80003a7e <iunlockput>
  end_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	ab8080e7          	jalr	-1352(ra) # 80004266 <end_op>
  return -1;
    800057b6:	557d                	li	a0,-1
}
    800057b8:	70ae                	ld	ra,232(sp)
    800057ba:	740e                	ld	s0,224(sp)
    800057bc:	64ee                	ld	s1,216(sp)
    800057be:	694e                	ld	s2,208(sp)
    800057c0:	69ae                	ld	s3,200(sp)
    800057c2:	616d                	addi	sp,sp,240
    800057c4:	8082                	ret

00000000800057c6 <sys_open>:

uint64
sys_open(void)
{
    800057c6:	7131                	addi	sp,sp,-192
    800057c8:	fd06                	sd	ra,184(sp)
    800057ca:	f922                	sd	s0,176(sp)
    800057cc:	f526                	sd	s1,168(sp)
    800057ce:	f14a                	sd	s2,160(sp)
    800057d0:	ed4e                	sd	s3,152(sp)
    800057d2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800057d4:	f4c40593          	addi	a1,s0,-180
    800057d8:	4505                	li	a0,1
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	456080e7          	jalr	1110(ra) # 80002c30 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057e2:	08000613          	li	a2,128
    800057e6:	f5040593          	addi	a1,s0,-176
    800057ea:	4501                	li	a0,0
    800057ec:	ffffd097          	auipc	ra,0xffffd
    800057f0:	484080e7          	jalr	1156(ra) # 80002c70 <argstr>
    800057f4:	87aa                	mv	a5,a0
    return -1;
    800057f6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057f8:	0a07c963          	bltz	a5,800058aa <sys_open+0xe4>

  begin_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	9ec080e7          	jalr	-1556(ra) # 800041e8 <begin_op>

  if(omode & O_CREATE){
    80005804:	f4c42783          	lw	a5,-180(s0)
    80005808:	2007f793          	andi	a5,a5,512
    8000580c:	cfc5                	beqz	a5,800058c4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000580e:	4681                	li	a3,0
    80005810:	4601                	li	a2,0
    80005812:	4589                	li	a1,2
    80005814:	f5040513          	addi	a0,s0,-176
    80005818:	00000097          	auipc	ra,0x0
    8000581c:	972080e7          	jalr	-1678(ra) # 8000518a <create>
    80005820:	84aa                	mv	s1,a0
    if(ip == 0){
    80005822:	c959                	beqz	a0,800058b8 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005824:	04449703          	lh	a4,68(s1)
    80005828:	478d                	li	a5,3
    8000582a:	00f71763          	bne	a4,a5,80005838 <sys_open+0x72>
    8000582e:	0464d703          	lhu	a4,70(s1)
    80005832:	47a5                	li	a5,9
    80005834:	0ce7ed63          	bltu	a5,a4,8000590e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	dbc080e7          	jalr	-580(ra) # 800045f4 <filealloc>
    80005840:	89aa                	mv	s3,a0
    80005842:	10050363          	beqz	a0,80005948 <sys_open+0x182>
    80005846:	00000097          	auipc	ra,0x0
    8000584a:	902080e7          	jalr	-1790(ra) # 80005148 <fdalloc>
    8000584e:	892a                	mv	s2,a0
    80005850:	0e054763          	bltz	a0,8000593e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005854:	04449703          	lh	a4,68(s1)
    80005858:	478d                	li	a5,3
    8000585a:	0cf70563          	beq	a4,a5,80005924 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000585e:	4789                	li	a5,2
    80005860:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005864:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005868:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000586c:	f4c42783          	lw	a5,-180(s0)
    80005870:	0017c713          	xori	a4,a5,1
    80005874:	8b05                	andi	a4,a4,1
    80005876:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000587a:	0037f713          	andi	a4,a5,3
    8000587e:	00e03733          	snez	a4,a4
    80005882:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005886:	4007f793          	andi	a5,a5,1024
    8000588a:	c791                	beqz	a5,80005896 <sys_open+0xd0>
    8000588c:	04449703          	lh	a4,68(s1)
    80005890:	4789                	li	a5,2
    80005892:	0af70063          	beq	a4,a5,80005932 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005896:	8526                	mv	a0,s1
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	046080e7          	jalr	70(ra) # 800038de <iunlock>
  end_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	9c6080e7          	jalr	-1594(ra) # 80004266 <end_op>

  return fd;
    800058a8:	854a                	mv	a0,s2
}
    800058aa:	70ea                	ld	ra,184(sp)
    800058ac:	744a                	ld	s0,176(sp)
    800058ae:	74aa                	ld	s1,168(sp)
    800058b0:	790a                	ld	s2,160(sp)
    800058b2:	69ea                	ld	s3,152(sp)
    800058b4:	6129                	addi	sp,sp,192
    800058b6:	8082                	ret
      end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	9ae080e7          	jalr	-1618(ra) # 80004266 <end_op>
      return -1;
    800058c0:	557d                	li	a0,-1
    800058c2:	b7e5                	j	800058aa <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058c4:	f5040513          	addi	a0,s0,-176
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	700080e7          	jalr	1792(ra) # 80003fc8 <namei>
    800058d0:	84aa                	mv	s1,a0
    800058d2:	c905                	beqz	a0,80005902 <sys_open+0x13c>
    ilock(ip);
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	f48080e7          	jalr	-184(ra) # 8000381c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058dc:	04449703          	lh	a4,68(s1)
    800058e0:	4785                	li	a5,1
    800058e2:	f4f711e3          	bne	a4,a5,80005824 <sys_open+0x5e>
    800058e6:	f4c42783          	lw	a5,-180(s0)
    800058ea:	d7b9                	beqz	a5,80005838 <sys_open+0x72>
      iunlockput(ip);
    800058ec:	8526                	mv	a0,s1
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	190080e7          	jalr	400(ra) # 80003a7e <iunlockput>
      end_op();
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	970080e7          	jalr	-1680(ra) # 80004266 <end_op>
      return -1;
    800058fe:	557d                	li	a0,-1
    80005900:	b76d                	j	800058aa <sys_open+0xe4>
      end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	964080e7          	jalr	-1692(ra) # 80004266 <end_op>
      return -1;
    8000590a:	557d                	li	a0,-1
    8000590c:	bf79                	j	800058aa <sys_open+0xe4>
    iunlockput(ip);
    8000590e:	8526                	mv	a0,s1
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	16e080e7          	jalr	366(ra) # 80003a7e <iunlockput>
    end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	94e080e7          	jalr	-1714(ra) # 80004266 <end_op>
    return -1;
    80005920:	557d                	li	a0,-1
    80005922:	b761                	j	800058aa <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005924:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005928:	04649783          	lh	a5,70(s1)
    8000592c:	02f99223          	sh	a5,36(s3)
    80005930:	bf25                	j	80005868 <sys_open+0xa2>
    itrunc(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	ff6080e7          	jalr	-10(ra) # 8000392a <itrunc>
    8000593c:	bfa9                	j	80005896 <sys_open+0xd0>
      fileclose(f);
    8000593e:	854e                	mv	a0,s3
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	d70080e7          	jalr	-656(ra) # 800046b0 <fileclose>
    iunlockput(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	134080e7          	jalr	308(ra) # 80003a7e <iunlockput>
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	914080e7          	jalr	-1772(ra) # 80004266 <end_op>
    return -1;
    8000595a:	557d                	li	a0,-1
    8000595c:	b7b9                	j	800058aa <sys_open+0xe4>

000000008000595e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000595e:	7175                	addi	sp,sp,-144
    80005960:	e506                	sd	ra,136(sp)
    80005962:	e122                	sd	s0,128(sp)
    80005964:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	882080e7          	jalr	-1918(ra) # 800041e8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000596e:	08000613          	li	a2,128
    80005972:	f7040593          	addi	a1,s0,-144
    80005976:	4501                	li	a0,0
    80005978:	ffffd097          	auipc	ra,0xffffd
    8000597c:	2f8080e7          	jalr	760(ra) # 80002c70 <argstr>
    80005980:	02054963          	bltz	a0,800059b2 <sys_mkdir+0x54>
    80005984:	4681                	li	a3,0
    80005986:	4601                	li	a2,0
    80005988:	4585                	li	a1,1
    8000598a:	f7040513          	addi	a0,s0,-144
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	7fc080e7          	jalr	2044(ra) # 8000518a <create>
    80005996:	cd11                	beqz	a0,800059b2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	0e6080e7          	jalr	230(ra) # 80003a7e <iunlockput>
  end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	8c6080e7          	jalr	-1850(ra) # 80004266 <end_op>
  return 0;
    800059a8:	4501                	li	a0,0
}
    800059aa:	60aa                	ld	ra,136(sp)
    800059ac:	640a                	ld	s0,128(sp)
    800059ae:	6149                	addi	sp,sp,144
    800059b0:	8082                	ret
    end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	8b4080e7          	jalr	-1868(ra) # 80004266 <end_op>
    return -1;
    800059ba:	557d                	li	a0,-1
    800059bc:	b7fd                	j	800059aa <sys_mkdir+0x4c>

00000000800059be <sys_mknod>:

uint64
sys_mknod(void)
{
    800059be:	7135                	addi	sp,sp,-160
    800059c0:	ed06                	sd	ra,152(sp)
    800059c2:	e922                	sd	s0,144(sp)
    800059c4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	822080e7          	jalr	-2014(ra) # 800041e8 <begin_op>
  argint(1, &major);
    800059ce:	f6c40593          	addi	a1,s0,-148
    800059d2:	4505                	li	a0,1
    800059d4:	ffffd097          	auipc	ra,0xffffd
    800059d8:	25c080e7          	jalr	604(ra) # 80002c30 <argint>
  argint(2, &minor);
    800059dc:	f6840593          	addi	a1,s0,-152
    800059e0:	4509                	li	a0,2
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	24e080e7          	jalr	590(ra) # 80002c30 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ea:	08000613          	li	a2,128
    800059ee:	f7040593          	addi	a1,s0,-144
    800059f2:	4501                	li	a0,0
    800059f4:	ffffd097          	auipc	ra,0xffffd
    800059f8:	27c080e7          	jalr	636(ra) # 80002c70 <argstr>
    800059fc:	02054b63          	bltz	a0,80005a32 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a00:	f6841683          	lh	a3,-152(s0)
    80005a04:	f6c41603          	lh	a2,-148(s0)
    80005a08:	458d                	li	a1,3
    80005a0a:	f7040513          	addi	a0,s0,-144
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	77c080e7          	jalr	1916(ra) # 8000518a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a16:	cd11                	beqz	a0,80005a32 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	066080e7          	jalr	102(ra) # 80003a7e <iunlockput>
  end_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	846080e7          	jalr	-1978(ra) # 80004266 <end_op>
  return 0;
    80005a28:	4501                	li	a0,0
}
    80005a2a:	60ea                	ld	ra,152(sp)
    80005a2c:	644a                	ld	s0,144(sp)
    80005a2e:	610d                	addi	sp,sp,160
    80005a30:	8082                	ret
    end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	834080e7          	jalr	-1996(ra) # 80004266 <end_op>
    return -1;
    80005a3a:	557d                	li	a0,-1
    80005a3c:	b7fd                	j	80005a2a <sys_mknod+0x6c>

0000000080005a3e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a3e:	7135                	addi	sp,sp,-160
    80005a40:	ed06                	sd	ra,152(sp)
    80005a42:	e922                	sd	s0,144(sp)
    80005a44:	e526                	sd	s1,136(sp)
    80005a46:	e14a                	sd	s2,128(sp)
    80005a48:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a4a:	ffffc097          	auipc	ra,0xffffc
    80005a4e:	f84080e7          	jalr	-124(ra) # 800019ce <myproc>
    80005a52:	892a                	mv	s2,a0
  
  begin_op();
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	794080e7          	jalr	1940(ra) # 800041e8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a5c:	08000613          	li	a2,128
    80005a60:	f6040593          	addi	a1,s0,-160
    80005a64:	4501                	li	a0,0
    80005a66:	ffffd097          	auipc	ra,0xffffd
    80005a6a:	20a080e7          	jalr	522(ra) # 80002c70 <argstr>
    80005a6e:	04054b63          	bltz	a0,80005ac4 <sys_chdir+0x86>
    80005a72:	f6040513          	addi	a0,s0,-160
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	552080e7          	jalr	1362(ra) # 80003fc8 <namei>
    80005a7e:	84aa                	mv	s1,a0
    80005a80:	c131                	beqz	a0,80005ac4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	d9a080e7          	jalr	-614(ra) # 8000381c <ilock>
  if(ip->type != T_DIR){
    80005a8a:	04449703          	lh	a4,68(s1)
    80005a8e:	4785                	li	a5,1
    80005a90:	04f71063          	bne	a4,a5,80005ad0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a94:	8526                	mv	a0,s1
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	e48080e7          	jalr	-440(ra) # 800038de <iunlock>
  iput(p->cwd);
    80005a9e:	15093503          	ld	a0,336(s2)
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	f34080e7          	jalr	-204(ra) # 800039d6 <iput>
  end_op();
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	7bc080e7          	jalr	1980(ra) # 80004266 <end_op>
  p->cwd = ip;
    80005ab2:	14993823          	sd	s1,336(s2)
  return 0;
    80005ab6:	4501                	li	a0,0
}
    80005ab8:	60ea                	ld	ra,152(sp)
    80005aba:	644a                	ld	s0,144(sp)
    80005abc:	64aa                	ld	s1,136(sp)
    80005abe:	690a                	ld	s2,128(sp)
    80005ac0:	610d                	addi	sp,sp,160
    80005ac2:	8082                	ret
    end_op();
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	7a2080e7          	jalr	1954(ra) # 80004266 <end_op>
    return -1;
    80005acc:	557d                	li	a0,-1
    80005ace:	b7ed                	j	80005ab8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ad0:	8526                	mv	a0,s1
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	fac080e7          	jalr	-84(ra) # 80003a7e <iunlockput>
    end_op();
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	78c080e7          	jalr	1932(ra) # 80004266 <end_op>
    return -1;
    80005ae2:	557d                	li	a0,-1
    80005ae4:	bfd1                	j	80005ab8 <sys_chdir+0x7a>

0000000080005ae6 <sys_exec>:

uint64
sys_exec(void)
{
    80005ae6:	7145                	addi	sp,sp,-464
    80005ae8:	e786                	sd	ra,456(sp)
    80005aea:	e3a2                	sd	s0,448(sp)
    80005aec:	ff26                	sd	s1,440(sp)
    80005aee:	fb4a                	sd	s2,432(sp)
    80005af0:	f74e                	sd	s3,424(sp)
    80005af2:	f352                	sd	s4,416(sp)
    80005af4:	ef56                	sd	s5,408(sp)
    80005af6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005af8:	e3840593          	addi	a1,s0,-456
    80005afc:	4505                	li	a0,1
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	152080e7          	jalr	338(ra) # 80002c50 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b06:	08000613          	li	a2,128
    80005b0a:	f4040593          	addi	a1,s0,-192
    80005b0e:	4501                	li	a0,0
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	160080e7          	jalr	352(ra) # 80002c70 <argstr>
    80005b18:	87aa                	mv	a5,a0
    return -1;
    80005b1a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b1c:	0c07c363          	bltz	a5,80005be2 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005b20:	10000613          	li	a2,256
    80005b24:	4581                	li	a1,0
    80005b26:	e4040513          	addi	a0,s0,-448
    80005b2a:	ffffb097          	auipc	ra,0xffffb
    80005b2e:	1ca080e7          	jalr	458(ra) # 80000cf4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b32:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b36:	89a6                	mv	s3,s1
    80005b38:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b3a:	02000a13          	li	s4,32
    80005b3e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b42:	00391513          	slli	a0,s2,0x3
    80005b46:	e3040593          	addi	a1,s0,-464
    80005b4a:	e3843783          	ld	a5,-456(s0)
    80005b4e:	953e                	add	a0,a0,a5
    80005b50:	ffffd097          	auipc	ra,0xffffd
    80005b54:	042080e7          	jalr	66(ra) # 80002b92 <fetchaddr>
    80005b58:	02054a63          	bltz	a0,80005b8c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b5c:	e3043783          	ld	a5,-464(s0)
    80005b60:	c3b9                	beqz	a5,80005ba6 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b62:	ffffb097          	auipc	ra,0xffffb
    80005b66:	f84080e7          	jalr	-124(ra) # 80000ae6 <kalloc>
    80005b6a:	85aa                	mv	a1,a0
    80005b6c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b70:	cd11                	beqz	a0,80005b8c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b72:	6605                	lui	a2,0x1
    80005b74:	e3043503          	ld	a0,-464(s0)
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	06c080e7          	jalr	108(ra) # 80002be4 <fetchstr>
    80005b80:	00054663          	bltz	a0,80005b8c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b84:	0905                	addi	s2,s2,1
    80005b86:	09a1                	addi	s3,s3,8
    80005b88:	fb491be3          	bne	s2,s4,80005b3e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8c:	f4040913          	addi	s2,s0,-192
    80005b90:	6088                	ld	a0,0(s1)
    80005b92:	c539                	beqz	a0,80005be0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b94:	ffffb097          	auipc	ra,0xffffb
    80005b98:	e54080e7          	jalr	-428(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9c:	04a1                	addi	s1,s1,8
    80005b9e:	ff2499e3          	bne	s1,s2,80005b90 <sys_exec+0xaa>
  return -1;
    80005ba2:	557d                	li	a0,-1
    80005ba4:	a83d                	j	80005be2 <sys_exec+0xfc>
      argv[i] = 0;
    80005ba6:	0a8e                	slli	s5,s5,0x3
    80005ba8:	fc0a8793          	addi	a5,s5,-64
    80005bac:	00878ab3          	add	s5,a5,s0
    80005bb0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bb4:	e4040593          	addi	a1,s0,-448
    80005bb8:	f4040513          	addi	a0,s0,-192
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	16e080e7          	jalr	366(ra) # 80004d2a <exec>
    80005bc4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc6:	f4040993          	addi	s3,s0,-192
    80005bca:	6088                	ld	a0,0(s1)
    80005bcc:	c901                	beqz	a0,80005bdc <sys_exec+0xf6>
    kfree(argv[i]);
    80005bce:	ffffb097          	auipc	ra,0xffffb
    80005bd2:	e1a080e7          	jalr	-486(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd6:	04a1                	addi	s1,s1,8
    80005bd8:	ff3499e3          	bne	s1,s3,80005bca <sys_exec+0xe4>
  return ret;
    80005bdc:	854a                	mv	a0,s2
    80005bde:	a011                	j	80005be2 <sys_exec+0xfc>
  return -1;
    80005be0:	557d                	li	a0,-1
}
    80005be2:	60be                	ld	ra,456(sp)
    80005be4:	641e                	ld	s0,448(sp)
    80005be6:	74fa                	ld	s1,440(sp)
    80005be8:	795a                	ld	s2,432(sp)
    80005bea:	79ba                	ld	s3,424(sp)
    80005bec:	7a1a                	ld	s4,416(sp)
    80005bee:	6afa                	ld	s5,408(sp)
    80005bf0:	6179                	addi	sp,sp,464
    80005bf2:	8082                	ret

0000000080005bf4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bf4:	7139                	addi	sp,sp,-64
    80005bf6:	fc06                	sd	ra,56(sp)
    80005bf8:	f822                	sd	s0,48(sp)
    80005bfa:	f426                	sd	s1,40(sp)
    80005bfc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bfe:	ffffc097          	auipc	ra,0xffffc
    80005c02:	dd0080e7          	jalr	-560(ra) # 800019ce <myproc>
    80005c06:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c08:	fd840593          	addi	a1,s0,-40
    80005c0c:	4501                	li	a0,0
    80005c0e:	ffffd097          	auipc	ra,0xffffd
    80005c12:	042080e7          	jalr	66(ra) # 80002c50 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c16:	fc840593          	addi	a1,s0,-56
    80005c1a:	fd040513          	addi	a0,s0,-48
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	dc2080e7          	jalr	-574(ra) # 800049e0 <pipealloc>
    return -1;
    80005c26:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c28:	0c054463          	bltz	a0,80005cf0 <sys_pipe+0xfc>
  fd0 = -1;
    80005c2c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c30:	fd043503          	ld	a0,-48(s0)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	514080e7          	jalr	1300(ra) # 80005148 <fdalloc>
    80005c3c:	fca42223          	sw	a0,-60(s0)
    80005c40:	08054b63          	bltz	a0,80005cd6 <sys_pipe+0xe2>
    80005c44:	fc843503          	ld	a0,-56(s0)
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	500080e7          	jalr	1280(ra) # 80005148 <fdalloc>
    80005c50:	fca42023          	sw	a0,-64(s0)
    80005c54:	06054863          	bltz	a0,80005cc4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c58:	4691                	li	a3,4
    80005c5a:	fc440613          	addi	a2,s0,-60
    80005c5e:	fd843583          	ld	a1,-40(s0)
    80005c62:	68a8                	ld	a0,80(s1)
    80005c64:	ffffc097          	auipc	ra,0xffffc
    80005c68:	a2a080e7          	jalr	-1494(ra) # 8000168e <copyout>
    80005c6c:	02054063          	bltz	a0,80005c8c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c70:	4691                	li	a3,4
    80005c72:	fc040613          	addi	a2,s0,-64
    80005c76:	fd843583          	ld	a1,-40(s0)
    80005c7a:	0591                	addi	a1,a1,4
    80005c7c:	68a8                	ld	a0,80(s1)
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	a10080e7          	jalr	-1520(ra) # 8000168e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c86:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c88:	06055463          	bgez	a0,80005cf0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c8c:	fc442783          	lw	a5,-60(s0)
    80005c90:	07e9                	addi	a5,a5,26
    80005c92:	078e                	slli	a5,a5,0x3
    80005c94:	97a6                	add	a5,a5,s1
    80005c96:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c9a:	fc042783          	lw	a5,-64(s0)
    80005c9e:	07e9                	addi	a5,a5,26
    80005ca0:	078e                	slli	a5,a5,0x3
    80005ca2:	94be                	add	s1,s1,a5
    80005ca4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ca8:	fd043503          	ld	a0,-48(s0)
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	a04080e7          	jalr	-1532(ra) # 800046b0 <fileclose>
    fileclose(wf);
    80005cb4:	fc843503          	ld	a0,-56(s0)
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	9f8080e7          	jalr	-1544(ra) # 800046b0 <fileclose>
    return -1;
    80005cc0:	57fd                	li	a5,-1
    80005cc2:	a03d                	j	80005cf0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005cc4:	fc442783          	lw	a5,-60(s0)
    80005cc8:	0007c763          	bltz	a5,80005cd6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ccc:	07e9                	addi	a5,a5,26
    80005cce:	078e                	slli	a5,a5,0x3
    80005cd0:	97a6                	add	a5,a5,s1
    80005cd2:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005cd6:	fd043503          	ld	a0,-48(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	9d6080e7          	jalr	-1578(ra) # 800046b0 <fileclose>
    fileclose(wf);
    80005ce2:	fc843503          	ld	a0,-56(s0)
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	9ca080e7          	jalr	-1590(ra) # 800046b0 <fileclose>
    return -1;
    80005cee:	57fd                	li	a5,-1
}
    80005cf0:	853e                	mv	a0,a5
    80005cf2:	70e2                	ld	ra,56(sp)
    80005cf4:	7442                	ld	s0,48(sp)
    80005cf6:	74a2                	ld	s1,40(sp)
    80005cf8:	6121                	addi	sp,sp,64
    80005cfa:	8082                	ret
    80005cfc:	0000                	unimp
	...

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	d1ffc0ef          	jal	ra,80002a5e <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	6d0c                	ld	a1,24(a0)
    80005d9c:	7110                	ld	a2,32(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bca080e7          	jalr	-1078(ra) # 800019a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	97aa                	add	a5,a5,a0
    80005dfc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	b92080e7          	jalr	-1134(ra) # 800019a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5151b          	slliw	a0,a0,0xd
    80005e1c:	0c2017b7          	lui	a5,0xc201
    80005e20:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e22:	43c8                	lw	a0,4(a5)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	b6a080e7          	jalr	-1174(ra) # 800019a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	04a7cc63          	blt	a5,a0,80005eb8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e64:	0001c797          	auipc	a5,0x1c
    80005e68:	03c78793          	addi	a5,a5,60 # 80021ea0 <disk>
    80005e6c:	97aa                	add	a5,a5,a0
    80005e6e:	0187c783          	lbu	a5,24(a5)
    80005e72:	ebb9                	bnez	a5,80005ec8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e74:	00451693          	slli	a3,a0,0x4
    80005e78:	0001c797          	auipc	a5,0x1c
    80005e7c:	02878793          	addi	a5,a5,40 # 80021ea0 <disk>
    80005e80:	6398                	ld	a4,0(a5)
    80005e82:	9736                	add	a4,a4,a3
    80005e84:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e88:	6398                	ld	a4,0(a5)
    80005e8a:	9736                	add	a4,a4,a3
    80005e8c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e90:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e94:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e98:	97aa                	add	a5,a5,a0
    80005e9a:	4705                	li	a4,1
    80005e9c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005ea0:	0001c517          	auipc	a0,0x1c
    80005ea4:	01850513          	addi	a0,a0,24 # 80021eb8 <disk+0x18>
    80005ea8:	ffffc097          	auipc	ra,0xffffc
    80005eac:	236080e7          	jalr	566(ra) # 800020de <wakeup>
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret
    panic("free_desc 1");
    80005eb8:	00003517          	auipc	a0,0x3
    80005ebc:	90050513          	addi	a0,a0,-1792 # 800087b8 <syscalls+0x300>
    80005ec0:	ffffa097          	auipc	ra,0xffffa
    80005ec4:	680080e7          	jalr	1664(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005ec8:	00003517          	auipc	a0,0x3
    80005ecc:	90050513          	addi	a0,a0,-1792 # 800087c8 <syscalls+0x310>
    80005ed0:	ffffa097          	auipc	ra,0xffffa
    80005ed4:	670080e7          	jalr	1648(ra) # 80000540 <panic>

0000000080005ed8 <virtio_disk_init>:
{
    80005ed8:	1101                	addi	sp,sp,-32
    80005eda:	ec06                	sd	ra,24(sp)
    80005edc:	e822                	sd	s0,16(sp)
    80005ede:	e426                	sd	s1,8(sp)
    80005ee0:	e04a                	sd	s2,0(sp)
    80005ee2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ee4:	00003597          	auipc	a1,0x3
    80005ee8:	8f458593          	addi	a1,a1,-1804 # 800087d8 <syscalls+0x320>
    80005eec:	0001c517          	auipc	a0,0x1c
    80005ef0:	0dc50513          	addi	a0,a0,220 # 80021fc8 <disk+0x128>
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	c74080e7          	jalr	-908(ra) # 80000b68 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	4398                	lw	a4,0(a5)
    80005f02:	2701                	sext.w	a4,a4
    80005f04:	747277b7          	lui	a5,0x74727
    80005f08:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f0c:	14f71b63          	bne	a4,a5,80006062 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	43dc                	lw	a5,4(a5)
    80005f16:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f18:	4709                	li	a4,2
    80005f1a:	14e79463          	bne	a5,a4,80006062 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f1e:	100017b7          	lui	a5,0x10001
    80005f22:	479c                	lw	a5,8(a5)
    80005f24:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f26:	12e79e63          	bne	a5,a4,80006062 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f2a:	100017b7          	lui	a5,0x10001
    80005f2e:	47d8                	lw	a4,12(a5)
    80005f30:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f32:	554d47b7          	lui	a5,0x554d4
    80005f36:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f3a:	12f71463          	bne	a4,a5,80006062 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f3e:	100017b7          	lui	a5,0x10001
    80005f42:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f46:	4705                	li	a4,1
    80005f48:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f4a:	470d                	li	a4,3
    80005f4c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f4e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f50:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f54:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc77f>
    80005f58:	8f75                	and	a4,a4,a3
    80005f5a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f5c:	472d                	li	a4,11
    80005f5e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f60:	5bbc                	lw	a5,112(a5)
    80005f62:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f66:	8ba1                	andi	a5,a5,8
    80005f68:	10078563          	beqz	a5,80006072 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f6c:	100017b7          	lui	a5,0x10001
    80005f70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f74:	43fc                	lw	a5,68(a5)
    80005f76:	2781                	sext.w	a5,a5
    80005f78:	10079563          	bnez	a5,80006082 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f7c:	100017b7          	lui	a5,0x10001
    80005f80:	5bdc                	lw	a5,52(a5)
    80005f82:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f84:	10078763          	beqz	a5,80006092 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f88:	471d                	li	a4,7
    80005f8a:	10f77c63          	bgeu	a4,a5,800060a2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f8e:	ffffb097          	auipc	ra,0xffffb
    80005f92:	b58080e7          	jalr	-1192(ra) # 80000ae6 <kalloc>
    80005f96:	0001c497          	auipc	s1,0x1c
    80005f9a:	f0a48493          	addi	s1,s1,-246 # 80021ea0 <disk>
    80005f9e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005fa0:	ffffb097          	auipc	ra,0xffffb
    80005fa4:	b46080e7          	jalr	-1210(ra) # 80000ae6 <kalloc>
    80005fa8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005faa:	ffffb097          	auipc	ra,0xffffb
    80005fae:	b3c080e7          	jalr	-1220(ra) # 80000ae6 <kalloc>
    80005fb2:	87aa                	mv	a5,a0
    80005fb4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005fb6:	6088                	ld	a0,0(s1)
    80005fb8:	cd6d                	beqz	a0,800060b2 <virtio_disk_init+0x1da>
    80005fba:	0001c717          	auipc	a4,0x1c
    80005fbe:	eee73703          	ld	a4,-274(a4) # 80021ea8 <disk+0x8>
    80005fc2:	cb65                	beqz	a4,800060b2 <virtio_disk_init+0x1da>
    80005fc4:	c7fd                	beqz	a5,800060b2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005fc6:	6605                	lui	a2,0x1
    80005fc8:	4581                	li	a1,0
    80005fca:	ffffb097          	auipc	ra,0xffffb
    80005fce:	d2a080e7          	jalr	-726(ra) # 80000cf4 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005fd2:	0001c497          	auipc	s1,0x1c
    80005fd6:	ece48493          	addi	s1,s1,-306 # 80021ea0 <disk>
    80005fda:	6605                	lui	a2,0x1
    80005fdc:	4581                	li	a1,0
    80005fde:	6488                	ld	a0,8(s1)
    80005fe0:	ffffb097          	auipc	ra,0xffffb
    80005fe4:	d14080e7          	jalr	-748(ra) # 80000cf4 <memset>
  memset(disk.used, 0, PGSIZE);
    80005fe8:	6605                	lui	a2,0x1
    80005fea:	4581                	li	a1,0
    80005fec:	6888                	ld	a0,16(s1)
    80005fee:	ffffb097          	auipc	ra,0xffffb
    80005ff2:	d06080e7          	jalr	-762(ra) # 80000cf4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ff6:	100017b7          	lui	a5,0x10001
    80005ffa:	4721                	li	a4,8
    80005ffc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005ffe:	4098                	lw	a4,0(s1)
    80006000:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006004:	40d8                	lw	a4,4(s1)
    80006006:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000600a:	6498                	ld	a4,8(s1)
    8000600c:	0007069b          	sext.w	a3,a4
    80006010:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006014:	9701                	srai	a4,a4,0x20
    80006016:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000601a:	6898                	ld	a4,16(s1)
    8000601c:	0007069b          	sext.w	a3,a4
    80006020:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006024:	9701                	srai	a4,a4,0x20
    80006026:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000602a:	4705                	li	a4,1
    8000602c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000602e:	00e48c23          	sb	a4,24(s1)
    80006032:	00e48ca3          	sb	a4,25(s1)
    80006036:	00e48d23          	sb	a4,26(s1)
    8000603a:	00e48da3          	sb	a4,27(s1)
    8000603e:	00e48e23          	sb	a4,28(s1)
    80006042:	00e48ea3          	sb	a4,29(s1)
    80006046:	00e48f23          	sb	a4,30(s1)
    8000604a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000604e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006052:	0727a823          	sw	s2,112(a5)
}
    80006056:	60e2                	ld	ra,24(sp)
    80006058:	6442                	ld	s0,16(sp)
    8000605a:	64a2                	ld	s1,8(sp)
    8000605c:	6902                	ld	s2,0(sp)
    8000605e:	6105                	addi	sp,sp,32
    80006060:	8082                	ret
    panic("could not find virtio disk");
    80006062:	00002517          	auipc	a0,0x2
    80006066:	78650513          	addi	a0,a0,1926 # 800087e8 <syscalls+0x330>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4d6080e7          	jalr	1238(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006072:	00002517          	auipc	a0,0x2
    80006076:	79650513          	addi	a0,a0,1942 # 80008808 <syscalls+0x350>
    8000607a:	ffffa097          	auipc	ra,0xffffa
    8000607e:	4c6080e7          	jalr	1222(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006082:	00002517          	auipc	a0,0x2
    80006086:	7a650513          	addi	a0,a0,1958 # 80008828 <syscalls+0x370>
    8000608a:	ffffa097          	auipc	ra,0xffffa
    8000608e:	4b6080e7          	jalr	1206(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006092:	00002517          	auipc	a0,0x2
    80006096:	7b650513          	addi	a0,a0,1974 # 80008848 <syscalls+0x390>
    8000609a:	ffffa097          	auipc	ra,0xffffa
    8000609e:	4a6080e7          	jalr	1190(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800060a2:	00002517          	auipc	a0,0x2
    800060a6:	7c650513          	addi	a0,a0,1990 # 80008868 <syscalls+0x3b0>
    800060aa:	ffffa097          	auipc	ra,0xffffa
    800060ae:	496080e7          	jalr	1174(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800060b2:	00002517          	auipc	a0,0x2
    800060b6:	7d650513          	addi	a0,a0,2006 # 80008888 <syscalls+0x3d0>
    800060ba:	ffffa097          	auipc	ra,0xffffa
    800060be:	486080e7          	jalr	1158(ra) # 80000540 <panic>

00000000800060c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060c2:	7119                	addi	sp,sp,-128
    800060c4:	fc86                	sd	ra,120(sp)
    800060c6:	f8a2                	sd	s0,112(sp)
    800060c8:	f4a6                	sd	s1,104(sp)
    800060ca:	f0ca                	sd	s2,96(sp)
    800060cc:	ecce                	sd	s3,88(sp)
    800060ce:	e8d2                	sd	s4,80(sp)
    800060d0:	e4d6                	sd	s5,72(sp)
    800060d2:	e0da                	sd	s6,64(sp)
    800060d4:	fc5e                	sd	s7,56(sp)
    800060d6:	f862                	sd	s8,48(sp)
    800060d8:	f466                	sd	s9,40(sp)
    800060da:	f06a                	sd	s10,32(sp)
    800060dc:	ec6e                	sd	s11,24(sp)
    800060de:	0100                	addi	s0,sp,128
    800060e0:	8aaa                	mv	s5,a0
    800060e2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060e4:	00c52d03          	lw	s10,12(a0)
    800060e8:	001d1d1b          	slliw	s10,s10,0x1
    800060ec:	1d02                	slli	s10,s10,0x20
    800060ee:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800060f2:	0001c517          	auipc	a0,0x1c
    800060f6:	ed650513          	addi	a0,a0,-298 # 80021fc8 <disk+0x128>
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	afe080e7          	jalr	-1282(ra) # 80000bf8 <acquire>
  for(int i = 0; i < 3; i++){
    80006102:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006104:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006106:	0001cb97          	auipc	s7,0x1c
    8000610a:	d9ab8b93          	addi	s7,s7,-614 # 80021ea0 <disk>
  for(int i = 0; i < 3; i++){
    8000610e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006110:	0001cc97          	auipc	s9,0x1c
    80006114:	eb8c8c93          	addi	s9,s9,-328 # 80021fc8 <disk+0x128>
    80006118:	a08d                	j	8000617a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000611a:	00fb8733          	add	a4,s7,a5
    8000611e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006122:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006124:	0207c563          	bltz	a5,8000614e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006128:	2905                	addiw	s2,s2,1
    8000612a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000612c:	05690c63          	beq	s2,s6,80006184 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006130:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006132:	0001c717          	auipc	a4,0x1c
    80006136:	d6e70713          	addi	a4,a4,-658 # 80021ea0 <disk>
    8000613a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000613c:	01874683          	lbu	a3,24(a4)
    80006140:	fee9                	bnez	a3,8000611a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006142:	2785                	addiw	a5,a5,1
    80006144:	0705                	addi	a4,a4,1
    80006146:	fe979be3          	bne	a5,s1,8000613c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000614a:	57fd                	li	a5,-1
    8000614c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000614e:	01205d63          	blez	s2,80006168 <virtio_disk_rw+0xa6>
    80006152:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006154:	000a2503          	lw	a0,0(s4)
    80006158:	00000097          	auipc	ra,0x0
    8000615c:	cfe080e7          	jalr	-770(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    80006160:	2d85                	addiw	s11,s11,1
    80006162:	0a11                	addi	s4,s4,4
    80006164:	ff2d98e3          	bne	s11,s2,80006154 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006168:	85e6                	mv	a1,s9
    8000616a:	0001c517          	auipc	a0,0x1c
    8000616e:	d4e50513          	addi	a0,a0,-690 # 80021eb8 <disk+0x18>
    80006172:	ffffc097          	auipc	ra,0xffffc
    80006176:	f08080e7          	jalr	-248(ra) # 8000207a <sleep>
  for(int i = 0; i < 3; i++){
    8000617a:	f8040a13          	addi	s4,s0,-128
{
    8000617e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006180:	894e                	mv	s2,s3
    80006182:	b77d                	j	80006130 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006184:	f8042503          	lw	a0,-128(s0)
    80006188:	00a50713          	addi	a4,a0,10
    8000618c:	0712                	slli	a4,a4,0x4

  if(write)
    8000618e:	0001c797          	auipc	a5,0x1c
    80006192:	d1278793          	addi	a5,a5,-750 # 80021ea0 <disk>
    80006196:	00e786b3          	add	a3,a5,a4
    8000619a:	01803633          	snez	a2,s8
    8000619e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061a0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800061a4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061a8:	f6070613          	addi	a2,a4,-160
    800061ac:	6394                	ld	a3,0(a5)
    800061ae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061b0:	00870593          	addi	a1,a4,8
    800061b4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061b6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061b8:	0007b803          	ld	a6,0(a5)
    800061bc:	9642                	add	a2,a2,a6
    800061be:	46c1                	li	a3,16
    800061c0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061c2:	4585                	li	a1,1
    800061c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800061c8:	f8442683          	lw	a3,-124(s0)
    800061cc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061d0:	0692                	slli	a3,a3,0x4
    800061d2:	9836                	add	a6,a6,a3
    800061d4:	058a8613          	addi	a2,s5,88
    800061d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800061dc:	0007b803          	ld	a6,0(a5)
    800061e0:	96c2                	add	a3,a3,a6
    800061e2:	40000613          	li	a2,1024
    800061e6:	c690                	sw	a2,8(a3)
  if(write)
    800061e8:	001c3613          	seqz	a2,s8
    800061ec:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061f0:	00166613          	ori	a2,a2,1
    800061f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061f8:	f8842603          	lw	a2,-120(s0)
    800061fc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006200:	00250693          	addi	a3,a0,2
    80006204:	0692                	slli	a3,a3,0x4
    80006206:	96be                	add	a3,a3,a5
    80006208:	58fd                	li	a7,-1
    8000620a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000620e:	0612                	slli	a2,a2,0x4
    80006210:	9832                	add	a6,a6,a2
    80006212:	f9070713          	addi	a4,a4,-112
    80006216:	973e                	add	a4,a4,a5
    80006218:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000621c:	6398                	ld	a4,0(a5)
    8000621e:	9732                	add	a4,a4,a2
    80006220:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006222:	4609                	li	a2,2
    80006224:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006228:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000622c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006230:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006234:	6794                	ld	a3,8(a5)
    80006236:	0026d703          	lhu	a4,2(a3)
    8000623a:	8b1d                	andi	a4,a4,7
    8000623c:	0706                	slli	a4,a4,0x1
    8000623e:	96ba                	add	a3,a3,a4
    80006240:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006244:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006248:	6798                	ld	a4,8(a5)
    8000624a:	00275783          	lhu	a5,2(a4)
    8000624e:	2785                	addiw	a5,a5,1
    80006250:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006254:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006258:	100017b7          	lui	a5,0x10001
    8000625c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006260:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006264:	0001c917          	auipc	s2,0x1c
    80006268:	d6490913          	addi	s2,s2,-668 # 80021fc8 <disk+0x128>
  while(b->disk == 1) {
    8000626c:	4485                	li	s1,1
    8000626e:	00b79c63          	bne	a5,a1,80006286 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006272:	85ca                	mv	a1,s2
    80006274:	8556                	mv	a0,s5
    80006276:	ffffc097          	auipc	ra,0xffffc
    8000627a:	e04080e7          	jalr	-508(ra) # 8000207a <sleep>
  while(b->disk == 1) {
    8000627e:	004aa783          	lw	a5,4(s5)
    80006282:	fe9788e3          	beq	a5,s1,80006272 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006286:	f8042903          	lw	s2,-128(s0)
    8000628a:	00290713          	addi	a4,s2,2
    8000628e:	0712                	slli	a4,a4,0x4
    80006290:	0001c797          	auipc	a5,0x1c
    80006294:	c1078793          	addi	a5,a5,-1008 # 80021ea0 <disk>
    80006298:	97ba                	add	a5,a5,a4
    8000629a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000629e:	0001c997          	auipc	s3,0x1c
    800062a2:	c0298993          	addi	s3,s3,-1022 # 80021ea0 <disk>
    800062a6:	00491713          	slli	a4,s2,0x4
    800062aa:	0009b783          	ld	a5,0(s3)
    800062ae:	97ba                	add	a5,a5,a4
    800062b0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062b4:	854a                	mv	a0,s2
    800062b6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062ba:	00000097          	auipc	ra,0x0
    800062be:	b9c080e7          	jalr	-1124(ra) # 80005e56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062c2:	8885                	andi	s1,s1,1
    800062c4:	f0ed                	bnez	s1,800062a6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062c6:	0001c517          	auipc	a0,0x1c
    800062ca:	d0250513          	addi	a0,a0,-766 # 80021fc8 <disk+0x128>
    800062ce:	ffffb097          	auipc	ra,0xffffb
    800062d2:	9de080e7          	jalr	-1570(ra) # 80000cac <release>
}
    800062d6:	70e6                	ld	ra,120(sp)
    800062d8:	7446                	ld	s0,112(sp)
    800062da:	74a6                	ld	s1,104(sp)
    800062dc:	7906                	ld	s2,96(sp)
    800062de:	69e6                	ld	s3,88(sp)
    800062e0:	6a46                	ld	s4,80(sp)
    800062e2:	6aa6                	ld	s5,72(sp)
    800062e4:	6b06                	ld	s6,64(sp)
    800062e6:	7be2                	ld	s7,56(sp)
    800062e8:	7c42                	ld	s8,48(sp)
    800062ea:	7ca2                	ld	s9,40(sp)
    800062ec:	7d02                	ld	s10,32(sp)
    800062ee:	6de2                	ld	s11,24(sp)
    800062f0:	6109                	addi	sp,sp,128
    800062f2:	8082                	ret

00000000800062f4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062f4:	1101                	addi	sp,sp,-32
    800062f6:	ec06                	sd	ra,24(sp)
    800062f8:	e822                	sd	s0,16(sp)
    800062fa:	e426                	sd	s1,8(sp)
    800062fc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062fe:	0001c497          	auipc	s1,0x1c
    80006302:	ba248493          	addi	s1,s1,-1118 # 80021ea0 <disk>
    80006306:	0001c517          	auipc	a0,0x1c
    8000630a:	cc250513          	addi	a0,a0,-830 # 80021fc8 <disk+0x128>
    8000630e:	ffffb097          	auipc	ra,0xffffb
    80006312:	8ea080e7          	jalr	-1814(ra) # 80000bf8 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006316:	10001737          	lui	a4,0x10001
    8000631a:	533c                	lw	a5,96(a4)
    8000631c:	8b8d                	andi	a5,a5,3
    8000631e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006320:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006324:	689c                	ld	a5,16(s1)
    80006326:	0204d703          	lhu	a4,32(s1)
    8000632a:	0027d783          	lhu	a5,2(a5)
    8000632e:	04f70863          	beq	a4,a5,8000637e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006332:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006336:	6898                	ld	a4,16(s1)
    80006338:	0204d783          	lhu	a5,32(s1)
    8000633c:	8b9d                	andi	a5,a5,7
    8000633e:	078e                	slli	a5,a5,0x3
    80006340:	97ba                	add	a5,a5,a4
    80006342:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006344:	00278713          	addi	a4,a5,2
    80006348:	0712                	slli	a4,a4,0x4
    8000634a:	9726                	add	a4,a4,s1
    8000634c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006350:	e721                	bnez	a4,80006398 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006352:	0789                	addi	a5,a5,2
    80006354:	0792                	slli	a5,a5,0x4
    80006356:	97a6                	add	a5,a5,s1
    80006358:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000635a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000635e:	ffffc097          	auipc	ra,0xffffc
    80006362:	d80080e7          	jalr	-640(ra) # 800020de <wakeup>

    disk.used_idx += 1;
    80006366:	0204d783          	lhu	a5,32(s1)
    8000636a:	2785                	addiw	a5,a5,1
    8000636c:	17c2                	slli	a5,a5,0x30
    8000636e:	93c1                	srli	a5,a5,0x30
    80006370:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006374:	6898                	ld	a4,16(s1)
    80006376:	00275703          	lhu	a4,2(a4)
    8000637a:	faf71ce3          	bne	a4,a5,80006332 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000637e:	0001c517          	auipc	a0,0x1c
    80006382:	c4a50513          	addi	a0,a0,-950 # 80021fc8 <disk+0x128>
    80006386:	ffffb097          	auipc	ra,0xffffb
    8000638a:	926080e7          	jalr	-1754(ra) # 80000cac <release>
}
    8000638e:	60e2                	ld	ra,24(sp)
    80006390:	6442                	ld	s0,16(sp)
    80006392:	64a2                	ld	s1,8(sp)
    80006394:	6105                	addi	sp,sp,32
    80006396:	8082                	ret
      panic("virtio_disk_intr status");
    80006398:	00002517          	auipc	a0,0x2
    8000639c:	50850513          	addi	a0,a0,1288 # 800088a0 <syscalls+0x3e8>
    800063a0:	ffffa097          	auipc	ra,0xffffa
    800063a4:	1a0080e7          	jalr	416(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
