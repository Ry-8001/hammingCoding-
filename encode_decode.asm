;Faruk Orak 		150180058
;Ramazan Yetişmiş	150190708

segment .bss
rows resb 8		;rows data are is used for represent the H matrix row by row in a single array
;uninitialized data

segment .text
global encode_data, decode_data

encode_data:
   push ebp						;call condition
   mov  ebp,esp    				;base pointer <---- stack pointer

	sub esp, 16					;allocate 4 local variable
 
    mov dword [ebp-4], 0		;var1 = higher part (ebp-4)
    mov dword [ebp-8], 0		;var2 = matrix multiplication result(ebp-8)
    mov dword [ebp-12], 0		;var3 general loop iterator ebp-12
    mov dword [ebp-16], 0		;var4 = WHOLE_CALCULATION iterator
    
WHOLE_CALCULATION:

	xor ecx, ecx				;clear ecx
	mov ecx,[ebp-16]			;take var4(whole_Calculation iterator)
	mov eax, [ebp + 8]			;take the address 
	shr ecx, 1					;divide by 2
    mov eax, [eax + ecx]		;take the i'th input byte
    mov ecx,[ebp-16]			;restore whole_calculation iterator in register
	and ecx, 1					;check whether odd or even
	cmp ecx, 0					;cmp to even
	je CNT 						;jump to CNT if it is even
	and	eax, 0b00001111			;take lower part	
	jmp CONTINUE
CNT:			
    and eax, 0b011110000		;take higher part
    shr eax, 4					;4 times shift left

CONTINUE: 
    mov [ebp-4], eax		;var1 = higher part (ebp-4)				
   
    xor ecx, ecx			;clear ecx
    xor eax, eax			;clear eax
GENERAL_LOOP:
	mov [ebp-12], eax		;store eax to var3
	mov eax, [ebp + 28]		;take Hmr address				
    xor edx, edx			;clear edx
;for loop
    mov ecx, 0				;i = 0
    
;TAKE THE RELATED COLUMN'S TRANSPOSE
FOR1:		
	shl edx, 1				;shift left edx
	add ecx, [ebp-12]		;add row count
    or edx, [eax+ecx]		;take the bit
    sub ecx, [ebp-12]		;sub row count
    add ecx, 16				;iterate 1 step
    cmp ecx, 64				;check for limit
    jne FOR1
;END

;DATA COLUMN MULTIPLICATION
	xor eax, eax		;clear
	mov eax, [ebp-4]	;take var1
	and eax, edx		;bitwise and
;END
	
;COUNT BITS AND STORE THE RESULT
	xor ecx,ecx				;clear ecx
	and eax, 0b01111		;clear other unnecessary bits to prevent errors
	mov edx,eax				;take eax to edx
BEGIN:
	mov eax,edx				;take edx to eax
	and eax, 0b0001			;check for least significant bit
	shr edx, 1				;shift to right 1 step
	cmp eax, 0				;check for 1 or 0
	je NEXT
	inc ecx					;ecx++
NEXT:
	cmp edx, 0				;check edx 0 or what
	je EXIT
	jmp BEGIN
EXIT:
	and ecx, 0b0001 		;result of the first multiplication
	mov eax, [ebp-8]		;take var2
	and eax, 0b01111		;clear other unnecessary bits
	shl eax, 1				;shift to leftby one
	or eax, ecx				;add the bit
	mov [ebp-8], eax		;store the interior result
;END

	mov eax, [ebp-12]		;take general loop iterator
	add eax,4				;iterate it by onw step
	cmp eax, 16				;check for limit
	jne	GENERAL_LOOP


	

	mov eax, [ebp-8]		;take result
	mov edx, [ebp-4]		;take stored data
	and eax, 0b00001111		;clear upper parts		
	and edx, 0b00001111		;clear upper parts
	shl edx, 4				;open 4 bit space to right
	or edx, eax				;add the parity
	
	mov eax, [ebp+16]		;take result array address
	mov ecx, [ebp-16]		;take index
	mov [eax+ecx], edx		;store data
	
	inc ecx					;iterate by one step
	mov [ebp-16], ecx		;store it back
	cmp ecx, [ebp+20]		;check for limit
	jne WHOLE_CALCULATION
	
	xor eax, eax			;clear eax
    mov esp, ebp			;return condition
    pop  ebp				;return condition				
    ret

	
decode_data:

	push ebp					;call condition
   	mov  ebp,esp    			;base pointer <---- stack pointer

	sub esp, 24					;allocate local variables
 
    mov dword [ebp-4], 0		;var1 = data
    mov dword [ebp-8], 0		;var2 = matrix multiplication result(ebp-8)
    mov dword [ebp-12], 0		;var3 = general loop iterator ebp-12 and used for fill rows as row count variable
    mov dword [ebp-16], 0		;var4 = WHOLE_CALCULATION2 iterator
	mov dword [ebp-20], 0		;var5 = total number of errors
	mov dword [ebp-24], 0		;var6 = iterator to fill rows data area

	xor eax,eax					;clear eax
	xor ecx,ecx					;clear ecx
	xor edx,edx					;clear edx
;FILL rows data area from H matrix to use later
FILL_GENERAL_LOOP:
	mov eax, [ebp+24]		;take H address
	mov ecx, 0				;fill ecx 0
FILL_FOR:
	mov edx, [ebp-8]		;take interior result
	shl edx,1				;1 shift left
	add ecx, [ebp-12]		;add row index
    or edx, [eax+ecx]		;take the bit
    sub ecx, [ebp-12]		;subtract row index
	and edx, 0b01111		;clear other unnecessary bits
	mov [ebp-8], edx		;store interior result
	add ecx, 4				;ecx++
	cmp ecx, 16				;check for limit
	jne FILL_FOR

	mov eax, [ebp-8]		;take final result
	mov edx, [ebp-24]		;data area index
	mov [rows+edx], eax		;store the result
	inc edx					;data iterator++
	mov [ebp-24], edx		;store iterator

	mov eax, [ebp-12]		;take general loop itearator
	add eax, ecx			;++
	mov [ebp-12], eax		;store it back

	cmp eax, 128			;check for limit
	jne FILL_GENERAL_LOOP
;FILL END

	mov dword [ebp-8], 0	;clear var2
    mov dword [ebp-12], 0	;clear var3

	xor eax,eax				;clear eax
	xor ecx,ecx				;clear ecx
	xor edx,edx				;clear edx

WHOLE_CALCULATION2:

	mov eax, [ebp+8]		;take encodedBytes address
	mov ecx, [ebp-16]		;take iterator
	mov eax,[eax+ecx]		;take first data
	mov [ebp-4], eax		;store the data

    xor ecx, ecx			;clear ecx
    xor eax, eax			;clear eax
GENERAL_LOOP2:
	mov [ebp-12], eax		;store general_loop2 counter back
	mov eax, [ebp + 24]		;take H address				
    xor edx, edx			;clear edx
;for loop
    mov ecx, 0				;i = 0
    
;TAKE THE RELATED COLUMN'S TRANSPOSE
FOR2:		
	shl edx, 1				;shift left edx
	add ecx, [ebp-12]		;add the row index
    or edx, [eax+ecx]		;take the bit
    sub ecx, [ebp-12]		;subtract the row index
    add ecx, 16				;iterate 1 step
    cmp ecx, 128			;check for limit
    jne FOR2
;END

;DATA COLUMN MULTIPLICATION
	xor eax, eax		;clear
	mov eax, [ebp-4]	;take var1
	and eax, edx		;bitwise and
;END
	
;COUNT BITS AND STORE THE RESULT	
	xor ecx,ecx				;clear ecx
	and eax, 0b011111111	;clear other bits
	mov edx,eax				;edx <- eax
BEGIN2:
	mov eax,edx				;eax <- edx
	and eax, 0b0001			;clear other unnecessary bits
	shr edx, 1				;shift edx to right by one
	cmp eax, 0				;check whether even or odd
	je NEXT2
	inc ecx					;iterate by one
NEXT2:
	cmp edx, 0				;check the number 0 or what
	je EXIT2
	jmp BEGIN2
EXIT2:
	and ecx, 0b0001 		;result of the first multiplication
	mov eax, [ebp-8]		;take var2
	and eax, 0b011111111	;clear other unnecessary bits
	shl eax, 1				;shit to left by one
	or eax, ecx				;add the bit
	mov [ebp-8], eax		;store the interior result
;END
	mov eax, [ebp-12]		;take loop iterator
	add eax,4				;iterate 1 right 
	cmp eax, 16				;check for column count
	jne	GENERAL_LOOP2

;LOOK FOR ERROR AND INCREMENT ERROR COUNTER
	xor eax,eax				;clear eax
	mov eax, [ebp-8]		;take result
	and eax, 0b01111		;clear other bits
	cmp eax, 0b0000			;check for error
	je DONT_INC				;if it's 0, then don't increment. There is no error.
;IF THERE IS ERROR BEGIN

	xor edx, edx			;clear edx
	or edx, 0b10000000		;generate error code
	mov ecx, 0				;start iterator
CORRECTION_LOOP:
	push edx				;push edx to stack to prevent data lose
	mov edx,[rows+ecx]		;take parity from rows
	and edx, 0b01111		;clear other unnecessary bits
	cmp eax,edx				;look for syndrome
	jne SYNDROME_NOT_EQU
	pop edx					;take edx back from stack
	xor eax,eax				;clear eax
	xor ecx,ecx				;clear ecx
	mov eax,[ebp+32]		;take error status array's address
	mov ecx,[ebp-16]		;take whole_calculation iterator
	mov [eax+ecx], edx		;store error status
	xor eax, eax			;clear eax
	mov eax,[ebp-4]			;take the encoded data
	xor eax,edx				;correct encoded data
	mov [ebp-4], eax		;store corrected data

	jmp CORRECTION_LOOP_NEXT
SYNDROME_NOT_EQU:
	pop edx					;take edx back from stack
	shr edx, 1				;shift edx by 1 to right
	inc ecx					;inc counter for rows
	jmp CORRECTION_LOOP
CORRECTION_LOOP_NEXT:
	mov eax, [ebp-20]		;take error counter 
	inc eax					;increment it	
	mov [ebp-20],eax		;store it again
	jmp SKIP_ERROR_STATUS
;IF THERE IS ERROR END
DONT_INC:
	xor eax,eax				;clear
	xor ecx,ecx				;clear
	mov eax,[ebp+32]		;take error status array's address
	mov ecx,[ebp-16]		;take whole_calculation iterator
	mov dword [eax+ecx], 0	;store error status
SKIP_ERROR_STATUS:
	mov eax, [ebp-16]		;take whole_calculation iterator
	and eax, 0b001			;look for whether odd or even
	cmp eax, 1				;if it is odd
	je ADD_TO_RIGHT
	xor ecx,ecx				;clear ecx
	mov ecx, [ebp-16]		;take whole caluclation iterator
	shr ecx, 1				;divide by 2 
	mov edx, [ebp+16]		;take the address of decodedBytes
	mov eax, [ebp-4]		;take encoded data
	and eax, 0b011110000	;take data part
	mov [edx+ecx], eax		;store data
	jmp EXIT_ADDING
ADD_TO_RIGHT:
	xor ecx,ecx				;clear ecx
	mov ecx, [ebp-16]		;take whole caluclation iterator
	shr ecx, 1				;divide by 2 
	mov edx, [ebp+16]		;take the address of decodedBytes
	mov eax, [ebp-4]		;take encoded data
	and eax, 0b011110000	;take data part
	shr eax, 4				;shift to right 4 times
	or eax, [edx+ecx]		;add to current data
	mov [edx+ecx], eax		;store the data
EXIT_ADDING:
	xor ecx,ecx				;clear ecx
	mov ecx, [ebp-16]		;take the whole_calculation iterator
	inc ecx					;ecx++
	mov [ebp-16], ecx		;store iterator
	mov eax, [ebp+12]		;take nEncodedBytes
	cmp ecx,eax				;look for limit
	jne WHOLE_CALCULATION2
;END

	mov eax, [ebp-20]		;return error count

	mov esp, ebp			;return condition
	pop  ebp				;return condition
    ret
