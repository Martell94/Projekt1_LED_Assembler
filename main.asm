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
.ORG PCINT0_vect                   ; Interruptvektor för knapp 1
   RJMP ISR_PCINT0_vect
   
.ORG TIMER2_vect                   ; Interruptvektor för Timer 2
   RJMP ISR_TIMER2_OVF
.ORG TIMER1_vect                   ; Interruptvektor för Timer 1
   RJMP ISR_TIMER1_COMPA
.ORG TIMER0_vect                   ; Interruptvektor för Timer 0
   RJMP ISR_TIMER0_OVF
   
;**************************************************
;                Interruptrutiner
;**************************************************
ISR_PCINT0_vect:                   ; Interruptrutin för knapp 1
   CLR R29                         ; R29 används som nollregister i hela koden, clearas här bara för säkerhets skull.
   STS PCICR, R29                  ; Stänger av PCI-avbrott temporärt
   STS TIMSK0, R16                 ; Ettställer overflowbiten för Timer 0
   
check_button1:                     ; Knapp 1: Blå LED
   IN R30, PINB                    ; Läser in PINB till R30-registret
   ANDI R30, (1 << BUTTON1)        ; Jämför PINB (Nu R30) med knappens pin
   BREQ check_button2              ; Ifall båda är noll hoppar den vidare och kollar knapp 2.
   CLR R30                         ; Rensar R30 
   CALL timer1_toggle              ; Knappen är nedtryckt, och då togglas timer 1.
   RJMP ISR_PCINT0_END
   
check_button2:                     ; Knapp 2: Grön LED. Gör i stort sett samma som ovan.
   IN R30, PINB                    ; Läser in PINB till R30-registret
   ANDI R30, (1 << BUTTON2)        ; Jämför PINB (Nu R30) med knappens pin
   BREQ check_button3              ; Ifall båda är noll hoppar den vidare och kollar knapp 3.
   CLR R30                         ; Rensar R30 
   CALL timer2_toggle              ; Knappen är nedtryckt, och då togglas timer 1.
   RJMP ISR_PCINT0_END
   
check_button3:                     ; Knapp 3: Reset
   IN R30, PINB                    ; Läser in PINB till R30-registret
   ANDI R30, (1 << BUTTON3)        ; Jämför PINB (Nu R30) med knappens pin
   BREQ ISR_PCINT0_END             ; Ifall båda är noll hoppar den till slutet
   CLR R30                         ; Rensar R30 
   CALL system_reset               ; Hoppar till system reset-rutinen
   
ISR_PCINT0_END:
   RETI                            ; Återvänder från interruptrutin. 
   
;**************************************************
;                 Timerinterrupts
;**************************************************
ISR_TIMER0_OVF:                    ; Interruptrutin för Timer 0, Debounce
   LDS R24, counter0               ; Skriver counter0s värde till R24.
   INC R24                         ; Inkrementerar värdet med 1
   CPI R24, TIMER0_MAX_COUNT       ; Jämför värdet med MAX_COUNT-makrot, som för timer0 är 18.
   BRLO TIMER0_OVF_END             ; Ifall värdet är lägre än MAX_COUNT så hoppar den över resten.
   STS PCICR, R16                  ; Ettställer bit 1 i PCICR, vilket aktiverar interrupts igen.
   CLR R29
   STS TIMSK0, R29                 ; Stänger av interrupts på Timer0 igen, då den gjort det den ska.
   CLR R24                         ; Nollställer räknaren.
   
TIMER0_OVF_END:                    ; Slutrutin för Timer0
   STS counter0, R24               ; Skriver värdet av R24 till counter0, då det inkrementerats eller nollats.
   RETI                            ; Återvänder från interruptrutinen.
   
;**************************************************
ISR_TIMER1_COMPA:                  ; Interruptrutin för Timer 1, LED1
   LDS R25, counter1               ; Skriver värdet av counter1 till R25. 
   INC R25                         ; Inkrementerar R25.
   CPI R25, TIMER1_MAX_COUNT       ; Jämför värdet med MAX_COUNT-makrot, som för timer1 är 12.
   BRLO TIMER1_COMPA_END           ; Ifall värdet är lägre än MAX_COUNT så hoppar den över resten.
   OUT PINB, R16                   ; Togglar lysdiodens pin. 
   CLR R25                         ; Nollställer counter1, så den är redo inför nästa cykel.
   
TIMER1_COMPA_END:                  ; Slutrutin för timer1.
   STS counter1, R25               ; Skriver värdet i R25 till counter1, då det inkrementerats eller nollats.
   RETI
   
;**************************************************
ISR_TIMER2_OVF:                    ; Interruptrutin för Timer 2, LED2
   LDS R26, counter2               ; Skriver värdet av counter2 till R26. 
   INC R26                         ; Inkrementerar R26.
   CPI R26, TIMER2_MAX_COUNT       ; Jämför värdet med MAX_COUNT-makrot, som för timer1 är 6.
   BRLO TIMER2_OVF_END             ; Ifall värdet är lägre än MAX_COUNT så hoppar den över resten.
   OUT PINB, R17                   ; Togglar lysdiodens pin. 
   CLR R26                         ; Nollställer counter2, så den är redo inför nästa cykel.
   
TIMER2_OVF_END:                    ; Slutrutin för timer2.
   STS counter2, R26               ; Skriver värdet i R26 till counter2, då det inkrementerats eller nollats.
   RETI
   
;**************************************************
;                Togglefunktioner
;**************************************************
timer1_toggle:                     ; Togglefunktion för timer1
   LDS R27, TIMSK1                 ; Skriver värdet från TIMSK1 till R27
   CPI R27, 0                      ; Jämför värdet med noll
   BREQ timer1_on                  ; ifall värdet är noll, hoppar det till timer1_on
timer1_off:                        ; Släcker LED1 och nollställer timer1
   CLR R27                         ; Nollar R27
   STS TIMSK1, R27                 ; Skriver R27 till TIMSK1
   IN R27, PORTB                   ; Läser in portb till R27
   ANDI R27, ~(1 << LED1)          ; Inverterar värdet på LED1-biten
   OUT PORTB, R27                  ; Skriver R27 till PORTB
   RET
timer1_on:                         ; Sätter igång timer1.
   STS TIMSK1, R17                 ; Ettställer timer1.
   RET
   
;**************************************************
timer2_toggle:                     ; Togglefunktion för timer2
   LDS R27, TIMSK2                 ; Skriver värdet i TIMSK2 till R27
   CPI R27, 0                      ; Jämför värdet med noll.
   BREQ timer2_on                  ; Ifall värder är noll hoppar den till timer2_on
   
timer2_off:                        ; Släcker LED2 och nollställer timer2
   CLR R27                         ; Nollar R27
   STS TIMSK2, R27                 ; Skriver R27 till TIMSK2
   IN R27, PORTB                   ; Läser in PORTB till R27
   ANDI R27, ~(1 << LED2)          ; Inverterar värdet på LED2-biten
   OUT PORTB, R27                  ; Skriver R27 till PORTB
   RET
   
timer2_on:                         ; Sätter igång timer2
   STS TIMSK2, R16                 ; Ettställer timer2.
   RET
   
;**************************************************
system_reset:                      ; Nollställer alla timers och LEDs.
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
   
   LDI R16, (1<<LED1)                  ; Ettställer relevanta bitar i div. register.
   LDI R17, (1<<LED2)
   LDI R19, (1<<LED1) | (1<<LED2)
   OUT DDRB, R19
   
   LDI R20, (1<<BUTTON1)               ; Ettställer relevanta bitar i div. register.
   LDI R21, (1<<BUTTON2)
   LDI R22, (1<<BUTTON3)
   LDI R23, (1<<BUTTON1) | (1<<BUTTON2) | (1<<BUTTON3)
   OUT PORTB, R23                      ; Aktiverar intern pullup på samtliga knappar.
   
   STS PCICR, R16                      ; Ettställer bit 0 i PCICR för att aktivera PCI-avbrott på knapp 5.
   STS PCMSK0, R23                     ; Ettställer relevanta bitar i PCMSK0.
   
   LDI R24, (1 << CS02) | (1 << CS00)  ; Används för att ettställa TCCR0B och TCCR1B
   OUT TCCR0B, R24                     ; Ettställer bit 0 och 2, för att initiera prescaler på 1024.
   CLR R24                             ; Nollställer för senare bruk.
   
   LDI R24, (1 << WGM12) | (1 << CS12) | (1 << CS10)
   STS TCCR1B, R24                     ; Ettställer bit 0 och 2, för att initiera prescaler på 1024.
   CLR R24
   
   LDI R24, (1 << CS22) | (1 << CS21) | (1 << CS00) ; Används för att ettställa TCCR2B
   STS TCCR2B, R24                     ; Ettställer bit 0, 1 och 2, för att initiera prescaler på 1024.
   CLR R24
   
   LDI R27, HIGH(256)                  ; Ettställer bit 1 i HIGH-registret för output compare
   LDI R28, LOW(256)                   ; Värdet här blir 0.
   STS OCR1AH, R27                     ; Skriver detta till OCR1AH/L
   STS OCR1AL, R28
   CLR R27                             ; Rensar R27.
   
   SEI                                 ; Aktiverar interrupts globalt.
   
   main_loop:
   ; ding dong
   RJMP main_loop
;**************************************************
