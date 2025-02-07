; scharr_dll.asm
; Kompilujemy w trybie x64 (Microsoft x64 calling convention)
.CODE

PUBLIC ASMScharrFunction

; Parametry:
;   RCX = pointer do bufora wejœciowego (inputImage)
;   RDX = pointer do bufora wyjœciowego (outputImage)
;   R8  = width (szerokoœæ obrazu)
;   R9  = height (wysokoœæ obrazu)
ASMScharrFunction PROC
    ; Zachowujemy rejestry, które bêdziemy u¿ywaæ
    push rsi
    push rdi
    push rbx
    push r12
    push r13
    push r14
    push r15
    ; Zachowujemy dodatkowo width i height – póŸniej je pobierzemy
    push r8      ; width
    push r9      ; height

    ; Skopiuj width do EDI (32-bit)
    mov edi, r8d

    ; SprawdŸ minimalne wymiary obrazu (musi byæ co najmniej 3x3)
    cmp r8d, 3
    jl ExitASM
    cmp r9d, 3
    jl ExitASM

    ; pêtla po wierszach – pomijamy pierwszy i ostatni (obrze¿a)
    mov r10d, 1          ; current y = 1
    mov r11d, r9d
    sub r11d, 1          ; y_max = height - 1

YLoop:
    cmp r10d, r11d
    jge LoopEnd

    ; pêtla po kolumnach – pomijamy pierwszy i ostatni
    mov r12d, 1          ; current x = 1
    mov r13d, r8d
    sub r13d, 1          ; x_max = width - 1

XLoop:
    cmp r12d, r13d
    jge XLoopEnd

    ; Zerujemy sumy dla kierunków X i Y
    xor r14d, r14d       ; sumX = 0
    xor r15d, r15d       ; sumY = 0

    ; ---------------------------
    ; Przetwarzamy 8 s¹siadów:
    ; S¹siedzi i ich wagi:
    ; (-1,-1): weightX = 3,   weightY = 3
    ; (-1, 0): weightX = 0,   weightY = 10
    ; (-1, 1): weightX = -3,  weightY = 3
    ; ( 0,-1): weightX = 10,  weightY = 0
    ; ( 0, 1): weightX = -10, weightY = 0
    ; ( 1,-1): weightX = 3,   weightY = -3
    ; ( 1, 0): weightX = 0,   weightY = -10
    ; ( 1, 1): weightX = -3,  weightY = -3
    ; ---------------------------

    ; --- S¹siad (-1, -1) ---
    mov eax, r10d
    add eax, -1           ; y + (-1)
    imul eax, edi         ; (y-1)*width
    mov ecx, r12d
    add ecx, -1           ; x + (-1)
    add eax, ecx          ; index = (y-1)*width + (x-1)
    movzx edx, byte ptr [rsi+rax] ; edx = pixel
    ; sumX += pixel * 3
    imul edx, 3
    add r14d, edx
    ; sumY += pixel * 3
    movzx edx, byte ptr [rsi+rax]
    imul edx, 3
    add r15d, edx

    ; --- S¹siad (-1, 0) ---
    mov eax, r10d
    add eax, -1
    imul eax, edi
    mov ecx, r12d
    ; x + 0
    add eax, ecx
    movzx edx, byte ptr [rsi+rax]
    ; sumX += pixel * 0 (pomijamy)
    ; sumY += pixel * 10
    imul edx, 10
    add r15d, edx

    ; --- S¹siad (-1, 1) ---
    mov eax, r10d
    add eax, -1
    imul eax, edi
    mov ecx, r12d
    add ecx, 1
    add eax, ecx
    movzx edx, byte ptr [rsi+rax]
    ; sumX += pixel * -3
    imul edx, -3
    add r14d, edx
    ; sumY += pixel * 3
    movzx edx, byte ptr [rsi+rax]
    imul edx, 3
    add r15d, edx

    ; --- S¹siad (0, -1) ---
    mov eax, r10d
    ; y + 0
    imul eax, edi
    mov ecx, r12d
    add ecx, -1
    add eax, ecx
    movzx edx, byte ptr [rsi+rax]
    ; sumX += pixel * 10
    imul edx, 10
    add r14d, edx
    ; sumY += pixel * 0

    ; --- S¹siad (0, 1) ---
    mov eax, r10d
    imul eax, edi
    mov ecx, r12d
    add ecx, 1
    add eax, ecx
    movzx edx, byte ptr [rsi+rax]
    ; sumX += pixel * -10
    imul edx, -10
    add r14d, edx
    ; sumY += pixel * 0

    ; --- S¹siad (1, -1) ---
    mov eax, r10d
    add eax, 1
    imul eax, edi
    mov ecx, r12d
    add ecx, -1
    add eax, ecx
    movzx edx, byte ptr [rsi+rax]
    ; sumX += pixel * 3
    imul edx, 3
    add r14d, edx
    ; sumY += pixel * -3
    movzx edx, byte ptr [rsi+rax]
    imul edx, -3
    add r15d, edx

    ; --- S¹siad (1, 0) ---
    mov eax, r10d
    add eax, 1
    imul eax, edi
    mov ecx, r12d
    add eax, ecx
    movzx edx, byte ptr [rsi+rax]
    ; sumX += pixel * 0
    ; sumY += pixel * -10
    imul edx, -10
    add r15d, edx

    ; --- S¹siad (1, 1) ---
    mov eax, r10d
    add eax, 1
    imul eax, edi
    mov ecx, r12d
    add ecx, 1
    add eax, ecx
    movzx edx, byte ptr [rsi+rax]
    ; sumX += pixel * -3
    imul edx, -3
    add r14d, edx
    ; sumY += pixel * -3
    movzx edx, byte ptr [rsi+rax]
    imul edx, -3
    add r15d, edx

    ; Obliczamy wartoœæ = |sumX| + |sumY|
    mov eax, r14d
    cdq
    xor eax, edx
    sub eax, edx
    mov ebx, r15d
    cdq
    xor ebx, edx
    sub ebx, edx
    add eax, ebx
    cmp eax, 255
    jle StorePixel
    mov eax, 255

StorePixel:
    ; Obliczamy indeks piksela wyjœciowego: index = current y * width + current x
    mov ebx, r10d
    imul ebx, edi
    add ebx, r12d
    mov [rdx+rbx], al

    inc r12d
    jmp XLoop

XLoopEnd:
    inc r10d
    jmp YLoop

LoopEnd:
    pop r9
    pop r8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rdi
    pop rsi
    ret

ExitASM:
    pop r9
    pop r8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rdi
    pop rsi
    ret
ASMScharrFunction ENDP

END
