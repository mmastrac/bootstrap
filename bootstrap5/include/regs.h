// Register definitions
#define pc r61
#define sp r60
// The compiler uses r59 for compound ops
#define ctmp r59
// The compiler uses r58 for %call
#define ctmp2 r58
// These are tmp regs free for use by code - no need to restore
#define tmp0 r57
#define tmp1 r56
#define tmp2 r55
#define tmp3 r54

#define ret r0
#define ret2 r1

// Compiler function arguments (avoids clobbering in recursive calls)
#define _carg0 r53
#define _carg1 r52
#define _carg2 r51
#define _carg3 r50
#define _carg4 r49
#define _carg5 r48
#define _carg6 r47
#define _carg7 r46
