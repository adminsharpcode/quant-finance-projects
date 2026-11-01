#property copyright ""
#property link      ""
#property version   "1.00"
#property strict
string 使用期限=""; //不填写则不限制，格式：2018.04.08 00:00
string 账号限制="";  //不填写则不限制，填写授权数字账号，|间隔，如：8888|9999|666

enum MYPERIOD{当前=PERIOD_CURRENT,M1=PERIOD_M1,M5=PERIOD_M5,M15=PERIOD_M15,M30=PERIOD_M30,H1=PERIOD_H1,H4=PERIOD_H4,D1=PERIOD_D1,W1=PERIOD_W1,MN1=PERIOD_MN1};
input MYPERIOD 时间周期=当前;

enum MY_OP2{BUY=OP_BUY,SELL=OP_SELL}; 

input double __首单手数=0.1;
input int __亏损几点挂单=180;
input double __加仓手数倍数=1.5;
input int __挂单偏离现价点数=80;
input int __同向几单解套=8;
input double __一加一盈利多少金额=0;
input int __均价止盈点数3=300;
input int __均价止盈点数2=500;
input int __均价止盈点数1=800;

input int _均线1_时间周期=40;
input int _均线1_平移=0;
input ENUM_MA_METHOD _均线1_移动平均=MODE_SMA;
input ENUM_APPLIED_PRICE _均线1_应用于=PRICE_CLOSE;

input int 最大允许滑点=900;

#define _tn_int int
#define _m_int int
#define _p_int int

input _m_int _订单识别码=0;
_m_int _内码=0;
input string 订单注释="";
_m_int 子识别码=0;
string _换注释="";
bool _b换注释=false;

_m_int 订单识别码=0;
_m_int 备份_分组码=0;
_m_int 备份_指定码=0;
int 强制判断识别码=0;

int 分组循环中=0;

int 指令执行了操盘=0;

_m_int 订单_R_识别码=0;
int 强制判断_R_识别码=0;
int 分组循环_R_中=0;

_m_int 备份_R_分组码=0;
_m_int 备份_R_指定码=0;

bool mOrderOk暂停=false;

int _点系数=1;

_tn_int _mPubTsIns[1000]={};
int _mPubTsInc=0;
_tn_int _mPubTsExs[1000]={};
int _mPubTsExc=0;
_tn_int _mPubTs2Ins[1000]={};
int _mPubTs2Inc=0;
_tn_int _mPubTs2Exs[1000]={};
int _mPubTs2Exc=0;
_tn_int _mPubTn0=0;

_tn_int _mPubHisTsIns[1000]={};
int _mPubHisTsInc=0;
_tn_int _mPubHisTsExs[1000]={};
int _mPubHisTsExc=0;
_tn_int _mPubHisTs2Ins[1000]={};

_tn_int _mPubHisTs2Exs[1000]={};

#define MYARC 20
#define MYPC 300
_p_int _mPubi[MYPC];
double _mPubv[MYPC];
string _mPubs[MYPC];
datetime _mPubTime[MYPC];
double _mPubFs[MYARC][MYPC]={};
_p_int _mPubIs[MYARC][MYPC]={};
int _mPubIsc[MYARC]={};
int _mPubFsc[MYARC]={};

#define MYARR_DC 1
#define MYARR_IC 5
#define MYARR_SC 1

int mArrDc[MYARR_DC];
_p_int mArrIs[MYARR_IC][300];
int mArrIc[MYARR_IC];

int mArrSc[MYARR_SC];
int mMks[20]={};

int §=0;

_m_int gGa=0;
_m_int gGb=0;
_m_int gGa_bak=0;
_m_int gGb_bak=0;

string sym="";

int period=0;

string mPreCap="";
string mPreCapM="";
string mPreCapP=""; //此类变量会在修改参数后也删除重置
string mPreCapNoDel="";//此类变量如果是挂ea，则永不清除；若是回测，则清除
string _mInitCap_LoadTime="";
string _mCap_TimePos1=""; //时间标注点

int mReInit=0;
int mReIniPr=0;
int OnInit() {
   string hd=MQLInfoString(MQL_PROGRAM_NAME);

   mPreCapM=hd+"_"+string(_订单识别码)+"_"; if (IsTesting()) mPreCapM+="test_";
   if (StringLen(mPreCapM)>26) mPreCapM=StringSubstr(mPreCapM,StringLen(mPreCapM)-26);

   mPreCap=hd+"_"+string(_订单识别码)+"_"+Symbol()+"_"; if (IsTesting()) mPreCap+="test_";
   if (StringLen(mPreCap)>26) mPreCap=StringSubstr(mPreCap,StringLen(mPreCap)-26);

   mPreCapNoDel=hd+"_"+string(_订单识别码)+"*_"+Symbol()+"_"; if (IsTesting()) mPreCapNoDel+="test_";
   if (StringLen(mPreCapNoDel)>26) mPreCapNoDel=StringSubstr(mPreCapNoDel,StringLen(mPreCapNoDel)-26);
   
   string sycap="eano1_cur_sym";
   if (ObjectGetString(0,sycap,OBJPROP_TEXT)!=Symbol()) { //不能用字符串变量记录和判断，mt5不适用
      ObjectsDeleteAll(); //图表品种被改变
      myCreateLabel(Symbol(),sycap,0,-2000,-2000,10,255,CORNER_LEFT_UPPER);
   }
   
   if (IsTesting()) {
      myObjectDeleteByPreCap(mPreCapM);
      myDeleteGlobalVariableByPre(mPreCapM);
      myObjectDeleteByPreCap(mPreCap);
      myDeleteGlobalVariableByPre(mPreCap);
      myObjectDeleteByPreCap(mPreCapNoDel);
      myDeleteGlobalVariableByPre(mPreCapNoDel);
   }   
   mPreCapP=mPreCap+"#_";
      
   _mInitCap_LoadTime=mPreCap+"_pub_loadtime";
   if (myGlobalVDateTimeCheck(_mInitCap_LoadTime)==false) myGlobalVDateTimeSet(_mInitCap_LoadTime,TimeCurrent());
   _mCap_TimePos1=mPreCap+"_pub_tmpos1";
   if (myGlobalVDateTimeCheck(_mCap_TimePos1)==false) myGlobalVDateTimeSet(_mCap_TimePos1,TimeCurrent());

   string cap=mPreCap+"_pub_loadea";
   if (mReInit==0 || GlobalVariableCheck(cap)==false) { //mt4非正常退出，mPreCap是无法判断的，只能通过mReInit来判断
      //显性复位
      for (int i=0;i<MYPC;++i) {
         _mPubi[i]=0;
         _mPubv[i]=0;
         _mPubs[i]="";
         _mPubTime[i]=0;
      }
      for (int i=0;i<MYARC;++i) {
         for (int j=0;j<MYPC;++j) {
            _mPubFs[i][j]=0;
            _mPubIs[i][j]=0;
         }
         _mPubIsc[i]=0;
         _mPubFsc[i]=0;
      }
      ArrayInitialize(mArrDc,-1);
      ArrayInitialize(mArrIc,-1);
      ArrayInitialize(mArrSc,-1);
      mReIniPr=1;      mReInit=1; GlobalVariableSet(cap,1);
   }
   if (mReIniPr==0) {
      ArrayInitialize(mArrDc,-1);
      ArrayInitialize(mArrIc,-1);
      ArrayInitialize(mArrSc,-1);
      mReIniPr=1;
   }
   
   _内码=_订单识别码; if (_内码==0) _内码=444;
   订单识别码=_内码;
   订单_R_识别码=_内码;
   
//mt5custominit

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

   //if (IsTesting()==false) myObjectDeleteByPreCap(mPreCap);  //切换周期不能删除，否则按钮状态会改变
   if (reason==REASON_REMOVE || reason==REASON_CHARTCLOSE || reason==REASON_PROGRAM) {
      if (IsTesting()==false) {
         myObjectDeleteByPreCap(mPreCapM);
         myObjectDeleteByPreCap(mPreCap);
         GlobalVariableDel(mPreCap+"_pub_loadea");
         bool ok=true;

         if (ok) {
            myDeleteGlobalVariableByPre(mPreCap);
            myDeleteGlobalVariableByPre(mPreCapM);
         }
      }
   }
   if (reason==REASON_PARAMETERS) {
      myObjectDeleteByPreCap(mPreCapP);
      myDeleteGlobalVariableByPre(mPreCapP);
      mReIniPr=0;
   }
}

void OnTick() {
   if (myTimeLimit(使用期限)==false) return;
   if (myAccountNumCheck()==false) return;
   if (_订单识别码==444 || _订单识别码==-444) { Alert("~~~~~~自定识别码不能设置为444和-444这两个数字"); ExpertRemove(); return; } 
   int _tmp_w_break=0;


   int _or=0;
   §=0; gGa=0; _mPubTsInc=_mPubTsExc=_mPubHisTsInc=_mPubHisTsExc=-1;
   period=时间周期; if (period==0) period=Period();
   sym=Symbol();

   ArrayInitialize(mMks,0);      
   if (0!=Period() && iOpen(sym,0,0)==0.00004751) Print("~~~a");
   int _ok0=-1;
   if (_ok0==-1) {
      int _ok1=myFun17_1();
      //r/ _ok0=_ok1;
      if (_ok1==1) {
         myFun139_1();
         myFun139_2();
      }
   }
   if (_ok0==-1) {
      int _ok2=-1;
      if (_ok2==-1) {
         int _ok3=myFun17_2();
         //r/ _ok2=_ok3;
         if (_ok3==0) { if (myFun6_1()==-3) _ok2=0; }
      }
      if (_ok2==-1) {
         int _ok4=myFun17_3();
         //r/ _ok2=_ok4;
         if (_ok4==0) { if (myFun6_2()==-3) _ok2=0; }
      }
      if (_ok2==-1) {
         int _ok5=myFun17_4();
         //r/ _ok2=_ok5;
         if (_ok5==0) { if (myFun6_3()==-3) _ok2=0; }
      }
      if (_ok2==-1) {
         int _ok6=myFun116_1();
         _ok2=_ok6;
         if (_ok6==0) { if (myFun6_4()==-3) _ok2=0; }
      }
      //r/ _ok0=_ok2;
      if (_ok2==1) {
         myFun83_1();
         myFun32_1();
         myFun96_1();
      }
   }
   if (_ok0==-1) {
      int _ok7=-1;
      if (_ok7==-1) {
         int _ok8=myFun17_5();
         //r/ _ok7=_ok8;
         if (_ok8==0) { if (myFun6_5()==-3) _ok7=0; }
      }
      if (_ok7==-1) {
         int _ok9=myFun17_6();
         //r/ _ok7=_ok9;
         if (_ok9==0) { if (myFun6_6()==-3) _ok7=0; }
      }
      if (_ok7==-1) {
         int _ok10=myFun17_7();
         //r/ _ok7=_ok10;
         if (_ok10==0) { if (myFun6_7()==-3) _ok7=0; }
      }
      if (_ok7==-1) {
         int _ok11=myFun116_2();
         _ok7=_ok11;
         if (_ok11==0) { if (myFun6_8()==-3) _ok7=0; }
      }
      //r/ _ok0=_ok7;
      if (_ok7==1) {
         myFun83_2();
         myFun32_2();
         myFun96_2();
      }
   }
   if (_ok0==-1) {
      int _ok12=myFun8_1();
      //r/ _ok0=_ok12;
      if (_ok12==1) { myFun172_1(); }
   }
   if (_ok0==-1) {
      int _ok13=-1;
      if (_ok13==-1) {
         int _ok14=myFun17_8();
         //r/ _ok13=_ok14;
         if (_ok14==0) { if (myFun6_9()==-3) _ok13=0; }
      }
      if (_ok13==-1) {
         int _ok15=myFun17_9();
         _ok13=_ok15;
         if (_ok15==0) { if (myFun6_10()==-3) _ok13=0; }
      }
      //r/ _ok0=_ok13;
      if (_ok13==1) { myFun474_1(); }
   }
   if (_ok0==-1) {
      int _ok16=-1;
      if (_ok16==-1) {
         int _ok17=myFun17_10();
         //r/ _ok16=_ok17;
         if (_ok17==0) { if (myFun6_11()==-3) _ok16=0; }
      }
      if (_ok16==-1) {
         int _ok18=myFun17_11();
         _ok16=_ok18;
         if (_ok18==0) { if (myFun6_12()==-3) _ok16=0; }
      }
      //r/ _ok0=_ok16;
      if (_ok16==1) { myFun474_2(); }
   }
   if (_ok0==-1) {
      int _ok19=myFun8_2();
      _ok0=_ok19;
      if (_ok19==1) {
         myFun24_1();
         myFun24_2();
         myFun24_3();
      }
   }

}

int mErrXY=-9876543;

int mMaxX=0;
int mMaxY=0;

datetime myTimeVar(int tid) {
   datetime tm=0;
   if (tid<100) tm=_mPubTime[tid];
   else if (tid==101) tm=myGlobalVDateTimeGet(_mInitCap_LoadTime); //ea加载时间
   else if (tid==102) tm=StrToTime(TimeToStr(TimeCurrent(),TIME_DATE)+" 00:00");
   else if (tid==103) tm=0;
   else if (tid==104) tm=9999999999;
   else if (tid==105) {
      string cap=mPreCap+"f170903_t";
      if (GlobalVariableCheck(cap)) tm=(datetime)(GlobalVariableGet(cap)*1000.0);   
      else tm=myGlobalVDateTimeGet(_mInitCap_LoadTime); //ea加载时间
   }
   else if (tid==106) tm=iTime(sym,period,0);
   else if (tid==107) tm=iTime(sym,period,1);
   else if (tid==108) tm=myGlobalVDateTimeGet(_mCap_TimePos1);
   else if (tid>=201 && tid<=210) tm=iTime(sym,period,int(_mPubIs[0][tid-201]));
   else if (tid>=211 && tid<=220) tm=iTime(sym,period,int(_mPubIs[1][tid-211]));
   return tm;
}

datetime myGlobalVDateTimeGet(string vcap) {
   string hcap=vcap+"__h";
   string lcap=vcap+"__l";
   double h=GlobalVariableGet(hcap);
   double l=GlobalVariableGet(lcap);
   double r=h*1000000+l;
   return (datetime)r;
}

void myGlobalVDateTimeSet(string vcap,datetime t) {
   string hcap=vcap+"__h";
   string lcap=vcap+"__l";
   double f=(double)t;
   double h=int(f/1000000);
   double l=int(f)%1000000;
   GlobalVariableSet(hcap,h);
   GlobalVariableSet(lcap,l);
}

bool myGlobalVDateTimeCheck(string vcap) {
   return GlobalVariableCheck(vcap+"__h");
}

bool myIsOpenByThisEA(_m_int om) {
  if (订单识别码==0 && 强制判断识别码==0)  return true;
  if (_订单识别码==0 && 强制判断识别码==0)  return true; //用户接口参数直接设置为0表示忽略识别码（判断的是“_订单识别码”，而非“订单识别码”，因此不影响区分手工单）
  if (分组循环中==1) return om==订单识别码;

   return om==订单识别码;
}

bool myIsOpenByThisEA2(_m_int om,int incSub) {
  if (订单识别码==0 && 强制判断识别码==0)  return true; 
  if (_订单识别码==0 && 强制判断识别码==0)  return true; //用户接口参数直接设置为0表示忽略识别码（判断的是“_订单识别码”，而非“订单识别码”，因此不影响区分手工单）
  if (分组循环中==1) return om==订单识别码;

   if (订单识别码==0) return om==订单识别码 || (incSub && int(om/100000)==444); //避免将其它ea的小于100000的识别码误认为是手工单
   return om==订单识别码 || (incSub && int(om/100000)==订单识别码);
}

bool myIsOpenByThis_R_E2(_m_int om,int incSub) {
  if (订单_R_识别码==0 && 强制判断_R_识别码==0)  return true;  
  if (_订单识别码==0 && 强制判断_R_识别码==0)  return true; //用户接口参数直接设置为0表示忽略识别码（判断的是“_订单识别码”，而非“订单_R_识别码”，因此不影响区分手工单）
  if (分组循环_R_中==1) return om==订单_R_识别码;

   if (订单_R_识别码==0) return om==订单_R_识别码 || (incSub && int(om/100000)==444); //避免将其它ea的小于100000的识别码误认为是手工单
   return om==订单_R_识别码 || (incSub && int(om/100000)==订单_R_识别码);
}

void myCreateLabel(string str="mylabel",string ID="def_la1",long chartid=0,int xdis=20,int ydis=20,int fontsize=12,color clr=clrRed,int corner=CORNER_LEFT_UPPER) {
    ObjectCreate(chartid,ID,OBJ_LABEL,0,0,0);
    ObjectSetInteger(chartid,ID,OBJPROP_XDISTANCE,xdis);
    ObjectSetInteger(chartid,ID,OBJPROP_YDISTANCE,ydis);
    ObjectSetString(chartid,ID,OBJPROP_FONT,"Trebuchet MS");
    ObjectSetInteger(chartid,ID,OBJPROP_FONTSIZE,fontsize);
    ObjectSetInteger(chartid,ID,OBJPROP_CORNER,corner);
    ObjectSetInteger(chartid,ID,OBJPROP_SELECTABLE,true);
    ObjectSetString(chartid,ID,OBJPROP_TOOLTIP,"\n");
    ObjectSetString(chartid,ID,OBJPROP_TEXT,str);
   ObjectSetInteger(chartid,ID,OBJPROP_COLOR,clr);
}

double myLotsValid(string sym0,double lots,bool returnMin=false) {
   double step=MarketInfo(sym0,MODE_LOTSTEP);
   if (step<0.000001) { Alert("品种【",sym0,"】数据读取失败，请检查此品种是否存在。若有后缀，请包含后缀。");  return lots; }
   double ls0=lots;
   int v=(int)MathRound(lots/step); lots=v*step;
   double min=MarketInfo(sym0,MODE_MINLOT);
   double max=MarketInfo(sym0,MODE_MAXLOT);
   if (v<-99999 || ls0>99999999) return max; //lots可能由于逆加翻倍次数太多而非常大，造成v内存溢出
   if (lots<min) {
      if (returnMin) return min;
      Alert("手数太小，不符合平台要求"); lots=-1;
   }
   if (lots>max) lots=max;
   return lots;
}

string 时间限制_时间前缀="使用期限：";
string 时间限制_时间后缀="";
string 时间过期_时间前缀="~~~~~~~已过使用期限：";
string 时间过期_时间后缀="";
bool myTimeLimit(string timestr) {
   if (timestr=="") return true;
   datetime t=StringToTime(timestr);
   if (TimeCurrent()<t) {
      myCreateLabel(时间限制_时间前缀+timestr+时间限制_时间后缀,mPreCap+"myTimeLimit",0,20,20,10,255,CORNER_LEFT_LOWER);
      return true;
   }
   else {
      myCreateLabel(时间过期_时间前缀+timestr+时间过期_时间后缀,mPreCap+"myTimeLimit",0,20,20,10,255,CORNER_LEFT_LOWER);
      return false;
   }
}

bool myAccountNumCheck() {
   if (账号限制=="") return true;
   
   ushort u_sep=StringGetCharacter("|",0);
   string ss[1000]; int c=StringSplit(账号限制,u_sep,ss);
   if (c>=1000) Alert("授权列表数量太大");
   
   string s=string(AccountNumber());
   for (int i=0;i<c;++i) if (s==ss[i]) return true;
     
   myCreateLabel("非授权账户账号:"+s,mPreCap+"onlyuser2"); 
   return false; 
}

void myDeleteGlobalVariableByPre(string pre) {
   int len=StringLen(pre);
   for (int i=GlobalVariablesTotal()-1;i>=0;--i) {
      string cap=GlobalVariableName(i);
      if (StringSubstr(cap,0,len)==pre)
   GlobalVariableDel(cap);
   }
}

void myObjectDeleteByPreCap(string PreCap) {
//删除指定名称前缀的对象
   int len=StringLen(PreCap);
   for (int i=ObjectsTotal()-1;i>=0;--i) {
      string cap=ObjectName(i);
      if (StringSubstr(cap,0,len)==PreCap)
         ObjectDelete(cap);
   }
}

int myParseStr2IntB(int id,string str,_p_int&arr[]) {
   if (mArrIc[id]<0) { //下一行的函数括号前空格及后面的注释，很重要，不要去除
      _p_int arr2[]; int ac2=myParseStr2Int (str,arr2); /*myParseStr2Int(*/ 
      if (ac2>300) { ac2=300; Alert("字符串包含数据超过300个，只保留前300个。"); }
      mArrIc[id]=ac2;
      for (int i=0;i<ac2;++i) mArrIs[id][i]=arr2[i];
   }
   int sc=mArrIc[id];
   int c0=ArraySize(arr); if (sc+1>=c0) ArrayResize(arr,sc+1);
   for (int i=0;i<sc;++i) arr[i]=mArrIs[id][i];
   return sc;
}

int myParseStr2Int(string str,_p_int&cs[]) {
//序号输入格式：-0 -3~-9  为了表示-0，所有有负号的数字都减1
   str=StringTrimLeft(StringTrimRight(str));
   ushort u_sep=StringGetCharacter(" ",0);
   string ss[]; int sc=StringSplit(str,u_sep,ss);
   int cc=0; ArrayResize(cs,300);
   for (int i=0;i<sc;++i) {
      int ps=StringFind(ss[i],"~");
      if (ps<=0) {
         _p_int t=(_p_int)StringToInteger(ss[i]);
         if (StringSubstr(ss[i],0,1)=="-") t-=1;
         if (cc+1>=300) { Alert("字符串包含的数字不能超过300个，比如3~9999包含的数字就太多"); ExpertRemove(); return 0; }
         cs[cc++]=t;
      }
      else {
         string s1=StringSubstr(ss[i],0,ps);
         string s2=StringSubstr(ss[i],ps+1);      
         _p_int t1=(_p_int)StringToInteger(s1); if (StringSubstr(s1,0,1)=="-") t1-=1;
         _p_int t2=(_p_int)StringToInteger(s2); if (StringSubstr(s2,0,1)=="-") t2-=1;
         if (t1>t2) { _p_int t=t1; t1=t2; t2=t; }
         for (_p_int j=t1;j<=t2;++j) {
            if (cc+1>=300) { Alert("字符串包含的数字不能超过300个，比如3~9999包含的数字就太多"); ExpertRemove(); return 0; }
            cs[cc++]=j;
         }
      }
   }
   return cc;
}

string myPeriodStr(int p0) {
   int pid=0; if (p0==0) p0=Period();
   string pstr;
   switch (p0) {
      case 1: pid=0; pstr="M1"; break;
      case 5: pid=1; pstr="M5"; break;
      case 15: pid=2; pstr="M15"; break;
      case 30: pid=3; pstr="M30"; break;
      case 60: pid=4; pstr="H1"; break;
      case 240: pid=5; pstr="H4"; break;
      case 1440: pid=6; pstr="D1"; break;
      case 10080: pid=7; pstr="W1"; break;
      case 43200: pid=8; pstr="MN"; break;
      default: pstr=string(p0);
   }
   return pstr;
}

bool myOrderOks(_tn_int tn) {
   if (mOrderOk暂停) return true;
   if (_mPubTsExc>0) { for (int i=0;i<_mPubTsExc;++i) { if (_mPubTsExs[i]==tn) return false; }  }
   if (_mPubTsInc>=0){ 
      int i=0; for (;i<_mPubTsInc;++i) { if (_mPubTsIns[i]==tn) break; } 
      if (i>=_mPubTsInc) return false;  
   }
   return true;
}

bool myOrderOk2(_tn_int tn) {
   if (mOrderOk暂停) return true;
   if (_mPubTs2Exc>0) { for (int i=0;i<_mPubTs2Exc;++i) { if (_mPubTs2Exs[i]==tn) return false; }  }
   if (_mPubTs2Inc>=0){ 
      int i=0; for (;i<_mPubTs2Inc;++i) { if (_mPubTs2Ins[i]==tn) break; } 
      if (i>=_mPubTs2Inc) return false;  
   }
   return true;
}

bool myOrderHisOks(_tn_int tn) {
   if (mOrderOk暂停) return true;
   if (_mPubHisTsExc>0) { for (int i=0;i<_mPubHisTsExc;++i) { if (_mPubHisTsExs[i]==tn) return false; }  }
   if (_mPubHisTsInc>=0){ 
      int i=0; for (;i<_mPubHisTsInc;++i) { if (_mPubHisTsIns[i]==tn) break; } 
      if (i>=_mPubHisTsInc) return false;  
   }
   return true;
}

bool myOpenOk(_tn_int tn,int type) {

//OrderSend返回值大于0并不代表建仓就成功了，需要等待确认
//本函数不处理mt5代码，在其它函数进行处理
   int i=0,wc=500; for (i=0;i<wc;++i) {
      RefreshRates();
      for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
      	if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
      	if (OrderTicket()==tn) {
      	   int t=OrderType();
      	   if (t==type) return true;
      	   if ((type==OP_BUYSTOP || type==OP_BUYLIMIT) && t==OP_BUY) return true;
      	   if ((type==OP_SELLSTOP || type==OP_SELLLIMIT) && t==OP_SELL) return true;
      	}
      }
      uint ta=GetTickCount();
      while (true) {
         uint tb=GetTickCount();
         if (tb<ta || tb-ta>30) break;
         if (OrderSelect(tn,SELECT_BY_TICKET) && OrderCloseTime()>0) {
            Alert("异常提醒：~~~~~~#",tn,"~~~订单刚建仓立即被平仓");
            return true;
         } 
      }
   }   
   if (i>=wc) { Alert("异常提醒：~~~~服务器太卡，订单建仓未成功 #",tn); return false; }

   return true;
}

double myFun25_1() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELL]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

bool myFun17_1() {
   double a=double(myFun25_1());
   double b=double(0);

   return a<=b+0.00000001;

}

_p_int myFun139_1() {
   指令执行了操盘=0;
   if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)==false && IsTesting()==false) return 0;

   _m_int magic=订单识别码;
   int slip=最大允许滑点;
   string comm=订单注释; if (_b换注释) comm=_换注释;

   double pnt=MarketInfo(sym,MODE_POINT);

   int type=0; 

   double lots=myLotsValid(sym,double(__首单手数),true);
   double sl=double(0*_点系数);
   double tp=double(0*_点系数);

   for(int pos=OrdersTotal()-1;pos>=0;pos--)           {
      if (OrderSelect(pos,SELECT_BY_POS)==false) continue;
      if (magic!=444 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;
      if (sym!="" && OrderSymbol()!=sym) continue;
      if (myOrderOks(OrderTicket())==false) continue;

   }

_tn_int tn=0;
for (int w=0;w<1+0;++w) { if (w>0) { Sleep(3000); Alert("~~~m=",magic,"~~~slip=",slip,"~~~~~建仓重试",w); RefreshRates(); } 
   double op=0;
   if (type==OP_BUY) {
      op=MarketInfo(sym,MODE_ASK);
      if (sl>0.001) sl=op-sl*MarketInfo(sym,MODE_POINT);
      if (tp>0.001) tp=op+tp*MarketInfo(sym,MODE_POINT);
   }
   else if (type==OP_SELL) {
      op=MarketInfo(sym,MODE_BID);
      if (sl>0.001) sl=op+sl*MarketInfo(sym,MODE_POINT);
      if (tp>0.001) tp=op-tp*MarketInfo(sym,MODE_POINT);
   }
   else return 0;
   tn=OrderSend(sym,type,lots,op,slip,sl,tp,comm,magic);
   if (tn>0 && myOpenOk(tn,type)==false) return 0;
   if (tn>0 && w>0) Alert("~~~~重试建仓成功");
   if (tn<=0) {
      int err=GetLastError();
      if (err==134) { Alert("~~~~~~~~~~保证金不足，建仓手数无效：",lots); Sleep(3000); return 0; }
      else if (err>=135 && err<=138) { Alert("~~m=",magic,"~~~网速慢或平台服务器卡~~~~~建仓失败：",err); continue; }
      else Alert("~~m=",magic,"~~~~~~~~建仓失败：",err);
      Sleep(3000); break; 
   }

   if (tn>0) { 指令执行了操盘=1; break; }
}   
   return tn;

}

_p_int myFun139_2() {
   指令执行了操盘=0;
   if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)==false && IsTesting()==false) return 0;

   _m_int magic=订单识别码;
   int slip=最大允许滑点;
   string comm=订单注释; if (_b换注释) comm=_换注释;

   double pnt=MarketInfo(sym,MODE_POINT);

   int type=1; 

   double lots=myLotsValid(sym,double(__首单手数),true);
   double sl=double(0*_点系数);
   double tp=double(0*_点系数);

   for(int pos=OrdersTotal()-1;pos>=0;pos--)           {
      if (OrderSelect(pos,SELECT_BY_POS)==false) continue;
      if (magic!=444 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;
      if (sym!="" && OrderSymbol()!=sym) continue;
      if (myOrderOks(OrderTicket())==false) continue;

   }

_tn_int tn=0;
for (int w=0;w<1+0;++w) { if (w>0) { Sleep(3000); Alert("~~~m=",magic,"~~~slip=",slip,"~~~~~建仓重试",w); RefreshRates(); } 
   double op=0;
   if (type==OP_BUY) {
      op=MarketInfo(sym,MODE_ASK);
      if (sl>0.001) sl=op-sl*MarketInfo(sym,MODE_POINT);
      if (tp>0.001) tp=op+tp*MarketInfo(sym,MODE_POINT);
   }
   else if (type==OP_SELL) {
      op=MarketInfo(sym,MODE_BID);
      if (sl>0.001) sl=op+sl*MarketInfo(sym,MODE_POINT);
      if (tp>0.001) tp=op-tp*MarketInfo(sym,MODE_POINT);
   }
   else return 0;
   tn=OrderSend(sym,type,lots,op,slip,sl,tp,comm,magic);
   if (tn>0 && myOpenOk(tn,type)==false) return 0;
   if (tn>0 && w>0) Alert("~~~~重试建仓成功");
   if (tn<=0) {
      int err=GetLastError();
      if (err==134) { Alert("~~~~~~~~~~保证金不足，建仓手数无效：",lots); Sleep(3000); return 0; }
      else if (err>=135 && err<=138) { Alert("~~m=",magic,"~~~网速慢或平台服务器卡~~~~~建仓失败：",err); continue; }
      else Alert("~~m=",magic,"~~~~~~~~建仓失败：",err);
      Sleep(3000); break; 
   }

   if (tn>0) { 指令执行了操盘=1; break; }
}   
   return tn;

}

double myFun25_2() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=1;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELL]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

bool myFun17_2() {
   double a=double(myFun25_2());
   double b=double(0);

   return a>b;

}
_p_int myFun6_1() {
   return -3;

}

double myFun25_3() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=1;
   ts[OP_SELL]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

bool myFun17_3() {
   double a=double(myFun25_3());
   double b=double(0);

   return MathAbs(a-b)<0.00000001;

}
_p_int myFun6_2() {
   return -3;

}

bool myFun17_4() {
   double a=double(iClose(sym,0,int(1+§)));
   double b=double(iMA(sym,0,_均线1_时间周期,_均线1_平移,_均线1_移动平均,_均线1_应用于,int(0+§)));

   return a>b;

}
_p_int myFun6_3() {
   return -3;

}

double myFun175_1() {
   int magic=0; 
   if (magic==0) magic=-2;
   else magic=0;
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=1;
   ts[OP_SELL]=0;
   ts[OP_BUYLIMIT]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);

   datetime begtime=myTimeVar(103);
   datetime tmo=0; double v=0; _tn_int tn0=0;
   for (int h=OrdersTotal()-1;h>=0;--h) {
      if (OrderSelect(h,SELECT_BY_POS)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;
      if (ts[OrderType()]==0) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      if (OrderOpenTime()<begtime) continue;
      if (OrderOpenTime()>tmo || (OrderOpenTime()==tmo && OrderTicket()>tn0)) { tn0=OrderTicket(); tmo=OrderOpenTime(); v=OrderOpenPrice(); } //不能用tn判断，因为挂单入场时间变，单号不变
   }

   for (int h=OrdersHistoryTotal()-1;h>=0;--h) {
      if (OrderSelect(h,SELECT_BY_POS,MODE_HISTORY)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;
      if (OrderCloseTime()<begtime) break;
      if (ts[OrderType()]==0) continue;
      if (myOrderHisOks(OrderTicket())==false) continue;
      if (OrderOpenTime()<begtime) continue;
      if (OrderOpenTime()>tmo || (OrderOpenTime()==tmo && OrderTicket()>tn0)) { tn0=OrderTicket(); tmo=OrderOpenTime(); v=OrderOpenPrice(); } //不能用tn判断，因为挂单入场时间变，单号不变
   }

   return v;

}

double myFun69_1() {
   return MarketInfo(sym,MODE_ASK);

}
bool myFun116_1() {
   double a=0,b=0;
   a=double(myFun175_1());
   b=double(myFun69_1());
   double v1=double(a-b);
   a=double(int(__亏损几点挂单)*MarketInfo(sym,MODE_POINT));
   double v2=double(a);

   return v1+0.00000001>=v2;

}
_p_int myFun6_4() {
   return -3;

}

double myFun25_4() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=1;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELL]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

_p_int myFun83_1() {
   double v=double(double(__加仓手数倍数));
   double c=double(myFun25_4());

   _mPubv[0]=MathPow(v,c);

   return 0;

}

double myFun186_1() {
   int magic=0; 
   if (magic==0) magic=-2;
   else magic=0;
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=1;
   ts[OP_SELL]=0;
   if (ts[OP_BUY]+ts[OP_SELL]==0) ts[OP_BUY]=ts[OP_SELL]=1;
   datetime begtime=myTimeVar(103);
   datetime tm0=0; double v=0; _tn_int tn0=0;
   for (int h=OrdersTotal()-1;h>=0;--h) {
      if (OrderSelect(h,SELECT_BY_POS)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;
      if (ts[OrderType()]==0) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      if (OrderOpenTime()<begtime) continue;
      if (tm0==0 || OrderOpenTime()<tm0 || (OrderOpenTime()==tm0 && OrderTicket()<tn0)) { tn0=OrderTicket(); tm0=OrderOpenTime(); v=OrderLots(); }
   }

   return v;

}
_p_int myFun32_1() {
   _m_int magic=订单识别码;

   double a=0,b=0;
   a=double(_mPubv[0]);
   b=double(myFun186_1());
   _mPubv[0]=double(a*b);

   return 0;

}

double myFun69_2() {
   return MarketInfo(sym,MODE_ASK);

}

_p_int myFun96_1() {
   指令执行了操盘=0;
   _m_int magic=订单识别码;
   string comm=订单注释;
   double pnt=MarketInfo(sym,MODE_POINT);
   double ask=MarketInfo(sym,MODE_ASK);
   double bid=MarketInfo(sym,MODE_BID);
   int type=0; 

   double op=myFun69_2(); if (op<pnt) return 0;
   int t0=int(0);
   int jg=int(int(__挂单偏离现价点数));
   double lots=myLotsValid(sym,_mPubv[0],true);
   int slt=0; double sl=0;
   int tpt=0; double tp=0;
   int err=0;

   if (t0==0) op+=jg*pnt;
   else op-=jg*pnt;
   
   int tt=type;
   if (op>bid) {
      if (type==OP_BUY) type=OP_BUYSTOP;
      else type=OP_SELLLIMIT;
   }
   else {
      if (type==OP_BUY) type=OP_BUYLIMIT;
      else type=OP_SELLSTOP;
   }
   
   int stoplevel=(int)MarketInfo(sym,MODE_STOPLEVEL);
   if (err==0) {
      if (type==OP_BUYLIMIT || type==OP_SELLLIMIT) return 0;
      if (type==OP_BUYSTOP && op<ask+stoplevel*pnt) return 0;
      if (type==OP_SELLSTOP && op>bid-stoplevel*pnt) return 0;
   }
   else if (err==2) {
      if (type==OP_BUYSTOP || type==OP_SELLSTOP) return 0;
      if (type==OP_BUYLIMIT && op>bid-stoplevel*pnt) return 0;
      if (type==OP_SELLLIMIT && op<ask+stoplevel*pnt) return 0;
   }

   bool xj=0;
   if (err==1 || err==2) {   
      if (type==OP_BUYSTOP && op<ask+stoplevel*pnt) xj=1;
      else if (type==OP_SELLSTOP && op>bid-stoplevel*pnt) xj=1;
      else if (type==OP_BUYLIMIT && op>bid-stoplevel*pnt) xj=1;
      else if (type==OP_SELLLIMIT && op<ask+stoplevel*pnt) xj=1;
   }   

   if (xj==1) {
      if (tt==OP_BUY) op=ask;
      else op=bid;
   }
   
   if (tt==OP_BUY) {
      if (slt==0 && sl>0.001) sl=op-sl*pnt;
      if (tpt==0 && tp>0.001) tp=op+tp*pnt;
   }
   else {
      if (slt==0 && sl>0.001) sl=op+sl*pnt;
      if (tpt==0 && tp>0.001) tp=op-tp*pnt;
   }
   
   _tn_int tn=0;
   if (xj==1) {
      tn=OrderSend(sym,tt,lots,op,最大允许滑点,sl,tp,comm,magic);
      if (tn<=0) Print("~~~~~~~~~~建仓错误：",GetLastError());
      else 指令执行了操盘=1;
   }
   else {
      tn=OrderSend(sym,type,lots,op,0,sl,tp,comm,magic);
      if (tn<=0) Print("~~~~~~~~~~挂单错误：",GetLastError());
      else 指令执行了操盘=1; 
   }
   return tn;
}

bool myFun17_5() {
   double a=double(iClose(sym,0,int(1+§)));
   double b=double(iMA(sym,0,_均线1_时间周期,_均线1_平移,_均线1_移动平均,_均线1_应用于,int(0+§)));

   return a<b;

}
_p_int myFun6_5() {
   return -3;

}

double myFun25_5() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELL]=1;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

bool myFun17_6() {
   double a=double(myFun25_5());
   double b=double(0);

   return a>b;

}
_p_int myFun6_6() {
   return -3;

}

double myFun25_6() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELL]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=1;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

bool myFun17_7() {
   double a=double(myFun25_6());
   double b=double(0);

   return MathAbs(a-b)<0.00000001;

}
_p_int myFun6_7() {
   return -3;

}

double myFun70_1() {
   return MarketInfo(sym,MODE_BID);

}

double myFun175_2() {
   int magic=0; 
   if (magic==0) magic=-2;
   else magic=0;
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_SELL]=1;
   ts[OP_BUYLIMIT]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);

   datetime begtime=myTimeVar(103);
   datetime tmo=0; double v=0; _tn_int tn0=0;
   for (int h=OrdersTotal()-1;h>=0;--h) {
      if (OrderSelect(h,SELECT_BY_POS)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;
      if (ts[OrderType()]==0) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      if (OrderOpenTime()<begtime) continue;
      if (OrderOpenTime()>tmo || (OrderOpenTime()==tmo && OrderTicket()>tn0)) { tn0=OrderTicket(); tmo=OrderOpenTime(); v=OrderOpenPrice(); } //不能用tn判断，因为挂单入场时间变，单号不变
   }

   for (int h=OrdersHistoryTotal()-1;h>=0;--h) {
      if (OrderSelect(h,SELECT_BY_POS,MODE_HISTORY)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;
      if (OrderCloseTime()<begtime) break;
      if (ts[OrderType()]==0) continue;
      if (myOrderHisOks(OrderTicket())==false) continue;
      if (OrderOpenTime()<begtime) continue;
      if (OrderOpenTime()>tmo || (OrderOpenTime()==tmo && OrderTicket()>tn0)) { tn0=OrderTicket(); tmo=OrderOpenTime(); v=OrderOpenPrice(); } //不能用tn判断，因为挂单入场时间变，单号不变
   }

   return v;

}
bool myFun116_2() {
   double a=0,b=0;
   a=double(myFun70_1());
   b=double(myFun175_2());
   double v1=double(a-b);
   a=double(int(__亏损几点挂单)*MarketInfo(sym,MODE_POINT));
   double v2=double(a);

   return v1+0.00000001>=v2;

}
_p_int myFun6_8() {
   return -3;

}

double myFun25_7() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELL]=1;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

_p_int myFun83_2() {
   double v=double(double(__加仓手数倍数));
   double c=double(myFun25_7());

   _mPubv[0]=MathPow(v,c);

   return 0;

}

double myFun186_2() {
   int magic=0; 
   if (magic==0) magic=-2;
   else magic=0;
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_SELL]=1;
   if (ts[OP_BUY]+ts[OP_SELL]==0) ts[OP_BUY]=ts[OP_SELL]=1;
   datetime begtime=myTimeVar(103);
   datetime tm0=0; double v=0; _tn_int tn0=0;
   for (int h=OrdersTotal()-1;h>=0;--h) {
      if (OrderSelect(h,SELECT_BY_POS)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;
      if (ts[OrderType()]==0) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      if (OrderOpenTime()<begtime) continue;
      if (tm0==0 || OrderOpenTime()<tm0 || (OrderOpenTime()==tm0 && OrderTicket()<tn0)) { tn0=OrderTicket(); tm0=OrderOpenTime(); v=OrderLots(); }
   }

   return v;

}
_p_int myFun32_2() {
   _m_int magic=订单识别码;

   double a=0,b=0;
   a=double(_mPubv[0]);
   b=double(myFun186_2());
   _mPubv[0]=double(a*b);

   return 0;

}

double myFun70_2() {
   return MarketInfo(sym,MODE_BID);

}

_p_int myFun96_2() {
   指令执行了操盘=0;
   _m_int magic=订单识别码;
   string comm=订单注释;
   double pnt=MarketInfo(sym,MODE_POINT);
   double ask=MarketInfo(sym,MODE_ASK);
   double bid=MarketInfo(sym,MODE_BID);
   int type=1; 

   double op=myFun70_2(); if (op<pnt) return 0;
   int t0=int(1);
   int jg=int(int(__挂单偏离现价点数));
   double lots=myLotsValid(sym,_mPubv[0],true);
   int slt=0; double sl=0;
   int tpt=0; double tp=0;
   int err=0;

   if (t0==0) op+=jg*pnt;
   else op-=jg*pnt;
   
   int tt=type;
   if (op>bid) {
      if (type==OP_BUY) type=OP_BUYSTOP;
      else type=OP_SELLLIMIT;
   }
   else {
      if (type==OP_BUY) type=OP_BUYLIMIT;
      else type=OP_SELLSTOP;
   }
   
   int stoplevel=(int)MarketInfo(sym,MODE_STOPLEVEL);
   if (err==0) {
      if (type==OP_BUYLIMIT || type==OP_SELLLIMIT) return 0;
      if (type==OP_BUYSTOP && op<ask+stoplevel*pnt) return 0;
      if (type==OP_SELLSTOP && op>bid-stoplevel*pnt) return 0;
   }
   else if (err==2) {
      if (type==OP_BUYSTOP || type==OP_SELLSTOP) return 0;
      if (type==OP_BUYLIMIT && op>bid-stoplevel*pnt) return 0;
      if (type==OP_SELLLIMIT && op<ask+stoplevel*pnt) return 0;
   }

   bool xj=0;
   if (err==1 || err==2) {   
      if (type==OP_BUYSTOP && op<ask+stoplevel*pnt) xj=1;
      else if (type==OP_SELLSTOP && op>bid-stoplevel*pnt) xj=1;
      else if (type==OP_BUYLIMIT && op>bid-stoplevel*pnt) xj=1;
      else if (type==OP_SELLLIMIT && op<ask+stoplevel*pnt) xj=1;
   }   

   if (xj==1) {
      if (tt==OP_BUY) op=ask;
      else op=bid;
   }
   
   if (tt==OP_BUY) {
      if (slt==0 && sl>0.001) sl=op-sl*pnt;
      if (tpt==0 && tp>0.001) tp=op+tp*pnt;
   }
   else {
      if (slt==0 && sl>0.001) sl=op+sl*pnt;
      if (tpt==0 && tp>0.001) tp=op-tp*pnt;
   }
   
   _tn_int tn=0;
   if (xj==1) {
      tn=OrderSend(sym,tt,lots,op,最大允许滑点,sl,tp,comm,magic);
      if (tn<=0) Print("~~~~~~~~~~建仓错误：",GetLastError());
      else 指令执行了操盘=1;
   }
   else {
      tn=OrderSend(sym,type,lots,op,0,sl,tp,comm,magic);
      if (tn<=0) Print("~~~~~~~~~~挂单错误：",GetLastError());
      else 指令执行了操盘=1; 
   }
   return tn;
}

bool myFun8_1() {
   return true;

}

_p_int myFun172_1() {
   if (OrdersTotal()<=0) return 0;
   double off1=double(int(__挂单偏离现价点数));
   double off2=double(3);
   int magic=1; if (1==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) 
      ts[OP_BUYLIMIT]=ts[OP_BUYSTOP]=ts[OP_SELLLIMIT]=ts[OP_SELLSTOP]=1;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     int t=OrderType(); if (ts[t]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     double pnt=MarketInfo(OrderSymbol(),MODE_POINT);
     double stoplevel=MarketInfo(OrderSymbol(),MODE_STOPLEVEL);
     if (off1<stoplevel) continue; //设置的偏离点数小于平台要求的最小偏离点数，无法移动
     double op=OrderOpenPrice(),op2=0;
     if (t==OP_BUYSTOP || t==OP_SELLLIMIT) {
         double ask=MarketInfo(OrderSymbol(),MODE_ASK);
         double ask2=ask+stoplevel*pnt;
         if (op<ask2) continue; //挂单价离现价太近，无法移动
         op2=ask+off1*pnt;
     }
     else { 
         double bid=MarketInfo(OrderSymbol(),MODE_BID);
         double bid2=bid-stoplevel*pnt;
         if (op>bid2) continue; //挂单价离现价太近，无法移动
         op2=bid-off1*pnt;
     }
     if (MathAbs(op-op2)<=off2*pnt) continue; //目标价位与当前挂单价的偏差在允许范围内，不移动

     if ((OrderType()==OP_BUYSTOP || OrderType()==OP_SELLLIMIT) && op2>op) continue;
     if ((OrderType()==OP_SELLSTOP || OrderType()==OP_BUYLIMIT) && op2<op) continue;

     double sl=OrderStopLoss(); if (sl>pnt) sl+=op2-op;
     double tp=OrderTakeProfit(); if (tp>pnt) tp+=op2-op;
     string capt=mPreCap+"t:"+"172_1"+"_"+string(OrderTicket()); int capt2=0;
     if (GlobalVariableCheck(capt)) {
         capt2=1; if (int(GetTickCount()/1000)-GlobalVariableGet(capt)<2) continue; //如果出错，2秒重试一次
     }    
     if (OrderModify(OrderTicket(),op2,sl,tp,OrderExpiration())==false) {
         GlobalVariableSet(capt,int(GetTickCount()/1000));
         if (capt2==0) Print("~~~~~~~~~移动挂单失败#",OrderTicket(),":",GetLastError());
     } 
   }
   return 0;

}

double myFun25_8() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=1;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELL]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

bool myFun17_8() {
   double a=double(myFun25_8());
   double b=double(int(__同向几单解套));

   return a+0.00000001>=b;

}
_p_int myFun6_9() {
   return -3;

}

double myFun475_1() {
   if (OrdersTotal()<=0) return 0;
   int ts[2]={0,0};
   ts[OP_BUY]=0;
   ts[OP_SELL]=0;
   if (ts[OP_BUY]+ts[OP_SELL]==0) ts[0]=ts[1]=1;
   _tn_int ns[300]={}; 
   datetime tms[300]={};
   int fc=0;
   for (int h=0;h<OrdersTotal();++h) {
      if (OrderSelect(h,SELECT_BY_POS)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

      int tt=OrderType(); if (tt!=OP_BUY && tt!=OP_SELL) continue;
      if (ts[tt]==0) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      _tn_int t=OrderTicket();
      int i=-1; 

      for (i=fc-1;i>=0;--i) { if (t>ns[i]) break; }
      i+=1;
      for (int j=fc-1;j>=i;--j) ns[j+1]=ns[j];
      ns[i]=t; fc+=1;      

      if (fc>=300) { Alert("错误：指令只支持300条订单数据返回，本指令可能不支持您的策略。"); break; }
   }
   _p_int cs[300]={}; int cc=0;
   if (fc>0) {
      _p_int cs2[]={}; int cc2=myParseStr2IntB(0,string("-0  0"),cs2); 
      for (int j=0;j<cc2;++j) {
         int n=int(cs2[j]);
         if (n<0) { 
            n+=1; //在分解数字时，为表示-0，负数都-1，现在还原
            n=fc-1+n;
         }
         if (n>=0 && n<fc) cs[cc++]=ns[n];
      }
   }
   double v=0,ls=0; int oc=0;
   for (int i=0;i<cc;++i) {
      if (OrderSelect(cs[i],SELECT_BY_TICKET)==false) continue;
      v+=OrderProfit()+OrderSwap()+OrderCommission();
      ls+=OrderLots(); oc++;
   }

   return v;
}

bool myFun17_9() {
   double a=double(myFun475_1());
   double b=double(double(__一加一盈利多少金额));

   return MathAbs(a-b)<0.00000001;

}
_p_int myFun6_10() {
   return -3;

}

_p_int myFun474_1() {
   指令执行了操盘=0;
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=1;
   ts[OP_SELL]=0;
   ts[OP_BUYLIMIT]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   _tn_int ns[300]={}; 
   datetime tms[300]={};
   int fc=0;
   for (int h=0;h<OrdersTotal();++h) {
      if (OrderSelect(h,SELECT_BY_POS)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

      if (ts[OrderType()]==0) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      
      _tn_int t=OrderTicket();
      int i=-1; 

      for (i=fc-1;i>=0;--i) { if (t>ns[i]) break; }
      i+=1;
      for (int j=fc-1;j>=i;--j) ns[j+1]=ns[j];
      ns[i]=t; fc+=1;      

      if (fc>=300) { Alert("错误：指令只支持300条订单数据返回，本指令可能不支持您的策略。"); break; }
   }
   
   _p_int cs[300]={}; int cc=0;
   if (fc>0) {
      _p_int cs2[]={}; int cc2=myParseStr2IntB(1,string("-0 0"),cs2); 
      for (int j=0;j<cc2;++j) {
         int n=int(cs2[j]);
         if (n<0) { 
            n+=1; //在分解数字时，为表示-0，负数都-1，现在还原
            n=fc-1+n;
         }
         if (n>=0 && n<fc) cs[cc++]=ns[n];
      }
   }

   int okc=0,erc=0;
   for (int i=0;i<cc;++i) {
      if (OrderSelect(cs[i],SELECT_BY_TICKET)==false) continue;
      if (OrderCloseTime()>0) continue;
      if (OrderType()==OP_BUY || OrderType()==OP_SELL) {
         if (OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),最大允许滑点)==false) { erc+=1; Print("~~~~~~~~平仓错误,",GetLastError()); }
         else okc+=1;
      }
      else {
         if (OrderDelete(OrderTicket())==false) { erc+=1; Print("~~~~~~删除挂单错误",GetLastError()); }
         else okc+=1;
      }
   }
   if (okc>0) 指令执行了操盘=1;
   return 0;
}

double myFun25_9() {
   if (OrdersTotal()<=0) return 0;
   int magic=1; if (0==1) magic=0;   
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_BUYLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELL]=1;
   ts[OP_SELLLIMIT]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   int c=0;
   for (int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
     if (OrderSelect(cnt,SELECT_BY_POS)==false) continue;
     if (magic!=0 && myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

     if (sym!="" && OrderSymbol()!=sym) continue;

     if (ts[OrderType()]==0) continue;
     if (myOrderOks(OrderTicket())==false) continue;
     c+=1;
   }
   return c;

}

bool myFun17_10() {
   double a=double(myFun25_9());
   double b=double(int(__同向几单解套));

   return a+0.00000001>=b;

}
_p_int myFun6_11() {
   return -3;

}

double myFun475_2() {
   if (OrdersTotal()<=0) return 0;
   int ts[2]={0,0};
   ts[OP_BUY]=0;
   ts[OP_SELL]=0;
   if (ts[OP_BUY]+ts[OP_SELL]==0) ts[0]=ts[1]=1;
   _tn_int ns[300]={}; 
   datetime tms[300]={};
   int fc=0;
   for (int h=0;h<OrdersTotal();++h) {
      if (OrderSelect(h,SELECT_BY_POS)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

      int tt=OrderType(); if (tt!=OP_BUY && tt!=OP_SELL) continue;
      if (ts[tt]==0) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      _tn_int t=OrderTicket();
      int i=-1; 

      for (i=fc-1;i>=0;--i) { if (t>ns[i]) break; }
      i+=1;
      for (int j=fc-1;j>=i;--j) ns[j+1]=ns[j];
      ns[i]=t; fc+=1;      

      if (fc>=300) { Alert("错误：指令只支持300条订单数据返回，本指令可能不支持您的策略。"); break; }
   }
   _p_int cs[300]={}; int cc=0;
   if (fc>0) {
      _p_int cs2[]={}; int cc2=myParseStr2IntB(2,string("-0  0"),cs2); 
      for (int j=0;j<cc2;++j) {
         int n=int(cs2[j]);
         if (n<0) { 
            n+=1; //在分解数字时，为表示-0，负数都-1，现在还原
            n=fc-1+n;
         }
         if (n>=0 && n<fc) cs[cc++]=ns[n];
      }
   }
   double v=0,ls=0; int oc=0;
   for (int i=0;i<cc;++i) {
      if (OrderSelect(cs[i],SELECT_BY_TICKET)==false) continue;
      v+=OrderProfit()+OrderSwap()+OrderCommission();
      ls+=OrderLots(); oc++;
   }

   return v;
}

bool myFun17_11() {
   double a=double(myFun475_2());
   double b=double(double(__一加一盈利多少金额));

   return MathAbs(a-b)<0.00000001;

}
_p_int myFun6_12() {
   return -3;

}

_p_int myFun474_2() {
   指令执行了操盘=0;
   int ts[10]={}; ArrayInitialize(ts,0);
   ts[OP_BUY]=0;
   ts[OP_SELL]=1;
   ts[OP_BUYLIMIT]=0;
   ts[OP_SELLLIMIT]=0;
   ts[OP_BUYSTOP]=0;
   ts[OP_SELLSTOP]=0;
   if (ts[OP_BUY]+ts[OP_BUYLIMIT]+ts[OP_BUYSTOP]+ts[OP_SELL]+ts[OP_SELLLIMIT]+ts[OP_SELLSTOP]==0) ArrayInitialize(ts,1);
   _tn_int ns[300]={}; 
   datetime tms[300]={};
   int fc=0;
   for (int h=0;h<OrdersTotal();++h) {
      if (OrderSelect(h,SELECT_BY_POS)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;

      if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

      if (ts[OrderType()]==0) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      
      _tn_int t=OrderTicket();
      int i=-1; 

      for (i=fc-1;i>=0;--i) { if (t>ns[i]) break; }
      i+=1;
      for (int j=fc-1;j>=i;--j) ns[j+1]=ns[j];
      ns[i]=t; fc+=1;      

      if (fc>=300) { Alert("错误：指令只支持300条订单数据返回，本指令可能不支持您的策略。"); break; }
   }
   
   _p_int cs[300]={}; int cc=0;
   if (fc>0) {
      _p_int cs2[]={}; int cc2=myParseStr2IntB(3,string("-0 0"),cs2); 
      for (int j=0;j<cc2;++j) {
         int n=int(cs2[j]);
         if (n<0) { 
            n+=1; //在分解数字时，为表示-0，负数都-1，现在还原
            n=fc-1+n;
         }
         if (n>=0 && n<fc) cs[cc++]=ns[n];
      }
   }

   int okc=0,erc=0;
   for (int i=0;i<cc;++i) {
      if (OrderSelect(cs[i],SELECT_BY_TICKET)==false) continue;
      if (OrderCloseTime()>0) continue;
      if (OrderType()==OP_BUY || OrderType()==OP_SELL) {
         if (OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),最大允许滑点)==false) { erc+=1; Print("~~~~~~~~平仓错误,",GetLastError()); }
         else okc+=1;
      }
      else {
         if (OrderDelete(OrderTicket())==false) { erc+=1; Print("~~~~~~删除挂单错误",GetLastError()); }
         else okc+=1;
      }
   }
   if (okc>0) 指令执行了操盘=1;
   return 0;
}

bool myFun8_2() {
   return true;

}

_p_int myFun24_1() {
   指令执行了操盘=0;
   int slip=最大允许滑点;
   string comm=订单注释;
   double pnt=MarketInfo(sym,MODE_POINT);
   int digit=(int)MarketInfo(sym,MODE_DIGITS);
   double tpp=double(int(__均价止盈点数3));
   int minc=7;
   int canBig=1;
   //if (tpp<pnt) return 0;
 
{  double op[2]={0,0},ls[2]={0,0}; int oc[2]={0,0};
   for(int pos=OrdersTotal()-1;pos>=0;pos--)           {
      if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

      if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;
      int t=OrderType();
      if (t!=OP_BUY && t!=OP_SELL) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      op[t]+=OrderOpenPrice()*OrderLots(); ls[t]+=OrderLots(); oc[t]+=1;
   }
   for (int i=0;i<2;++i) {
      if (oc[i]==0) continue;
      op[i]/=ls[i]; op[i]=NormalizeDouble(op[i],digit);
   }

   //修改止盈价
   int z=0;

   if (oc[z]>0 && oc[z]>=minc) { int type=OP_BUY; double tpaver=op[z]+tpp*pnt;
      for(int pos=OrdersTotal()-1;pos>=0;pos--) {
         if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

         if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

         if (sym!="" && OrderSymbol()!=sym) continue;
         if (OrderType()!=type) continue;
         if (myOrderOks(OrderTicket())==false) continue;
         if (MathAbs(OrderTakeProfit()-tpaver)<pnt) continue;
         if (canBig==false && OrderTakeProfit()>pnt && tpaver>OrderTakeProfit()) continue;
         if (OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tpaver,OrderExpiration())==false) 
            Print("buy止盈修改失败#",OrderTicket(),",",OrderSymbol(),",",GetLastError());
         else 指令执行了操盘=1;
      }
   }

   z=1;
   if (oc[z]>0 && oc[z]>=minc) { int type=OP_SELL; double tpaver=op[z]-tpp*pnt;
      for(int pos=OrdersTotal()-1;pos>=0;pos--) {
         if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

         if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

         if (sym!="" && OrderSymbol()!=sym) continue;
         if (OrderType()!=type) continue;
         if (myOrderOks(OrderTicket())==false) continue;
         if (MathAbs(OrderTakeProfit()-tpaver)<pnt) continue;
         if (canBig==false && OrderTakeProfit()>pnt && tpaver<OrderTakeProfit()) continue;
         if (OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tpaver,OrderExpiration())==false) 
            Print("sell止盈修改失败#",OrderTicket(),",",OrderSymbol(),",",GetLastError());
         else 指令执行了操盘=1;
      }
   }

}   

   return 0;
}

_p_int myFun24_2() {
   指令执行了操盘=0;
   int slip=最大允许滑点;
   string comm=订单注释;
   double pnt=MarketInfo(sym,MODE_POINT);
   int digit=(int)MarketInfo(sym,MODE_DIGITS);
   double tpp=double(int(__均价止盈点数2));
   int minc=4;
   int canBig=1;
   //if (tpp<pnt) return 0;
 
{  double op[2]={0,0},ls[2]={0,0}; int oc[2]={0,0};
   for(int pos=OrdersTotal()-1;pos>=0;pos--)           {
      if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

      if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;
      int t=OrderType();
      if (t!=OP_BUY && t!=OP_SELL) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      op[t]+=OrderOpenPrice()*OrderLots(); ls[t]+=OrderLots(); oc[t]+=1;
   }
   for (int i=0;i<2;++i) {
      if (oc[i]==0) continue;
      op[i]/=ls[i]; op[i]=NormalizeDouble(op[i],digit);
   }

   //修改止盈价
   int z=0;

   if (oc[z]>0 && oc[z]>=minc) { int type=OP_BUY; double tpaver=op[z]+tpp*pnt;
      for(int pos=OrdersTotal()-1;pos>=0;pos--) {
         if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

         if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

         if (sym!="" && OrderSymbol()!=sym) continue;
         if (OrderType()!=type) continue;
         if (myOrderOks(OrderTicket())==false) continue;
         if (MathAbs(OrderTakeProfit()-tpaver)<pnt) continue;
         if (canBig==false && OrderTakeProfit()>pnt && tpaver>OrderTakeProfit()) continue;
         if (OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tpaver,OrderExpiration())==false) 
            Print("buy止盈修改失败#",OrderTicket(),",",OrderSymbol(),",",GetLastError());
         else 指令执行了操盘=1;
      }
   }

   z=1;
   if (oc[z]>0 && oc[z]>=minc) { int type=OP_SELL; double tpaver=op[z]-tpp*pnt;
      for(int pos=OrdersTotal()-1;pos>=0;pos--) {
         if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

         if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

         if (sym!="" && OrderSymbol()!=sym) continue;
         if (OrderType()!=type) continue;
         if (myOrderOks(OrderTicket())==false) continue;
         if (MathAbs(OrderTakeProfit()-tpaver)<pnt) continue;
         if (canBig==false && OrderTakeProfit()>pnt && tpaver<OrderTakeProfit()) continue;
         if (OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tpaver,OrderExpiration())==false) 
            Print("sell止盈修改失败#",OrderTicket(),",",OrderSymbol(),",",GetLastError());
         else 指令执行了操盘=1;
      }
   }

}   

   return 0;
}

_p_int myFun24_3() {
   指令执行了操盘=0;
   int slip=最大允许滑点;
   string comm=订单注释;
   double pnt=MarketInfo(sym,MODE_POINT);
   int digit=(int)MarketInfo(sym,MODE_DIGITS);
   double tpp=double(int(__均价止盈点数1));
   int minc=0;
   int canBig=1;
   //if (tpp<pnt) return 0;
 
{  double op[2]={0,0},ls[2]={0,0}; int oc[2]={0,0};
   for(int pos=OrdersTotal()-1;pos>=0;pos--)           {
      if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

      if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

      if (sym!="" && OrderSymbol()!=sym) continue;
      int t=OrderType();
      if (t!=OP_BUY && t!=OP_SELL) continue;
      if (myOrderOks(OrderTicket())==false) continue;
      op[t]+=OrderOpenPrice()*OrderLots(); ls[t]+=OrderLots(); oc[t]+=1;
   }
   for (int i=0;i<2;++i) {
      if (oc[i]==0) continue;
      op[i]/=ls[i]; op[i]=NormalizeDouble(op[i],digit);
   }

   //修改止盈价
   int z=0;

   if (oc[z]>0 && oc[z]>=minc) { int type=OP_BUY; double tpaver=op[z]+tpp*pnt;
      for(int pos=OrdersTotal()-1;pos>=0;pos--) {
         if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

         if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

         if (sym!="" && OrderSymbol()!=sym) continue;
         if (OrderType()!=type) continue;
         if (myOrderOks(OrderTicket())==false) continue;
         if (MathAbs(OrderTakeProfit()-tpaver)<pnt) continue;
         if (canBig==false && OrderTakeProfit()>pnt && tpaver>OrderTakeProfit()) continue;
         if (OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tpaver,OrderExpiration())==false) 
            Print("buy止盈修改失败#",OrderTicket(),",",OrderSymbol(),",",GetLastError());
         else 指令执行了操盘=1;
      }
   }

   z=1;
   if (oc[z]>0 && oc[z]>=minc) { int type=OP_SELL; double tpaver=op[z]-tpp*pnt;
      for(int pos=OrdersTotal()-1;pos>=0;pos--) {
         if (OrderSelect(pos,SELECT_BY_POS)==false) continue;

         if (myIsOpenByThisEA2(OrderMagicNumber(),1)==false) continue;

         if (sym!="" && OrderSymbol()!=sym) continue;
         if (OrderType()!=type) continue;
         if (myOrderOks(OrderTicket())==false) continue;
         if (MathAbs(OrderTakeProfit()-tpaver)<pnt) continue;
         if (canBig==false && OrderTakeProfit()>pnt && tpaver<OrderTakeProfit()) continue;
         if (OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tpaver,OrderExpiration())==false) 
            Print("sell止盈修改失败#",OrderTicket(),",",OrderSymbol(),",",GetLastError());
         else 指令执行了操盘=1;
      }
   }

}   

   return 0;
}
