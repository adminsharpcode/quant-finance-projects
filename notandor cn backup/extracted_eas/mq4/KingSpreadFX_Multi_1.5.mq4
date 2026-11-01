#property version "1.00";
#property strict

enum ETipoPiramidazione
{
   EPiramidazioneNessuna = 0, // Disattivata
   EPiramidazionePoints = 1, // In Points
   EPiramidazioneIngressoSuccessivo = 2 // Ingresso successivo
};

enum ETipoIncrementoSize
{
   ENessuno = 0, // Nessuno
   EMoltiplicatore = 1, // Moltiplicatore
   EAddizionale = 2 // Addizionale
};

enum ETipoControlloFlottante
{
   EValutaConto = 0, // In Valuta Conto
   EPercentualeSuBalance = 1 // Percentuale Su Balance
};

extern int MagicInp = 1; // Magic Number (1-100-200-300-400 etc..)
extern int numeroStrumentiPossibili = 5; // Numero coppie massime possibili
extern string eaCoppia1; // Impostazioni Coppia 1
extern string strumento1Coppia1; // Strumento 1
extern string strumento2Coppia1; // Strumento 2
extern double contratti1Coppia1 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia1 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia1; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia1; // Valore ampiezza minima bande
extern string eaCoppia2; // Impostazioni Coppia 2
extern string strumento1Coppia2; // Strumento 1
extern string strumento2Coppia2; // Strumento 2
extern double contratti1Coppia2 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia2 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia2; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia2; // Valore ampiezza minima bande
extern string eaCoppia3; // Impostazioni Coppia 3
extern string strumento1Coppia3; // Strumento 1
extern string strumento2Coppia3; // Strumento 2
extern double contratti1Coppia3 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia3 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia3; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia3; // Valore ampiezza minima bande
extern string eaCoppia4; // Impostazioni Coppia 4
extern string strumento1Coppia4; // Strumento 1
extern string strumento2Coppia4; // Strumento 2
extern double contratti1Coppia4 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia4 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia4; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia4; // Valore ampiezza minima bande
extern string eaCoppia5; // Impostazioni Coppia 5
extern string strumento1Coppia5; // Strumento 1
extern string strumento2Coppia5; // Strumento 2
extern double contratti1Coppia5 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia5 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia5; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia5; // Valore ampiezza minima bande
extern string eaCoppia6; // Impostazioni Coppia 6
extern string strumento1Coppia6; // Strumento 1
extern string strumento2Coppia6; // Strumento 2
extern double contratti1Coppia6 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia6 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia6; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia6; // Valore ampiezza minima bande
extern string eaCoppia7; // Impostazioni Coppia 7
extern string strumento1Coppia7; // Strumento 1
extern string strumento2Coppia7; // Strumento 2
extern double contratti1Coppia7 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia7 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia7; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia7; // Valore ampiezza minima bande
extern string eaCoppia8; // Impostazioni Coppia 8
extern string strumento1Coppia8; // Strumento 1
extern string strumento2Coppia8; // Strumento 2
extern double contratti1Coppia8 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia8 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia8; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia8; // Valore ampiezza minima bande
extern string eaCoppia9; // Impostazioni Coppia 9
extern string strumento1Coppia9; // Strumento 1
extern string strumento2Coppia9; // Strumento 2
extern double contratti1Coppia9 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia9 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia9; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia9; // Valore ampiezza minima bande
extern string eaCoppia10; // Impostazioni Coppia 10
extern string strumento1Coppia10; // Strumento 1
extern string strumento2Coppia10; // Strumento 2
extern double contratti1Coppia10 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia10 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia10; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia10; // Valore ampiezza minima bande
extern string eaCoppia11; // Impostazioni Coppia 11
extern string strumento1Coppia11; // Strumento 1
extern string strumento2Coppia11; // Strumento 2
extern double contratti1Coppia11 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia11 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia11; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia11; // Valore ampiezza minima bande
extern string eaCoppia12; // Impostazioni Coppia 12
extern string strumento1Coppia12; // Strumento 1
extern string strumento2Coppia12; // Strumento 2
extern double contratti1Coppia12 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia12 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia12; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia12; // Valore ampiezza minima bande
extern string eaCoppia13; // Impostazioni Coppia 13
extern string strumento1Coppia13; // Strumento 1
extern string strumento2Coppia13; // Strumento 2
extern double contratti1Coppia13 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia13 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia13; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia13; // Valore ampiezza minima bande
extern string eaCoppia14; // Impostazioni Coppia 14
extern string strumento1Coppia14; // Strumento 1
extern string strumento2Coppia14; // Strumento 2
extern double contratti1Coppia14 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia14 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia14; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia14; // Valore ampiezza minima bande
extern string eaCoppia15; // Impostazioni Coppia 15
extern string strumento1Coppia15; // Strumento 1
extern string strumento2Coppia15; // Strumento 2
extern double contratti1Coppia15 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia15 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia15; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia15; // Valore ampiezza minima bande
extern string eaCoppia16; // Impostazioni Coppia 16
extern string strumento1Coppia16; // Strumento 1
extern string strumento2Coppia16; // Strumento 2
extern double contratti1Coppia16 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia16 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia16; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia16; // Valore ampiezza minima bande
extern string eaCoppia17; // Impostazioni Coppia 17
extern string strumento1Coppia17; // Strumento 1
extern string strumento2Coppia17; // Strumento 2
extern double contratti1Coppia17 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia17 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia17; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia17; // Valore ampiezza minima bande
extern string eaCoppia18; // Impostazioni Coppia 18
extern string strumento1Coppia18; // Strumento 1
extern string strumento2Coppia18; // Strumento 2
extern double contratti1Coppia18 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia18 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia18; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia18; // Valore ampiezza minima bande
extern string eaCoppia19; // Impostazioni Coppia 19
extern string strumento1Coppia19; // Strumento 1
extern string strumento2Coppia19; // Strumento 2
extern double contratti1Coppia19 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia19 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia19; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia19; // Valore ampiezza minima bande
extern string eaCoppia20; // Impostazioni Coppia 20
extern string strumento1Coppia20; // Strumento 1
extern string strumento2Coppia20; // Strumento 2
extern double contratti1Coppia20 = 0.01; // Contratti Strumento 1
extern double contratti2Coppia20 = 0.01; // Contratti Strumento 2
extern int pointsDistanzaOverlayCoppia20; // Points Distanza Overlay
extern double valoreAmpiezzaMinimaBarreCoppia20; // Valore ampiezza minima bande
extern string commentoAggiuntivo; // Commento Aggiuntivo
extern string eaIndicatoreSpreadRatio; // Impostazioni Spread Ratio
extern string ea; // <--- Impostazioni Bollinger --->
extern int periodoBollinger = 40; // Periodo Bollinger
extern double deviazioneStandard = 1; // Deviazione Standard
extern string eaOverlay; // Impostazioni Overlay
extern int numeroBarre = 200; // Numero Barre
extern bool utilizzaOverlay; // Utilizza Overlay Chart
extern string eaOperativita; // Impostazioni operatività
extern string orarioOperativita = "00:00:00-23:59:59"; // Ora Operatività (Broker)
extern string orarioOperativita2 = "00:00:00-23:59:59"; // Ora Operatività 2 (Broker)
extern ETipoPiramidazione tipoPiramidazione = EPiramidazioneNessuna; // Selezionare il tipo di Piramidazione
extern int numeroMassimoPiramidazioni; // Numero massimo operazioni, 0 è illimitato
extern int pointsDistanzaPiramidazione; // Points Distanza piramidazione Step 1(da strumento primo)
extern int numeroPiramidazioneStep2; // Numero Piramidazioni per Step 2
extern int pointsDistanzaPiramidazioneStep2; // Points Distanza piramidazione Step 2
extern int numeroPiramidazioneStep3; // Numero Piramidazioni per Step 3
extern int pointsDistanzaPiramidazioneStep3; // Points Distanza piramidazione Step 3
extern int numeroPiramidazioneStep4; // Numero Piramidazioni per Step 4
extern int pointsDistanzaPiramidazioneStep4; // Points Distanza piramidazione Step 4
extern ETipoIncrementoSize tipoIncrementoSize = ENessuno; // Selezionare il tipo di incremento della size
extern double valoreIncremento = 0.01; // Valore incremento
extern double targetValuta = 10; // Target Valuta, 0 è disattivato
extern int numeroMediazioniAttivazioneSecondoTarget; // Numero Mediazioni Attivazione Secondo Target, 0è disatti.
extern double targetValuta2 = 10; // Target Valuta 2
extern double stopValuta; // Stoploss Valuta, 0 è disattivato
extern double trailingStopStart; // Trailing Stop Start, 0 è disattivato
extern double trailingStop; // Trailing Stop
extern double trailingStep; // Trailing Step
extern bool utilizzaChiusuraBandaCentrale; // Utilizza Chiusura banda centrale
extern int numeroMassimoOperazioniInGain; // Numero massimo operazioni in gain
extern double massimoGainGiornaliero; // Massimo Gain Giornaliero in valuta, 0 è disattivato
extern double massimoLossGiornaliero; // Massimo Loss Giornaliero in valuta, 0 è disattivato
extern int minutiControlloPosizioniDisallineate = 5; // Minuti Controllo posizioni disallineate, 0 è disattivato
extern bool limitaIngressoNuoveOperazioniSeSuperatoDD; // Limita Ingresso Nuove Operazioni Se Superato DD
extern ETipoControlloFlottante tipoControlloFlottante = EValutaConto; // Selezionare il tipo di controllo flottante
extern double valoreLimite; // Valore Limite
extern int grandezzaFont = 10; // Grandezza Caratteri
extern string exEA1 = "<---------- Allarmi ---------->"; // <>
extern string exEA2; // <--- Allarmi causa Errori --->
extern bool utilizzaAllarmiErrore = true; // Allarmi EA per errori
extern bool utilizzaAlertErrore = true; // Utilizza Allarme per errori
extern bool utilizzaPopupErrore = true; // Utilizza Notifiche Push per errori
extern bool utilizzaMailErrore = true; // Utilizza Invio Mail per errori
extern string exEA3; // <--- Allarmi per Inserimento Ordini --->
extern bool utilizzaAllarmiInserimentoOrdini = true; // Allarmi EA per inserimento ordini
extern bool utilizzaAlertInserimentoOrdini = true; // Utilizza Allarme per inserimento ordini
extern bool utilizzaPopupInserimentoOrdini = true; // Utilizza Notifiche Push per inserimento ordini
extern bool utilizzaMailInserimentoOrdini = true; // Utilizza Invio Mail per inserimento ordini
extern string exEA4; // <--- Allarmi per Modifica Ordini( Stoploss & Takeprofit )--->
extern bool utilizzaAllarmiModificaOrdini = true; // Allarmi EA per modifica ordini
extern bool utilizzaAlertModificaOrdini = true; // Utilizza Allarme per modifica ordini
extern bool utilizzaPopupModificaOrdini = true; // Utilizza Notifiche Push per modifica ordini
extern bool utilizzaMailModificaOrdini = true; // Utilizza Invio Mail per modifica ordini

int Gi_000000;
bool Gb_000001;
bool returned_b;
int Gi_000005;
string Gs_000005;
int Gi_000006;
string Gs_000006;
int Gi_000007;
string Gs_000007;
int Gi_000008;
string Gs_000008;
int Gi_000009;
string Gs_000009;
int Gi_00000A;
string Gs_00000A;
int Gi_00000B;
string Gs_00000B;
int Gi_00000C;
string Gs_00000C;
int Gi_00000D;
string Gs_00000D;
int Gi_00000E;
string Gs_00000E;
int Gi_00000F;
string Gs_00000F;
int Gi_000010;
string Gs_000010;
int Gi_000011;
string Gs_000011;
int Gi_000012;
string Gs_000012;
int Gi_000013;
string Gs_000013;
int Gi_000014;
string Gs_000014;
int Gi_000015;
string Gs_000015;
int Gi_000016;
string Gs_000016;
int Gi_000017;
string Gs_000017;
int Gi_000018;
string Gs_000018;
int Gi_000019;
string Gs_000019;
int Gi_00001A;
string Gs_00001A;
int Gi_00001B;
string Gs_00001B;
int Gi_00001C;
string Gs_00001C;
int Gi_00001D;
string Gs_00001D;
int Gi_00001E;
string Gs_00001E;
int Gi_00001F;
string Gs_00001F;
int Gi_000020;
string Gs_000020;
int Gi_000021;
string Gs_000021;
int Gi_000022;
string Gs_000022;
int Gi_000023;
string Gs_000023;
int Gi_000024;
string Gs_000024;
int Gi_000025;
string Gs_000025;
int Gi_000026;
string Gs_000026;
int Gi_000027;
string Gs_000027;
int Gi_000028;
string Gs_000028;
int Gi_000029;
string Gs_000029;
int Gi_00002A;
string Gs_00002A;
int Gi_00002B;
string Gs_00002B;
int Gi_00002C;
string Gs_00002C;
int Gi_00002D;
double Gd_00002D;
int Gi_00002E;
double Gd_00002E;
int Gi_00002F;
double Gd_00002F;
int Gi_000030;
double Gd_000030;
int Gi_000031;
double Gd_000031;
int Gi_000032;
double Gd_000032;
int Gi_000033;
double Gd_000033;
int Gi_000034;
double Gd_000034;
int Gi_000035;
double Gd_000035;
int Gi_000036;
double Gd_000036;
int Gi_000037;
double Gd_000037;
int Gi_000038;
double Gd_000038;
int Gi_000039;
double Gd_000039;
int Gi_00003A;
double Gd_00003A;
int Gi_00003B;
double Gd_00003B;
int Gi_00003C;
double Gd_00003C;
int Gi_00003D;
double Gd_00003D;
int Gi_00003E;
double Gd_00003E;
int Gi_00003F;
double Gd_00003F;
int Gi_000040;
double Gd_000040;
int Gi_000041;
double Gd_000041;
int Gi_000042;
double Gd_000042;
int Gi_000043;
double Gd_000043;
int Gi_000044;
double Gd_000044;
int Gi_000045;
double Gd_000045;
int Gi_000046;
double Gd_000046;
int Gi_000047;
double Gd_000047;
int Gi_000048;
double Gd_000048;
int Gi_000049;
double Gd_000049;
int Gi_00004A;
double Gd_00004A;
int Gi_00004B;
double Gd_00004B;
int Gi_00004C;
double Gd_00004C;
int Gi_00004D;
double Gd_00004D;
int Gi_00004E;
double Gd_00004E;
int Gi_00004F;
double Gd_00004F;
int Gi_000050;
double Gd_000050;
int Gi_000051;
double Gd_000051;
int Gi_000052;
double Gd_000052;
int Gi_000053;
double Gd_000053;
int Gi_000054;
double Gd_000054;
int Gi_000055;
int Gi_000056;
int Gi_000057;
int Gi_000058;
int Gi_000059;
int Gi_00005A;
int Gi_00005B;
int Gi_00005C;
int Gi_00005D;
int Gi_00005E;
int Gi_00005F;
int Gi_000060;
int Gi_000061;
int Gi_000062;
int Gi_000063;
int Gi_000064;
int Gi_000065;
int Gi_000066;
int Gi_000067;
int Gi_000068;
int Gi_000069;
double Gd_000069;
int Gi_00006A;
double Gd_00006A;
int Gi_00006B;
double Gd_00006B;
int Gi_00006C;
double Gd_00006C;
int Gi_00006D;
double Gd_00006D;
int Gi_00006E;
double Gd_00006E;
int Gi_00006F;
double Gd_00006F;
int Gi_000070;
double Gd_000070;
int Gi_000071;
double Gd_000071;
int Gi_000072;
double Gd_000072;
int Gi_000073;
double Gd_000073;
int Gi_000074;
double Gd_000074;
int Gi_000075;
double Gd_000075;
int Gi_000076;
double Gd_000076;
int Gi_000077;
double Gd_000077;
int Gi_000078;
double Gd_000078;
int Gi_000079;
double Gd_000079;
int Gi_00007A;
double Gd_00007A;
int Gi_00007B;
double Gd_00007B;
int Gi_00007C;
double Gd_00007C;
int returned_i;
int Gi_000002;
long Gl_000003;
long returned_l;
int Gi_000004;
long Gl_000005;
long Il_009C78;
int Ii_00D778;
string Gs_000000;
int Gi_000001;
string Gs_000001;
string Gs_000002;
int Gi_000003;
string Gs_000003;
bool Gb_00000C;
double Gd_00000D;
bool Gb_000010;
double Gd_000011;
bool Gb_000012;
bool Gb_000016;
string Is_009CA0;
double Gd_000018;
double Gd_000019;
double Ind_000;
long Gl_00001B;
double Gd_00001B;
double Gd_00001D;
bool Gb_00001D;
double Gd_000013;
double Gd_000014;
long Gl_000016;
double Gd_000016;
bool Gb_000006;
bool Gb_000009;
short Gst_000001;
short returned_st;
string Gs_000004;
double Gd_000010;
double Gd_000012;
double Gd_000009;
double Gd_000008;
double Gd_00000E;
double Gd_00000A;
bool Gb_00000E;
bool Ib_009C80;
string Is_009C88;
long Il_009C98;
int Ii_009CAC;
int Ii_009DE8;
int Ii_009DEC;
int Ii_009DF0;
long Il_009DF8;
long Gl_000000;
bool Gb_00001F;
double Ind_003;
long Gl_000020;
bool Gb_000023;
long Gl_000024;
long Gl_000026;
bool Gb_000027;
bool Gb_000029;
long Gl_00002B;
long Gl_000033;
string Gs_000033;
string Gs_000034;
bool Gb_000036;
double Ind_002;
long Gl_000037;
double Ind_004;
bool Gb_000038;
long Gl_000039;
bool Gb_00002A;
bool Gb_000028;
bool Gb_000024;
bool Gb_000020;
double Gd_000003;
double Gd_000002;
double Gd_000004;
bool Gb_00000A;
long Gl_00000B;
long Gl_000012;
bool Gb_000015;
bool Gb_000018;
bool Gb_00001A;
long Gl_00001C;
bool Gb_00001B;
bool Gb_000019;
double Gd_000000;
double Gd_000001;
long Gl_000001;
long Gl_000002;
short Gst_000000;
bool Gb_000000;
bool Gb_000003;
double Gd_000005;
double Gd_000006;
double Gd_000007;
bool Gb_000007;
double Gd_00000B;
bool Gb_00000B;
double Gd_00000F;
bool Gb_00000F;
bool Gb_000014;
long Gl_000022;
double Gd_000023;
double Gd_000022;
long Gl_000023;
double Gd_000024;
long Gl_000025;
bool Gb_00002D;
bool Gb_00002F;
long Gl_000031;
bool Gb_000032;
long Gl_000038;
long Gl_00003A;
bool Gb_000037;
double Gd_00001E;
double Gd_00001F;
bool Gb_000022;
bool Gb_000004;
long Gl_000009;
long Gl_000006;
long Gl_00000A;
long Gl_00000C;
long Gl_000015;
long Gl_000017;
long Gl_000018;
bool Gb_000005;
long Gl_000007;
bool Gb_000002;

int Ii_000034[10000] = { 97606, 97628, 97664, 92109, 90887, 41615, 93487, 95965, 59787, 82969, 71581, 85336, 5545802, 99224, 97664, 48819, 65896 };
string Is_009CB0[];
string Is_009CE4[];
double Id_009D18[];
double Id_009D4C[];
int Ii_009D80[];
double Id_009DB4[];
long Il_009E34[300];
long Il_00A7C8[300];
long Il_00B15C[300];
long Il_00BAF0[300];
double Id_00C484[300];
double Id_00CE18[300];

int init()
{
   int Li_FFFFFC;
   Il_009C78 = 4133894400;
   Ib_009C80 = false;
   Is_009C88 = "";
   Il_009C98 = 0;
   Is_009CA0 = "Spread Trading EA";
   Ii_009CAC = 0;
   Ii_009DE8 = 2631720;
   Ii_009DEC = 1315860;
   Ii_009DF0 = 600;
   Il_009DF8 = 0;
   Ii_00D778 = 0;

   ArrayResize(Is_009CB0, 20, 0);
   Is_009CB0[0] = strumento1Coppia1;
   Is_009CB0[1] = strumento1Coppia2;
   Is_009CB0[2] = strumento1Coppia3;
   Is_009CB0[3] = strumento1Coppia4;
   Is_009CB0[4] = strumento1Coppia5;
   Is_009CB0[5] = strumento1Coppia6;
   Is_009CB0[6] = strumento1Coppia7;
   Is_009CB0[7] = strumento1Coppia8;
   Is_009CB0[8] = strumento1Coppia9;
   Is_009CB0[9] = strumento1Coppia10;
   Is_009CB0[10] = strumento1Coppia11;
   Is_009CB0[11] = strumento1Coppia12;
   Is_009CB0[12] = strumento1Coppia13;
   Is_009CB0[13] = strumento1Coppia14;
   Is_009CB0[14] = strumento1Coppia15;
   Is_009CB0[15] = strumento1Coppia16;
   Is_009CB0[16] = strumento1Coppia17;
   Is_009CB0[17] = strumento1Coppia18;
   Is_009CB0[18] = strumento1Coppia19;
   Is_009CB0[19] = strumento1Coppia20;
   ArrayResize(Is_009CE4, 20, 0);
   Is_009CE4[0] = strumento2Coppia1;
   Is_009CE4[1] = strumento2Coppia2;
   Is_009CE4[2] = strumento2Coppia3;
   Is_009CE4[3] = strumento2Coppia4;
   Is_009CE4[4] = strumento2Coppia5;
   Is_009CE4[5] = strumento2Coppia6;
   Is_009CE4[6] = strumento2Coppia7;
   Is_009CE4[7] = strumento2Coppia8;
   Is_009CE4[8] = strumento2Coppia9;
   Is_009CE4[9] = strumento2Coppia10;
   Is_009CE4[10] = strumento2Coppia11;
   Is_009CE4[11] = strumento2Coppia12;
   Is_009CE4[12] = strumento2Coppia13;
   Is_009CE4[13] = strumento2Coppia14;
   Is_009CE4[14] = strumento2Coppia15;
   Is_009CE4[15] = strumento2Coppia16;
   Is_009CE4[16] = strumento2Coppia17;
   Is_009CE4[17] = strumento2Coppia18;
   Is_009CE4[18] = strumento2Coppia19;
   Is_009CE4[19] = strumento2Coppia20;
   ArrayResize(Id_009D18, 20, 0);
   Id_009D18[0] = contratti1Coppia1;
   Id_009D18[1] = contratti1Coppia2;
   Id_009D18[2] = contratti1Coppia3;
   Id_009D18[3] = contratti1Coppia4;
   Id_009D18[4] = contratti1Coppia5;
   Id_009D18[5] = contratti1Coppia6;
   Id_009D18[6] = contratti1Coppia7;
   Id_009D18[7] = contratti1Coppia8;
   Id_009D18[8] = contratti1Coppia9;
   Id_009D18[9] = contratti1Coppia10;
   Id_009D18[10] = contratti1Coppia11;
   Id_009D18[11] = contratti1Coppia12;
   Id_009D18[12] = contratti1Coppia13;
   Id_009D18[13] = contratti1Coppia14;
   Id_009D18[14] = contratti1Coppia15;
   Id_009D18[15] = contratti1Coppia16;
   Id_009D18[16] = contratti1Coppia17;
   Id_009D18[17] = contratti1Coppia18;
   Id_009D18[18] = contratti1Coppia19;
   Id_009D18[19] = contratti1Coppia20;
   ArrayResize(Id_009D4C, 20, 0);
   Id_009D4C[0] = contratti2Coppia1;
   Id_009D4C[1] = contratti2Coppia2;
   Id_009D4C[2] = contratti2Coppia3;
   Id_009D4C[3] = contratti2Coppia4;
   Id_009D4C[4] = contratti2Coppia5;
   Id_009D4C[5] = contratti2Coppia6;
   Id_009D4C[6] = contratti2Coppia7;
   Id_009D4C[7] = contratti2Coppia8;
   Id_009D4C[8] = contratti2Coppia9;
   Id_009D4C[9] = contratti2Coppia10;
   Id_009D4C[10] = contratti2Coppia11;
   Id_009D4C[11] = contratti2Coppia12;
   Id_009D4C[12] = contratti2Coppia13;
   Id_009D4C[13] = contratti2Coppia14;
   Id_009D4C[14] = contratti2Coppia15;
   Id_009D4C[15] = contratti2Coppia16;
   Id_009D4C[16] = contratti2Coppia17;
   Id_009D4C[17] = contratti2Coppia18;
   Id_009D4C[18] = contratti2Coppia19;
   Id_009D4C[19] = contratti2Coppia20;
   ArrayResize(Ii_009D80, 20, 0);
   Ii_009D80[0] = pointsDistanzaOverlayCoppia1;
   Ii_009D80[1] = pointsDistanzaOverlayCoppia2;
   Ii_009D80[2] = pointsDistanzaOverlayCoppia3;
   Ii_009D80[3] = pointsDistanzaOverlayCoppia4;
   Ii_009D80[4] = pointsDistanzaOverlayCoppia5;
   Ii_009D80[5] = pointsDistanzaOverlayCoppia6;
   Ii_009D80[6] = pointsDistanzaOverlayCoppia7;
   Ii_009D80[7] = pointsDistanzaOverlayCoppia8;
   Ii_009D80[8] = pointsDistanzaOverlayCoppia9;
   Ii_009D80[9] = pointsDistanzaOverlayCoppia10;
   Ii_009D80[10] = pointsDistanzaOverlayCoppia11;
   Ii_009D80[11] = pointsDistanzaOverlayCoppia12;
   Ii_009D80[12] = pointsDistanzaOverlayCoppia13;
   Ii_009D80[13] = pointsDistanzaOverlayCoppia14;
   Ii_009D80[14] = pointsDistanzaOverlayCoppia15;
   Ii_009D80[15] = pointsDistanzaOverlayCoppia16;
   Ii_009D80[16] = pointsDistanzaOverlayCoppia17;
   Ii_009D80[17] = pointsDistanzaOverlayCoppia18;
   Ii_009D80[18] = pointsDistanzaOverlayCoppia19;
   Ii_009D80[19] = pointsDistanzaOverlayCoppia20;
   ArrayResize(Id_009DB4, 20, 0);
   Id_009DB4[0] = valoreAmpiezzaMinimaBarreCoppia1;
   Id_009DB4[1] = valoreAmpiezzaMinimaBarreCoppia2;
   Id_009DB4[2] = valoreAmpiezzaMinimaBarreCoppia3;
   Id_009DB4[3] = valoreAmpiezzaMinimaBarreCoppia4;
   Id_009DB4[4] = valoreAmpiezzaMinimaBarreCoppia5;
   Id_009DB4[5] = valoreAmpiezzaMinimaBarreCoppia6;
   Id_009DB4[6] = valoreAmpiezzaMinimaBarreCoppia7;
   Id_009DB4[7] = valoreAmpiezzaMinimaBarreCoppia8;
   Id_009DB4[8] = valoreAmpiezzaMinimaBarreCoppia9;
   Id_009DB4[9] = valoreAmpiezzaMinimaBarreCoppia10;
   Id_009DB4[10] = valoreAmpiezzaMinimaBarreCoppia11;
   Id_009DB4[11] = valoreAmpiezzaMinimaBarreCoppia12;
   Id_009DB4[12] = valoreAmpiezzaMinimaBarreCoppia13;
   Id_009DB4[13] = valoreAmpiezzaMinimaBarreCoppia14;
   Id_009DB4[14] = valoreAmpiezzaMinimaBarreCoppia15;
   Id_009DB4[15] = valoreAmpiezzaMinimaBarreCoppia16;
   Id_009DB4[16] = valoreAmpiezzaMinimaBarreCoppia17;
   Id_009DB4[17] = valoreAmpiezzaMinimaBarreCoppia18;
   Id_009DB4[18] = valoreAmpiezzaMinimaBarreCoppia19;
   Id_009DB4[19] = valoreAmpiezzaMinimaBarreCoppia20;
   func_1010();
   Li_FFFFFC = 0;
   
   return Li_FFFFFC;
}

void OnTick()
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   string tmp_str00000D;
   string tmp_str00000E;
   string tmp_str00000F;
   string tmp_str000010;
   string tmp_str000011;
   string tmp_str000012;
   string tmp_str000013;
   string tmp_str000014;
   string tmp_str000015;
   string tmp_str000016;
   string tmp_str000017;
   string tmp_str000018;
   string tmp_str000019;
   string tmp_str00001A;
   string tmp_str00001B;
   string tmp_str00001C;
   string tmp_str00001D;
   string tmp_str00001E;
   string tmp_str00001F;
   int Li_FFFFFC;
   string Ls_FFFFF0;
   string Ls_FFFFE0;
   int Li_FFFFDC;
   string Ls_FFFFD0;
   int Li_FFFFCC;
   int Li_FFFFC8;
   string Ls_FFFFB8;
   string Ls_FFFFA8;

   Ii_00D778 = MagicInp;
   Li_FFFFFC = 0;
   if (ArraySize(Is_009CB0) > 0) { 
   do { 
   Ls_FFFFF0 = Is_009CB0[Li_FFFFFC];
   Ls_FFFFE0 = Is_009CE4[Li_FFFFFC];
   if (Ls_FFFFF0 == "" || Ls_FFFFE0 == "") { 
   
   Ii_00D778 = Ii_00D778 + 1;
   } 
   else { 
   Li_FFFFDC = MagicInp;
   Ls_FFFFD0 = "";
   Li_FFFFCC = 0;
   Li_FFFFC8 = 0;
   if (ArraySize(Is_009CB0) > 0) { 
   do { 
   Ls_FFFFB8 = Is_009CB0[Li_FFFFC8];
   Ls_FFFFA8 = Is_009CE4[Li_FFFFC8];
   if (Ls_FFFFF0 == "" || Ls_FFFFE0 == "") { 
   
   Li_FFFFDC = Li_FFFFDC + 1;
   } 
   else { 
   tmp_str000000 = "LS";
   Gi_000004 = Li_FFFFDC;
   tmp_str000001 = Ls_FFFFA8;
   tmp_str000002 = Ls_FFFFB8;
   Gi_000005 = OrdersTotal();
   Gb_000006 = false;
   if (Gi_000005 >= 0) {
   do { 
   if (OrderSelect(Gi_000005, 0, 0) && OrderMagicNumber() == Gi_000004) {
   tmp_str000003 = OrderComment();
   if (StringSubstr(tmp_str000003, 0, 2) == tmp_str000000) {
   if (OrderSymbol() == tmp_str000002 || OrderSymbol() == tmp_str000001) {
   
   Gb_000006 = true;
   break;
   }}}
   Gi_000005 = Gi_000005 - 1;
   } while (Gi_000005 >= 0); 
   }
   else Gb_000006 = false;
   
   tmp_str000004 = "SS";
   Gi_000007 = Li_FFFFDC;
   tmp_str000005 = Ls_FFFFA8;
   tmp_str000006 = Ls_FFFFB8;
   Gi_000008 = OrdersTotal();
   Gb_000009 = false;
   if (Gi_000008 >= 0) {
   do { 
   if (OrderSelect(Gi_000008, 0, 0) && OrderMagicNumber() == Gi_000007) {
   tmp_str000007 = OrderComment();
   if (StringSubstr(tmp_str000007, 0, 2) == tmp_str000004) {
   if (OrderSymbol() == tmp_str000006 || OrderSymbol() == tmp_str000005) {
   
   Gb_000009 = true;
   break;
   }}}
   Gi_000008 = Gi_000008 - 1;
   } while (Gi_000008 >= 0); 
   }
   else Gb_000009 = false;
   
   if (Gb_000006 || Gb_000009) {
   
   tmp_str000008 = Ls_FFFFB8 + "!";
   tmp_str000008 = tmp_str000008 + Ls_FFFFA8;
   tmp_str000008 = tmp_str000008 + "_";
   if (StringFind(Ls_FFFFD0, tmp_str000008, 0) < 0) { 
   tmp_str000009 = Ls_FFFFB8 + "!";
   tmp_str000009 = tmp_str000009 + Ls_FFFFA8;
   tmp_str000009 = tmp_str000009 + "_";
   Ls_FFFFD0 = Ls_FFFFD0 + tmp_str000009;
   Li_FFFFCC = Li_FFFFCC + 1;
   }} 
   Li_FFFFDC = Li_FFFFDC + 1;
   } 
   Li_FFFFC8 = Li_FFFFC8 + 1;
   } while (Li_FFFFC8 < ArraySize(Is_009CB0)); 
   } 
   tmp_str000009 = "LS";
   Gi_00000A = Ii_00D778;
   tmp_str00000A = Ls_FFFFE0;
   tmp_str00000B = Ls_FFFFF0;
   Gi_00000B = OrdersTotal();
   Gb_00000C = false;
   if (Gi_00000B >= 0) {
   do { 
   if (OrderSelect(Gi_00000B, 0, 0) && OrderMagicNumber() == Gi_00000A) {
   tmp_str00000C = OrderComment();
   if (StringSubstr(tmp_str00000C, 0, 2) == tmp_str000009) {
   if (OrderSymbol() == tmp_str00000B || OrderSymbol() == tmp_str00000A) {
   
   Gb_00000C = true;
   break;
   }}}
   Gi_00000B = Gi_00000B - 1;
   } while (Gi_00000B >= 0); 
   }
   else Gb_00000C = false;
   
   if (Gb_00000C != true) { 
   Id_00C484[Li_FFFFFC] = 0;
   } 
   tmp_str00000D = "SS";
   Gi_00000E = Ii_00D778;
   tmp_str00000E = Ls_FFFFE0;
   tmp_str00000F = Ls_FFFFF0;
   Gi_00000F = OrdersTotal();
   Gb_000010 = false;
   if (Gi_00000F >= 0) {
   do { 
   if (OrderSelect(Gi_00000F, 0, 0) && OrderMagicNumber() == Gi_00000E) {
   tmp_str000010 = OrderComment();
   if (StringSubstr(tmp_str000010, 0, 2) == tmp_str00000D) {
   if (OrderSymbol() == tmp_str00000F || OrderSymbol() == tmp_str00000E) {
   
   Gb_000010 = true;
   break;
   }}}
   Gi_00000F = Gi_00000F - 1;
   } while (Gi_00000F >= 0); 
   }
   else Gb_000010 = false;
   
   if (Gb_000010 != true) { 
   Id_00CE18[Li_FFFFFC] = 0;
   } 
   Gb_000012 = (massimoGainGiornaliero == 0);
   if (Gb_000012) { 
   Gb_000012 = false;
   } 
   else { 
   Gd_000013 = 0;
   Gi_000014 = OrdersTotal() - 1;
   Gi_000015 = Gi_000014;
   if (Gi_000014 >= 0) { 
   do { 
   if (OrderSelect(Gi_000015, 0, 0)) { 
   Gd_000014 = OrderProfit();
   Gd_000014 = (Gd_000014 + OrderCommission());
   Gd_000013 = ((Gd_000014 + OrderSwap()) + Gd_000013);
   } 
   Gi_000015 = Gi_000015 - 1;
   } while (Gi_000015 >= 0); 
   } 
   Gd_000014 = 0;
   Gi_000016 = HistoryTotal() - 1;
   Gi_000017 = Gi_000016;
   if (Gi_000016 >= 0) { 
   do { 
   if (OrderSelect(Gi_000017, 0, 1)) { 
   tmp_str000011 = TimeToString(OrderCloseTime(), 1);
   if (tmp_str000011 != TimeToString(TimeCurrent(), 1)) break; 
   Gd_000016 = OrderProfit();
   Gd_000016 = (Gd_000016 + OrderCommission());
   Gd_000014 = ((Gd_000016 + OrderSwap()) + Gd_000014);
   } 
   Gi_000017 = Gi_000017 - 1;
   } while (Gi_000017 >= 0); 
   } 
   if (((Gd_000014 + Gd_000013) >= massimoGainGiornaliero)) { 
   tmp_str000011 = "Chiusura totale per massimo gain";
   func_1035(tmp_str000011);
   Gb_000012 = true;
   } 
   else { 
   Gb_000012 = false;
   }} 
   Gb_000016 = (massimoLossGiornaliero == 0);
   if (Gb_000016) { 
   Gb_000016 = false;
   } 
   else { 
   Gd_000018 = 0;
   Gi_000019 = OrdersTotal() - 1;
   Gi_00001A = Gi_000019;
   if (Gi_000019 >= 0) { 
   do { 
   if (OrderSelect(Gi_00001A, 0, 0)) { 
   Gd_000019 = OrderProfit();
   Gd_000019 = (Gd_000019 + OrderCommission());
   Gd_000018 = ((Gd_000019 + OrderSwap()) + Gd_000018);
   } 
   Gi_00001A = Gi_00001A - 1;
   } while (Gi_00001A >= 0); 
   } 
   Gd_000019 = 0;
   Gi_00001B = HistoryTotal() - 1;
   Gi_00001C = Gi_00001B;
   if (Gi_00001B >= 0) { 
   do { 
   if (OrderSelect(Gi_00001C, 0, 1)) { 
   tmp_str000012 = TimeToString(OrderCloseTime(), 1);
   if (tmp_str000012 != TimeToString(TimeCurrent(), 1)) break; 
   Gd_00001B = OrderProfit();
   Gd_00001B = (Gd_00001B + OrderCommission());
   Gd_000019 = ((Gd_00001B + OrderSwap()) + Gd_000019);
   } 
   Gi_00001C = Gi_00001C - 1;
   } while (Gi_00001C >= 0); 
   } 
   Gd_00001B = (Gd_000019 + Gd_000018);
   Gd_00001D = -massimoLossGiornaliero;
   if ((Gd_00001B <= Gd_00001D)) { 
   tmp_str000012 = "Chiusura totale per massimo loss";
   func_1035(tmp_str000012);
   Gb_000016 = true;
   } 
   else { 
   Gb_000016 = false;
   }} 
   if (Gb_000012 || Gb_000016) {
   
   tmp_str000013 = "Stop per gain o loss raggiunto";
   tmp_str000014 = Is_009CA0 + "stop";
   ObjectCreate(0, tmp_str000014, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000014, tmp_str000013, 15, "Dubai", 255);
   ObjectSet(tmp_str000014, OBJPROP_CORNER, 2);
   ObjectSet(tmp_str000014, OBJPROP_XDISTANCE, 20);
   ObjectSet(tmp_str000014, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, tmp_str000014, 1011, 1);
   return ;
   }
   tmp_str000015 = Is_009CA0 + "stop";
   ObjectDelete(0, tmp_str000015);
   tmp_str000016 = Ls_FFFFE0;
   tmp_str000017 = Ls_FFFFF0;
   func_1042(tmp_str000017, tmp_str000016);
   tmp_str000018 = Ls_FFFFE0;
   tmp_str000019 = Ls_FFFFF0;
   func_1030(Li_FFFFCC, Li_FFFFFC, tmp_str000019, tmp_str000018);
   tmp_str00001A = Ls_FFFFE0;
   tmp_str00001B = Ls_FFFFF0;
   func_1032(Li_FFFFFC, tmp_str00001B, tmp_str00001A);
   tmp_str00001C = Ls_FFFFE0;
   tmp_str00001D = Ls_FFFFF0;
   func_1033(Li_FFFFFC, tmp_str00001D, tmp_str00001C);
   tmp_str00001E = Ls_FFFFE0;
   tmp_str00001F = Ls_FFFFF0;
   func_1036(tmp_str00001F, tmp_str00001E);
   Ii_00D778 = Ii_00D778 + 1;
   } 
   Li_FFFFFC = Li_FFFFFC + 1;
   } while (Li_FFFFFC < ArraySize(Is_009CB0)); 
   } 
   func_1010();
   
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, Is_009CA0, -1, -1);
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   string tmp_str00000D;
   string tmp_str00000E;
   string tmp_str00000F;
   string tmp_str000010;
   string tmp_str000011;
   string tmp_str000012;
   string tmp_str000013;
   string tmp_str000014;
   string tmp_str000015;
   string tmp_str000016;
   string tmp_str000017;
   string tmp_str000018;
   string tmp_str000019;
   string tmp_str00001A;
   string tmp_str00001B;
   string tmp_str00001C;
   string tmp_str00001D;
   string tmp_str00001E;
   string tmp_str00001F;
   string tmp_str000020;
   string tmp_str000021;
   string tmp_str000022;
   string tmp_str000023;
   string tmp_str000024;
   string tmp_str000025;
   string tmp_str000026;
   string tmp_str000027;
   string tmp_str000028;
   string tmp_str000029;
   string tmp_str00002A;
   string tmp_str00002B;
   string tmp_str00002C;
   string tmp_str00002D;
   string tmp_str00002E;
   string tmp_str00002F;
   int Li_FFFFC8;
   int Li_FFFFC4;
   int Li_FFFFC0;
   string Ls_FFFFB0;
   string Ls_FFFFA0;
   int Li_FFFF9C;
   int Li_FFFF98;
   string Ls_FFFF88;
   string Ls_FFFF78;
   int Li_FFFF74;
   int Li_FFFF70;
   string Ls_FFFF60;
   string Ls_FFFF50;
   int Li_FFFF24;
   int Li_FFFF20;
   string Ls_FFFF10;
   string Ls_FFFF00;
   string Ls_FFFEF0;
   double Ld_FFFEE8;
   double Ld_FFFEE0;
   double Ld_FFFED8;
   string Ls_FFFF40;
   double Ld_FFFF38;
   double Ld_FFFF30;
   double Ld_FFFF28;

   tmp_str000000 = Is_009CA0 + "mini";
   if (sparam == tmp_str000000) { 
   if (ObjectGetString(0, sparam, 999, 0) == "-") { 
   ObjectSetString(0, sparam, 999, "Ê");
   ObjectSetString(0, sparam, 1001, "Wingdings 2");
   ObjectsDeleteAll(0, Is_009CA0, -1, -1);
   func_1010();
   } 
   else { 
   if (ObjectGetString(0, sparam, 999, 0) == "Ê") { 
   ObjectSetString(0, sparam, 999, "-");
   ObjectSetString(0, sparam, 1001, "Dubai");
   func_1010();
   }}} 
   tmp_str000000 = Is_009CA0 + "_chiudiTutto_";
   if (StringFind(sparam, tmp_str000000, 0) >= 0) { 
   string Ls_FFFFCC[];
   tmp_str000001 = sparam;
   tmp_str000002 = tmp_str000001;
   tmp_str000003 = "_";
   Gst_000001 = (short)StringGetCharacter(tmp_str000003, 0);
   StringSplit(tmp_str000002, Gst_000001, Ls_FFFFCC);
   Li_FFFFC8 = (int)Ls_FFFFCC[2];
   Li_FFFFC4 = MagicInp;
   tmp_str000004 = (string)Li_FFFFC8;
   tmp_str000004 = "Numero cliccato :" + tmp_str000004;
   Print(tmp_str000004);
   Li_FFFFC0 = 0;
   if (ArraySize(Is_009CB0) > 0) { 
   do { 
   Ls_FFFFB0 = Is_009CB0[Li_FFFFC0];
   Ls_FFFFA0 = Is_009CE4[Li_FFFFC0];
   if (Ls_FFFFB0 == "") { 
   Li_FFFFC4 = Li_FFFFC4 + 1;
   } 
   else { 
   if (Li_FFFFC8 == Li_FFFFC4) { 
   tmp_str000005 = "Trovato : " + Ls_FFFFB0;
   tmp_str000005 = tmp_str000005 + " ";
   tmp_str000005 = tmp_str000005 + Ls_FFFFA0;
   Print(tmp_str000005);
   tmp_str000006 = "Chiusura manuale";
   tmp_str000007 = "LS";
   tmp_str000008 = Ls_FFFFA0;
   tmp_str000009 = Ls_FFFFB0;
   func_1034(tmp_str000009, tmp_str000008, Li_FFFFC4, tmp_str000007, tmp_str000006);
   tmp_str00000A = "Chiusura manuale";
   tmp_str00000B = "SS";
   tmp_str00000C = Ls_FFFFA0;
   tmp_str00000D = Ls_FFFFB0;
   func_1034(tmp_str00000D, tmp_str00000C, Li_FFFFC4, tmp_str00000B, tmp_str00000A);
   break; 
   } 
   Li_FFFFC4 = Li_FFFFC4 + 1;
   } 
   Li_FFFFC0 = Li_FFFFC0 + 1;
   } while (Li_FFFFC0 < ArraySize(Is_009CB0)); 
   } 
   ArrayFree(Ls_FFFFCC);
   } 
   tmp_str00000E = Is_009CA0 + "_chiudiTotale";
   if (sparam == tmp_str00000E) { 
   Li_FFFF9C = MagicInp;
   Li_FFFF98 = 0;
   if (ArraySize(Is_009CB0) > 0) { 
   do { 
   Ls_FFFF88 = Is_009CB0[Li_FFFF98];
   Ls_FFFF78 = Is_009CE4[Li_FFFF98];
   tmp_str00000E = "Trovato Totale : " + Ls_FFFF88;
   tmp_str00000E = tmp_str00000E + " ";
   tmp_str00000E = tmp_str00000E + Ls_FFFF78;
   Print(tmp_str00000E);
   tmp_str00000F = "Chiusura Totale manuale";
   tmp_str000010 = "LS";
   tmp_str000011 = Ls_FFFF78;
   tmp_str000012 = Ls_FFFF88;
   func_1034(tmp_str000012, tmp_str000011, Li_FFFF9C, tmp_str000010, tmp_str00000F);
   tmp_str000013 = "Chiusura Totale manuale";
   tmp_str000014 = "SS";
   tmp_str000015 = Ls_FFFF78;
   tmp_str000016 = Ls_FFFF88;
   func_1034(tmp_str000016, tmp_str000015, Li_FFFF9C, tmp_str000014, tmp_str000013);
   Li_FFFF9C = Li_FFFF9C + 1;
   Li_FFFF98 = Li_FFFF98 + 1;
   } while (Li_FFFF98 < ArraySize(Is_009CB0)); 
   }} 
   tmp_str000017 = Is_009CA0 + "_chiudiGain";
   if (sparam == tmp_str000017) { 
   Li_FFFF74 = MagicInp;
   Li_FFFF70 = 0;
   if (ArraySize(Is_009CB0) > 0) { 
   do { 
   Ls_FFFF60 = Is_009CB0[Li_FFFF70];
   Ls_FFFF50 = Is_009CE4[Li_FFFF70];
   if (Ls_FFFF60 == "" || Ls_FFFF50 == "") { 
   
   Li_FFFF74 = Li_FFFF74 + 1;
   } 
   else { 
   Ls_FFFF40 = "Flat";
   Ld_FFFF38 = 0;
   Ld_FFFF30 = 0;
   Ld_FFFF28 = 0;
   Gi_00000C = Li_FFFF74;
   tmp_str000017 = Ls_FFFF50;
   tmp_str000018 = Ls_FFFF60;
   Gi_00000D = OrdersTotal();
   if (Gi_00000D >= 0) { 
   do { 
   if (OrderSelect(Gi_00000D, 0, 0) && OrderMagicNumber() == Gi_00000C) { 
   if (OrderSymbol() == tmp_str000018 || OrderSymbol() == tmp_str000017) { 
   
   tmp_str000019 = OrderComment();
   if (StringSubstr(tmp_str000019, 0, 2) == "LS") { 
   Ls_FFFF40 = "Long Spread";
   } 
   else { 
   Ls_FFFF40 = "Short Spread";
   } 
   if (OrderSymbol() == tmp_str000018) { 
   Ld_FFFF30 = (Ld_FFFF30 + NormalizeDouble(OrderLots(), 2));
   } 
   if (OrderSymbol() == tmp_str000017) { 
   Ld_FFFF28 = (Ld_FFFF28 + NormalizeDouble(OrderLots(), 2));
   } 
   Gd_00000E = OrderProfit();
   Gd_00000E = (Gd_00000E + OrderSwap());
   Ld_FFFF38 = ((Gd_00000E + OrderCommission()) + Ld_FFFF38);
   }} 
   Gi_00000D = Gi_00000D - 1;
   } while (Gi_00000D >= 0); 
   } 
   if ((Ld_FFFF38 > 0)) { 
   tmp_str00001A = "Chiusura Totale Gain";
   tmp_str00001B = "LS";
   tmp_str00001C = Ls_FFFF50;
   tmp_str00001D = Ls_FFFF60;
   func_1034(tmp_str00001D, tmp_str00001C, Li_FFFF74, tmp_str00001B, tmp_str00001A);
   tmp_str00001E = "Chiusura Totale Gain";
   tmp_str00001F = "SS";
   tmp_str000020 = Ls_FFFF50;
   tmp_str000021 = Ls_FFFF60;
   func_1034(tmp_str000021, tmp_str000020, Li_FFFF74, tmp_str00001F, tmp_str00001E);
   } 
   Li_FFFF74 = Li_FFFF74 + 1;
   } 
   Li_FFFF70 = Li_FFFF70 + 1;
   } while (Li_FFFF70 < ArraySize(Is_009CB0)); 
   }} 
   tmp_str000022 = Is_009CA0 + "_chiudiLoss";
   if (sparam == tmp_str000022) { 
   Li_FFFF24 = MagicInp;
   Li_FFFF20 = 0;
   if (ArraySize(Is_009CB0) > 0) { 
   do { 
   Ls_FFFF10 = Is_009CB0[Li_FFFF20];
   Ls_FFFF00 = Is_009CE4[Li_FFFF20];
   if (Ls_FFFF10 == "" || Ls_FFFF00 == "") { 
   
   Li_FFFF24 = Li_FFFF24 + 1;
   } 
   else { 
   Ls_FFFEF0 = "Flat";
   Ld_FFFEE8 = 0;
   Ld_FFFEE0 = 0;
   Ld_FFFED8 = 0;
   Gi_000014 = Li_FFFF24;
   tmp_str000022 = Ls_FFFF00;
   tmp_str000023 = Ls_FFFF10;
   Gi_000015 = OrdersTotal();
   if (Gi_000015 >= 0) { 
   do { 
   if (OrderSelect(Gi_000015, 0, 0) && OrderMagicNumber() == Gi_000014) { 
   if (OrderSymbol() == tmp_str000023 || OrderSymbol() == tmp_str000022) { 
   
   tmp_str000024 = OrderComment();
   if (StringSubstr(tmp_str000024, 0, 2) == "LS") { 
   Ls_FFFEF0 = "Long Spread";
   } 
   else { 
   Ls_FFFEF0 = "Short Spread";
   } 
   if (OrderSymbol() == tmp_str000023) { 
   Ld_FFFEE0 = (Ld_FFFEE0 + NormalizeDouble(OrderLots(), 2));
   } 
   if (OrderSymbol() == tmp_str000022) { 
   Ld_FFFED8 = (Ld_FFFED8 + NormalizeDouble(OrderLots(), 2));
   } 
   Gd_000016 = OrderProfit();
   Gd_000016 = (Gd_000016 + OrderSwap());
   Ld_FFFEE8 = ((Gd_000016 + OrderCommission()) + Ld_FFFEE8);
   }} 
   Gi_000015 = Gi_000015 - 1;
   } while (Gi_000015 >= 0); 
   } 
   if ((Ld_FFFEE8 < 0)) { 
   tmp_str000025 = "Chiusura Totale Loss";
   tmp_str000026 = "LS";
   tmp_str000027 = Ls_FFFF00;
   tmp_str000028 = Ls_FFFF10;
   func_1034(tmp_str000028, tmp_str000027, Li_FFFF24, tmp_str000026, tmp_str000025);
   tmp_str000029 = "Chiusura Totale Loss";
   tmp_str00002A = "SS";
   tmp_str00002B = Ls_FFFF00;
   tmp_str00002C = Ls_FFFF10;
   func_1034(tmp_str00002C, tmp_str00002B, Li_FFFF24, tmp_str00002A, tmp_str000029);
   } 
   Li_FFFF24 = Li_FFFF24 + 1;
   } 
   Li_FFFF20 = Li_FFFF20 + 1;
   } while (Li_FFFF20 < ArraySize(Is_009CB0)); 
   }} 
   tmp_str00002D = Is_009CA0 + "_newGrids";
   if (sparam != tmp_str00002D) return; 
   tmp_str00002D = IntegerToString(MagicInp, 0, 32);
   tmp_str00002D = tmp_str00002D + "_newgrid";
   if (GlobalVariableGet(tmp_str00002D) != 0) { 
   tmp_str00002E = IntegerToString(MagicInp, 0, 32);
   tmp_str00002E = tmp_str00002E + "_newgrid";
   GlobalVariableSet(tmp_str00002E, 0);
   ObjectSetInteger(0, sparam, 1025, 255);
   ObjectSetInteger(0, sparam, 1035, 255);
   ObjectSetString(0, sparam, 999, "New grids NOT allowed!");
   } 
   else { 
   tmp_str00002F = IntegerToString(MagicInp, 0, 32);
   tmp_str00002F = tmp_str00002F + "_newgrid";
   GlobalVariableSet(tmp_str00002F, 1);
   ObjectSetInteger(0, sparam, 1025, 3329330);
   ObjectSetInteger(0, sparam, 1035, 3329330);
   ObjectSetString(0, sparam, 999, "New grids allowed");
   } 
   ObjectSetInteger(0, sparam, 1018, 0);
   
}

void func_1010()
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   string tmp_str00000D;
   string tmp_str00000E;
   string tmp_str00000F;
   string tmp_str000010;
   string tmp_str000011;
   string tmp_str000012;
   string tmp_str000013;
   string tmp_str000014;
   string tmp_str000015;
   string tmp_str000016;
   string tmp_str000017;
   string tmp_str000018;
   string tmp_str000019;
   string tmp_str00001A;
   string tmp_str00001B;
   string tmp_str00001C;
   string tmp_str00001D;
   string tmp_str00001E;
   string tmp_str00001F;
   string tmp_str000020;
   string tmp_str000021;
   string tmp_str000022;
   string tmp_str000023;
   string tmp_str000024;
   string tmp_str000025;
   string tmp_str000026;
   string tmp_str000027;
   string tmp_str000028;
   string tmp_str000029;
   string tmp_str00002A;
   string tmp_str00002B;
   string tmp_str00002C;
   string tmp_str00002D;
   string tmp_str00002E;
   string tmp_str00002F;
   string tmp_str000030;
   string tmp_str000031;
   string tmp_str000032;
   string tmp_str000033;
   string tmp_str000034;
   string tmp_str000035;
   string tmp_str000036;
   string tmp_str000037;
   string tmp_str000038;
   string tmp_str000039;
   int Li_FFFFFC;
   double Ld_FFE818;
   int Li_FFE814;
   double Ld_FFE808;
   int Li_FFE804;
   double Ld_FFE7F8;
   int Li_FFE7F4;
   int Li_FFE7F0;
   string Ls_FFE7E0;
   string Ls_FFE7D0;
   bool Lb_FFE7A7;
   int Li_FFE7A0;
   string Ls_FFE790;
   string Ls_FFE780;
   double Ld_FFE778;
   int Li_FFE774;
   int Li_FFE770;
   string Ls_FFE7C0;
   double Ld_FFE7B8;
   double Ld_FFE7B0;
   double Ld_FFE7A8;

   tmp_str000000 = IntegerToString(MagicInp, 0, 32);
   tmp_str000001 = Is_009CA0 + "magic";
   ObjectCreate(0, tmp_str000001, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000001, tmp_str000000, 20, "Dubai", 8421504);
   ObjectSet(tmp_str000001, OBJPROP_CORNER, 1);
   ObjectSet(tmp_str000001, OBJPROP_XDISTANCE, 5);
   ObjectSet(tmp_str000001, OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, tmp_str000001, 1011, 5);
   tmp_str000002 = Is_009CA0 + "mini";
   if (ObjectFind(tmp_str000002) < 0) { 
   tmp_str000003 = "Dubai";
   tmp_str000004 = "SPREAD EA";
   tmp_str000005 = Is_009CA0 + "spreadEAButton";
   ObjectCreate(0, tmp_str000005, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str000005, 102, 10);
   ObjectSetInteger(0, tmp_str000005, 101, 0);
   ObjectSetInteger(0, tmp_str000005, 103, 20);
   ObjectSetInteger(0, tmp_str000005, 1019, 150);
   ObjectSetInteger(0, tmp_str000005, 1020, 30);
   ObjectSetString(0, tmp_str000005, 999, tmp_str000004);
   ObjectSetString(0, tmp_str000005, 1001, tmp_str000003);
   ObjectSetInteger(0, tmp_str000005, 6, 255);
   ObjectSetInteger(0, tmp_str000005, 1025, Ii_009DEC);
   ObjectSetInteger(0, tmp_str000005, 1035, Ii_009DEC);
   ObjectSetInteger(0, tmp_str000005, 1029, 1);
   ObjectSetInteger(0, tmp_str000005, 208, 1);
   ObjectSetInteger(0, tmp_str000005, 1018, 0);
   ObjectSetInteger(0, tmp_str000005, 100, 12);
   ObjectSetInteger(0, tmp_str000005, 9, 0);
   tmp_str000006 = "Wingdings 2";
   tmp_str000007 = "Ê";
   tmp_str000008 = Is_009CA0 + "mini";
   ObjectCreate(0, tmp_str000008, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str000008, 102, 150);
   ObjectSetInteger(0, tmp_str000008, 101, 0);
   ObjectSetInteger(0, tmp_str000008, 103, 20);
   ObjectSetInteger(0, tmp_str000008, 1019, 30);
   ObjectSetInteger(0, tmp_str000008, 1020, 30);
   ObjectSetString(0, tmp_str000008, 999, tmp_str000007);
   ObjectSetString(0, tmp_str000008, 1001, tmp_str000006);
   ObjectSetInteger(0, tmp_str000008, 6, 255);
   ObjectSetInteger(0, tmp_str000008, 1025, Ii_009DEC);
   ObjectSetInteger(0, tmp_str000008, 1035, Ii_009DEC);
   ObjectSetInteger(0, tmp_str000008, 1029, 1);
   ObjectSetInteger(0, tmp_str000008, 208, 1);
   ObjectSetInteger(0, tmp_str000008, 1018, 0);
   ObjectSetInteger(0, tmp_str000008, 100, 13);
   ObjectSetInteger(0, tmp_str000008, 9, 0);
   } 
   tmp_str000009 = Is_009CA0 + "mini";
   if (ObjectGetString(0, tmp_str000009, 999, 0) == "Ê") return; 
   tmp_str00000A = "Dubai";
   tmp_str00000B = "";
   tmp_str00000C = Is_009CA0 + "background";
   ObjectCreate(0, tmp_str00000C, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str00000C, 102, 10);
   ObjectSetInteger(0, tmp_str00000C, 101, 0);
   ObjectSetInteger(0, tmp_str00000C, 103, 45);
   ObjectSetInteger(0, tmp_str00000C, 1019, Ii_009DF0);
   ObjectSetInteger(0, tmp_str00000C, 1020, 200);
   ObjectSetString(0, tmp_str00000C, 999, tmp_str00000B);
   ObjectSetString(0, tmp_str00000C, 1001, tmp_str00000A);
   ObjectSetInteger(0, tmp_str00000C, 6, Ii_009DEC);
   ObjectSetInteger(0, tmp_str00000C, 1025, Ii_009DEC);
   ObjectSetInteger(0, tmp_str00000C, 1035, Ii_009DEC);
   ObjectSetInteger(0, tmp_str00000C, 1029, 1);
   ObjectSetInteger(0, tmp_str00000C, 208, 1);
   ObjectSetInteger(0, tmp_str00000C, 1018, 0);
   ObjectSetInteger(0, tmp_str00000C, 100, 20);
   ObjectSetInteger(0, tmp_str00000C, 9, 0);
   Li_FFFFFC = 65;
   double Ld_FFF69C[300];
   ArrayInitialize(Ld_FFF69C, 0);
   string Ls_FFE858[300];
   Ld_FFE818 = 0;
   Li_FFE814 = 0;
   Ld_FFE808 = 0;
   Li_FFE804 = 0;
   Ld_FFE7F8 = 0;
   Li_FFE7F4 = MagicInp;
   Li_FFE7F0 = 0;
   if (ArraySize(Is_009CB0) > 0) { 
   do { 
   Ls_FFE7E0 = Is_009CB0[Li_FFE7F0];
   Ls_FFE7D0 = Is_009CE4[Li_FFE7F0];
   if (Ls_FFE7E0 == "" || Ls_FFE7D0 == "") { 
   
   Li_FFE7F4 = Li_FFE7F4 + 1;
   } 
   else { 
   Ls_FFE7C0 = "Flat";
   Ld_FFE7B8 = 0;
   Ld_FFE7B0 = 0;
   Ld_FFE7A8 = 0;
   Gi_000006 = Li_FFE7F4;
   tmp_str00000D = Ls_FFE7D0;
   tmp_str00000E = Ls_FFE7E0;
   Gi_000007 = OrdersTotal();
   if (Gi_000007 >= 0) { 
   do { 
   if (OrderSelect(Gi_000007, 0, 0) && OrderMagicNumber() == Gi_000006) { 
   if (OrderSymbol() == tmp_str00000E || OrderSymbol() == tmp_str00000D) { 
   
   tmp_str00000F = OrderComment();
   if (StringSubstr(tmp_str00000F, 0, 2) == "LS") { 
   Ls_FFE7C0 = "Long Spread";
   } 
   else { 
   Ls_FFE7C0 = "Short Spread";
   } 
   if (OrderSymbol() == tmp_str00000E) { 
   Ld_FFE7B0 = (Ld_FFE7B0 + NormalizeDouble(OrderLots(), 2));
   } 
   if (OrderSymbol() == tmp_str00000D) { 
   Ld_FFE7A8 = (Ld_FFE7A8 + NormalizeDouble(OrderLots(), 2));
   } 
   Gd_000008 = OrderProfit();
   Gd_000008 = (Gd_000008 + OrderSwap());
   Ld_FFE7B8 = ((Gd_000008 + OrderCommission()) + Ld_FFE7B8);
   }} 
   Gi_000007 = Gi_000007 - 1;
   } while (Gi_000007 >= 0); 
   } 
   Ld_FFF69C[Li_FFE7F0] = Ld_FFE7B8;
   tmp_str000010 = Ls_FFE7E0 + "/";
   tmp_str000010 = tmp_str000010 + Ls_FFE7D0;
   Ls_FFE858[Li_FFE7F0] = tmp_str000010;
   if ((Ld_FFE7B8 < Ld_FFE808)) { 
   Ld_FFE808 = Ld_FFE7B8;
   Li_FFE804 = Li_FFE7F0;
   } 
   if ((Ld_FFE7B8 > Ld_FFE818)) { 
   Ld_FFE818 = Ld_FFE7B8;
   Li_FFE814 = Li_FFE7F0;
   } 
   tmp_str000010 = "Dubai";
   Gi_00000A = Ii_009DF0 - 20;
   Gi_00000B = Li_FFFFFC - 10;
   tmp_str000011 = "";
   tmp_str000012 = Is_009CA0 + "_back_";
   tmp_str000012 = tmp_str000012 + Ls_FFE7E0;
   tmp_str000012 = tmp_str000012 + "/";
   tmp_str000012 = tmp_str000012 + Ls_FFE7D0;
   ObjectCreate(0, tmp_str000012, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str000012, 102, 20);
   ObjectSetInteger(0, tmp_str000012, 101, 0);
   ObjectSetInteger(0, tmp_str000012, 103, Gi_00000B);
   ObjectSetInteger(0, tmp_str000012, 1019, Gi_00000A);
   ObjectSetInteger(0, tmp_str000012, 1020, 25);
   ObjectSetString(0, tmp_str000012, 999, tmp_str000011);
   ObjectSetString(0, tmp_str000012, 1001, tmp_str000010);
   ObjectSetInteger(0, tmp_str000012, 6, Ii_009DE8);
   ObjectSetInteger(0, tmp_str000012, 1025, Ii_009DE8);
   ObjectSetInteger(0, tmp_str000012, 1035, Ii_009DE8);
   ObjectSetInteger(0, tmp_str000012, 1029, 1);
   ObjectSetInteger(0, tmp_str000012, 208, 1);
   ObjectSetInteger(0, tmp_str000012, 1018, 0);
   ObjectSetInteger(0, tmp_str000012, 100, 10);
   ObjectSetInteger(0, tmp_str000012, 9, 0);
   Gi_00000B = Li_FFFFFC + 2;
   tmp_str000013 = Ls_FFE7E0 + "/";
   tmp_str000013 = tmp_str000013 + Ls_FFE7D0;
   tmp_str000014 = Is_009CA0 + "_nome_";
   tmp_str000014 = tmp_str000014 + Ls_FFE7E0;
   tmp_str000014 = tmp_str000014 + "/";
   tmp_str000014 = tmp_str000014 + Ls_FFE7D0;
   ObjectCreate(0, tmp_str000014, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000014, tmp_str000013, grandezzaFont, "Dubai", 16777215);
   ObjectSet(tmp_str000014, OBJPROP_CORNER, 0);
   ObjectSet(tmp_str000014, OBJPROP_XDISTANCE, 30);
   ObjectSet(tmp_str000014, OBJPROP_YDISTANCE, Gi_00000B);
   ObjectSetInteger(0, tmp_str000014, 1011, 1);
   Gi_00000B = 0;
   Gi_00000C = 1;
   if (Ls_FFE7C0 == "Long Spread") { 
   Gi_00000E = 3329330;
   } 
   else { 
   if (Ls_FFE7C0 == "Short Spread") { 
   Gi_00000F = 255;
   } 
   else { 
   Gi_00000F = 13882323;
   } 
   Gi_00000E = Gi_00000F;
   } 
   Gi_00000F = Gi_00000E;
   Gi_000010 = Li_FFFFFC + 2;
   if (Ls_FFE7C0 == "Long Spread") { 
   Gi_000011 = 180;
   } 
   else { 
   if (Ls_FFE7C0 == "Short Spread") { 
   Gi_000012 = 180;
   } 
   else { 
   Gi_000012 = 200;
   } 
   Gi_000011 = Gi_000012;
   } 
   tmp_str000015 = Ls_FFE7C0;
   tmp_str000016 = Is_009CA0 + "_tipoSpread_";
   tmp_str000016 = tmp_str000016 + Ls_FFE7E0;
   tmp_str000016 = tmp_str000016 + "/";
   tmp_str000016 = tmp_str000016 + Ls_FFE7D0;
   ObjectCreate(0, tmp_str000016, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000016, tmp_str000015, grandezzaFont, "Dubai", Gi_00000F);
   ObjectSet(tmp_str000016, OBJPROP_CORNER, Gi_00000B);
   ObjectSet(tmp_str000016, OBJPROP_XDISTANCE, Gi_000011);
   ObjectSet(tmp_str000016, OBJPROP_YDISTANCE, Gi_000010);
   ObjectSetInteger(0, tmp_str000016, 1011, Gi_00000C);
   Gi_000012 = Li_FFFFFC + 2;
   tmp_str000017 = "" + DoubleToString(Ld_FFE7B0, 2);
   tmp_str000017 = tmp_str000017 + "/";
   tmp_str000017 = tmp_str000017 + DoubleToString(Ld_FFE7A8, 2);
   tmp_str000018 = Is_009CA0 + "_exp_";
   tmp_str000018 = tmp_str000018 + Ls_FFE7E0;
   tmp_str000018 = tmp_str000018 + "/";
   tmp_str000018 = tmp_str000018 + Ls_FFE7D0;
   ObjectCreate(0, tmp_str000018, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000018, tmp_str000017, grandezzaFont, "Dubai", 16777215);
   ObjectSet(tmp_str000018, OBJPROP_CORNER, 0);
   ObjectSet(tmp_str000018, OBJPROP_XDISTANCE, 300);
   ObjectSet(tmp_str000018, OBJPROP_YDISTANCE, Gi_000012);
   ObjectSetInteger(0, tmp_str000018, 1011, 1);
   Gi_000012 = 0;
   Gi_000013 = 1;
   if ((Ld_FFE7B8 > 0)) { 
   Gi_000015 = 3329330;
   } 
   else { 
   if ((Ld_FFE7B8 < 0)) { 
   Gi_000016 = 255;
   } 
   else { 
   Gi_000016 = 13882323;
   } 
   Gi_000015 = Gi_000016;
   } 
   Gi_000016 = Li_FFFFFC + 2;
   tmp_str000019 = "P/L : " + DoubleToString(Ld_FFE7B8, 2);
   tmp_str00001A = Is_009CA0 + "_pl_";
   tmp_str00001A = tmp_str00001A + Ls_FFE7E0;
   tmp_str00001A = tmp_str00001A + "/";
   tmp_str00001A = tmp_str00001A + Ls_FFE7D0;
   ObjectCreate(0, tmp_str00001A, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str00001A, tmp_str000019, grandezzaFont, "Dubai", Gi_000015);
   ObjectSet(tmp_str00001A, OBJPROP_CORNER, Gi_000012);
   ObjectSet(tmp_str00001A, OBJPROP_XDISTANCE, 400);
   ObjectSet(tmp_str00001A, OBJPROP_YDISTANCE, Gi_000016);
   ObjectSetInteger(0, tmp_str00001A, 1011, Gi_000013);
   tmp_str00001B = "Dubai";
   Gi_000016 = 0;
   Gi_000017 = grandezzaFont - 1;
   if ((Ld_FFE7B8 > 0)) { 
   Gi_000018 = 16777215;
   } 
   else { 
   if ((Ld_FFE7B8 < 0)) { 
   Gi_000019 = 16777215;
   } 
   else { 
   Gi_000019 = 0;
   } 
   Gi_000018 = Gi_000019;
   } 
   Gi_000019 = Gi_000018;
   if ((Ld_FFE7B8 > 0)) { 
   Gi_00001A = 3329330;
   } 
   else { 
   if ((Ld_FFE7B8 < 0)) { 
   Gi_00001B = 255;
   } 
   else { 
   Gi_00001B = 11119017;
   } 
   Gi_00001A = Gi_00001B;
   } 
   Gi_00001B = Li_FFFFFC - 8;
   tmp_str00001C = "Close Spread";
   tmp_str00001D = Is_009CA0 + "_chiudiTutto_";
   tmp_str00001D = tmp_str00001D + IntegerToString(Li_FFE7F4, 0, 32);
   ObjectCreate(0, tmp_str00001D, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str00001D, 102, 490);
   ObjectSetInteger(0, tmp_str00001D, 101, Gi_000016);
   ObjectSetInteger(0, tmp_str00001D, 103, Gi_00001B);
   ObjectSetInteger(0, tmp_str00001D, 1019, 100);
   ObjectSetInteger(0, tmp_str00001D, 1020, 20);
   ObjectSetString(0, tmp_str00001D, 999, tmp_str00001C);
   ObjectSetString(0, tmp_str00001D, 1001, tmp_str00001B);
   ObjectSetInteger(0, tmp_str00001D, 6, Gi_000019);
   ObjectSetInteger(0, tmp_str00001D, 1025, Gi_00001A);
   ObjectSetInteger(0, tmp_str00001D, 1035, Gi_00001A);
   ObjectSetInteger(0, tmp_str00001D, 1029, 1);
   ObjectSetInteger(0, tmp_str00001D, 208, 1);
   ObjectSetInteger(0, tmp_str00001D, 1018, 0);
   ObjectSetInteger(0, tmp_str00001D, 100, Gi_000017);
   ObjectSetInteger(0, tmp_str00001D, 9, 0);
   Ld_FFE7F8 = (Ld_FFE7F8 + Ld_FFE7B8);
   Li_FFFFFC = Li_FFFFFC + 30;
   Li_FFE7F4 = Li_FFE7F4 + 1;
   } 
   Li_FFE7F0 = Li_FFE7F0 + 1;
   } while (Li_FFE7F0 < ArraySize(Is_009CB0)); 
   } 
   Gi_00001C = 0;
   Gi_00001D = 1;
   if ((Ld_FFE7F8 > 0)) { 
   Gi_00001F = 3329330;
   } 
   else { 
   if ((Ld_FFE7F8 < 0)) { 
   Gi_000020 = 255;
   } 
   else { 
   Gi_000020 = 13882323;
   } 
   Gi_00001F = Gi_000020;
   } 
   Gi_000020 = Li_FFFFFC + 2;
   tmp_str00001E = "Totale : ";
   tmp_str00001F = Is_009CA0 + "_Totale";
   ObjectCreate(0, tmp_str00001F, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str00001F, tmp_str00001E, grandezzaFont, "Dubai", Gi_00001F);
   ObjectSet(tmp_str00001F, OBJPROP_CORNER, Gi_00001C);
   ObjectSet(tmp_str00001F, OBJPROP_XDISTANCE, 150);
   ObjectSet(tmp_str00001F, OBJPROP_YDISTANCE, Gi_000020);
   ObjectSetInteger(0, tmp_str00001F, 1011, Gi_00001D);
   Gi_000020 = 0;
   Gi_000021 = 1;
   if ((Ld_FFE7F8 > 0)) { 
   Gi_000023 = 3329330;
   } 
   else { 
   if ((Ld_FFE7F8 < 0)) { 
   Gi_000024 = 255;
   } 
   else { 
   Gi_000024 = 13882323;
   } 
   Gi_000023 = Gi_000024;
   } 
   Gi_000024 = Li_FFFFFC + 2;
   tmp_str000020 = "P/L : " + DoubleToString(Ld_FFE7F8, 2);
   tmp_str000021 = Is_009CA0 + "_plTotale";
   ObjectCreate(0, tmp_str000021, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000021, tmp_str000020, grandezzaFont, "Dubai", Gi_000023);
   ObjectSet(tmp_str000021, OBJPROP_CORNER, Gi_000020);
   ObjectSet(tmp_str000021, OBJPROP_XDISTANCE, 200);
   ObjectSet(tmp_str000021, OBJPROP_YDISTANCE, Gi_000024);
   ObjectSetInteger(0, tmp_str000021, 1011, Gi_000021);
   tmp_str000022 = "Dubai";
   Gi_000024 = grandezzaFont - 1;
   Gi_000025 = Li_FFFFFC - 8;
   tmp_str000023 = "Close Gain";
   tmp_str000024 = Is_009CA0 + "_chiudiGain";
   ObjectCreate(0, tmp_str000024, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str000024, 102, 280);
   ObjectSetInteger(0, tmp_str000024, 101, 0);
   ObjectSetInteger(0, tmp_str000024, 103, Gi_000025);
   ObjectSetInteger(0, tmp_str000024, 1019, 100);
   ObjectSetInteger(0, tmp_str000024, 1020, 20);
   ObjectSetString(0, tmp_str000024, 999, tmp_str000023);
   ObjectSetString(0, tmp_str000024, 1001, tmp_str000022);
   ObjectSetInteger(0, tmp_str000024, 6, 16777215);
   ObjectSetInteger(0, tmp_str000024, 1025, 3329330);
   ObjectSetInteger(0, tmp_str000024, 1035, 3329330);
   ObjectSetInteger(0, tmp_str000024, 1029, 1);
   ObjectSetInteger(0, tmp_str000024, 208, 1);
   ObjectSetInteger(0, tmp_str000024, 1018, 0);
   ObjectSetInteger(0, tmp_str000024, 100, Gi_000024);
   ObjectSetInteger(0, tmp_str000024, 9, 0);
   tmp_str000025 = "Dubai";
   tmp_str000026 = "Close Loss";
   tmp_str000027 = Is_009CA0 + "_chiudiLoss";
   ObjectCreate(0, tmp_str000027, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str000027, 102, 385);
   ObjectSetInteger(0, tmp_str000027, 101, 0);
   ObjectSetInteger(0, tmp_str000027, 103, Gi_000025);
   ObjectSetInteger(0, tmp_str000027, 1019, 100);
   ObjectSetInteger(0, tmp_str000027, 1020, 20);
   ObjectSetString(0, tmp_str000027, 999, tmp_str000026);
   ObjectSetString(0, tmp_str000027, 1001, tmp_str000025);
   ObjectSetInteger(0, tmp_str000027, 6, 16777215);
   ObjectSetInteger(0, tmp_str000027, 1025, 255);
   ObjectSetInteger(0, tmp_str000027, 1035, 255);
   ObjectSetInteger(0, tmp_str000027, 1029, 1);
   ObjectSetInteger(0, tmp_str000027, 208, 1);
   ObjectSetInteger(0, tmp_str000027, 1018, 0);
   ObjectSetInteger(0, tmp_str000027, 100, Gi_000024);
   ObjectSetInteger(0, tmp_str000027, 9, 0);
   tmp_str000028 = "Dubai";
   Gi_000026 = 0;
   if ((Ld_FFE7F8 > 0)) { 
   Gi_000027 = 16777215;
   } 
   else { 
   if ((Ld_FFE7F8 < 0)) { 
   Gi_000028 = 16777215;
   } 
   else { 
   Gi_000028 = 0;
   } 
   Gi_000027 = Gi_000028;
   } 
   Gi_000028 = Gi_000027;
   if ((Ld_FFE7F8 > 0)) { 
   Gi_000029 = 3329330;
   } 
   else { 
   if ((Ld_FFE7F8 < 0)) { 
   Gi_00002A = 255;
   } 
   else { 
   Gi_00002A = 11119017;
   } 
   Gi_000029 = Gi_00002A;
   } 
   Gi_00002A = Li_FFFFFC - 8;
   tmp_str000029 = "Close ALL";
   tmp_str00002A = Is_009CA0 + "_chiudiTotale";
   ObjectCreate(0, tmp_str00002A, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str00002A, 102, 490);
   ObjectSetInteger(0, tmp_str00002A, 101, Gi_000026);
   ObjectSetInteger(0, tmp_str00002A, 103, Gi_00002A);
   ObjectSetInteger(0, tmp_str00002A, 1019, 100);
   ObjectSetInteger(0, tmp_str00002A, 1020, 20);
   ObjectSetString(0, tmp_str00002A, 999, tmp_str000029);
   ObjectSetString(0, tmp_str00002A, 1001, tmp_str000028);
   ObjectSetInteger(0, tmp_str00002A, 6, Gi_000028);
   ObjectSetInteger(0, tmp_str00002A, 1025, Gi_000029);
   ObjectSetInteger(0, tmp_str00002A, 1035, Gi_000029);
   ObjectSetInteger(0, tmp_str00002A, 1029, 1);
   ObjectSetInteger(0, tmp_str00002A, 208, 1);
   ObjectSetInteger(0, tmp_str00002A, 1018, 0);
   ObjectSetInteger(0, tmp_str00002A, 100, Gi_000024);
   ObjectSetInteger(0, tmp_str00002A, 9, 0);
   tmp_str00002B = IntegerToString(MagicInp, 0, 32);
   tmp_str00002B = tmp_str00002B + "_newgrid";
   if (GlobalVariableCheck(tmp_str00002B) != true) { 
   tmp_str00002C = IntegerToString(MagicInp, 0, 32);
   tmp_str00002C = tmp_str00002C + "_newgrid";
   GlobalVariableSet(tmp_str00002C, 1);
   } 
   tmp_str00002D = IntegerToString(MagicInp, 0, 32);
   tmp_str00002D = tmp_str00002D + "_newgrid";
   Lb_FFE7A7 = GlobalVariableGet(tmp_str00002D);
   tmp_str00002E = "Dubai";
   Gi_00002B = 0;
   Gi_00002C = grandezzaFont - 1;
   Gi_00002D = 16777215;
   if (Lb_FFE7A7) { 
   Gi_00002E = 3329330;
   } 
   else { 
   Gi_00002E = 255;
   } 
   Gi_00002F = 20;
   Gi_000030 = 125;
   Gi_000031 = Li_FFFFFC - 8;
   Gi_000032 = 20;
   if (Lb_FFE7A7) { 
   tmp_str00002F = "New grids allowed";
   } 
   else { 
   tmp_str00002F = "New grid NOT allowed!";
   } 
   tmp_str000030 = Is_009CA0 + "_newGrids";
   ObjectCreate(0, tmp_str000030, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, tmp_str000030, 102, Gi_000032);
   ObjectSetInteger(0, tmp_str000030, 101, Gi_00002B);
   ObjectSetInteger(0, tmp_str000030, 103, Gi_000031);
   ObjectSetInteger(0, tmp_str000030, 1019, Gi_000030);
   ObjectSetInteger(0, tmp_str000030, 1020, Gi_00002F);
   ObjectSetString(0, tmp_str000030, 999, tmp_str00002F);
   ObjectSetString(0, tmp_str000030, 1001, tmp_str00002E);
   ObjectSetInteger(0, tmp_str000030, 6, Gi_00002D);
   ObjectSetInteger(0, tmp_str000030, 1025, Gi_00002E);
   ObjectSetInteger(0, tmp_str000030, 1035, Gi_00002E);
   ObjectSetInteger(0, tmp_str000030, 1029, 1);
   ObjectSetInteger(0, tmp_str000030, 208, 1);
   ObjectSetInteger(0, tmp_str000030, 1018, 0);
   ObjectSetInteger(0, tmp_str000030, 100, Gi_00002C);
   ObjectSetInteger(0, tmp_str000030, 9, 0);
   Gi_000033 = Li_FFFFFC - 15;
   tmp_str000031 = Is_009CA0 + "background";
   ObjectSetInteger(0, tmp_str000031, 1020, Gi_000033);
   Li_FFE7A0 = 0;
   if (ArraySize(Is_009CB0) > 0) { 
   do { 
   Ls_FFE790 = Is_009CB0[Li_FFE7A0];
   Ls_FFE780 = Is_009CE4[Li_FFE7A0];
   Ld_FFE778 = 1315860;
   if ((Ld_FFF69C[Li_FFE7A0] < 0)) { 
   Gd_000037 = (Ld_FFF69C[Li_FFE7A0] * 120);
   Li_FFE774 = (int)(Gd_000037 / Ld_FFE808);
   tmp_str000032 = IntegerToString(Li_FFE774, 0, 32);
   tmp_str000032 = tmp_str000032 + ",0,0";
   
   Ld_FFE778 = StringToColor(tmp_str000032);
   Gi_000037 = (int)Ld_FFE778;
   tmp_str000033 = Is_009CA0 + "_back_";
   tmp_str000033 = tmp_str000033 + Ls_FFE790;
   tmp_str000033 = tmp_str000033 + "/";
   tmp_str000033 = tmp_str000033 + Ls_FFE780;
   ObjectSetInteger(0, tmp_str000033, 1025, Gi_000037);
   Gi_000037 = (int)Ld_FFE778;
   tmp_str000034 = Is_009CA0 + "_back_";
   tmp_str000034 = tmp_str000034 + Ls_FFE790;
   tmp_str000034 = tmp_str000034 + "/";
   tmp_str000034 = tmp_str000034 + Ls_FFE780;
   ObjectSetInteger(0, tmp_str000034, 1035, Gi_000037);
   } 
   else { 
   if ((Ld_FFF69C[Li_FFE7A0] > 0)) { 
   Gd_000039 = (Ld_FFF69C[Li_FFE7A0] * 120);
   Li_FFE770 = (int)(Gd_000039 / Ld_FFE818);
   tmp_str000035 = "0," + IntegerToString(Li_FFE770, 0, 32);
   tmp_str000035 = tmp_str000035 + ",0";
   
   Ld_FFE778 = StringToColor(tmp_str000035);
   Gi_000039 = (int)Ld_FFE778;
   tmp_str000036 = Is_009CA0 + "_back_";
   tmp_str000036 = tmp_str000036 + Ls_FFE790;
   tmp_str000036 = tmp_str000036 + "/";
   tmp_str000036 = tmp_str000036 + Ls_FFE780;
   ObjectSetInteger(0, tmp_str000036, 1025, Gi_000039);
   Gi_000039 = (int)Ld_FFE778;
   tmp_str000037 = Is_009CA0 + "_back_";
   tmp_str000037 = tmp_str000037 + Ls_FFE790;
   tmp_str000037 = tmp_str000037 + "/";
   tmp_str000037 = tmp_str000037 + Ls_FFE780;
   ObjectSetInteger(0, tmp_str000037, 1035, Gi_000039);
   } 
   else { 
   tmp_str000038 = Is_009CA0 + "_back_";
   tmp_str000038 = tmp_str000038 + Ls_FFE790;
   tmp_str000038 = tmp_str000038 + "/";
   tmp_str000038 = tmp_str000038 + Ls_FFE780;
   ObjectSetInteger(0, tmp_str000038, 1025, Ii_009DE8);
   tmp_str000039 = Is_009CA0 + "_back_";
   tmp_str000039 = tmp_str000039 + Ls_FFE790;
   tmp_str000039 = tmp_str000039 + "/";
   tmp_str000039 = tmp_str000039 + Ls_FFE780;
   ObjectSetInteger(0, tmp_str000039, 1035, Ii_009DE8);
   }} 
   Li_FFE7A0 = Li_FFE7A0 + 1;
   } while (Li_FFE7A0 < ArraySize(Is_009CB0)); 
   } 
   ArrayFree(Ls_FFE858);
   ArrayFree(Ld_FFF69C);
   
}

bool func_1014()
{
   string tmp_str000000;
   string tmp_str000001;
   bool Lb_FFFFFF;

   if (MagicInp <= 0) { 
   Alert("Errore, il Magic non può essere <= 0");
   Lb_FFFFFF = false;
   return Lb_FFFFFF;
   } 
   returned_i = _Period;
   if (returned_i >= 1 && returned_i <= 43200) {
   if (returned_i == 1) Is_009C88 = "1 Minuto";
   if (returned_i == 5) Is_009C88 = "5 Minuti";
   if (returned_i == 15) Is_009C88 = "15 Minuti";
   if (returned_i == 30) Is_009C88 = "30 Minuti";
   if (returned_i == 60) Is_009C88 = "Orario";
   if (returned_i == 240) Is_009C88 = "4 Ore";
   if (returned_i == 1440) Is_009C88 = "Giornaliero";
   if (returned_i == 10080) Is_009C88 = "Settimanale";
   if (returned_i == 43200) Is_009C88 = "Mensile";
   }
   else{
   Is_009C88 = "null";
   }
   if (Il_009C98 == 0) { 
   Il_009C98 = TimeCurrent();
   } 
   tmp_str000000 = IntegerToString(MagicInp, 0, 32);
   tmp_str000001 = Is_009CA0 + "magic";
   ObjectCreate(0, tmp_str000001, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000001, tmp_str000000, 20, "Dubai", 8421504);
   ObjectSet(tmp_str000001, OBJPROP_CORNER, 1);
   ObjectSet(tmp_str000001, OBJPROP_XDISTANCE, 5);
   ObjectSet(tmp_str000001, OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, tmp_str000001, 1011, 5);
   Lb_FFFFFF = true;
   
   return Lb_FFFFFF;
}

void func_1016(int Fa_i_00, string Fa_s_01, string Fa_s_02, string Fa_s_03, string Fa_s_04, int Fa_i_05)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;

   if (utilizzaAllarmiErrore) { 
   if (utilizzaAlertErrore) { 
   tmp_str000000 = "Error " + DoubleToString(Fa_i_05, 0);
   tmp_str000000 = tmp_str000000 + " ";
   tmp_str000000 = tmp_str000000 + Fa_s_03;
   tmp_str000000 = tmp_str000000 + " ";
   tmp_str000000 = tmp_str000000 + Is_009CA0;
   tmp_str000000 = tmp_str000000 + " ";
   tmp_str000000 = tmp_str000000 + Fa_s_01;
   tmp_str000000 = tmp_str000000 + "/";
   tmp_str000000 = tmp_str000000 + Fa_s_02;
   tmp_str000000 = tmp_str000000 + " on TF ";
   tmp_str000000 = tmp_str000000 + Is_009C88;
   tmp_str000000 = tmp_str000000 + " with ID ";
   tmp_str000000 = tmp_str000000 + DoubleToString(Fa_i_00, 0);
   tmp_str000000 = tmp_str000000 + Fa_s_04;
   Alert(tmp_str000000);
   } 
   if (IsTesting() != true) { 
   if (utilizzaPopupErrore && Il_009DF8 != Time[0]) { 
   tmp_str000001 = "Error " + DoubleToString(Fa_i_05, 0);
   tmp_str000001 = tmp_str000001 + " ";
   tmp_str000001 = tmp_str000001 + Fa_s_03;
   tmp_str000001 = tmp_str000001 + " ";
   tmp_str000001 = tmp_str000001 + Is_009CA0;
   tmp_str000001 = tmp_str000001 + " ";
   tmp_str000001 = tmp_str000001 + Fa_s_01;
   tmp_str000001 = tmp_str000001 + "/";
   tmp_str000001 = tmp_str000001 + Fa_s_02;
   tmp_str000001 = tmp_str000001 + " on TF ";
   tmp_str000001 = tmp_str000001 + Is_009C88;
   tmp_str000001 = tmp_str000001 + " with ID ";
   tmp_str000001 = tmp_str000001 + DoubleToString(Fa_i_00, 0);
   tmp_str000001 = tmp_str000001 + Fa_s_04;
   SendNotification(tmp_str000001);
   } 
   if (utilizzaMailErrore && Il_009DF8 != Time[0]) { 
   tmp_str000002 = "Error " + DoubleToString(Fa_i_05, 0);
   tmp_str000002 = tmp_str000002 + " ";
   tmp_str000002 = tmp_str000002 + Fa_s_03;
   tmp_str000002 = tmp_str000002 + " ";
   tmp_str000002 = tmp_str000002 + Is_009CA0;
   tmp_str000002 = tmp_str000002 + " ";
   tmp_str000002 = tmp_str000002 + Fa_s_01;
   tmp_str000002 = tmp_str000002 + "/";
   tmp_str000002 = tmp_str000002 + Fa_s_02;
   tmp_str000002 = tmp_str000002 + " on TF ";
   tmp_str000002 = tmp_str000002 + Is_009C88;
   tmp_str000002 = tmp_str000002 + " with ID ";
   tmp_str000002 = tmp_str000002 + DoubleToString(Fa_i_00, 0);
   tmp_str000002 = tmp_str000002 + Fa_s_04;
   tmp_str000003 = "Error " + Fa_s_01;
   tmp_str000003 = tmp_str000003 + "/";
   tmp_str000003 = tmp_str000003 + Fa_s_02;
   tmp_str000003 = tmp_str000003 + "TF ";
   tmp_str000003 = tmp_str000003 + Is_009C88;
   tmp_str000003 = tmp_str000003 + " with ID ";
   tmp_str000003 = tmp_str000003 + DoubleToString(Fa_i_00, 0);
   SendMail(tmp_str000003, tmp_str000002);
   }} 
   Il_009DF8 = Time[0];
   return ;
   } 
   tmp_str000004 = "Error " + DoubleToString(Fa_i_05, 0);
   tmp_str000004 = tmp_str000004 + " ";
   tmp_str000004 = tmp_str000004 + Fa_s_03;
   tmp_str000004 = tmp_str000004 + " ";
   tmp_str000004 = tmp_str000004 + Is_009CA0;
   tmp_str000004 = tmp_str000004 + " ";
   tmp_str000004 = tmp_str000004 + Fa_s_01;
   tmp_str000004 = tmp_str000004 + "/";
   tmp_str000004 = tmp_str000004 + Fa_s_02;
   tmp_str000004 = tmp_str000004 + " on TF ";
   tmp_str000004 = tmp_str000004 + Is_009C88;
   tmp_str000004 = tmp_str000004 + " with ID ";
   tmp_str000004 = tmp_str000004 + DoubleToString(Fa_i_00, 0);
   tmp_str000004 = tmp_str000004 + Fa_s_04;
   Print(tmp_str000004);
   
}

void func_1025(string Fa_s_00, string Fa_s_01, string Fa_s_02, int Fa_i_03, int Fa_i_04, double Fa_d_05, double Fa_d_06, string Fa_s_07, int Fa_i_08, double Fa_d_09, double Fa_d_0A)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   bool Lb_FFFFFF;
   int Li_FFFFF8;
   int Li_FFFFF4;
   string Ls_FFFFE8;
   int Li_FFFFE4;
   int Li_FFFFE0;

   Fa_d_05 = NormalizeDouble(Fa_d_05, 2);
   Fa_d_06 = NormalizeDouble(Fa_d_06, (int)SymbolInfoInteger(Fa_s_00, SYMBOL_DIGITS));
   Lb_FFFFFF = false;
   Li_FFFFF8 = 0;
   Li_FFFFF4 = 10;
   Ls_FFFFE8 = "";
   if (Fa_i_04 == 0) { 
   Ls_FFFFE8 = "Long";
   } 
   else { 
   if (Fa_i_04 == 1) { 
   Ls_FFFFE8 = "Short";
   }} 
   if (Lb_FFFFFF) return; 
   if (Li_FFFFF8 >= Li_FFFFF4) return; 
   do { 
   RefreshRates();
   Li_FFFFE4 = 0;
   Gi_000000 = Fa_i_08;
   if (commentoAggiuntivo != "") { 
   tmp_str000000 = "_" + commentoAggiuntivo;
   } 
   else { 
   tmp_str000000 = "";
   } 
   tmp_str000000 = Fa_s_07 + tmp_str000000;
   tmp_str000000 = tmp_str000000 + "_";
   tmp_str000000 = tmp_str000000 + IntegerToString(Ii_00D778, 0, 32);
   Li_FFFFE4 = OrderSend(Fa_s_00, Fa_i_04, Fa_d_05, Fa_d_06, 20, Fa_d_09, Fa_d_0A, tmp_str000000, Fa_i_03, 0, Gi_000000);
   if (Li_FFFFE4 < 0) { 
   Gi_000002 = GetLastError();
   Li_FFFFE0 = Gi_000002;
   tmp_str000001 = "";
   tmp_str000002 = "inserimento ordine " + Ls_FFFFE8;
   tmp_str000002 = tmp_str000002 + " ";
   tmp_str000002 = tmp_str000002 + Fa_s_07;
   tmp_str000003 = Fa_s_02;
   tmp_str000004 = Fa_s_01;
   func_1016(Fa_i_03, tmp_str000004, tmp_str000003, tmp_str000002, tmp_str000001, Gi_000002);
   Li_FFFFF8 = Li_FFFFF8 + 1;
   } 
   else { 
   tmp_str000005 = "";
   tmp_str000006 = Ls_FFFFE8 + " ";
   tmp_str000006 = tmp_str000006 + Fa_s_07;
   tmp_str000007 = tmp_str000006;
   tmp_str000008 = Fa_s_02;
   tmp_str000009 = Fa_s_01;
   Gi_000002 = Fa_i_03;
   if (utilizzaAllarmiInserimentoOrdini) { 
   if (utilizzaAlertInserimentoOrdini) { 
   tmp_str000006 = tmp_str000006 + " ";
   tmp_str000006 = tmp_str000006 + Is_009CA0;
   tmp_str000006 = tmp_str000006 + " ";
   tmp_str000006 = tmp_str000006 + tmp_str000009;
   tmp_str000006 = tmp_str000006 + "/";
   tmp_str000006 = tmp_str000006 + tmp_str000008;
   tmp_str000006 = tmp_str000006 + " on TF ";
   tmp_str000006 = tmp_str000006 + Is_009C88;
   tmp_str000006 = tmp_str000006 + " with ID ";
   tmp_str000006 = tmp_str000006 + DoubleToString(Fa_i_03, 0);
   tmp_str000006 = tmp_str000006 + "";
   Alert(tmp_str000006);
   } 
   if (IsTesting() != true) { 
   if (utilizzaPopupInserimentoOrdini) { 
   tmp_str00000A = tmp_str000007 + " ";
   tmp_str00000A = tmp_str00000A + Is_009CA0;
   tmp_str00000A = tmp_str00000A + " ";
   tmp_str00000A = tmp_str00000A + tmp_str000009;
   tmp_str00000A = tmp_str00000A + "/";
   tmp_str00000A = tmp_str00000A + tmp_str000008;
   tmp_str00000A = tmp_str00000A + " on TF ";
   tmp_str00000A = tmp_str00000A + Is_009C88;
   tmp_str00000A = tmp_str00000A + " with ID ";
   tmp_str00000A = tmp_str00000A + DoubleToString(Gi_000002, 0);
   tmp_str00000A = tmp_str00000A + tmp_str000005;
   SendNotification(tmp_str00000A);
   } 
   if (utilizzaMailInserimentoOrdini) { 
   tmp_str00000B = tmp_str000007 + " ";
   tmp_str00000B = tmp_str00000B + Is_009CA0;
   tmp_str00000B = tmp_str00000B + " ";
   tmp_str00000B = tmp_str00000B + tmp_str000009;
   tmp_str00000B = tmp_str00000B + "/";
   tmp_str00000B = tmp_str00000B + tmp_str000008;
   tmp_str00000B = tmp_str00000B + " on TF ";
   tmp_str00000B = tmp_str00000B + Is_009C88;
   tmp_str00000B = tmp_str00000B + " with ID ";
   tmp_str00000B = tmp_str00000B + DoubleToString(Gi_000002, 0);
   tmp_str00000B = tmp_str00000B + tmp_str000005;
   tmp_str00000C = tmp_str000007 + tmp_str000009;
   tmp_str00000C = tmp_str00000C + "/";
   tmp_str00000C = tmp_str00000C + tmp_str000008;
   tmp_str00000C = tmp_str00000C + " TF ";
   tmp_str00000C = tmp_str00000C + Is_009C88;
   tmp_str00000C = tmp_str00000C + " with ID (Magic Number) ";
   tmp_str00000C = tmp_str00000C + DoubleToString(Gi_000002, 0);
   SendMail(tmp_str00000C, tmp_str00000B);
   }}} 
   Lb_FFFFFF = true;
   return ;
   } 
   Li_FFFFF8 = Li_FFFFF8 + 1;
   Sleep(300);
   if (Lb_FFFFFF) return; 
   } while (Li_FFFFF8 < Li_FFFFF4); 
   
}

bool func_1027(string Fa_s_00)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string Ls_FFFFF0;
   string Ls_FFFFE0;
   string Ls_FFFFD0;
   string Ls_FFFF90;
   string Ls_FFFF80;
   short Lst_FFFF7E;
   int Li_FFFF44;
   long Ll_FFFF38;
   string Ls_FFFF28;
   long Ll_FFFF20;
   long Ll_FFFF18;
   int Li_FFFF14;
   bool Lb_FFFFFF;

   Ls_FFFFF0 = "";
   Ls_FFFFE0 = "";
   Ls_FFFFD0 = "";
   Ls_FFFFF0 = Fa_s_00;
   string Ls_FFFF9C[];
   Ls_FFFF90 = Ls_FFFFF0;
   Ls_FFFF80 = "-";
   Lst_FFFF7E = 0;
   string Ls_FFFF48[];
   Lst_FFFF7E = (short)StringGetCharacter(Ls_FFFF80, 0);
   Gst_000000 = Lst_FFFF7E;
   Li_FFFF44 = StringSplit(Ls_FFFF90, Gst_000000, Ls_FFFF48);
   Ls_FFFFE0 = Ls_FFFF48[0];
   Ls_FFFFD0 = Ls_FFFF48[1];
   if (Ls_FFFFD0 == "00:00:00") { 
   Ls_FFFFD0 = "23:59:59";
   } 
   Ll_FFFF38 = TimeCurrent();
   Ls_FFFF28 = TimeToString(Ll_FFFF38, 1);
   tmp_str000000 = Ls_FFFF28 + " ";
   tmp_str000000 = tmp_str000000 + Ls_FFFFE0;
   Ll_FFFF20 = StringToTime(tmp_str000000);
   tmp_str000001 = Ls_FFFF28 + " ";
   tmp_str000001 = tmp_str000001 + Ls_FFFFD0;
   Ll_FFFF18 = StringToTime(tmp_str000001);
   Li_FFFF14 = TimeDayOfWeek(TimeCurrent());
   if (Ll_FFFF20 < Ll_FFFF18) { 
   if (TimeCurrent() >= Ll_FFFF20 && TimeCurrent() <= Ll_FFFF18) { 
   ObjectDelete(0, "FiltroOrario");
   Lb_FFFFFF = true;
   ArrayFree(Ls_FFFF48);
   ArrayFree(Ls_FFFF9C);
   return Lb_FFFFFF;
   } 
   tmp_str000002 = "Filtro orario Attivato";
   tmp_str000003 = "FiltroOrario";
   ObjectCreate(0, tmp_str000003, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000003, tmp_str000002, 12, "Estrangelo Edessa", 255);
   ObjectSet(tmp_str000003, OBJPROP_CORNER, 1);
   ObjectSet(tmp_str000003, OBJPROP_XDISTANCE, 20);
   ObjectSet(tmp_str000003, OBJPROP_YDISTANCE, 20);
   Lb_FFFFFF = false;
   ArrayFree(Ls_FFFF48);
   ArrayFree(Ls_FFFF9C);
   return Lb_FFFFFF;
   } 
   if (TimeCurrent() <= Ll_FFFF18) { 
   Ll_FFFF20 = Ll_FFFF20 - 86400;
   } 
   else { 
   if (TimeCurrent() >= Ll_FFFF20) { 
   Ll_FFFF18 = Ll_FFFF18 + 86400;
   }} 
   if (TimeCurrent() >= Ll_FFFF20 && TimeCurrent() <= Ll_FFFF18) { 
   ObjectDelete(0, "FiltroOrario");
   Lb_FFFFFF = true;
   ArrayFree(Ls_FFFF48);
   ArrayFree(Ls_FFFF9C);
   return Lb_FFFFFF;
   } 
   tmp_str000004 = "Filtro orario Attivato";
   tmp_str000005 = "FiltroOrario";
   ObjectCreate(0, tmp_str000005, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0);
   ObjectSetText(tmp_str000005, tmp_str000004, 12, "Estrangelo Edessa", 255);
   ObjectSet(tmp_str000005, OBJPROP_CORNER, 1);
   ObjectSet(tmp_str000005, OBJPROP_XDISTANCE, 20);
   ObjectSet(tmp_str000005, OBJPROP_YDISTANCE, 20);
   Lb_FFFFFF = false;
   ArrayFree(Ls_FFFF48);
   ArrayFree(Ls_FFFF9C);
   
   return Lb_FFFFFF;
}

void func_1030(int Fa_i_00, int Fa_i_01, string Fa_s_02, string Fa_s_03)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   string tmp_str00000D;
   string tmp_str00000E;
   string tmp_str00000F;
   string tmp_str000010;
   string tmp_str000011;
   string tmp_str000012;
   string tmp_str000013;
   string tmp_str000014;
   string tmp_str000015;
   string tmp_str000016;
   string tmp_str000017;
   string tmp_str000018;
   string tmp_str000019;
   string tmp_str00001A;
   string tmp_str00001B;
   string tmp_str00001C;
   string tmp_str00001D;
   string tmp_str00001E;
   string tmp_str00001F;
   string tmp_str000020;
   string tmp_str000021;
   string tmp_str000022;
   string tmp_str000023;
   string tmp_str000024;
   string tmp_str000025;
   string tmp_str000026;
   string tmp_str000027;
   string tmp_str000028;
   string tmp_str000029;
   string tmp_str00002A;
   string tmp_str00002B;
   string tmp_str00002C;
   string tmp_str00002D;
   string tmp_str00002E;
   string tmp_str00002F;
   string tmp_str000030;
   string tmp_str000031;
   string tmp_str000032;
   string tmp_str000033;
   string tmp_str000034;
   string tmp_str000035;
   string tmp_str000036;
   string tmp_str000037;
   string tmp_str000038;
   string tmp_str000039;
   string tmp_str00003A;
   string tmp_str00003B;
   string tmp_str00003C;
   string tmp_str00003D;
   string tmp_str00003E;
   string tmp_str00003F;
   string tmp_str000040;
   string tmp_str000041;
   string tmp_str000042;
   string tmp_str000043;
   string tmp_str000044;
   string tmp_str000045;
   string tmp_str000046;
   string tmp_str000047;
   string tmp_str000048;
   string tmp_str000049;
   string tmp_str00004A;
   string tmp_str00004B;
   string tmp_str00004C;
   string tmp_str00004D;
   string tmp_str00004E;
   string tmp_str00004F;
   string tmp_str000050;
   string tmp_str000051;
   string tmp_str000052;
   string tmp_str000053;
   string tmp_str000054;
   string tmp_str000055;
   bool Lb_FFFFFF;
   bool Lb_FFFFFE;
   bool Lb_FFFFFD;
   bool Lb_FFFFFC;
   bool Lb_FFFFFB;
   bool Lb_FFFFFA;

   tmp_str000000 = orarioOperativita;
   if (func_1027(tmp_str000000) != true) { 
   tmp_str000001 = orarioOperativita2;
   if (!func_1027(tmp_str000001)) return; 
   } 
   if (numeroMassimoOperazioniInGain != 0) { 
   tmp_str000002 = Fa_s_03;
   tmp_str000003 = Fa_s_02;
   if (!func_1038(tmp_str000003, tmp_str000002)) return; 
   } 
   tmp_str000004 = Fa_s_03;
   tmp_str000005 = Fa_s_02;
   if ((iCustom(tmp_str000005, 0, "AA_SpreadRatio_1.1", tmp_str000004, ea, periodoBollinger, deviazioneStandard, 4, 0) != 2147483647)) { 
   tmp_str000006 = Fa_s_03;
   tmp_str000007 = Fa_s_02;
   Gb_000000 = (iCustom(tmp_str000007, 0, "AA_SpreadRatio_1.1", tmp_str000006, ea, periodoBollinger, deviazioneStandard, 4, 0) != 0);
   } 
   if (Gb_000000 && (Id_009DB4[Fa_i_01] == 0) == false) { 
   tmp_str000008 = Fa_s_03;
   tmp_str000009 = Fa_s_02;
   Gd_000002 = iCustom(tmp_str000009, 0, "AA_SpreadRatio_1.1", tmp_str000008, ea, periodoBollinger, deviazioneStandard, 1, 1);
   tmp_str00000A = Fa_s_03;
   tmp_str00000B = Fa_s_02;
   Gd_000003 = (Gd_000002 - iCustom(tmp_str00000B, 0, "AA_SpreadRatio_1.1", tmp_str00000A, ea, periodoBollinger, deviazioneStandard, 2, 1));
   Gb_000000 = (Gd_000003 >= Id_009DB4[Fa_i_01]);
   } 
   Lb_FFFFFF = Gb_000000;
   tmp_str00000C = Fa_s_03;
   tmp_str00000D = Fa_s_02;
   if ((iCustom(tmp_str00000D, 0, "AA_SpreadRatio_1.1", tmp_str00000C, ea, periodoBollinger, deviazioneStandard, 5, 0) != 2147483647)) { 
   tmp_str00000E = Fa_s_03;
   tmp_str00000F = Fa_s_02;
   Gb_000003 = (iCustom(tmp_str00000F, 0, "AA_SpreadRatio_1.1", tmp_str00000E, ea, periodoBollinger, deviazioneStandard, 5, 0) != 0);
   } 
   if (Gb_000003 && (Id_009DB4[Fa_i_01] == 0) == false) { 
   tmp_str000010 = Fa_s_03;
   tmp_str000011 = Fa_s_02;
   Gd_000006 = iCustom(tmp_str000011, 0, "AA_SpreadRatio_1.1", tmp_str000010, ea, periodoBollinger, deviazioneStandard, 1, 1);
   tmp_str000012 = Fa_s_03;
   tmp_str000013 = Fa_s_02;
   Gd_000007 = (Gd_000006 - iCustom(tmp_str000013, 0, "AA_SpreadRatio_1.1", tmp_str000012, ea, periodoBollinger, deviazioneStandard, 2, 1));
   Gb_000003 = (Gd_000007 >= Id_009DB4[Fa_i_01]);
   } 
   Lb_FFFFFE = Gb_000003;
   Gb_000007 = !utilizzaOverlay;
   if (utilizzaOverlay) { 
   tmp_str000014 = Fa_s_03;
   tmp_str000015 = Fa_s_02;
   Gd_000009 = iCustom(tmp_str000015, 0, "AA_OverLayChart", tmp_str000014, numeroBarre, 2, 1);
   if ((Gd_000009 > iClose(Fa_s_02, 0, 1))) { 
   tmp_str000016 = Fa_s_03;
   tmp_str000017 = Fa_s_02;
   Gd_00000A = iCustom(tmp_str000017, 0, "AA_OverLayChart", tmp_str000016, numeroBarre, 2, 1);
   Gd_00000B = fabs((Gd_00000A - iClose(Fa_s_02, 0, 1)));
   Gb_000007 = (Gd_00000B >= (Ii_009D80[Fa_i_01] * SymbolInfoDouble(Fa_s_02, SYMBOL_POINT)));
   }} 
   Lb_FFFFFD = Gb_000007;
   Gb_00000B = !utilizzaOverlay;
   if (utilizzaOverlay) { 
   tmp_str000018 = Fa_s_03;
   tmp_str000019 = Fa_s_02;
   Gd_00000D = iCustom(tmp_str000019, 0, "AA_OverLayChart", tmp_str000018, numeroBarre, 2, 1);
   if ((Gd_00000D < iClose(Fa_s_02, 0, 1))) { 
   tmp_str00001A = Fa_s_03;
   tmp_str00001B = Fa_s_02;
   Gd_00000E = iCustom(tmp_str00001B, 0, "AA_OverLayChart", tmp_str00001A, numeroBarre, 2, 1);
   Gd_00000F = fabs((Gd_00000E - iClose(Fa_s_02, 0, 1)));
   Gb_00000B = (Gd_00000F >= (Ii_009D80[Fa_i_01] * SymbolInfoDouble(Fa_s_02, SYMBOL_POINT)));
   }} 
   Lb_FFFFFC = Gb_00000B;
   Gb_00000F = Lb_FFFFFF;
   if (Lb_FFFFFF) { 
   Gb_00000F = Lb_FFFFFD;
   } 
   Lb_FFFFFB = Gb_00000F;
   Gb_00000F = Lb_FFFFFE;
   if (Lb_FFFFFE) { 
   Gb_00000F = Lb_FFFFFC;
   } 
   Lb_FFFFFA = Gb_00000F;
   if (Lb_FFFFFB) { 
   tmp_str00001C = "LS";
   Gi_00000F = Ii_00D778;
   tmp_str00001D = Fa_s_03;
   tmp_str00001E = Fa_s_02;
   Gi_000011 = OrdersTotal();
   Gb_000012 = false;
   if (Gi_000011 >= 0) {
   do { 
   if (OrderSelect(Gi_000011, 0, 0) && OrderMagicNumber() == Gi_00000F) {
   tmp_str00001F = OrderComment();
   if (StringSubstr(tmp_str00001F, 0, 2) == tmp_str00001C) {
   if (OrderSymbol() == tmp_str00001E || OrderSymbol() == tmp_str00001D) {
   
   Gb_000012 = true;
   break;
   }}}
   Gi_000011 = Gi_000011 - 1;
   } while (Gi_000011 >= 0); 
   }
   else Gb_000012 = false;
   
   if (Gb_000012 != true) { 
   tmp_str000020 = "LS";
   Gi_000013 = Ii_00D778;
   tmp_str000021 = Fa_s_03;
   tmp_str000022 = Fa_s_02;
   Gi_000014 = HistoryTotal() - 1;
   Gi_000015 = Gi_000014;
   Gb_000014 = false;
   if (Gi_000014 >= 0) {
   do { 
   if (OrderSelect(Gi_000015, 0, 1)) {
   if (OrderSymbol() == tmp_str000022 || OrderSymbol() == tmp_str000021) {
   
   if (OrderCloseTime() < Il_009C98) {
   Gb_000014 = false;
   break;
   }
   if (OrderMagicNumber() == Gi_000013) {
   tmp_str000023 = OrderComment();
   if (StringSubstr(tmp_str000023, 0, 2) == tmp_str000020) {
   tmp_str000024 = OrderSymbol();
   if (iBarShift(tmp_str000024, 0, OrderOpenTime(), true) == 0 || iBarShift(OrderSymbol(), 0, OrderCloseTime(), true) == 0) {
   
   Gb_000014 = true;
   break;
   }}}}}
   Gi_000015 = Gi_000015 - 1;
   } while (Gi_000015 >= 0); 
   }
   else Gb_000014 = false;
   
   if (Gb_000014 != true) { 
   tmp_str000026 = "SS";
   Gi_000016 = Ii_00D778;
   tmp_str000027 = Fa_s_03;
   tmp_str000028 = Fa_s_02;
   Gi_000017 = OrdersTotal();
   Gb_000018 = false;
   if (Gi_000017 >= 0) {
   do { 
   if (OrderSelect(Gi_000017, 0, 0) && OrderMagicNumber() == Gi_000016) {
   tmp_str000029 = OrderComment();
   if (StringSubstr(tmp_str000029, 0, 2) == tmp_str000026) {
   if (OrderSymbol() == tmp_str000028 || OrderSymbol() == tmp_str000027) {
   
   Gb_000018 = true;
   break;
   }}}
   Gi_000017 = Gi_000017 - 1;
   } while (Gi_000017 >= 0); 
   }
   else Gb_000018 = false;
   
   tmp_str00002A = "SS";
   Gi_000019 = Ii_00D778;
   tmp_str00002B = Fa_s_03;
   tmp_str00002C = Fa_s_02;
   Gi_00001A = HistoryTotal() - 1;
   Gi_00001B = Gi_00001A;
   Gb_00001A = false;
   if (Gi_00001A >= 0) {
   do { 
   if (OrderSelect(Gi_00001B, 0, 1)) {
   if (OrderSymbol() == tmp_str00002C || OrderSymbol() == tmp_str00002B) {
   
   if (OrderCloseTime() < Il_009C98) {
   Gb_00001A = false;
   break;
   }
   if (OrderMagicNumber() == Gi_000019) {
   tmp_str00002D = OrderComment();
   if (StringSubstr(tmp_str00002D, 0, 2) == tmp_str00002A) {
   tmp_str00002E = OrderSymbol();
   if (iBarShift(tmp_str00002E, 0, OrderOpenTime(), true) == 0
   || iBarShift(OrderSymbol(), 0, OrderCloseTime(), true) == 0) {
   
   Gb_00001A = true;
   break;
   }}}}}
   Gi_00001B = Gi_00001B - 1;
   } while (Gi_00001B >= 0); 
   }
   else Gb_00001A = false;
   
   if (Ib_009C80 || (!Gb_000018 && !Gb_00001A)) {
   
   if (Il_009E34[Fa_i_01] != iTime(Fa_s_02, 0, 0) && Fa_i_00 < numeroStrumentiPossibili) { 
   if (limitaIngressoNuoveOperazioniSeSuperatoDD != true) { 
   Gb_00001D = true;
   } 
   else { 
   if (tipoControlloFlottante == 0) { 
   Gd_00001E = valoreLimite;
   } 
   else { 
   Gd_00001E = ((AccountInfoDouble(ACCOUNT_BALANCE) * valoreLimite) / 100);
   } 
   Gd_00001F = 0;
   Gi_000020 = OrdersTotal() - 1;
   Gi_000021 = Gi_000020;
   if (Gi_000020 >= 0) { 
   do { 
   if (OrderSelect(Gi_000021, 0, 0) && OrderMagicNumber() >= MagicInp) { 
   Gi_000020 = OrderMagicNumber();
   Gi_000022 = MagicInp + 50;
   if (Gi_000020 < Gi_000022) { 
   Gd_000022 = OrderProfit();
   Gd_000022 = (Gd_000022 + OrderCommission());
   Gd_00001F = ((Gd_000022 + OrderSwap()) + Gd_00001F);
   }} 
   Gi_000021 = Gi_000021 - 1;
   } while (Gi_000021 >= 0); 
   } 
   if ((Gd_00001F < 0) && (Gd_00001F < -Gd_00001E)) {
   Gb_00001D = false;
   }
   else{
   Gb_00001D = true;
   }} 
   if (Gb_00001D) { 
   tmp_str000030 = IntegerToString(MagicInp, 0, 32);
   tmp_str000030 = tmp_str000030 + "_newgrid";
   if (GlobalVariableGet(tmp_str000030) != 0) { 
   Ii_009CAC = Ii_009CAC + 1;
   tmp_str000031 = "LS_Master" + IntegerToString(Ii_009CAC, 0, 32);
   tmp_str000032 = Fa_s_03;
   tmp_str000033 = Fa_s_02;
   tmp_str000034 = Fa_s_02;
   func_1025(tmp_str000034, tmp_str000033, tmp_str000032, Ii_00D778, 0, Id_009D18[Fa_i_01], SymbolInfoDouble(Fa_s_02, SYMBOL_ASK), tmp_str000031, 16711680, 0, 0);
   tmp_str000035 = "LS_Master" + IntegerToString(Ii_009CAC, 0, 32);
   tmp_str000036 = Fa_s_03;
   tmp_str000037 = Fa_s_02;
   tmp_str000038 = Fa_s_03;
   func_1025(tmp_str000038, tmp_str000037, tmp_str000036, Ii_00D778, 1, Id_009D4C[Fa_i_01], SymbolInfoDouble(Fa_s_03, SYMBOL_BID), tmp_str000035, 255, 0, 0);
   Gl_000024 = iTime(Fa_s_02, 0, 0);
   Il_009E34[Fa_i_01] = Gl_000024;
   }}}}}}} 
   if (Lb_FFFFFA == false) return; 
   tmp_str000039 = "SS";
   Gi_000024 = Ii_00D778;
   tmp_str00003A = Fa_s_03;
   tmp_str00003B = Fa_s_02;
   Gi_000026 = OrdersTotal();
   Gb_000027 = false;
   if (Gi_000026 >= 0) {
   do { 
   if (OrderSelect(Gi_000026, 0, 0) && OrderMagicNumber() == Gi_000024) {
   tmp_str00003C = OrderComment();
   if (StringSubstr(tmp_str00003C, 0, 2) == tmp_str000039) {
   if (OrderSymbol() == tmp_str00003B || OrderSymbol() == tmp_str00003A) {
   
   Gb_000027 = true;
   break;
   }}}
   Gi_000026 = Gi_000026 - 1;
   } while (Gi_000026 >= 0); 
   }
   else Gb_000027 = false;
   
   if (Gb_000027) return; 
   tmp_str00003D = "SS";
   Gi_000028 = Ii_00D778;
   tmp_str00003E = Fa_s_03;
   tmp_str00003F = Fa_s_02;
   Gi_000029 = HistoryTotal() - 1;
   Gi_00002A = Gi_000029;
   Gb_000029 = false;
   if (Gi_000029 >= 0) {
   do { 
   if (OrderSelect(Gi_00002A, 0, 1)) {
   if (OrderSymbol() == tmp_str00003F || OrderSymbol() == tmp_str00003E) {
   
   if (OrderCloseTime() < Il_009C98) {
   Gb_000029 = false;
   break;
   }
   if (OrderMagicNumber() == Gi_000028) {
   tmp_str000040 = OrderComment();
   if (StringSubstr(tmp_str000040, 0, 2) == tmp_str00003D) {
   tmp_str000041 = OrderSymbol();
   if (iBarShift(tmp_str000041, 0, OrderOpenTime(), true) == 0
   || iBarShift(OrderSymbol(), 0, OrderCloseTime(), true) == 0) {
   
   Gb_000029 = true;
   break;
   }}}}}
   Gi_00002A = Gi_00002A - 1;
   } while (Gi_00002A >= 0); 
   }
   else Gb_000029 = false;
   
   if (Gb_000029) return; 
   if (Ib_009C80 != true) { 
   tmp_str000043 = "LS";
   Gi_00002B = Ii_00D778;
   tmp_str000044 = Fa_s_03;
   tmp_str000045 = Fa_s_02;
   Gi_00002C = OrdersTotal();
   Gb_00002D = false;
   if (Gi_00002C >= 0) {
   do { 
   if (OrderSelect(Gi_00002C, 0, 0) && OrderMagicNumber() == Gi_00002B) {
   tmp_str000046 = OrderComment();
   if (StringSubstr(tmp_str000046, 0, 2) == tmp_str000043) {
   if (OrderSymbol() == tmp_str000045 || OrderSymbol() == tmp_str000044) {
   
   Gb_00002D = true;
   break;
   }}}
   Gi_00002C = Gi_00002C - 1;
   } while (Gi_00002C >= 0); 
   }
   else Gb_00002D = false;
   
   if (Gb_00002D) return; 
   tmp_str000047 = "LS";
   Gi_00002E = Ii_00D778;
   tmp_str000048 = Fa_s_03;
   tmp_str000049 = Fa_s_02;
   Gi_00002F = HistoryTotal() - 1;
   Gi_000030 = Gi_00002F;
   Gb_00002F = false;
   if (Gi_00002F >= 0) {
   do { 
   if (OrderSelect(Gi_000030, 0, 1)) {
   if (OrderSymbol() == tmp_str000049 || OrderSymbol() == tmp_str000048) {
   
   if (OrderCloseTime() < Il_009C98) {
   Gb_00002F = false;
   break;
   }
   if (OrderMagicNumber() == Gi_00002E) {
   tmp_str00004A = OrderComment();
   if (StringSubstr(tmp_str00004A, 0, 2) == tmp_str000047) {
   tmp_str00004B = OrderSymbol();
   if (iBarShift(tmp_str00004B, 0, OrderOpenTime(), true) == 0
   || iBarShift(OrderSymbol(), 0, OrderCloseTime(), true) == 0) {
   
   Gb_00002F = true;
   break;
   }}}}}
   Gi_000030 = Gi_000030 - 1;
   } while (Gi_000030 >= 0); 
   }
   else Gb_00002F = false;
   
   if (Gb_00002F) return; 
   } 
   if (Il_00A7C8[Fa_i_01] == iTime(Fa_s_02, 0, 0)) return; 
   if (Fa_i_00 >= numeroStrumentiPossibili) return; 
   if (limitaIngressoNuoveOperazioniSeSuperatoDD != true) { 
   Gb_000032 = true;
   } 
   else { 
   if (tipoControlloFlottante == 0) { 
   Gd_000033 = valoreLimite;
   } 
   else { 
   Gd_000033 = ((AccountInfoDouble(ACCOUNT_BALANCE) * valoreLimite) / 100);
   } 
   Gd_000034 = 0;
   Gi_000035 = OrdersTotal() - 1;
   Gi_000036 = Gi_000035;
   if (Gi_000035 >= 0) { 
   do { 
   if (OrderSelect(Gi_000036, 0, 0) && OrderMagicNumber() >= MagicInp) { 
   Gi_000035 = OrderMagicNumber();
   Gi_000037 = MagicInp + 50;
   if (Gi_000035 < Gi_000037) { 
   Gd_000037 = OrderProfit();
   Gd_000037 = (Gd_000037 + OrderCommission());
   Gd_000034 = ((Gd_000037 + OrderSwap()) + Gd_000034);
   }} 
   Gi_000036 = Gi_000036 - 1;
   } while (Gi_000036 >= 0); 
   } 
   if ((Gd_000034 < 0) && (Gd_000034 < -Gd_000033)) {
   Gb_000032 = false;
   }
   else{
   Gb_000032 = true;
   }} 
   if (Gb_000032 == false) return; 
   tmp_str00004D = IntegerToString(MagicInp, 0, 32);
   tmp_str00004D = tmp_str00004D + "_newgrid";
   if (GlobalVariableGet(tmp_str00004D) == 0) return; 
   Ii_009CAC = Ii_009CAC + 1;
   tmp_str00004E = "SS_Master" + IntegerToString(Ii_009CAC, 0, 32);
   tmp_str00004F = Fa_s_03;
   tmp_str000050 = Fa_s_02;
   tmp_str000051 = Fa_s_02;
   func_1025(tmp_str000051, tmp_str000050, tmp_str00004F, Ii_00D778, 1, Id_009D18[Fa_i_01], SymbolInfoDouble(Fa_s_02, SYMBOL_BID), tmp_str00004E, 255, 0, 0);
   tmp_str000052 = "SS_Master" + IntegerToString(Ii_009CAC, 0, 32);
   tmp_str000053 = Fa_s_03;
   tmp_str000054 = Fa_s_02;
   tmp_str000055 = Fa_s_03;
   func_1025(tmp_str000055, tmp_str000054, tmp_str000053, Ii_00D778, 0, Id_009D4C[Fa_i_01], SymbolInfoDouble(Fa_s_03, SYMBOL_ASK), tmp_str000052, 16711680, 0, 0);
   Gl_000039 = iTime(Fa_s_02, 0, 0);
   Il_00A7C8[Fa_i_01] = Gl_000039;
   
}

void func_1032(int Fa_i_00, string Fa_s_01, string Fa_s_02)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   string tmp_str00000D;
   string tmp_str00000E;
   string tmp_str00000F;
   string tmp_str000010;
   string tmp_str000011;
   string tmp_str000012;
   string tmp_str000013;
   string tmp_str000014;
   string tmp_str000015;
   string tmp_str000016;
   string tmp_str000017;
   string tmp_str000018;
   string tmp_str000019;
   string tmp_str00001A;
   string tmp_str00001B;
   string tmp_str00001C;
   string tmp_str00001D;
   string tmp_str00001E;
   string tmp_str00001F;
   string tmp_str000020;
   string tmp_str000021;
   string tmp_str000022;
   string tmp_str000023;
   string tmp_str000024;
   string tmp_str000025;
   string tmp_str000026;
   string tmp_str000027;
   string tmp_str000028;
   string tmp_str000029;
   string tmp_str00002A;
   string tmp_str00002B;
   double Ld_FFFFF8;
   string Ls_FFFFE8;
   double Ld_FFFFE0;
   double Ld_FFFFD8;
   int Li_FFFFD4;
   int Li_FFFFD0;
   bool Lb_FFFFCF;
   double Ld_FFFFC0;
   double Ld_FFFFB8;
   double Ld_FFFFB0;
   double Ld_FFFFA8;
   bool Lb_FFFFA7;
   int Li_FFFFA0;
   bool Lb_FFFF9F;
   double Ld_FFFF90;
   double Ld_FFFF88;
   double Ld_FFFF80;
   double Ld_FFFF78;
   bool Lb_FFFF77;

   if (tipoPiramidazione == 0) return; 
   if (tipoPiramidazione != 1) { 
   if (tipoPiramidazione != 2) return; 
   } 
   Ld_FFFFF8 = 0;
   Ls_FFFFE8 = "";
   Ld_FFFFE0 = 0;
   Ld_FFFFD8 = 0;
   Li_FFFFD4 = 0;
   tmp_str000000 = "LS";
   tmp_str000001 = Fa_s_02;
   tmp_str000002 = Fa_s_01;
   Li_FFFFD4 = 0;
   Gi_000004 = OrdersTotal() - 1;
   Gi_000005 = Gi_000004;
   if (Gi_000004 >= 0) { 
   do { 
   if (OrderSelect(Gi_000005, 0, 0) && OrderMagicNumber() == Ii_00D778) { 
   if (OrderSymbol() == tmp_str000002 || OrderSymbol() == tmp_str000001) { 
   
   tmp_str000003 = OrderComment();
   if (StringSubstr(tmp_str000003, 0, 2) == tmp_str000000) { 
   if (OrderSymbol() == tmp_str000002) { 
   Li_FFFFD4 = Li_FFFFD4 + 1;
   } 
   if ((Ld_FFFFF8 == 0) && OrderSymbol() == tmp_str000002) { 
   tmp_str000004 = OrderSymbol();
   Ld_FFFFF8 = NormalizeDouble(OrderOpenPrice(), (int)SymbolInfoInteger(tmp_str000004, SYMBOL_DIGITS));
   Ld_FFFFE0 = NormalizeDouble(OrderLots(), 2);
   } 
   if ((Ld_FFFFD8 == 0) && OrderSymbol() == tmp_str000001) { 
   Ld_FFFFD8 = NormalizeDouble(OrderLots(), 2);
   }}}} 
   Gi_000005 = Gi_000005 - 1;
   } while (Gi_000005 >= 0); 
   } 
   Gb_000004 = (Ld_FFFFF8 != 0);
   if (Gb_000004) { 
   Gb_000004 = true;
   } 
   else { 
   Gb_000004 = false;
   } 
   if (Gb_000004) { 
   if (numeroMassimoPiramidazioni == 0 || Li_FFFFD4 < numeroMassimoPiramidazioni) { 
   
   Li_FFFFD0 = pointsDistanzaPiramidazione;
   if (numeroPiramidazioneStep2 != 0 && Li_FFFFD4 - 1 >= numeroPiramidazioneStep2 && Li_FFFFD4 - 1 < numeroPiramidazioneStep3) {
   Li_FFFFD0 = pointsDistanzaPiramidazioneStep2;
   }
   else{
   if (numeroPiramidazioneStep3 != 0 && Li_FFFFD4 - 1 >= numeroPiramidazioneStep3 && Li_FFFFD4 - 1 < numeroPiramidazioneStep4) {
   Li_FFFFD0 = pointsDistanzaPiramidazioneStep3;
   }
   else{
   if (numeroPiramidazioneStep4 != 0) { 
   Gi_000006 = Li_FFFFD4 - 1;
   if (Gi_000006 >= numeroPiramidazioneStep4) { 
   Li_FFFFD0 = pointsDistanzaPiramidazioneStep4;
   }}}} 
   Gd_000006 = (Ld_FFFFF8 - SymbolInfoDouble(Fa_s_01, SYMBOL_ASK));
   if ((Gd_000006 >= (Li_FFFFD0 * SymbolInfoDouble(Fa_s_01, SYMBOL_POINT))) != true) { 
   Gb_000006 = (Li_FFFFD0 == 0);
   } 
   Lb_FFFFCF = Gb_000006;
   Ld_FFFFC0 = Ld_FFFFE0;
   Ld_FFFFB8 = Ld_FFFFD8;
   if (tipoIncrementoSize != 0) { 
   if (tipoIncrementoSize == 1) { 
   Ld_FFFFC0 = (Ld_FFFFE0 * valoreIncremento);
   Ld_FFFFC0 = NormalizeDouble(Ld_FFFFC0, 2);
   Ld_FFFFB8 = (Ld_FFFFD8 * valoreIncremento);
   Ld_FFFFB8 = NormalizeDouble(Ld_FFFFB8, 2);
   } 
   else { 
   if (tipoIncrementoSize == 2) { 
   Ld_FFFFC0 = (Ld_FFFFC0 + valoreIncremento);
   Ld_FFFFC0 = NormalizeDouble(Ld_FFFFC0, 2);
   Ld_FFFFB8 = (Ld_FFFFB8 + valoreIncremento);
   Ld_FFFFB8 = NormalizeDouble(Ld_FFFFB8, 2);
   }} 
   Ld_FFFFB0 = SymbolInfoDouble(Fa_s_01, 34);
   if ((Ld_FFFFB0 <= SymbolInfoDouble(Fa_s_01, 35))) { 
   do { 
   if ((NormalizeDouble(Ld_FFFFB0, 2) >= Ld_FFFFC0)) { 
   Ld_FFFFC0 = NormalizeDouble(Ld_FFFFB0, 2);
   break; 
   } 
   Ld_FFFFB0 = (Ld_FFFFB0 + SymbolInfoDouble(Fa_s_01, 36));
   } while (Ld_FFFFB0 <= SymbolInfoDouble(Fa_s_01, 35)); 
   } 
   Ld_FFFFA8 = SymbolInfoDouble(Fa_s_02, 34);
   if ((Ld_FFFFA8 <= SymbolInfoDouble(Fa_s_02, 35))) { 
   do { 
   if ((NormalizeDouble(Ld_FFFFA8, 2) >= Ld_FFFFB8)) { 
   Ld_FFFFB8 = NormalizeDouble(Ld_FFFFA8, 2);
   break; 
   } 
   Ld_FFFFA8 = (Ld_FFFFA8 + SymbolInfoDouble(Fa_s_02, 36));
   } while (Ld_FFFFA8 <= SymbolInfoDouble(Fa_s_02, 35)); 
   }} 
   Lb_FFFFA7 = false;
   if (tipoPiramidazione == 2) { 
   tmp_str000005 = Fa_s_02;
   tmp_str000006 = Fa_s_01;
   if ((iCustom(tmp_str000006, 0, "AA_SpreadRatio_1.1", tmp_str000005, ea, periodoBollinger, deviazioneStandard, 4, 0) != 2147483647)) { 
   tmp_str000007 = Fa_s_02;
   tmp_str000008 = Fa_s_01;
   Gb_000006 = (iCustom(tmp_str000008, 0, "AA_SpreadRatio_1.1", tmp_str000007, ea, periodoBollinger, deviazioneStandard, 4, 0) != 0);
   } 
   if (Gb_000006) { 
   tmp_str000009 = "LS";
   Gi_000007 = Ii_00D778;
   tmp_str00000A = Fa_s_02;
   tmp_str00000B = Fa_s_01;
   Gi_000008 = OrdersTotal();
   Gb_000009 = false;
   if (Gi_000008 >= 0) {
   do { 
   if (OrderSelect(Gi_000008, 0, 0) && OrderMagicNumber() == Gi_000007) {
   tmp_str00000C = OrderComment();
   if (StringSubstr(tmp_str00000C, 0, 2) == tmp_str000009) {
   Gl_000009 = OrderOpenTime();
   tmp_str00000D = OrderSymbol();
   if (Gl_000009 >= iTime(tmp_str00000D, 0, 0)) {
   if (OrderSymbol() == tmp_str00000B || OrderSymbol() == tmp_str00000A) {
   
   Gb_000009 = true;
   break;
   }}}}
   Gi_000008 = Gi_000008 - 1;
   } while (Gi_000008 >= 0); 
   }
   else Gb_000009 = false;
   
   Gb_000006 = !Gb_000009;
   } 
   Lb_FFFFA7 = Gb_000006;
   } 
   else { 
   Lb_FFFFA7 = true;
   } 
   if (Lb_FFFFA7 && Lb_FFFFCF && Il_00B15C[Fa_i_00] != iTime(Fa_s_01, 0, 0) && Il_009E34[Fa_i_00] != iTime(Fa_s_01, 0, 0)) { 
   Ii_009CAC = Ii_009CAC + 1;
   tmp_str00000E = "LS_Pir" + IntegerToString(Ii_009CAC, 0, 32);
   tmp_str00000F = Fa_s_02;
   tmp_str000010 = Fa_s_01;
   tmp_str000011 = Fa_s_01;
   func_1025(tmp_str000011, tmp_str000010, tmp_str00000F, Ii_00D778, 0, Ld_FFFFC0, SymbolInfoDouble(Fa_s_01, SYMBOL_ASK), tmp_str00000E, 16711680, 0, 0);
   tmp_str000012 = "LS_Pir" + IntegerToString(Ii_009CAC, 0, 32);
   tmp_str000013 = Fa_s_02;
   tmp_str000014 = Fa_s_01;
   tmp_str000015 = Fa_s_02;
   func_1025(tmp_str000015, tmp_str000014, tmp_str000013, Ii_00D778, 1, Ld_FFFFB8, SymbolInfoDouble(Fa_s_02, SYMBOL_BID), tmp_str000012, 255, 0, 0);
   Gl_00000B = iTime(Fa_s_01, 0, 0);
   Il_00B15C[Fa_i_00] = Gl_00000B;
   }}} 
   Ld_FFFFF8 = 0;
   Ls_FFFFE8 = "";
   Ld_FFFFE0 = 0;
   Ld_FFFFD8 = 0;
   Li_FFFFD4 = 0;
   tmp_str000016 = "SS";
   tmp_str000017 = Fa_s_02;
   tmp_str000018 = Fa_s_01;
   Li_FFFFD4 = 0;
   Gi_000010 = OrdersTotal() - 1;
   Gi_000011 = Gi_000010;
   if (Gi_000010 >= 0) { 
   do { 
   if (OrderSelect(Gi_000011, 0, 0) && OrderMagicNumber() == Ii_00D778) { 
   if (OrderSymbol() == tmp_str000018 || OrderSymbol() == tmp_str000017) { 
   
   tmp_str000019 = OrderComment();
   if (StringSubstr(tmp_str000019, 0, 2) == tmp_str000016) { 
   if (OrderSymbol() == tmp_str000018) { 
   Li_FFFFD4 = Li_FFFFD4 + 1;
   } 
   if ((Ld_FFFFF8 == 0) && OrderSymbol() == tmp_str000018) { 
   tmp_str00001A = OrderSymbol();
   Ld_FFFFF8 = NormalizeDouble(OrderOpenPrice(), (int)SymbolInfoInteger(tmp_str00001A, SYMBOL_DIGITS));
   Ld_FFFFE0 = NormalizeDouble(OrderLots(), 2);
   } 
   if ((Ld_FFFFD8 == 0) && OrderSymbol() == tmp_str000017) { 
   Ld_FFFFD8 = NormalizeDouble(OrderLots(), 2);
   }}}} 
   Gi_000011 = Gi_000011 - 1;
   } while (Gi_000011 >= 0); 
   } 
   Gb_000010 = (Ld_FFFFF8 != 0);
   if (Gb_000010) { 
   Gb_000010 = true;
   } 
   else { 
   Gb_000010 = false;
   } 
   if (Gb_000010 == false) return; 
   if (numeroMassimoPiramidazioni != 0) { 
   if (Li_FFFFD4 >= numeroMassimoPiramidazioni) return; 
   } 
   Li_FFFFA0 = pointsDistanzaPiramidazione;
   if (numeroPiramidazioneStep2 != 0 && Li_FFFFD4 - 1 >= numeroPiramidazioneStep2 && Li_FFFFD4 - 1 < numeroPiramidazioneStep3) {
   Li_FFFFA0 = pointsDistanzaPiramidazioneStep2;
   }
   else{
   if (numeroPiramidazioneStep3 != 0 && Li_FFFFD4 - 1 >= numeroPiramidazioneStep3 && Li_FFFFD4 - 1 < numeroPiramidazioneStep4) {
   Li_FFFFA0 = pointsDistanzaPiramidazioneStep3;
   }
   else{
   if (numeroPiramidazioneStep4 != 0) { 
   Gi_000012 = Li_FFFFD4 - 1;
   if (Gi_000012 >= numeroPiramidazioneStep4) { 
   Li_FFFFA0 = pointsDistanzaPiramidazioneStep4;
   }}}} 
   Gd_000012 = (SymbolInfoDouble(Fa_s_01, SYMBOL_BID) - Ld_FFFFF8);
   if ((Gd_000012 >= (Li_FFFFA0 * SymbolInfoDouble(Fa_s_01, SYMBOL_POINT))) != true) { 
   Gb_000012 = (Li_FFFFA0 == 0);
   } 
   Lb_FFFF9F = Gb_000012;
   Ld_FFFF90 = Ld_FFFFE0;
   Ld_FFFF88 = Ld_FFFFD8;
   if (tipoIncrementoSize != 0) { 
   if (tipoIncrementoSize == 1) { 
   Ld_FFFF90 = (Ld_FFFFE0 * valoreIncremento);
   Ld_FFFF90 = NormalizeDouble(Ld_FFFF90, 2);
   Ld_FFFF88 = (Ld_FFFFD8 * valoreIncremento);
   Ld_FFFF88 = NormalizeDouble(Ld_FFFF88, 2);
   } 
   else { 
   if (tipoIncrementoSize == 2) { 
   Ld_FFFF90 = (Ld_FFFF90 + valoreIncremento);
   Ld_FFFF90 = NormalizeDouble(Ld_FFFF90, 2);
   Ld_FFFF88 = (Ld_FFFF88 + valoreIncremento);
   Ld_FFFF88 = NormalizeDouble(Ld_FFFF88, 2);
   }} 
   Ld_FFFF80 = SymbolInfoDouble(Fa_s_01, 34);
   if ((Ld_FFFF80 <= SymbolInfoDouble(Fa_s_01, 35))) { 
   do { 
   if ((NormalizeDouble(Ld_FFFF80, 2) >= Ld_FFFF90)) { 
   Ld_FFFF90 = NormalizeDouble(Ld_FFFF80, 2);
   break; 
   } 
   Ld_FFFF80 = (Ld_FFFF80 + SymbolInfoDouble(Fa_s_01, 36));
   } while (Ld_FFFF80 <= SymbolInfoDouble(Fa_s_01, 35)); 
   } 
   Ld_FFFF78 = SymbolInfoDouble(Fa_s_02, 34);
   if ((Ld_FFFF78 <= SymbolInfoDouble(Fa_s_02, 35))) { 
   do { 
   if ((NormalizeDouble(Ld_FFFF78, 2) >= Ld_FFFF88)) { 
   Ld_FFFF88 = NormalizeDouble(Ld_FFFF78, 2);
   break; 
   } 
   Ld_FFFF78 = (Ld_FFFF78 + SymbolInfoDouble(Fa_s_02, 36));
   } while (Ld_FFFF78 <= SymbolInfoDouble(Fa_s_02, 35)); 
   }} 
   Lb_FFFF77 = false;
   if (tipoPiramidazione == 2) { 
   tmp_str00001B = Fa_s_02;
   tmp_str00001C = Fa_s_01;
   if ((iCustom(tmp_str00001C, 0, "AA_SpreadRatio_1.1", tmp_str00001B, ea, periodoBollinger, deviazioneStandard, 5, 0) != 2147483647)) { 
   tmp_str00001D = Fa_s_02;
   tmp_str00001E = Fa_s_01;
   Gb_000012 = (iCustom(tmp_str00001E, 0, "AA_SpreadRatio_1.1", tmp_str00001D, ea, periodoBollinger, deviazioneStandard, 5, 0) != 0);
   } 
   if (Gb_000012) { 
   tmp_str00001F = "SS";
   Gi_000013 = Ii_00D778;
   tmp_str000020 = Fa_s_02;
   tmp_str000021 = Fa_s_01;
   Gi_000014 = OrdersTotal();
   Gb_000015 = false;
   if (Gi_000014 >= 0) {
   do { 
   if (OrderSelect(Gi_000014, 0, 0) && OrderMagicNumber() == Gi_000013) {
   tmp_str000022 = OrderComment();
   if (StringSubstr(tmp_str000022, 0, 2) == tmp_str00001F) {
   Gl_000015 = OrderOpenTime();
   tmp_str000023 = OrderSymbol();
   if (Gl_000015 >= iTime(tmp_str000023, 0, 0)) {
   if (OrderSymbol() == tmp_str000021 || OrderSymbol() == tmp_str000020) {
   
   Gb_000015 = true;
   break;
   }}}}
   Gi_000014 = Gi_000014 - 1;
   } while (Gi_000014 >= 0); 
   }
   else Gb_000015 = false;
   
   Gb_000012 = !Gb_000015;
   } 
   Lb_FFFF77 = Gb_000012;
   } 
   else { 
   Lb_FFFF77 = true;
   } 
   if (Lb_FFFF77 == false) return; 
   if (Lb_FFFF9F == false) return; 
   if (Il_00BAF0[Fa_i_00] == iTime(Fa_s_01, 0, 0)) return; 
   if (Il_00A7C8[Fa_i_00] == iTime(Fa_s_01, 0, 0)) return; 
   Ii_009CAC = Ii_009CAC + 1;
   tmp_str000024 = "SS_Pir" + IntegerToString(Ii_009CAC, 0, 32);
   tmp_str000025 = Fa_s_02;
   tmp_str000026 = Fa_s_01;
   tmp_str000027 = Fa_s_01;
   func_1025(tmp_str000027, tmp_str000026, tmp_str000025, Ii_00D778, 1, Ld_FFFF90, SymbolInfoDouble(Fa_s_01, SYMBOL_BID), tmp_str000024, 255, 0, 0);
   tmp_str000028 = "SS_Pir" + IntegerToString(Ii_009CAC, 0, 32);
   tmp_str000029 = Fa_s_02;
   tmp_str00002A = Fa_s_01;
   tmp_str00002B = Fa_s_02;
   func_1025(tmp_str00002B, tmp_str00002A, tmp_str000029, Ii_00D778, 0, Ld_FFFF88, SymbolInfoDouble(Fa_s_02, SYMBOL_ASK), tmp_str000028, 16711680, 0, 0);
   Gl_000017 = iTime(Fa_s_01, 0, 0);
   Il_00BAF0[Fa_i_00] = Gl_000017;
   
}

void func_1033(int Fa_i_00, string Fa_s_01, string Fa_s_02)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   string tmp_str00000D;
   string tmp_str00000E;
   string tmp_str00000F;
   string tmp_str000010;
   string tmp_str000011;
   string tmp_str000012;
   string tmp_str000013;
   string tmp_str000014;
   string tmp_str000015;
   string tmp_str000016;
   string tmp_str000017;
   string tmp_str000018;
   string tmp_str000019;
   string tmp_str00001A;
   string tmp_str00001B;
   double Ld_FFFFF8;
   double Ld_FFFFF0;
   int Li_FFFFEC;
   int Li_FFFFE8;
   int Li_FFFFE4;
   double Ld_FFFFD8;
   double Ld_FFFFD0;

   Ld_FFFFF8 = 0;
   Ld_FFFFF0 = 0;
   Li_FFFFEC = 0;
   Li_FFFFE8 = 0;
   Li_FFFFE4 = OrdersTotal() - 1;
   if (Li_FFFFE4 >= 0) { 
   do { 
   if (OrderSelect(Li_FFFFE4, 0, 0) && OrderMagicNumber() == Ii_00D778) { 
   if (OrderSymbol() == Fa_s_01 || OrderSymbol() == Fa_s_02) { 
   
   tmp_str000000 = OrderComment();
   if (StringSubstr(tmp_str000000, 0, 2) == "LS") { 
   Gd_000000 = OrderProfit();
   Gd_000000 = (Gd_000000 + OrderSwap());
   Ld_FFFFF8 = ((Gd_000000 + OrderCommission()) + Ld_FFFFF8);
   if (OrderSymbol() == Fa_s_01) { 
   Li_FFFFEC = Li_FFFFEC + 1;
   }} 
   tmp_str000001 = OrderComment();
   if (StringSubstr(tmp_str000001, 0, 2) == "SS") { 
   Gd_000000 = OrderProfit();
   Gd_000000 = (Gd_000000 + OrderSwap());
   Ld_FFFFF0 = ((Gd_000000 + OrderCommission()) + Ld_FFFFF0);
   if (OrderSymbol() == Fa_s_01) { 
   Li_FFFFE8 = Li_FFFFE8 + 1;
   }}}} 
   Li_FFFFE4 = Li_FFFFE4 - 1;
   } while (Li_FFFFE4 >= 0); 
   } 
   Ld_FFFFD8 = targetValuta;
   Ld_FFFFD0 = targetValuta;
   if (numeroMediazioniAttivazioneSecondoTarget != 0) { 
   if (Li_FFFFEC > numeroMediazioniAttivazioneSecondoTarget) { 
   Ld_FFFFD8 = targetValuta2;
   } 
   if (Li_FFFFE8 > numeroMediazioniAttivazioneSecondoTarget) { 
   Ld_FFFFD0 = targetValuta2;
   }} 
   if ((targetValuta != 0)) { 
   if ((Ld_FFFFF8 >= Ld_FFFFD8)) { 
   tmp_str000002 = "Chiusura target valuta : " + DoubleToString(Ld_FFFFF8, 2);
   tmp_str000003 = "LS";
   tmp_str000004 = Fa_s_02;
   tmp_str000005 = Fa_s_01;
   func_1034(tmp_str000005, tmp_str000004, Ii_00D778, tmp_str000003, tmp_str000002);
   } 
   if ((Ld_FFFFF0 >= Ld_FFFFD0)) { 
   tmp_str000006 = "Chiusura target valuta : " + DoubleToString(Ld_FFFFF0, 2);
   tmp_str000007 = "SS";
   tmp_str000008 = Fa_s_02;
   tmp_str000009 = Fa_s_01;
   func_1034(tmp_str000009, tmp_str000008, Ii_00D778, tmp_str000007, tmp_str000006);
   }} 
   if ((stopValuta != 0)) { 
   Gd_000000 = -stopValuta;
   if ((Ld_FFFFF8 <= Gd_000000)) { 
   tmp_str00000A = "Chiusura stoploss valuta : " + DoubleToString(Ld_FFFFF8, 2);
   tmp_str00000B = "LS";
   tmp_str00000C = Fa_s_02;
   tmp_str00000D = Fa_s_01;
   func_1034(tmp_str00000D, tmp_str00000C, Ii_00D778, tmp_str00000B, tmp_str00000A);
   } 
   Gd_000000 = -stopValuta;
   if ((Ld_FFFFF0 <= Gd_000000)) { 
   tmp_str00000E = "Chiusura stoploss valuta : " + DoubleToString(Ld_FFFFF0, 2);
   tmp_str00000F = "SS";
   tmp_str000010 = Fa_s_02;
   tmp_str000011 = Fa_s_01;
   func_1034(tmp_str000011, tmp_str000010, Ii_00D778, tmp_str00000F, tmp_str00000E);
   }} 
   if ((trailingStopStart == 0)) return; 
   if ((Ld_FFFFF8 >= trailingStopStart)) { 
   Gd_000001 = (Ld_FFFFF8 - Id_00C484[Fa_i_00]);
   if ((Gd_000001 > (trailingStop + trailingStep))) { 
   Gd_000001 = (Ld_FFFFF8 - trailingStop);
   Id_00C484[Fa_i_00] = Gd_000001;
   tmp_str000012 = IntegerToString(Ii_00D778, 0, 32);
   tmp_str000012 = tmp_str000012 + " aggiornato trailing LS : ";
   tmp_str000012 = tmp_str000012 + DoubleToString(Id_00C484[Fa_i_00], 2);
   Print(tmp_str000012);
   }} 
   if ((Id_00C484[Fa_i_00] != 0) && (Ld_FFFFF8 <= Id_00C484[Fa_i_00])) { 
   tmp_str000013 = "Trailing Stop LS";
   tmp_str000014 = "LS";
   tmp_str000015 = Fa_s_02;
   tmp_str000016 = Fa_s_01;
   func_1034(tmp_str000016, tmp_str000015, Ii_00D778, tmp_str000014, tmp_str000013);
   Id_00C484[Fa_i_00] = 0;
   } 
   if ((Ld_FFFFF0 >= trailingStopStart)) { 
   Gd_000007 = (Ld_FFFFF0 - Id_00CE18[Fa_i_00]);
   if ((Gd_000007 > (trailingStop + trailingStep))) { 
   Gd_000007 = (Ld_FFFFF0 - trailingStop);
   Id_00CE18[Fa_i_00] = Gd_000007;
   tmp_str000017 = IntegerToString(Ii_00D778, 0, 32);
   tmp_str000017 = tmp_str000017 + " aggiornato trailing SS : ";
   tmp_str000017 = tmp_str000017 + DoubleToString(Id_00CE18[Fa_i_00], 2);
   Print(tmp_str000017);
   }} 
   if ((Id_00CE18[Fa_i_00] == 0)) return; 
   if ((Ld_FFFFF0 > Id_00CE18[Fa_i_00])) return; 
   tmp_str000018 = "Trailing Stop SS";
   tmp_str000019 = "SS";
   tmp_str00001A = Fa_s_02;
   tmp_str00001B = Fa_s_01;
   func_1034(tmp_str00001B, tmp_str00001A, Ii_00D778, tmp_str000019, tmp_str000018);
   Id_00CE18[Fa_i_00] = 0;
   
}

void func_1034(string Fa_s_00, string Fa_s_01, int Fa_i_02, string Fa_s_03, string Fa_s_04)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   int Li_FFFFFC;
   int Li_FFFFF8;
   int Li_FFFFF4;

   Li_FFFFFC = OrdersTotal();
   if (Li_FFFFFC < 0) return; 
   do { 
   if (OrderSelect(Li_FFFFFC, 0, 0) && OrderMagicNumber() == Fa_i_02) { 
   tmp_str000000 = OrderComment();
   if (StringSubstr(tmp_str000000, 0, 2) == Fa_s_03) { 
   if (OrderSymbol() == Fa_s_00 || OrderSymbol() == Fa_s_01) { 
   
   Li_FFFFF8 = 0;
   do { 
   RefreshRates();
   if (OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 20, 255) != true) { 
   Gi_000002 = GetLastError();
   Li_FFFFF4 = Gi_000002;
   tmp_str000001 = "";
   tmp_str000002 = Fa_s_04;
   tmp_str000003 = Fa_s_01;
   tmp_str000004 = Fa_s_00;
   func_1016(Fa_i_02, tmp_str000004, tmp_str000003, tmp_str000002, tmp_str000001, Gi_000002);
   } 
   else { 
   tmp_str000005 = Fa_s_04;
   tmp_str000006 = Fa_s_01;
   tmp_str000007 = Fa_s_00;
   if (utilizzaAllarmiModificaOrdini == false) break; 
   tmp_str000008 = tmp_str000005 + " ";
   tmp_str000008 = tmp_str000008 + Is_009CA0;
   tmp_str000008 = tmp_str000008 + " ";
   tmp_str000008 = tmp_str000008 + tmp_str000007;
   tmp_str000008 = tmp_str000008 + "/";
   tmp_str000008 = tmp_str000008 + tmp_str000006;
   tmp_str000008 = tmp_str000008 + " on TF ";
   tmp_str000008 = tmp_str000008 + Is_009C88;
   tmp_str000008 = tmp_str000008 + " with ID ";
   tmp_str000008 = tmp_str000008 + DoubleToString(Fa_i_02, 0);
   tmp_str000008 = tmp_str000008 + "";
   Alert(tmp_str000008);
   if (IsTesting()) break; 
   tmp_str000009 = tmp_str000005 + " ";
   tmp_str000009 = tmp_str000009 + Is_009CA0;
   tmp_str000009 = tmp_str000009 + " ";
   tmp_str000009 = tmp_str000009 + tmp_str000007;
   tmp_str000009 = tmp_str000009 + "/";
   tmp_str000009 = tmp_str000009 + tmp_str000006;
   tmp_str000009 = tmp_str000009 + " on TF ";
   tmp_str000009 = tmp_str000009 + Is_009C88;
   tmp_str000009 = tmp_str000009 + " with ID ";
   tmp_str000009 = tmp_str000009 + DoubleToString(Fa_i_02, 0);
   tmp_str000009 = tmp_str000009 + "";
   SendNotification(tmp_str000009);
   tmp_str00000A = tmp_str000005 + " ";
   tmp_str00000A = tmp_str00000A + Is_009CA0;
   tmp_str00000A = tmp_str00000A + " ";
   tmp_str00000A = tmp_str00000A + tmp_str000007;
   tmp_str00000A = tmp_str00000A + "/";
   tmp_str00000A = tmp_str00000A + tmp_str000006;
   tmp_str00000A = tmp_str00000A + " on TF ";
   tmp_str00000A = tmp_str00000A + Is_009C88;
   tmp_str00000A = tmp_str00000A + " with ID ";
   tmp_str00000A = tmp_str00000A + DoubleToString(Fa_i_02, 0);
   tmp_str00000A = tmp_str00000A + "";
   tmp_str00000B = tmp_str000005 + tmp_str000007;
   tmp_str00000B = tmp_str00000B + "/";
   tmp_str00000B = tmp_str00000B + tmp_str000006;
   tmp_str00000B = tmp_str00000B + " TF ";
   tmp_str00000B = tmp_str00000B + Is_009C88;
   tmp_str00000B = tmp_str00000B + " with ID (Magic Number) ";
   tmp_str00000B = tmp_str00000B + DoubleToString(Ii_00D778, 0);
   SendMail(tmp_str00000B, tmp_str00000A);
   break; 
   } 
   Li_FFFFF8 = Li_FFFFF8 + 1;
   } while (Li_FFFFF8 < 10); 
   }}} 
   Li_FFFFFC = Li_FFFFFC - 1;
   } while (Li_FFFFFC >= 0); 
   
}

void func_1035(string Fa_s_00)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   int Li_FFFFFC;
   int Li_FFFFF8;
   int Li_FFFFF4;

   Li_FFFFFC = OrdersTotal();
   if (Li_FFFFFC < 0) return; 
   do { 
   if (OrderSelect(Li_FFFFFC, 0, 0)) { 
   Li_FFFFF8 = 0;
   do { 
   RefreshRates();
   if (OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 20, 255) != true) { 
   Gi_000002 = GetLastError();
   Li_FFFFF4 = Gi_000002;
   tmp_str000000 = "";
   tmp_str000001 = Fa_s_00;
   tmp_str000002 = "";
   tmp_str000003 = "";
   func_1016(MagicInp, tmp_str000003, tmp_str000002, tmp_str000001, tmp_str000000, Gi_000002);
   } 
   else { 
   tmp_str000004 = Fa_s_00;
   if (utilizzaAllarmiModificaOrdini == false) break; 
   tmp_str000005 = tmp_str000004 + " ";
   tmp_str000005 = tmp_str000005 + Is_009CA0;
   tmp_str000005 = tmp_str000005 + " ";
   tmp_str000005 = tmp_str000005 + "";
   tmp_str000005 = tmp_str000005 + "/";
   tmp_str000005 = tmp_str000005 + "";
   tmp_str000005 = tmp_str000005 + " on TF ";
   tmp_str000005 = tmp_str000005 + Is_009C88;
   tmp_str000005 = tmp_str000005 + " with ID ";
   tmp_str000005 = tmp_str000005 + DoubleToString(MagicInp, 0);
   tmp_str000005 = tmp_str000005 + "";
   Alert(tmp_str000005);
   if (IsTesting()) break; 
   tmp_str000006 = tmp_str000004 + " ";
   tmp_str000006 = tmp_str000006 + Is_009CA0;
   tmp_str000006 = tmp_str000006 + " ";
   tmp_str000006 = tmp_str000006 + "";
   tmp_str000006 = tmp_str000006 + "/";
   tmp_str000006 = tmp_str000006 + "";
   tmp_str000006 = tmp_str000006 + " on TF ";
   tmp_str000006 = tmp_str000006 + Is_009C88;
   tmp_str000006 = tmp_str000006 + " with ID ";
   tmp_str000006 = tmp_str000006 + DoubleToString(MagicInp, 0);
   tmp_str000006 = tmp_str000006 + "";
   SendNotification(tmp_str000006);
   tmp_str000007 = tmp_str000004 + " ";
   tmp_str000007 = tmp_str000007 + Is_009CA0;
   tmp_str000007 = tmp_str000007 + " ";
   tmp_str000007 = tmp_str000007 + "";
   tmp_str000007 = tmp_str000007 + "/";
   tmp_str000007 = tmp_str000007 + "";
   tmp_str000007 = tmp_str000007 + " on TF ";
   tmp_str000007 = tmp_str000007 + Is_009C88;
   tmp_str000007 = tmp_str000007 + " with ID ";
   tmp_str000007 = tmp_str000007 + DoubleToString(MagicInp, 0);
   tmp_str000007 = tmp_str000007 + "";
   tmp_str000008 = tmp_str000004 + "";
   tmp_str000008 = tmp_str000008 + "/";
   tmp_str000008 = tmp_str000008 + "";
   tmp_str000008 = tmp_str000008 + " TF ";
   tmp_str000008 = tmp_str000008 + Is_009C88;
   tmp_str000008 = tmp_str000008 + " with ID (Magic Number) ";
   tmp_str000008 = tmp_str000008 + DoubleToString(Ii_00D778, 0);
   SendMail(tmp_str000008, tmp_str000007);
   break; 
   } 
   Li_FFFFF8 = Li_FFFFF8 + 1;
   } while (Li_FFFFF8 < 10); 
   } 
   Li_FFFFFC = Li_FFFFFC - 1;
   } while (Li_FFFFFC >= 0); 
   
}

void func_1036(string Fa_s_00, string Fa_s_01)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   string tmp_str00000D;
   string tmp_str00000E;
   string tmp_str00000F;
   string tmp_str000010;
   string tmp_str000011;
   string tmp_str000012;
   string tmp_str000013;
   string tmp_str000014;
   string tmp_str000015;
   string tmp_str000016;
   string tmp_str000017;
   string tmp_str000018;
   string tmp_str000019;
   string tmp_str00001A;
   string tmp_str00001B;
   string tmp_str00001C;
   string tmp_str00001D;
   string tmp_str00001E;
   string tmp_str00001F;

   if (utilizzaChiusuraBandaCentrale == false) return; 
   tmp_str000000 = "LS";
   Gi_000000 = Ii_00D778;
   tmp_str000001 = Fa_s_01;
   tmp_str000002 = Fa_s_00;
   Gi_000001 = OrdersTotal();
   Gb_000002 = false;
   if (Gi_000001 >= 0) {
   do { 
   if (OrderSelect(Gi_000001, 0, 0) && OrderMagicNumber() == Gi_000000) {
   tmp_str000003 = OrderComment();
   if (StringSubstr(tmp_str000003, 0, 2) == tmp_str000000) {
   if (OrderSymbol() == tmp_str000002 || OrderSymbol() == tmp_str000001) {
   
   Gb_000002 = true;
   break;
   }}}
   Gi_000001 = Gi_000001 - 1;
   } while (Gi_000001 >= 0); 
   }
   else Gb_000002 = false;
   
   if (Gb_000002) { 
   tmp_str000004 = "LS";
   Gi_000003 = Ii_00D778;
   tmp_str000005 = Fa_s_01;
   tmp_str000006 = Fa_s_00;
   Gd_000004 = 0;
   Gi_000005 = OrdersTotal();
   if (Gi_000005 >= 0) { 
   do { 
   if (OrderSelect(Gi_000005, 0, 0) && OrderMagicNumber() == Gi_000003) { 
   tmp_str000007 = OrderComment();
   if (StringSubstr(tmp_str000007, 0, 2) == tmp_str000004) { 
   if (OrderSymbol() == tmp_str000006 || OrderSymbol() == tmp_str000005) { 
   
   Gd_000006 = OrderProfit();
   Gd_000006 = (Gd_000006 + OrderSwap());
   Gd_000004 = ((Gd_000006 + OrderCommission()) + Gd_000004);
   }}} 
   Gi_000005 = Gi_000005 - 1;
   } while (Gi_000005 >= 0); 
   } 
   if ((Gd_000004 > 0)) { 
   tmp_str000008 = Fa_s_01;
   tmp_str000009 = Fa_s_00;
   Gd_000006 = iCustom(tmp_str000009, 0, "AA_SpreadRatio_1.1", tmp_str000008, ea, periodoBollinger, deviazioneStandard, 0, 1);
   tmp_str00000A = Fa_s_01;
   tmp_str00000B = Fa_s_00;
   if ((Gd_000006 > iCustom(tmp_str00000B, 0, "AA_SpreadRatio_1.1", tmp_str00000A, ea, periodoBollinger, deviazioneStandard, 3, 1))) { 
   tmp_str00000C = "Chiusura su banda centrale ";
   tmp_str00000D = "LS";
   tmp_str00000E = Fa_s_01;
   tmp_str00000F = Fa_s_00;
   func_1034(tmp_str00000F, tmp_str00000E, Ii_00D778, tmp_str00000D, tmp_str00000C);
   }}} 
   tmp_str000010 = "SS";
   Gi_000007 = Ii_00D778;
   tmp_str000011 = Fa_s_01;
   tmp_str000012 = Fa_s_00;
   Gd_000008 = 0;
   Gi_000009 = OrdersTotal();
   if (Gi_000009 >= 0) { 
   do { 
   if (OrderSelect(Gi_000009, 0, 0) && OrderMagicNumber() == Gi_000007) { 
   tmp_str000013 = OrderComment();
   if (StringSubstr(tmp_str000013, 0, 2) == tmp_str000010) { 
   if (OrderSymbol() == tmp_str000012 || OrderSymbol() == tmp_str000011) { 
   
   Gd_00000A = OrderProfit();
   Gd_00000A = (Gd_00000A + OrderSwap());
   Gd_000008 = ((Gd_00000A + OrderCommission()) + Gd_000008);
   }}} 
   Gi_000009 = Gi_000009 - 1;
   } while (Gi_000009 >= 0); 
   } 
   if ((Gd_000008 <= 0)) return; 
   tmp_str000014 = "SS";
   Gi_00000A = Ii_00D778;
   tmp_str000015 = Fa_s_01;
   tmp_str000016 = Fa_s_00;
   Gi_00000B = OrdersTotal();
   Gb_00000C = false;
   if (Gi_00000B >= 0) {
   do { 
   if (OrderSelect(Gi_00000B, 0, 0) && OrderMagicNumber() == Gi_00000A) {
   tmp_str000017 = OrderComment();
   if (StringSubstr(tmp_str000017, 0, 2) == tmp_str000014) {
   if (OrderSymbol() == tmp_str000016 || OrderSymbol() == tmp_str000015) {
   
   Gb_00000C = true;
   break;
   }}}
   Gi_00000B = Gi_00000B - 1;
   } while (Gi_00000B >= 0); 
   }
   else Gb_00000C = false;
   
   if (Gb_00000C == false) return; 
   tmp_str000018 = Fa_s_01;
   tmp_str000019 = Fa_s_00;
   Gd_00000D = iCustom(tmp_str000019, 0, "AA_SpreadRatio_1.1", tmp_str000018, ea, periodoBollinger, deviazioneStandard, 0, 1);
   tmp_str00001A = Fa_s_01;
   tmp_str00001B = Fa_s_00;
   if ((Gd_00000D >= iCustom(tmp_str00001B, 0, "AA_SpreadRatio_1.1", tmp_str00001A, ea, periodoBollinger, deviazioneStandard, 3, 1))) return; 
   tmp_str00001C = "Chiusura su banda centrale ";
   tmp_str00001D = "SS";
   tmp_str00001E = Fa_s_01;
   tmp_str00001F = Fa_s_00;
   func_1034(tmp_str00001F, tmp_str00001E, Ii_00D778, tmp_str00001D, tmp_str00001C);
   
}

bool func_1038(string Fa_s_00, string Fa_s_01)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   bool Lb_FFFFFF;
   int Li_FFFFC4;
   string Ls_FFFFB8;
   double Ld_FFFFB0;
   bool Lb_FFFFAF;
   double Ld_FFFFA0;
   int Li_FFFF9C;
   string Ls_FFFF90;
   int Li_FFFF8C;

   if (numeroMassimoOperazioniInGain == 0) { 
   Lb_FFFFFF = true;
   return Lb_FFFFFF;
   } 
   double Ld_FFFFC8[];
   Li_FFFFC4 = HistoryTotal() - 1;
   if (Li_FFFFC4 >= 0) { 
   do { 
   if (OrderSelect(Li_FFFFC4, 0, 1) && OrderMagicNumber() == Ii_00D778) { 
   if (OrderSymbol() == Fa_s_00 || OrderSymbol() == Fa_s_01) {
   
   if (OrderCloseTime() < Il_009C98) break; 
   tmp_str000000 = TimeToString(OrderCloseTime(), 1);
   if (tmp_str000000 != TimeToString(TimeCurrent(), 1)) break; 
   if (OrderSymbol() == Fa_s_00) { 
   Ls_FFFFB8 = OrderComment();
   Gd_000000 = OrderProfit();
   Gd_000000 = (Gd_000000 + OrderCommission());
   Ld_FFFFB0 = (Gd_000000 + OrderSwap());
   Lb_FFFFAF = false;
   tmp_str000000 = Ls_FFFFB8;
   tmp_str000001 = Fa_s_01;
   Gd_000001 = 0;
   Gi_000002 = HistoryTotal() - 1;
   Gi_000003 = Gi_000002;
   if (Gi_000002 >= 0) { 
   do { 
   if (OrderSelect(Gi_000003, 0, 1) && OrderMagicNumber() == Ii_00D778) { 
   if (OrderCloseTime() < Il_009C98) break; 
   if (OrderSymbol() == tmp_str000001 && tmp_str000000 == OrderComment()) { 
   Gd_000002 = OrderProfit();
   Gd_000002 = (Gd_000002 + OrderSwap());
   Gd_000001 = ((Gd_000002 + OrderCommission()) + Gd_000001);
   Lb_FFFFAF = true;
   }} 
   Gi_000003 = Gi_000003 - 1;
   } while (Gi_000003 >= 0); 
   } 
   Ld_FFFFA0 = Gd_000001;
   if (Lb_FFFFAF) { 
   ArrayResize(Ld_FFFFC8, (ArraySize(Ld_FFFFC8) + 1), 0);
   Gd_000002 = (Ld_FFFFB0 + Gd_000001);
   Gi_000004 = ArraySize(Ld_FFFFC8) - 1;
   Ld_FFFFC8[Gi_000004] = Gd_000002;
   }}}} 
   Li_FFFFC4 = Li_FFFFC4 - 1;
   } while (Li_FFFFC4 >= 0); 
   } 
   Li_FFFF9C = 0;
   Ls_FFFF90 = "";
   Li_FFFF8C = 0;
   if (ArraySize(Ld_FFFFC8) > 0) { 
   do { 
   tmp_str000002 = DoubleToString(Ld_FFFFC8[Li_FFFF8C], 2);
   tmp_str000002 = tmp_str000002 + "\n";
   Ls_FFFF90 = Ls_FFFF90 + tmp_str000002;
   if ((Ld_FFFFC8[Li_FFFF8C] > 0)) { 
   Li_FFFF9C = Li_FFFF9C + 1;
   } 
   else { 
   Li_FFFF9C = Li_FFFF9C - 1;
   } 
   Li_FFFF8C = Li_FFFF8C + 1;
   } while (Li_FFFF8C < ArraySize(Ld_FFFFC8)); 
   } 
   if (Li_FFFF9C >= numeroMassimoOperazioniInGain) { 
   Lb_FFFFFF = true;
   ArrayFree(Ld_FFFFC8);
   return Lb_FFFFFF;
   } 
   Lb_FFFFFF = false;
   ArrayFree(Ld_FFFFC8);
   
   return Lb_FFFFFF;
}

void func_1042(string Fa_s_00, string Fa_s_01)
{
   string tmp_str000000;
   string tmp_str000001;
   string tmp_str000002;
   string tmp_str000003;
   string tmp_str000004;
   string tmp_str000005;
   string tmp_str000006;
   string tmp_str000007;
   string tmp_str000008;
   string tmp_str000009;
   string tmp_str00000A;
   string tmp_str00000B;
   string tmp_str00000C;
   string tmp_str00000D;
   int Li_FFFFFC;
   string Ls_FFFFF0;
   int Li_FFFFEC;

   if (minutiControlloPosizioniDisallineate == 0) return; 
   Li_FFFFFC = OrdersTotal() - 1;
   if (Li_FFFFFC < 0) return; 
   do { 
   if (OrderSelect(Li_FFFFFC, 0, 0) && OrderMagicNumber() == Ii_00D778) { 
   if (OrderSymbol() == Fa_s_00 || OrderSymbol() == Fa_s_01) { 
   
   Ls_FFFFF0 = OrderComment();
   Li_FFFFEC = OrderTicket();
   Gl_000000 = TimeCurrent();
   Gl_000000 = Gl_000000 - OrderOpenTime();
   Gi_000001 = minutiControlloPosizioniDisallineate * 60;
   Gl_000001 = Gi_000001;
   if (Gl_000000 >= Gl_000001) { 
   tmp_str000000 = Ls_FFFFF0;
   tmp_str000001 = Fa_s_01;
   tmp_str000002 = Fa_s_00;
   Gi_000001 = 0;
   Gi_000002 = OrdersTotal() - 1;
   Gi_000003 = Gi_000002;
   if (Gi_000002 >= 0) {
   do { 
   if (OrderSelect(Gi_000003, 0, 0)) {
   if (OrderMagicNumber() == Ii_00D778) {
   if (OrderSymbol() == tmp_str000002 || OrderSymbol() == tmp_str000001) {
   
   OrderComment();
   if (OrderComment() == tmp_str000000) {
   Gi_000001 = Gi_000001 + 1;
   }}}}
   else{
   Print("Errore selezione ordine");
   Gb_000002 = true;
   break;
   }
   Gi_000003 = Gi_000003 - 1;
   } while (Gi_000003 >= 0); 
   }
   if (Gi_000001 >= 2) { 
   Gb_000002 = true;
   } 
   else { 
   Gb_000002 = false;
   } 
   if (Gb_000002 == false && OrderSelect(Li_FFFFFC, 0, 0) && OrderTicket() == Li_FFFFEC) { 
   if (OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 20, 255) != true) { 
   tmp_str000004 = "";
   tmp_str000005 = "Chiusura ordine per disallineamento posizioni";
   tmp_str000006 = Fa_s_01;
   tmp_str000007 = Fa_s_00;
   func_1016(Ii_00D778, tmp_str000007, tmp_str000006, tmp_str000005, tmp_str000004, GetLastError());
   } 
   else { 
   tmp_str000008 = Fa_s_01;
   tmp_str000009 = Fa_s_00;
   if (utilizzaAllarmiModificaOrdini) { 
   tmp_str00000A = "Chiusura ordine per disallineamento posizioni ";
   tmp_str00000A = "Chiusura ordine per disallineamento posizioni " + Is_009CA0;
   tmp_str00000A = tmp_str00000A + " ";
   tmp_str00000A = tmp_str00000A + tmp_str000009;
   tmp_str00000A = tmp_str00000A + "/";
   tmp_str00000A = tmp_str00000A + tmp_str000008;
   tmp_str00000A = tmp_str00000A + " on TF ";
   tmp_str00000A = tmp_str00000A + Is_009C88;
   tmp_str00000A = tmp_str00000A + " with ID ";
   tmp_str00000A = tmp_str00000A + DoubleToString(Ii_00D778, 0);
   tmp_str00000A = tmp_str00000A + "";
   Alert(tmp_str00000A);
   if (IsTesting() != true) { 
   tmp_str00000B = "Chiusura ordine per disallineamento posizioni ";
   tmp_str00000B = "Chiusura ordine per disallineamento posizioni " + Is_009CA0;
   tmp_str00000B = tmp_str00000B + " ";
   tmp_str00000B = tmp_str00000B + tmp_str000009;
   tmp_str00000B = tmp_str00000B + "/";
   tmp_str00000B = tmp_str00000B + tmp_str000008;
   tmp_str00000B = tmp_str00000B + " on TF ";
   tmp_str00000B = tmp_str00000B + Is_009C88;
   tmp_str00000B = tmp_str00000B + " with ID ";
   tmp_str00000B = tmp_str00000B + DoubleToString(Ii_00D778, 0);
   tmp_str00000B = tmp_str00000B + "";
   SendNotification(tmp_str00000B);
   tmp_str00000C = "Chiusura ordine per disallineamento posizioni ";
   tmp_str00000C = "Chiusura ordine per disallineamento posizioni " + Is_009CA0;
   tmp_str00000C = tmp_str00000C + " ";
   tmp_str00000C = tmp_str00000C + tmp_str000009;
   tmp_str00000C = tmp_str00000C + "/";
   tmp_str00000C = tmp_str00000C + tmp_str000008;
   tmp_str00000C = tmp_str00000C + " on TF ";
   tmp_str00000C = tmp_str00000C + Is_009C88;
   tmp_str00000C = tmp_str00000C + " with ID ";
   tmp_str00000C = tmp_str00000C + DoubleToString(Ii_00D778, 0);
   tmp_str00000C = tmp_str00000C + "";
   tmp_str00000D = "Chiusura ordine per disallineamento posizioni" + tmp_str000009;
   tmp_str00000D = tmp_str00000D + "/";
   tmp_str00000D = tmp_str00000D + tmp_str000008;
   tmp_str00000D = tmp_str00000D + " TF ";
   tmp_str00000D = tmp_str00000D + Is_009C88;
   tmp_str00000D = tmp_str00000D + " with ID (Magic Number) ";
   tmp_str00000D = tmp_str00000D + DoubleToString(Ii_00D778, 0);
   SendMail(tmp_str00000D, tmp_str00000C);
   }}}}}}} 
   Li_FFFFFC = Li_FFFFFC - 1;
   } while (Li_FFFFFC >= 0); 
   
}


