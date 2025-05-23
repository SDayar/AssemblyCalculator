			org		$4
vector_001	dc.l	Main
vector_000	dc.l	$ffb500
			;-----------------------;
			;Programmes principales	;
			;-----------------------;
			org		$500
Main		clr.l 	d1;Colonne 
			clr.l	d2;Ligne
			;--------Affichage de la demande de saisie----------
			movea.l	#Phr_saisie,a0
			jsr		Print;On affiche la phrase : "Veuillez....." avant de réinitialiser d1
			clr.l 	d1
			;-----------------
			
			;-------Saisie----------
			movea.l #sBuffer,a0
			move.l #600000,d3
			move.l #8000,d4
			addq.b	#2,d2; On saute à la deuxième ligne
			addq.b	#1,d1;On commence à la colonne 1
			jsr 	GetInput; On demande la saisie tout en affichant avant de réinitialiser d1
			clr.l 	d1
			;-----------------------
			;-----On détermine la valeur s'il y en a-----------
			jsr 	GetExpr
			
			;--------Affichage du mot 'Résultat' ou 'Erreur dans l'expression'-------
			bne		\ERROR_EXPR; Si GetEpxr, on affiche le message d'erreur
			movea.l	#Resultat,a0
			addq.b	#2,d2
			jsr 	Print; Sinon affiche 'Résultat' et le résultat tout en bas
			clr.l	d1
			;--------------------------------------------------------------;
			
			;-----------On convertit le résultat en chaine de str avant d'afficher la valeur tout en bas------------
			jsr		Itoa; a0 pointera sur BUFFER qui contiendra la valeur transformée
			addq.b	#2,d2;Ligne suivante
			jsr		Print
			illegal
			;-----------------------------------------------------------------
			
		
			
			
			
\ERROR_EXPR	;Si il y a une erreur dans la saisie de l'expression, on affiche le message d'erreur avant de quitter
			movea.l	#ERROR_MSG,a0
			addq.b	#2,d2;On saute à la ligne
			jsr 	Print
			illegal;On quitte le programme principale
			
			;-------------------;
			;Sous-programmes    ;
			;------------------;
			
;---------------------IsCharError-----------------------------;
loopIsCh	move.b	(a0)+,d1
			beq		\false_0; Si on arrive à 0, le mot est valide.
			cmpi	#'0',d1
			bhs		\loop2IsCh; On va vérifier dans loop2IsCh si le caractère est inférieur à '9', sinon on revient dans le programme
			jmp		\true;Le caractère est inférieur à '0', Z=1
			jmp		loopIsCh;On revient vers le loop
\loop2IsCh  cmpi	#'9',d1
			bhi		\true;Le caractère n'est pas un chiffre	
			jmp		\false;Le caractère est un chiffre, on met Z=0 et on revient dans loopIsCh		
\true		move.l	(a7)+,d1
			ori.b	#%000000100,ccr;On positionne le flag Z à 1, ce n'est pas un chiffre
			jmp		Depil_Quit;On dépile et on revient au programme principale
			
\false		andi.b	#%11111011,ccr;On positionne le flag Z à 0, c'est un chiffre
			jmp		loopIsCh;on retourne vers loop
			
\false_0	move.l	(a7)+,d1
			andi.b	#%11111011,ccr; On met le flag à 0 et on sort du sous- programme
			jmp		Depil_Quit
IsCharError	;Sortie -> Z=1 si la chaine ne contient pas que des chiffres, sinon Z=0
			;Registre intermédiaire : d1, valeur pointée par a0 à l'instant t
			movem.l	d1/a0,-(a7);J'empile a0 puis d1
			jmp		loopIsCh
;------------------------------------------------------------------;

;-----------------------IsMaxError---------------------------------;
IsMaxError	;Sortie -> Z=1 si val(a0) est non valable, Z=0 sinon.
			;Registres intermédiaires-> d1 et a1
			move.l	a0,-(a7);On empile la valeur de a0
			movem.l	d1/a1,-(a7);Puis d1/a1
			jsr		StrLen; a0 est empilé puis dépilé
			cmp		#5,d0
			bhi		\true;S'il y a plus de 5 chiffres, Z=1_
			blo		\false;S'il y a moins de 5 chiffres, Z=0
			movea.l	#MAX_NUMBER,a1;On assigne l'adresse de MAX_NUMBER à a1, puis on procède à la comparaison
			jmp		\CmparToMax
			
\true		ori.b	#%00000100,ccr;On positionne le flag Z à 1, ce n'est pas un chiffre valable
			movem.l	(a7)+,a1/d1; On dépile a1/d1
			jmp		Depil_Quit;On dépile le reste et on revient au programme principale
\false		andi.b	#%11111011,ccr;On positionne le flag Z à 0, c'est un chiffre valable
			movem.l	(a7)+,a1/d1;On dépile a1/d1
			jmp		Depil_Quit;On dépile le reste et on revient au programme principale	

\CmparToMax	move.b	(a0)+,d1
			tst.b	 d1
			bls		\false;Le nombre est valable
			cmp.b	(a1)+,d1;On compare le nombre au MAX=32767
			bhi		\true;Si le chiffre pointé est différent du chiffre pointé par MAX alors, on sort
			jmp		\CmparToMax
			
;----------------------------------------------------------------------

;--------------------Convert-------------------------------------------
Convert		;Sortie: d0.l qui contient la chaine convertie si aucune erreur survient(Z=1) sinon Z=0 et d0.l n'est pas modifié.

			move.l	a0,-(a7);On empile valeur de a0
			tst.b	(a0)
			beq		\false;Si la chaine est vide met Z=0.
			jsr		IsCharError
			beq		\false
			jsr 	IsMaxError
			beq		\false
			jsr 	Atoui
			ori.b	#%00000100,ccr; Z=1, la chaine est valide.
			jmp		Depil_Quit
			
			
			
			
\false		andi.b	#%11111011,ccr;On positionne le flag Z à 0, la chaine est vide ou non valide
			jmp		Depil_Quit;On dépile le reste et on revient au programme principale		
;-----------------------------------------------------------------------;

;-------------------------Print(Sortie vidéo)---------------------------
Print		movem.l	a0/d0-d1,-(a7);On empile  a0
			jmp		LoopPrint
LoopPrint	move.b	(a0)+,d0
			beq		\quit
			addq	#1,d1
			jsr		PrintChar
			jmp		LoopPrint
\quit		movem.l	(a7)+,d1/d0
			jmp		Depil_Quit
;-----------------------------------------------------------------------;
;-----------------------Next0p-------------------------------------------;
NextOp		;Valeur de sortie = a0.l: adresse mémoire du premier opérateur dans une chaine
			;Registre intermédiaire : d0 qui contient la donnée du registre pointée par a0 à l'instant t, a1 qui contiendra la chaine du nombre maximale sur 16 bits et d1 la donnée pointée par a1 à l'instant t
			movem.l	d0-d1/a1,-(a7);On empile les registres intermédiaires. 
			jmp		\NextCar
			
\NextCar   	lea		LISTE_OPERA,a1;On repositionne le pointeur de a1 vers le début de LISTE_OPERA
			move.b	(a0)+,d0; d0 contient la donnée d'entrée qui est pointée. 	
			beq		\quitNextOp;Il n'y a pas d'opérateur
			jmp		\IsOpera
\IsOpera	move.b	(a1)+,d1
			beq		\NextCar;On a testé avec tous les opérateur
			cmp		d0,d1
			beq		\quitNextOp; Un opérateur a été identifié
			jmp		\IsOpera
\quitNextOp	suba	#$1,a0
			movem.l	(a7)+,a1/d0-d1
			rts
;----------------------GetNum-------------------------------------------;
GetNum		;Sortie -> D0.l qui contient la valeur numérique dans une chaine d'opération s'il y en a, puis A0.l qui contient l'adresse du premier caractère du résultat soit l'opérateur
			;Registres intermédiaire -> [a1, a2], avec a1 qui pointe vers le premier caractère puis a2 vers l'opérateur. D1.L qui sauvegardera la valeur de l'opérateur.
			movem.l	d1/a1-a2,-(a7); a1 et a2 seront les bords de l'inntervalle
			movea.l	a0,a1;a1 est le début de la chaine
			jsr		NextOp
			movea.l	a0,a2;On copie l'adresse (éventuelle) de l'opérateur à a2
			move.b	(a2),d1; d1 contient le contenu pointée par a2
			tst.b	(a1)
			beq		\true;Si la valeur pointée est NULL, Z=1. Fin de chaine
			;Sinon,Z=1, d0.l sera la valeur de sortie t a0.l contiendra NextOp
			;Je remplace la valeur de a2 dans la chaine par NULL
			move.b	#0,(a2);On modifie le signe pointé par a2, par un 0 pour indiquer la fin de la chaine à transformer
			movea.l a1,a0; On place a1 à la première position de la chaine avant d'appeler convert
			jsr		Convert
			bne		\false;Si la convertion n'est pas valide, Z=0
			jmp		\true
\false		andi.b	#%11111011,ccr
			movea.l	a1,a0; a0 repointe vers le début de la chaine
			movem.l	(a7)+,a1-a2/d1;Si false, on dépile tout 
			rts
\true		move.b	d1,(a2);Je remplace la valeur nulle de a2 par sa valeur précédente
			movea.l	a2,a0; On copie l'adresse situé juste après le nombre converti
			movem.l	(a7)+,a1-a2/d1; On dépile tout sauf d0
			ori.b	#%00000100,ccr
			rts
;-----------------------------------------------------------------------;
;----------------------------GetExpr------------------------------------;
GetExpr		;Sortie->Z=0, il y a une erreur sur la conversion et D0.l est perdu, sinon Z=1 et D0.l renvoie la valeur de l'expression
			;Registres intermédiaires: d1.l qui contiendra le résultat final, d2.l qui servira à contenir l'opératur ou l'opérateur null
			movem.l	d1-d2,-(a7)
			jsr		GetNum
			bne		\false; On quitte le sous programme si GetNum renvoie false, Z=0
			move.l	d0,d1;Sinon on intialise d1.l par le permier nombre renvoyé par GetNum
			jmp		\LoopGetEx
\LoopGetEx	move.b	(a0)+,d2; Je récupère l'opérateur
			beq		\true;On sort de la boucle si on arrive à la fin, Z=1, et d0.l renvoie la valeur numérique
			jsr 	GetNum
			bne		\false;On sort de la boucle si GetNum renvoie Z=0. Donc Z=0 et d0.l est perdu	
			
\IsAdd		cmpi	#'+',d2
			bne		\IsMul
			add.l	d0,d1
			jmp		\LoopGetEx
\IsMul		cmpi	#'*',d2
			bne		\IsSub
			muls.l	d0,d1
			jmp		\LoopGetEx
\IsSub		cmpi	#'-',d2
			bne		\IsDiv
			sub		d0,d1
			jmp		\LoopGetEx
\IsDiv		cmpi	#'/',d2
			bne		\LoopGetEx
			cmpi	#0,d0
			beq		\false;Si on se retrouve avec une division par zéro,Z=0 et on quitte la calculatrice.
			divs	d0,d1
			jmp		\LoopGetEx
\true		move.l	d1,d0;On déplace la résultat final de d1 à d0
			movem.l	(a7)+,d1-d2
			ori.b	#%00000100,ccr
			rts
			
\false		andi.b	#%11111011,ccr
			movem.l	(a7)+,d1-d2
			rts
			
			
			
			
			
;------------------------------------------------------------------------;
;---------------------------Uitoa----------------------------------------;
Uitoa		;Entrée : d0.w, qui contient l'entier à transformer en une chaine de caractère
			;Sortie:  a0.l qui va pointer au premier caractère qui correspond à l'entier
			movem.w	d0/d1,-(a7)
			movea.l	#BUFFER,a0
			move.b	#0,(a0);On initialise le point d'arrêt
			jmp		\UitoaLoop
\UitoaLoop	divs.w	#10,d0
\RecupReste	swap	d0
			move.w	d0,d1
			addi.b	#$30,d1
			move.b	d1,-(a0)
			move.w	#0,d0
			swap	d0
			tst.w	d0
			beq		\QUIT
			jmp		\UitoaLoop
			
\QUIT		; Fin de caractère
			movem.w	(a7)+,d0/d1
			rts
			
			
			
;-----------------------------------------------------------------------;
;----------------------------Itoa----------------------------------------;
Itoa		tst.w	d0
			bmi		\CallAbsol
			jsr		Uitoa
			rts
\CallAbsol  jsr 	Absolue
			jsr		Uitoa
			suba	#$1,a0
			move.b	#'-',(a0)+
			suba	#$1,a0
			rts
;-----------------------------------------------------------------------;
		
;----------------------------Autres-------------------------------------;
StrLen		;Sortie = d0, nombre de caractères
			;Registre intermédiaire = d3 qui contiendra le caracrère pointé à l'instant t-1
			move.l	a0,-(a7)
			move.l	a1,-(a7)
			move.l	d3,-(a7)
			
			clr.l	d0
			
loopStrLen	move.b	(a1)+,d3
			beq		\quitStrLen
			addq.l	#1,d0
			bra		loopStrLen
			
\quitStrLen move.l	(a7)+,d3
			move.l	(a7)+,a1
			jmp		Depil_Quit
Atoui 		;Valeur de sortie d0 = nombre sur 16 bits
			;Registre intermédiaire= d1, valeur pointée par a0 à l'instant t
			movem.l	a0/d1,-(a7);On empile la valeur intermédiaire
			clr.l	d0;On réinitialise la valeur de sortie
			clr.l	d1;On réinitialise la valeur intermédiaire
			jmp		\loopAtoui
			rts

\loopAtoui	move.b	(a0)+,d1
			beq		\quit_sProg
			sub.b	#'0',d1
			mulu	#10,d0
			add.w	d1,d0; L'addition est réalisée sur 16 bits
			jmp		\loopAtoui
			
		
\quit_sProg	move.l	(a7)+,d1; Je dépile la valeur intermédiaire
			jmp		Depil_Quit

Absolue		NEG		d0	
			rts

Depil_Quit	move.l (a7)+,a0; Dépile a0 - la valeur d'entrée commmune
			rts;On revient vers le programme principale

PrintChar	incbin	"PrintChar.bin"	
GetInput 	incbin "GetInput.bin"		
			
			org		$2000
sBuffer		ds.b	60
BUFFER		ds.b	7
sTest 		dc.b	"1254+6",0
MAX_NUMBER	dc.b	"32767",0
LISTE_OPERA	dc.b	"+*-/",0
Phr_saisie	dc.b	"Veuillez saisir une expression : ",0
Resultat	dc.b	"Resultat : ",0
ERROR_MSG	dc.b	"Erreur dans l'expression",0
