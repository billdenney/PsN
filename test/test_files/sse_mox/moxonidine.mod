$PROB MOXONIDINE PK ANALYSIS 
$INPUT ID VISI XAT2=DROP DGRP DOSE
       FLAG=DROP ONO=DROP XIME=DROP DVO=DROP NEUY=DROP
       SCR=DROP AGE SEX NYHA WT
       COMP=DROP ACE DIG DIU NUMB=DROP
       TAD=DROP TIME VIDD=DROP CRCL AMT
       SS II VID CMT=DROP CONO=DROP
       DV EVID=DROP OVID=DROP 
$DATA moxonidine.dta IGNORE=@
$ABBREVIATED DERIV2 = NO COMRES = 6
$SUBROUTINES ADVAN2 TRANS1
$PK
;----------IOV--------------------
   VIS3               = 0
   IF(VISI.EQ.3) VIS3 = 1
   VIS8               = 0
   IF(VISI.EQ.8) VIS8 = 1
   KPLAG = VIS3*ETA(4)+VIS8*ETA(5)

   TVCL  = THETA(1)
   TVV   = THETA(2)
   TVKA  = THETA(3)

   CL    = TVCL*EXP(ETA(1))
   V     = TVV*EXP(ETA(2))
   KA    = TVKA*EXP(ETA(3))
   LAG   = THETA(4)
   PHI   = LOG(LAG/(1-LAG))
   ALAG1 = EXP(PHI+KPLAG)/(1+EXP(PHI+KPLAG))
   K     = CL/V
   S2    = V

$ERROR

     IPRED = LOG(.025)
     W     = THETA(5)
     IF(F.GT.0) IPRED = LOG(F)
     IRES  = IPRED-DV
     IWRES = IRES/W
     Y     = IPRED+ERR(1)*W

$THETA (0,27.5) (0,13) (0,0.2) (0,.1) (0,.23) 
$OMEGA BLOCK(2) .3 .1 .3
$OMEGA BLOCK(1) .3
$OMEGA BLOCK(1) .3
$OMEGA BLOCK(1) SAME
$SIGMA 1 FIX
$EST MAXEVALS = 9990 PRINT = 10
;$COV



