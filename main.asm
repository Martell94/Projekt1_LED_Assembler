;**************************************************
;              Makron, vektorer etc
;**************************************************
.EQU LED1 = PORTB0
.EQU LED2 = PORTB1
   
.EQU BUTTON1 = PORTB3
.EQU BUTTON2 = PORTB4
.EQU BUTTON3 = PORTB5
   
.EQU RESET_vect = 0x00
   
.EQU PCINT0_vect = 0x06
.EQU TIMER2_vect = 0x12
.EQU TIMER1_vect = 0x16
.EQU TIMER0_vect = 0x20
   
.EQU TIMER0_MAX_COUNT = 18
.EQU TIMER1_MAX_COUNT = 12
.EQU TIMER2_MAX_COUNT = 6
   
;**************************************************
.DSEG
   .ORG SRAM_START
   counter0: .byte 1                ; static uint8_t counter0 = 0. Reg = R24
   counter1: .byte 1                ; static uint8_t counter1 = 0. Reg = R25
   counter2: .byte 1                ; static uint8_t counter2 = 0. Reg = R26
   
.CSEG
   .ORG RESET_vect
   RJMP main
   
;**************************************************
.ORG PCINT0_vect                   ; Interruptvektor f�r knapp 1
   RJMP ISR_PCINT0_vect
   
.ORG TIMER2_vect                   ; Interruptvektor f�r Timer 2
   RJMP ISR_TIMER2_OVF
.ORG TIMER1_vect                   ; Interruptvektor f�r Timer 1
   RJMP ISR_TIMER1_COMPA
.ORG TIMER0_vect                   ; Interruptvektor f�r Timer 0
   RJMP ISR_TIMER0_OVF
   
;**************************************************
;                Interruptrutiner
;**************************************************
ISR_PCINT0_vect:                   ; Interruptrutin f�r knapp 1
   CLR R29                         ; R29 anv�nds som nollregister i hela koden, clearas h�r bara f�r s�kerhets skull.
   STS PCICR, R29                  ; St�nger av PCI-avbrott tempor�rt
   STS TIMSK0, R16                 ; Ettst�ller overflowbiten f�r Timer 0
   
check_button1:                     ; Knapp 1: Bl� LED
   IN R30, PINB                    ; L�ser in PINB till R30-registret
   ANDI R30, (1 << BUTTON1)        ; J�mf�r PINB (Nu R30) med knappens pin
   BREQ check_button2              ; Ifall b�da �r noll hoppar den vidare och kollar knapp 2.
   CLR R30                         ; Rensar R30 
   CALL timer1_toggle              ; Knappen �r nedtryckt, och d� togglas timer 1.
   RJMP ISR_PCINT0_END
   
check_button2:                     ; Knapp 2: Gr�n LED. G�r i stort sett samma som ovan.
   IN R30, PINB                    ; L�ser in PINB till R30-registret
   ANDI R30, (1 << BUTTON2)        ; J�mf�r PINB (Nu R30) med knappens pin
   BREQ check_button3              ; Ifall b�da �r noll hoppar den vidare och kollar knapp 3.
   CLR R30                         ; Rensar R30 
   CALL timer2_toggle              ; Knappen �r nedtryckt, och d� togglas timer 1.
   RJMP ISR_PCINT0_END
   
check_button3:                     ; Knapp 3: Reset
   IN R30, PINB                    ; L�ser in PINB till R30-registret
   ANDI R30, (1 << BUTTON3)        ; J�mf�r PINB (Nu R30) med knappens pin
   BREQ ISR_PCINT0_END             ; Ifall b�da �r noll hoppar den till slutet
   CLR R30                         ; Rensar R30 
   CALL system_reset               ; Hoppar till system reset-rutinen
   
ISR_PCINT0_END:
   RETI                            ; �terv�nder fr�n interruptrutin. 
   
;**************************************************
;                 Timerinterrupts
;**************************************************
ISR_TIMER0_OVF:                    ; Interruptrutin f�r Timer 0, Debounce
   LDS R24, counter0               ; Skriver counter0s v�rde till R24.
   INC R24                         ; Inkrementerar v�rdet med 1
   CPI R24, TIMER0_MAX_COUNT       ; J�mf�r v�rdet med MAX_COUNT-makrot, som f�r timer0 �r 18.
   BRLO TIMER0_OVF_END             ; Ifall v�rdet �r l�gre �n MAX_COUNT s� hoppar den �ver resten.
   STS PCICR, R16                  ; Ettst�ller bit 1 i PCICR, vilket aktiverar interrupts igen.
   CLR R29
   STS TIMSK0, R29                 ; St�nger av interrupts p� Timer0 igen, d� den gjort det den ska.
   CLR R24                         ; Nollst�ller r�knaren.
   
TIMER0_OVF_END:                    ; Slutrutin f�r Timer0
   STS counter0, R24               ; Skriver v�rdet av R24 till counter0, d� det inkrementerats eller nollats.
   RETI                            ; �terv�nder fr�n interruptrutinen.
   
;**************************************************
ISR_TIMER1_COMPA:                  ; Interruptrutin f�r Timer 1, LED1
   LDS R25, counter1               ; Skriver v�rdet av counter1 till R25. 
   INC R25                         ; Inkrementerar R25.
   CPI R25, TIMER1_MAX_COUNT       ; J�mf�r v�rdet med MAX_COUNT-makrot, som f�r timer1 �r 12.
   BRLO TIMER1_COMPA_END           ; Ifall v�rdet �r l�gre �n MAX_COUNT s� hoppar den �ver resten.
   OUT PINB, R16                   ; Togglar lysdiodens pin. 
   CLR R25                         ; Nollst�ller counter1, s� den �r redo inf�r n�sta cykel.
   
TIMER1_COMPA_END:                  ; Slutrutin f�r timer1.
   STS counter1, R25               ; Skriver v�rdet i R25 till counter1, d� det inkrementerats eller nollats.
   RETI
   
;**************************************************
ISR_TIMER2_OVF:                    ; Interruptrutin f�r Timer 2, LED2
   LDS R26, counter2               ; Skriver v�rdet av counter2 till R26. 
   INC R26                         ; Inkrementerar R26.
   CPI R26, TIMER2_MAX_COUNT       ; J�mf�r v�rdet med MAX_COUNT-makrot, som f�r timer1 �r 6.
   BRLO TIMER2_OVF_END             ; Ifall v�rdet �r l�gre �n MAX_COUNT s� hoppar den �ver resten.
   OUT PINB, R17                   ; Togglar lysdiodens pin. 
   CLR R26                         ; Nollst�ller counter2, s� den �r redo inf�r n�sta cykel.
   
TIMER2_OVF_END:                    ; Slutrutin f�r timer2.
   STS counter2, R26               ; Skriver v�rdet i R26 till counter2, d� det inkrementerats eller nollats.
   RETI
   
;**************************************************
;                Togglefunktioner
;**************************************************
timer1_toggle:                     ; Togglefunktion f�r timer1
   LDS R27, TIMSK1                 ; Skriver v�rdet fr�n TIMSK1 till R27
   CPI R27, 0                      ; J�mf�r v�rdet med noll
   BREQ timer1_on                  ; ifall v�rdet �r noll, hoppar det till timer1_on
timer1_off:                        ; Sl�cker LED1 och nollst�ller timer1
   CLR R27                         ; Nollar R27
   STS TIMSK1, R27                 ; Skriver R27 till TIMSK1
   IN R27, PORTB                   ; L�ser in portb till R27
   ANDI R27, ~(1 << LED1)          ; Inverterar v�rdet p� LED1-biten
   OUT PORTB, R27                  ; Skriver R27 till PORTB
   RET
timer1_on:                         ; S�tter ig�ng timer1.
   STS TIMSK1, R17                 ; Ettst�ller timer1.
   RET
   
;**************************************************
timer2_toggle:                     ; Togglefunktion f�r timer2
   LDS R27, TIMSK2                 ; Skriver v�rdet i TIMSK2 till R27
   CPI R27, 0                      ; J�mf�r v�rdet med noll.
   BREQ timer2_on                  ; Ifall v�rder �r noll hoppar den till timer2_on
   
timer2_off:                        ; Sl�cker LED2 och nollst�ller timer2
   CLR R27                         ; Nollar R27
   STS TIMSK2, R27                 ; Skriver R27 till TIMSK2
   IN R27, PORTB                   ; L�ser in PORTB till R27
   ANDI R27, ~(1 << LED2)          ; Inverterar v�rdet p� LED2-biten
   OUT PORTB, R27                  ; Skriver R27 till PORTB
   RET
   
timer2_on:                         ; S�tter ig�ng timer2
   STS TIMSK2, R16                 ; Ettst�ller timer2.
   RET
   
;**************************************************
system_reset:                      ; Nollst�ller alla timers och LEDs.
   CLR R29                         ; Nollar R29
   OUT PORTB, R29                  ; Nollar PORTB
   STS TIMSK1, R29                 ; Nollar TIMSK1
   STS TIMSK2, R29                 ; Nollar TIMSK2
   STS counter1, R29               ; Nollar counter1
   STS counter2, R29               ; Nollar counter2
   RET
   
;**************************************************
;                      main
;**************************************************
main:
   
setup:
   
   LDI R16, (1<<LED1)                  ; Ettst�ller relevanta bitar i div. register.
   LDI R17, (1<<LED2)
   LDI R19, (1<<LED1) | (1<<LED2)
   OUT DDRB, R19
   
   LDI R20, (1<<BUTTON1)               ; Ettst�ller relevanta bitar i div. register.
   LDI R21, (1<<BUTTON2)
   LDI R22, (1<<BUTTON3)
   LDI R23, (1<<BUTTON1) | (1<<BUTTON2) | (1<<BUTTON3)
   OUT PORTB, R23                      ; Aktiverar intern pullup p� samtliga knappar.
   
   STS PCICR, R16                      ; Ettst�ller bit 0 i PCICR f�r att aktivera PCI-avbrott p� knapp 5.
   STS PCMSK0, R23                     ; Ettst�ller relevanta bitar i PCMSK0.
   
   LDI R24, (1 << CS02) | (1 << CS00)  ; Anv�nds f�r att ettst�lla TCCR0B och TCCR1B
   OUT TCCR0B, R24                     ; Ettst�ller bit 0 och 2, f�r att initiera prescaler p� 1024.
   CLR R24                             ; Nollst�ller f�r senare bruk.
   
   LDI R24, (1 << WGM12) | (1 << CS12) | (1 << CS10)
   STS TCCR1B, R24                     ; Ettst�ller bit 0 och 2, f�r att initiera prescaler p� 1024.
   CLR R24
   
   LDI R24, (1 << CS22) | (1 << CS21) | (1 << CS00) ; Anv�nds f�r att ettst�lla TCCR2B
   STS TCCR2B, R24                     ; Ettst�ller bit 0, 1 och 2, f�r att initiera prescaler p� 1024.
   CLR R24
   
   LDI R27, HIGH(256)                  ; Ettst�ller bit 1 i HIGH-registret f�r output compare
   LDI R28, LOW(256)                   ; V�rdet h�r blir 0.
   STS OCR1AH, R27                     ; Skriver detta till OCR1AH/L
   STS OCR1AL, R28
   CLR R27                             ; Rensar R27.
   
   SEI                                 ; Aktiverar interrupts globalt.
   
   main_loop:
   ; ding dong
   RJMP main_loop
;**************************************************
