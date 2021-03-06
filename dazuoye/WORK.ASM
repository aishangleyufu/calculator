;;位空间定义
;;步进电机
        B_MOTOR  BIT    01H          ;;=1启动
        B_FORWARD       BIT     02H      ;;正向/反向标志


;;IO定义
;;液晶相关
        RS       BIT     P2.0
        RW       BIT     P2.1
        E        BIT     P2.2
        PSB      BIT     P2.3
        RST      BIT     P2.4
;;AD相关
        AD_RD    BIT     P2.6
        AD_WR    BIT     P2.7
;;电机控制
        MOTOR_P1        BIT     P3.0
        MOTOR_P2        BIT     P3.1
        MOTOR_P3        BIT     P3.2
        MOTOR_P4        BIT     P3.3
;;24c02 EEPROM
        SCL     BIT     P3.6
        SDA     BIT     P3.7

;;内部RAM空间

        DELH     EQU     30H
        DELL     EQU     31H
;;按键相关寄存器
        KEYCODE  EQU     32H
        LASTCODE EQU     33H
        N_SAME   EQU     34H
        TEMP     EQU     35H
        N_DISP   EQU     36H
;;光标位置
        CURSOR   EQU     37H
;;时钟相关寄存器
        T_2MS    EQU    40H             ;;2ms定时计数
        T_100MS  EQU    41H             ;;100ms定时计数

        SECOND  EQU     42H
        MINUTE  EQU     43H
        HOUR    EQU     44H

        COUNT   EQU     45H

        MOTOR_STEP      EQU     46H
        MOTOR_DELAY     EQU     47H
        SADDH           EQU     48H
        SADDL           EQU     49H

        DISP_BUF        EQU     50H
        IIC_BUF         EQU     60H


        ORG     0000H
        LJMP    BEGIN

        ORG     000BH
        LJMP    TIMER0_INT



        ORG     0100H
BEGIN:
        MOV     SP,#0E0H
;;电机控制初始化
        CLR     B_MOTOR
        SETB    B_FORWARD
;;按键初始化
        MOV     KEYCODE,#0FFH
        MOV     LASTCODE,#0FFH
        MOV     N_SAME,#0

;;显示时间值初始化
        LCALL   INI_LCD
        LCALL   DISP_LCD1

        LCALL   INI_TIMER
        MOV     R0,#10H
        MOV     R1,#DISP_BUF
DISP_LOOP1:
        MOV     @R1,#20H
        INC     R1
        DJNZ    R0,DISP_LOOP1

        MOV     SADDH,#0
        MOV     SADDL,#0
        MOV     R1,#IIC_BUF
        MOV     R2,#8
        LCALL   W24C
        LCALL   DELAY2MS

        MOV     SADDH,#0
        MOV     SADDL,#0
        MOV     R1,#IIC_BUF+8
        MOV     R2,#8
        LCALL   R24C

LOOP:
        LCALL   READ_ADC
        LCALL   DO_KEY           ;;根据键码值运行相应操作
        LCALL   DISP
        LJMP    LOOP
;;定时器T0初始化
INI_TIMER:
        MOV     T_2MS,#0
        MOV     T_100MS,#0
        MOV     SECOND,#0
        MOV     MINUTE,#59
        MOV     HOUR,#11
        MOV     TMOD,#01H               ;;TIMER0 MODE1
        MOV     TCON,#0
        MOV     TH0,#0F8H
        MOV     TL0,#30H               ;;2mS
        SETB    TR0
        SETB    ET0
        SETB    EA
        RET
;;LCD DISPLAY
DISP:
	MOV	COUNT,#10H     ;显示8个字符
	MOV	A,#90H          ;起始地址
	LCALL 	SEND_I
        MOV     R0,#DISP_BUF
DISP_1:
    	MOV	A,@R0
	LCALL	SEND_D
	INC	R0
	DJNZ	COUNT,DISP_1
        RET

;;ADC
READ_ADC:
        CLR     AD_WR
        NOP
        NOP
        NOP
        SETB    AD_WR
        MOV     P0,#0FFH
        LCALL   DELAY2MS
        CLR     AD_RD
        NOP
        NOP
        NOP
        MOV     A,P0
        SETB    AD_RD
        MOV     B,#100
        DIV     AB
        ORL     A,#30H
        MOV     DISP_BUF+2,A
        MOV     A,B
        MOV     B,#10
        DIV     AB
        ORL     A,#30H
        MOV     DISP_BUF+3,A
        ORL     B,#30H
        MOV     DISP_BUF+4,B


        RET

;;LCD初始化
INI_LCD:

        CLR  	RST
        SETB 	RST
        NOP
        SETB 	PSB                ;***8位数据并口
;**初始化*******
        MOV	A,#30H	     ;30H—基本指令操作
        LCALL SEND_I

        MOV	A,#30H       ;30H--基本指令操作
        LCALL SEND_I

        MOV	A,#0CH	      ;开显示,关光标,不闪烁
        LCALL SEND_I

        MOV	A,#01H		;清除显示
        LCALL SEND_I

        MOV	A,#06H		;指定在写入或读取数据时，光标的移动方向
        LCALL SEND_I        ;DDRAM 的地址计数器(AC)加1
        RET

;;LCD 显示
DISP_LCD1:        MOV	A,#01H		;清除显示
        LCALL SEND_I

	MOV	DPTR,#TABZ      ;;显示汉字和字符
	MOV	COUNT,#10H     ;显示8个字符
	MOV	A,#80H          ;起始地址
	LCALL 	SEND_I
	LCALL 	DISP_HZ
	RET


TABZ:     DB  '  浙江大学2015  '


;写指令子程序
;RS=0,RW=0,E=高脉冲,D0-D7=指令码
;********************************************************
SEND_I:
	    LCALL CHK_BUSY
	    CLR	 RS
	    CLR	 RW
	    MOV	P0,A
	    SETB E
	    NOP
	    NOP
	    CLR	 E
	    RET


; ;写数据子程序
;RS=1,RW=0,E=高脉冲,D0-D7=数据
;**********************************************************
SEND_D:
	    LCALL	CHK_BUSY
	    SETB	RS
	    CLR	   RW
	    MOV	   P0,A
	    SETB   E
	    NOP
	    NOP
	    CLR	   E
	    RET

;测忙子程序
;RS=0,RW=1,E=H,D0-D7=状态字
;*********************************************************
CHK_BUSY:
    	   MOV	P0,#0FFH    ;测忙碌子程序
	   CLR	RS
	   SETB	RW
	   SETB	E
	   JB	P0.7,$
	   CLR	E
	   RET

 ;显示汉字或字符
;DPTR 字符串位置，COUNT：长度
;*********************************************************
DISP_HZ:
    	 CLR	A
         MOVC	A,@A+DPTR
	 LCALL	SEND_D
	 INC	DPTR
	 DJNZ	COUNT,DISP_HZ
	 RET







;;定时器中断
TIMER0_INT:
        PUSH    ACC
        PUSH    PSW
        PUSH    DPL
        PUSH    DPH
        LCALL TIMER              ;;时钟运行
;        LCALL   DISP_TIMER       ;;时钟放入显示缓冲
        LCALL   KEY_SCAN         ;;键盘扫描
        LCALL   MOTOR
;        LCALL   SET_CURSOR       ;;显示光标

;        LCALL   DISP_LED         ;;LED显示
        POP     DPH
        POP     DPL
        POP     PSW
        POP     ACC
        RETI

;;内部时钟运行
;;INPUT:NONE
;;OUTPUT:TIP,SECOND,MINUTE,HOUR
;;INFLUENCED:ACC

TIMER:
        MOV     TH0,#0F8H
        MOV     TL0,#30H               ;;2mS
;;2ms计数加1
        INC     T_2MS
        MOV     A,T_2MS
        CLR     C
        SUBB    A,#50
        JC      TIMER0_RET
        MOV     T_2MS,A
;;100ms计数加1
        INC     T_100MS
        MOV     A,T_100MS
        CLR     C
        SUBB    A,#10
        JC      TIMER0_RET
        MOV     T_100MS,A
;;秒计数加1
        INC     SECOND
        MOV     A,SECOND
        CLR     C
        SUBB    A,#60
        JC      TIMER0_RET
        MOV     SECOND,A
;;分钟计数加1
        INC     MINUTE
        MOV     A,MINUTE
        CLR     C
        SUBB    A,#60
        JC      TIMER0_RET
        MOV     MINUTE,A
;;小时计数加1
        INC     HOUR
        MOV     A,HOUR
        SUBB    A,#12
        JC      TIMER0_RET
        MOV     HOUR,A
TIMER0_RET:
        RET



;;显示时间，将显示数据放入显示缓冲区
;;INPUT:SECOND,MINUTE,HOUR
;;OUTPUT:LED_BUF
;;INFLUENCED:ACC，B，R0
DISP_TIMER:
;        MOV     R0,#LED_BUF
        MOV     A,HOUR
        MOV     B,#10
        DIV     AB
        MOV     @R0,A
        INC     R0
        MOV     @R0,B
        INC     R0              ;;DISPLAY HOUR

        MOV     @R0,#0EH        ;;-
        INC     R0

        MOV     A,MINUTE
        MOV     B,#10
        DIV     AB
        MOV     @R0,A
        INC     R0
        MOV     @R0,B
        INC     R0               ;;DISPLAY MINUTE

        MOV     @R0,#0EH        ;;-
        INC     R0

        MOV     A,SECOND
        MOV     B,#10
        DIV     AB
        MOV     @R0,A
        INC     R0
        MOV     @R0,B            ;;DISPLAY SECOND


        RET



;;DELAY 2ms
DELAY2MS:
        MOV     DELH,#2
DELAY2:
        MOV     DELL,#250
DELAY1:
        NOP
        NOP
        DJNZ    DELL,DELAY1
        DJNZ    DELH,DELAY2
        RET

MOTOR:
        JNB     B_MOTOR,STOP_MOTOR
        INC     MOTOR_DELAY
        MOV     A,MOTOR_DELAY
        CJNE    A,#10,MOT_NEXT
MOT_NEXT:
        JC      MOTOR_RET
        MOV     MOTOR_DELAY,#0
        JNB     B_FORWARD,BACK_ROTATE
        MOV     A,MOTOR_STEP
        INC     MOTOR_STEP
        JNZ     STEP_MF1
        SETB    MOTOR_P1
        SETB    MOTOR_P2
        CLR     MOTOR_P3
        CLR     MOTOR_P4
MOTOR_RET:
        RET
STEP_MF1:
        CJNE    A,#1,STEP_MF2
        SETB    MOTOR_P1
        CLR     MOTOR_P2
        CLR     MOTOR_P3
        SETB    MOTOR_P4
        RET

STEP_MF2:
        CJNE    A,#2,STEP_MF3
        CLR     MOTOR_P1
        CLR     MOTOR_P2
        SETB    MOTOR_P3
        SETB    MOTOR_P4
        RET
STEP_MF3:
        CLR     MOTOR_P1
        SETB    MOTOR_P2
        SETB    MOTOR_P3
        CLR     MOTOR_P4
        MOV     MOTOR_STEP,#0
        RET

BACK_ROTATE:

        RET
STOP_MOTOR:
        CLR     MOTOR_P1
        CLR     MOTOR_P2
        CLR     MOTOR_P3
        CLR     MOTOR_P4
        RET



;;按键处理
;;INPUT:KEYCODE
;;OUTPUT:
;;INFLUENCED:ACC
;;
DO_KEY:
        MOV     A,KEYCODE
        CJNE    A,#0FFH,KEY_0
        RET
KEY_0:
        CJNE    A,#0FH,KEY_1
        CPL     B_MOTOR
        SETB    B_FORWARD
        SJMP    KEY_RET

KEY_1:

      NOP

KEY_RET:
        MOV     KEYCODE,#0FFH
        RET

;;键盘扫描
;;INPUT:P1，P2
;;OUTPUT:KEYCODE
;;INFLUENCED:LASTCODE-上次采样的键码
;;           N_SAME -采样到相同键码的次数
;;DPTR
KEY_SCAN:
        MOV     P1,#0F0H
        NOP
        MOV     A,P1
        ANL     A,#0F0H
        MOV     B,A
        MOV     P1,#0FH
        NOP
        MOV     A,P1
        ANL     A,#0FH
        ORL     A,B
        MOV     DPTR,#TAB_KEY
        MOVC    A,@A+DPTR
        CJNE    A,LASTCODE,GET_NEW_KEY
        MOV     A,N_SAME
        CJNE    A,#3,GET_NEXT
;;新键码
        MOV     KEYCODE,LASTCODE
KEY_EXIT:
        INC     N_SAME
        RET
GET_NEXT:
        JC      KEY_EXIT
        RET
GET_NEW_KEY:
        MOV     LASTCODE,A
        MOV     N_SAME,#0
        RET

TAB_KEY:
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;0-10H
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;10-1FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;20-2FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;30-3FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;40-4FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;50-5FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;60-6FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0CH,0FFH,0FFH,0FFH,0DH,0FFH,0EH,0FH,0FFH ;70-7FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;80-8FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;90-9FH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;A0-AFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0AH,0FFH,0FFH,0FFH,09H,0FFH,00H,0BH,0FFH  ;B0-BFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;C0-CFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,05H,0FFH,0FFH,0FFH,06H,0FFH,07H,08H,0FFH  ;D0-DFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,01H,0FFH,0FFH,0FFH,02H,0FFH,03H,04H,0FFH  ;E0-EFH
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;F0-FFH










START:
                SETB     SDA                       ;发送起始条件的数据信号
                NOP
                SETB     SCL                       ;发送起始条件的时钟信号
                NOP                                     ;起始条件建立时间大于4US
                NOP
                NOP
                NOP
                NOP
                CLR      SDA                       ;发送起始信号
                NOP                                     ;起始条件锁定时间大于4US
                NOP
                NOP
                NOP
                NOP
                CLR      SCL                       ;钳住IIC总线,准备发送或接收数据
                RET

STOP:
                CLR      SDA                       ;发送停止条件的数据信号
                NOP
                SETB     SCL                       ;发送停止条件的时钟信号
                NOP                                ;起始条件建立时间大于4US
                NOP
                NOP
                NOP
                NOP
                SETB     SDA                       ;发送IIC总线停止信号
                NOP
                NOP
                NOP
                NOP
                RET

;;接收应答
;;====================================================================
ACKN:
	SETB	SDA
	SETB	SCL
	NOP
	JB	SDA,	$
	NOP
	NOP
	CLR	SCL
	RET

ACKS:
	CLR	SDA
	NOP
	NOP
	NOP
	SETB	SCL
	NOP
	NOP
	NOP
	NOP
	CLR	SCL
	RET

;;名称: RBYTE
;;功能: READ ONE BYTE DATA FROM 24C16
;;输入: (无)
;;输出: A
;;--------------------------------------------------------------------------
;;调用: (无)
;;--------------------------------------------------------------------------
;;影响: A,R0
;;堆栈: 2
;;--------------------------------------------------------------------------
;;参数说明:
;;		A:接收数据(1字节)
;;--------------------------------------------------------------------------
;;注意:
;;--------------------------------------------------------------------------
RBYTE:
	SETB	SDA
	MOV	R0,	#8
XRB1:
	SETB	SCL
	NOP
	NOP
	NOP
	MOV	C,	SDA
	CLR	SCL
	RLC	A
	NOP
	NOP
	DJNZ	R0,	XRB1
	RET

;;名称: WBYTE
;;功能: WRITE ONE BYTE DATA TO 24C16
;;输入: A
;;输出: (无)
;;--------------------------------------------------------------------------
;;调用: (无)
;;--------------------------------------------------------------------------
;;影响: A,R0
;;堆栈: 2
;;--------------------------------------------------------------------------
;;参数说明:
;;		A:发送数据(1字节)
;;--------------------------------------------------------------------------
;;注意:
;;--------------------------------------------------------------------------
WBYTE:
	MOV	R0,#8
XWB1:
	RLC	A
	NOP
	NOP
	MOV	SDA,C
	NOP
	SETB	SCL
	NOP
               NOP
	NOP
	NOP
	NOP
	CLR	SCL
	DJNZ	R0,XWB1
	RET

;;名称: W24C
;;功能: WRITE DATA TO 24C16
;;输入: SADD,R1,R2
;;输出: (无)
;;--------------------------------------------------------------------------
;;调用: START,WBYTE,ACKN,STOP
;;--------------------------------------------------------------------------
;;影响: A,R1,R2
;;堆栈: 4
;;--------------------------------------------------------------------------
;;参数说明:
;;		SADDH,SADDL:24C16 ADDRESS
;;		R2:WRITE NUMBER
;;		R1:RAM ADDRESS POINTER
;;--------------------------------------------------------------------------
;;注意:
;;--------------------------------
W24C:
        LCALL	START			;IIC起始信号
        MOV     	A,      SADDH
        RL     	A
	ORL	A,	#0A0H
	LCALL	WBYTE			;写命令字节
	LCALL	ACKN			;收应答
	MOV	A,	SADDL
	LCALL	WBYTE			;写2416的地址
	LCALL	ACKN			;收应答
WD24:
	MOV	A,	@R1
	INC	R1
	LCALL	WBYTE
	LCALL	ACKN
	DJNZ	R2,	WD24
	LCALL	STOP			;IIC结束信号
	RET

;;--------------------------------------------------------------------------
;;名称: R24C
;;功能: READ DATA FROM 24C16
;;输入: SADD,R1,R2
;;输出: (无)
;;--------------------------------------------------------------------------
;;调用: START,WBYTE,ACKN,RBYTE,STOP
;;--------------------------------------------------------------------------
;;影响: A,R1,R2
;;堆栈: 4
;;--------------------------------------------------------------------------
;;参数说明:
;;		SADD:24C16 ADDRESS
;;		R2:WRITE NUMBER
;;		R1:RAM ADDRESS POINTER
;;--------------------------------------------------------------------------
;;注意:
;;-------------------------
R24C:
	LCALL	START			;IIC起始信号
        MOV     A,      SADDH
       	RL      A
	ORL	A,	#0A0H
	LCALL	WBYTE			;写命令字节
	LCALL	ACKN			;收应答
	MOV	A,	SADDL
	LCALL	WBYTE			;地址字节
	LCALL	ACKN			;收应答
	LCALL	START
       	MOV     A,      SADDH
       	RL      A
	ORL	A,	#0A1H
	LCALL	WBYTE			;读命令字节
	LCALL	ACKN			;收应答
RC24:
        	LCALL   RBYTE			;读2416
	MOV	@R1,A
	INC	R1
	DJNZ	R2,RCX
	LCALL	STOP			;IIC结束信号
	RET
RCX:
	LCALL	ACKS			;发应答
	SJMP	RC24

