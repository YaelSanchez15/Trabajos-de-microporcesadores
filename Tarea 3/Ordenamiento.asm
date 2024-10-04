;Programa que genera 20 numeros random y ordena de forma ascendente o descendente
;dependiendo de lo que se elija y al terminar, se puede repetir el programa o
;terminar, se muestran los mensajes de eleccion, los numeros generados y los
;numeros ordenados en un LCD

;-------------------------------
;main
;-------------------------------
	.org 0000h
	ld sp, 27ffh	;stack
	ld a, 89h	;definiendo los puertos: A=In, B=In y C=Out
	out (cw), a
	ld hl, texto		;coloca el texto de la variable texto
	call colocar_texto
	ld b, 20		;contador (numero de numeros a generar)
	ld hl, numero
	call rand8_LCG		;subrutina que genera los numeros
	ld hl, numero
	call colocar_texto	;Coloca el numero generado en la pantalla
	ld d, 20
	ld hl, numero
	ld (direccion), hl
	call ordenar		;ordena los numeros en orden ascendente
	ld hl, texto2		;apunta a la direccion de la variable texto2
	call colocar_texto	;coloca el texto de la variable texto2
	ld hl, texto3
	call colocar_texto	;coloca el texto de la variable texto3
	ld hl, texto4
	call colocar_texto	;coloca el texto de la variable texto4
	ld d, 20		;conttador
	ld hl, numero
	ld (direccion), hl
	call opciones		;seleccion de ascendente o descendente
	ld hl, texto5
	call colocar_texto	;coloca el texto de la variable texto5
	ld hl, texto6
	call colocar_texto	;coloca el texto de la variable texto6
	ld hl, texto7
	call colocar_texto	;coloca el texto de la variable texto7
	call repetir		;se decide si se repite el programa o no
	ld hl, texto8
	call colocar_texto	;coloca el texto de la variable texto8
	halt
	.end



;-----------------------------
;Subrutinas
;-----------------------------
colocar_texto:
	ld a, (hl)
	cp '&'		;cuando en el texto hay un & termina
	jp z, end2
	out (lcd), a	;coloca lo que hay en a en el lcd
	inc hl		;dirige a la siguiente posicion de memoria
	jp colocar_texto

end2:
	ret

rand8_LCG:		;genera los numeros ramdom
       	ld a, r
       	ld c,a
       	add a,a
       	add a,c
       	add a,a
       	add a,a
       	add a,c
       	add a,82
	srl a		;Solo se queda con los ultimos 4 bits
	srl a
	srl a
	srl a
	add a, 30h	;Suma 30 para convertir a ASCII
	cp 3Ah		;Compara si se supera el 39H (el 9 el ascii)
	jp nc, ajustar
	inc hl
       	ld (hl),a	;Carga el valor a la direccion que apunta hl
	dec b
	jp nz, rand8_LCG ;Si aun no se colocan los 20 numeros se repite

	ret
ajustar:
	sub 6h		;Como hay 4 bits el numero maximo es 3F (15+30H) por lo que resto 6 para colocar en el rango (30H-39H)
	inc hl
       	ld (hl),a	;Carga el valor a la direccion que apunta hl
	dec b
	jp nz, rand8_LCG	;Si aun no se colocan los 20 numeros se repite


       	ret


ordenar:
	ld hl, (direccion)	;Apunto a la direccion donde se guardaran los numeros
	ld e, 20		;contador

ascendente:
	ld a, (hl)		;carga en a lo que hay en la dirreccion a la que apunta hl
	inc hl			;pasamos a la siguinte direccion de memoria
	ld b, (hl)		;carga en b lo que hay en la direccion a la que apunta hl
	dec e			;reduce el contador
	jp z, reinicio
	cp b			;compara a con b
	jp nc, intercambio	;si a es mayor a b va a intercambio
	jp ascendente		;si el contador no ha llegado a cero se repite

intercambio:		;intercambia valores en las posiciones de memoria
	ld (hl), a
	dec hl
	ld (hl), b
	inc hl
	jp ascendente

reinicio:		;Apunta al inicio para volver a comparar
	dec d
	jp z, end3
	jp ordenar

end3: ret

opciones:
	in a, (teclado)	;coloca en a lo ingresado por el teclado
	cp 41h		;Compara si lo ingresado en a es un A
	jp z, mostrar_as
	cp 44h		;compara si lo ingresado en a es una B
	jp z, mostrar_des
	jp opciones	;si no es ninguna de las opciones anteriores se repite

mostrar_as:
	ld hl, (direccion)	;apunta a la primera direccion donde esta guardado el numero
loop
	ld a, (hl)		;carga en a lo que hay en la direccion a la que apunta hl
	out (lcd), a		;muestra el valor de a en el LCD
	inc hl			;pasa a la siguiente direccion
	dec d			;decrementa el contador
	jp z, end4		;si el contador llega a cero va a end4
	jp loop
end4:
	ret

mostrar_des:
	ld hl, (direccion)	;apunta a la primera direccion donde esta guardado el numero
	ld e, 19		;contador
final:				;coloca el apuntador a la ultima posicion (donde esta el ultimo numero)
	inc hl
	dec e
	jp nz, final

loop2
	ld a, (hl)		;carga en a lo que hay en la direccion a la que apunta hl
	out (lcd), a		;muestra el valor de a en el LCD
	dec hl			;pasa a la posicion anterior de memoria
	dec d			;decrementa el contador
	jp z, end5		;si el contador es cero se direge a end5
	jp loop2
end5:
	ret

repetir:
	in a, (teclado)		;Coloca en a lo ingresado en el teclado
	cp 53h			;compra si es una S
	jp z, final2
	cp 4eh			;compara si es una N
	jp z, final3
	jp repetir


final2:
	jp 0000h		;Comienza de nuevo el programa
final3:
	ret
;-----------------------------
;datos
;-----------------------------
 	.org 2000h
numero	.db "1         "
numero2	.db "           &"
direccion .db "        "
texto	.db "Num. Generando:&"
cw	.equ 03h
lcd	.equ 00h
teclado	.equ 02h
texto2	.db " Como ordenar? &"
texto3	.db " (A)Ascendente &"
texto4	.db "(D)Descendente &"
texto5 	.db " Repetir? &"
texto6	.db " (S)Si &"
texto7	.db " (N)No &"
texto8	.db " Terminado &"


