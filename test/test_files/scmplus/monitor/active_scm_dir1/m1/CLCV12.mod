$PROBLEM    PHENOBARB SIMPLE MODEL
$INPUT      ID TIME AMT WGT APGR=DROP DV CV1 CV2=DROP CV3 CVD1=DROP
            CVD2 CVD3=DROP
$DATA      ../../pheno_ch.csv IGNORE=@
$SUBROUTINE ADVAN1 TRANS2
$PK

;;; CLCV1-DEFINITION START
CLCV1 = ( 1 + THETA(5)*(CV1 - 46.67))
;;; CLCV1-DEFINITION END

;;; CL-RELATION START
CLCOV=CLCV1
;;; CL-RELATION END


;;; VWGT-DEFINITION START
VWGT = ( 1 + THETA(4)*(WGT - 1.3))
;;; VWGT-DEFINITION END

;;; V-RELATION START
VCOV=VWGT
;;; V-RELATION END




      TVCL  = THETA(1)

TVCL = CLCOV*TVCL
      CL    = TVCL*EXP(ETA(1))

      TVV   = THETA(2)

TVV = VCOV*TVV
      V     = TVV*EXP(ETA(2))

      S1    = V
$ERROR


      
      W     = THETA(3)
      Y     = F+W*EPS(1)

      IPRED = F          ;  individual-specific prediction
      IRES  = DV-IPRED   ;  individual-specific residual
      IWRES = IRES/W     ;  individual-specific weighted residual

$THETA  (0,0.00603751)
$THETA  (0,1.32074)
$THETA  (0,2.87637)
$THETA  (-0.435,0.770805,1.429) ; VWGT1
$THETA  (-0.019,-1.9E-05,0.023) ; CLCV11
$OMEGA  0.177915
 0.0267252
$SIGMA  1  FIX
$ESTIMATION MAXEVAL=9999 SIGDIGITS=4 METHOD=CONDITIONAL
$COVARIANCE PRINT=E
;$TABLE ID TIME AMT WGT APGR DV NOPRINT FILE=sdtab2

