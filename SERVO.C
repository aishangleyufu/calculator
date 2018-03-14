#include <reg51.h>
#include <intrins.h>
#define unit unsigned int
#define uchar unsigned char
void delay_ms(int x);
void Init_Timer0(void);
void servo_interrupt(uchar act,int speed);
void Timer0_isr(void);
uchar code FFW[4]={0xf3,0xf9,0xfc,0xf6};        //����˫������
uchar code REV[4]={0xf3,0xf6,0xfc,0xf9};        //����˫���ķ�
uchar code FFW_1[8]={0xf1,0xf3,0xf2,0xf6,0xf4,0xfc,0xf8,0xf9};   //���൥˫������
uchar code REV_1[8]={0xf9,0xf8,0xfc,0xf4,0xf6,0xf2,0xf3,0xf1};   //���൥˫���ķ�
int i=0;
int speed=10;   //һ��Ҫ��int��������uchar����Ϊ2^8=256̫С
uchar act_rot=0;

/*--------------������-----------------------*/
main(){
 Init_Timer0();
 act_rot=1;
  delay_ms(2000);             //act_rot��speed��Ҫ�����ȫ�ֱ���
 act_rot=2;
 delay_ms(2000);
 act_rot=1;
 speed=20;
 delay_ms(2000);
 act_rot=2;
 delay_ms(2000);
  act_rot=0;
}
/*---------------------------------------*/

/*----------------��ʱ1ms-----------------------*/
void delay_ms(int x)          //delay 1ms
{char i;
while(x--){for(i=114;i>0;i--){};
}
}
/*------------------------------------------------ */



/*------------------------------------------------
                    ��ʱ����ʼ���ӳ���
------------------------------------------------*/
void Init_Timer0(void)
{
 TMOD |= 0x01;	  //ʹ��ģʽ1��16λ��ʱ����ʹ��"|"���ſ�����ʹ�ö����ʱ��ʱ����Ӱ��
 //TH0=0x00;	      //������ֵ
 //TL0=0x00;
 EA=1;            //���жϴ�
 ET0=1;           //��ʱ���жϴ�
 TR0=1;           //��ʱ�����ش�
 PT0=1;           //���ȼ���
}
/*----------------------------------------*/



/*--------����жϳ���---�������жϷ�������������---------*/
/*------act:0 ͣ�� 1 ��ת 2 ��ת------speed 10�ǿ� 20���� ��Ӧ�ж�ʱ�䣨ms)--------*/
void servo_interrupt(uchar act,int speed){
 int m;                           
 m=speed*1000;
 TH0=(65536-m)/256;		  //P1�ĵ�4λ���Ƶ��
 TL0=(65536-m)%256;
 if(act==0){
 P1&=0XF0;}
 if(act==1){
 P1=FFW[i];}
 if(act==2){
 P1=REV[i];}
 i++;
 if(i==4) i=0;
}
/*-----------------------------------------------------*/


/*------------------�жϷ������------------------*/
void Timer0_isr(void) interrupt 1
{
 servo_interrupt(act_rot,speed);
}
/*------------------------------------------------*/