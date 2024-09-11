;Considerando que el sistema solo tiene memoria EEPROM(segmento para código),escribir un
;algoritmo (programa)en lenguaje ensambladorque calcule la raíz cuadrada de un número
;entero, sin signo, de 8 bits.El número, del que se obtendrá su raíz cuadrada debe ser
;dado en BCD (decimal),en el registro B;de tal maneraque podremos obtener la raíz cuadrada
;de números en el rango de 010 a 9910, dados en decimal. EL resultado (solo la parte
;entera), debe ser depositado (en decimal) en el registro C.

	.org 0000
	ld b, 9 ;numero del que se obtendra la raiz
	ld a, b
	cp 0	;si b es 0 la raiz es cero
	jp z, numcero_o_uno
	cp 1	;si b es 1 la raiz es 1
	jp z, numcero_o_uno
	ld h, 10 ;limite superior (la raiz de 99 no es mayor a 10)
	ld l, 1  ;limite inferior

obtencion_numero:
	ld a, h
	cp l
	jp c, end3
	ld a, l
	add a, h
	srl a    ;resultado

;inicio del contador

	ld e, 1
	ld d, a
	ld c, a

calcular_cuadrado:

	ld a, c
	add a, d ;elevando el numero al cuadrado mediante sumas
	inc e
	ld c, a
	ld a, d
	cp e
	jp z, comparacion
	jp calcular_cuadrado

comparacion:

	ld a, c
	cp b	;comparando si el numero al cuadrado es igual al numero ingresado
	jp z, end2
	jp nc, mayor
	jp c, menor

menor:
	ld l, d
	inc l	;incremento del limite inferior
	jp obtencion_numero

mayor:
	ld h, d
	dec h	;decremento del limite superior
	jp obtencion_numero

numcero_o_uno:
	ld c, a
	halt
	end
end3:
	ld c, h
	jp bcd
end2:
	ld c, d
	jp bcd

bcd:
	ld a,b
	ld l,0

encontrar_hexa:
	cp 10
	jr c, decimal
	sub 10
	inc l
	jr encontrar_hexa
decimal:
	sla l
	sla l
	sla l
	sla l
	or l
	ld b,a

	halt
	.end
