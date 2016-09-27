.text
.arm

.global  _start
.func    _start

_start:
   /* Exception vector */
   B  _reset                                       /* Reset entry           */
   B .                                             /* Undefined instruction */
   B .                                             /* Software interrupt    */
   B .                                             /* Prefetch abort        */
   B .                                             /* Data Abort            */
   B .                                             /* Reverved              */
   B .                                             /* IRQ                   */
   B .                                             /* FIQ                   */

.string "Copyright - Bartosz Bartyzel"
.align 4

_reset:
   ldr   r0, =_reset
   ldr   r1, =_cstartup
   mov   lr, r1
   ldr   sp, =__stack_end__
   b     low_level_init

_cstartup:
   /* Copy from FLASH to RAM */
   ldr   r0, =__fastcode_load
   ldr   r1, =__fastcode_start
   ldr   r2, =__fastcode_end
1:
   cmp   r1, r2
   ldmltia  r0!, {r3}
   stmltia  r1!, {r3}
   blt   1b
   
   /* Relocate the .data section (from FLASH to RAM) */
   ldr   r0, =__data_load
   ldr   r1, =__data_start
   ldr   r2, =_edata
1:
   cmp   r1, r2
   ldmltia  r0!, {r3}
   stmltia  r1!, {r3}
   blt   1b

   /* Clear the .bss section */
   ldr   r1, =__bss_start__
   ldr   r2, =__bss_end__
   mov   r3, #0
1:
   cmp r1,  r2
   stmltia  r1!, {r3}
   blt   1b

   /* Fill the .stack section */
   ldr   r1, =__stack_start__
   ldr   r2, =__stack_end__
   ldr   r3, =STACK_FILL
1:
   cmp   r1, r2
   stmltia r1!, {r3}
   blt   1b

   /* Initialize stack pointers for all ARM modes */
   msr   CPSR_c, #(IRQ_MODE | I_BIT | F_BIT)
   ldr   sp, =__irq_stack_top__

   msr   CPSR_c, #(FIQ_MODE | I_BIT | F_BIT)
   ldr   sp, =__fiq_stack_top__

   msr   CPSR_c, #(SVC_MODE | I_BIT | F_BIT)
   ldr   sp, =__svc_stack_top__

   msr   CPSR_c, #(ABT_MODE | I_BIT | F_BIT)
   ldr   sp, =__abt_stack_top__

   msr   CPSR_c, #(UND_MODE | I_BIT | F_BIT)
   ldr   sp, =__und_stack_top__

   msr   CPSR_c, #(SYS_MODE | I_BIT | F_BIT)
   ldr   sp, =__c_stack_top__

   /* Start main */
   ldr   r12, =main
   mov   lr, pc
   bx    r12

   /* Cause exception if main returns */
   swi   0xFFFFFF

.size _start, . - _start
.endfunc

.end
