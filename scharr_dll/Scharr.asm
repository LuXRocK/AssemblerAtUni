option casemap:none

; Upublicznienie funkcji, aby była widoczna poza tym modułem
PUBLIC ASMScharrFunction

.code
ASMScharrFunction PROC
    ; -------------------- PROLOG --------------------
    push    rbp             ; Zapisujemy poprzedni wskaźnik ramki stosu
    mov     rbp, rsp        ; Ustawiamy nowy wskaźnik ramki stosu na bieżący wskaźnik stosu
    push    rbx             ; Zapisujemy rejestr RBX (zachowujemy jego wartość)
    push    rsi             ; Zapisujemy rejestr RSI (zachowujemy jego wartość)
    push    rdi             ; Zapisujemy rejestr RDI (zachowujemy jego wartość)
    push    r12             ; Zapisujemy rejestr R12 (zachowujemy jego wartość)
    push    r13             ; Zapisujemy rejestr R13 (zachowujemy jego wartość)
    push    r14             ; Zapisujemy rejestr R14 (zachowujemy jego wartość)
    push    r15             ; Zapisujemy rejestr R15 (zachowujemy jego wartość)
    sub     rsp, 64         ; Rezerwujemy 64 bajty na zmienne lokalne (obszar roboczy)

    ; ----------------- USTAWIENIE PARAMETRÓW -----------------
    ; Zgodnie z konwencją Microsoft x64:
    ; RCX = wskaźnik do obrazu wejściowego (inputImage)
    ; RDX = wskaźnik do obrazu wyjściowego (outputImage)
    ; R8  = szerokość obrazu (width)
    ; R9  = wysokość obrazu (height)
    mov     rsi, rcx        ; Przenosimy wskaźnik inputImage do rejestru RSI
    mov     rdi, rdx        ; Przenosimy wskaźnik outputImage do rejestru RDI
    mov     rbx, r8         ; Przechowujemy szerokość obrazu w rejestrze RBX
    mov     r10, r9         ; Przechowujemy wysokość obrazu w rejestrze R10

    ; -------------------- CZYSZCZENIE KRAWĘDZI --------------------
    ; Zerujemy górny wiersz obrazu wyjściowego (pierwszy wiersz)
    xor     rax, rax        ; Ustawiamy licznik kolumn (RAX) na 0
top_row_loop:
    cmp     rax, rbx        ; Porównujemy licznik z szerokością obrazu
    jge     top_row_done    ; Jeśli osiągnęliśmy szerokość, kończymy pętlę
    mov     byte ptr [rdi + rax], 0  ; Ustawiamy piksel w górnym wierszu na 0
    inc     rax             ; Zwiększamy licznik kolumn
    jmp     top_row_loop    ; Powtarzamy pętlę
top_row_done:

    ; Zerujemy dolny wiersz obrazu wyjściowego (ostatni wiersz)
    mov     rax, r10        ; Ładujemy wysokość obrazu
    dec     rax             ; Obliczamy indeks ostatniego wiersza (height - 1)
    imul    rax, rbx        ; Przemnażamy indeks przez szerokość, aby uzyskać offset w pamięci
    lea     r11, [rdi + rax] ; Obliczamy adres początku dolnego wiersza i zapisujemy go w R11
    xor     rax, rax        ; Resetujemy licznik kolumn
bottom_row_loop:
    cmp     rax, rbx        ; Sprawdzamy, czy przetworzyliśmy wszystkie kolumny
    jge     bottom_row_done ; Jeśli tak, wychodzimy z pętli
    mov     byte ptr [r11 + rax], 0  ; Ustawiamy piksel w dolnym wierszu na 0
    inc     rax             ; Zwiększamy licznik kolumn
    jmp     bottom_row_loop ; Powtarzamy pętlę
bottom_row_done:

    ; Zerujemy lewą kolumnę obrazu wyjściowego (pierwsza kolumna każdej linii)
    xor     rax, rax        ; Ustawiamy licznik wierszy na 0
left_col_loop:
    cmp     rax, r10        ; Sprawdzamy, czy przetworzyliśmy wszystkie wiersze
    jge     left_col_done   ; Jeśli tak, kończymy pętlę
    mov     rcx, rax        ; Kopiujemy bieżący indeks wiersza do RCX
    imul    rcx, rbx        ; Obliczamy offset wiersza (wiersz * szerokość)
    mov     byte ptr [rdi + rcx], 0 ; Ustawiamy pierwszy piksel w danym wierszu (lewa kolumna) na 0
    inc     rax             ; Zwiększamy licznik wierszy
    jmp     left_col_loop   ; Powtarzamy pętlę
left_col_done:

    ; Zerujemy prawą kolumnę obrazu wyjściowego (ostatnia kolumna każdej linii)
    xor     rax, rax        ; Ustawiamy licznik wierszy na 0
right_col_loop:
    cmp     rax, r10        ; Sprawdzamy, czy przetworzyliśmy wszystkie wiersze
    jge     right_col_done  ; Jeśli tak, kończymy pętlę
    mov     rcx, rax        ; Kopiujemy bieżący indeks wiersza do RCX
    imul    rcx, rbx        ; Obliczamy offset wiersza (wiersz * szerokość)
    mov     rdx, rbx        ; Ładujemy szerokość obrazu do RDX
    dec     rdx             ; Obliczamy indeks ostatniej kolumny (width - 1)
    add     rcx, rdx        ; Dodajemy indeks ostatniej kolumny, aby uzyskać offset ostatniego piksela w wierszu
    mov     byte ptr [rdi + rcx], 0 ; Ustawiamy ten piksel na 0
    inc     rax             ; Zwiększamy licznik wierszy
    jmp     right_col_loop  ; Powtarzamy pętlę
right_col_done:

    ; ----------------- PRZETWARZANIE PIKSELI WEWNĄTRZ OBRAZU -----------------
    ; Przetwarzamy wiersze od 1 do (height - 2) – pomijamy krawędzie
    mov     r11, 1         ; Ustawiamy indeks bieżącego wiersza na 1 (pomijamy pierwszy wiersz)
outer_loop:
    mov     rax, r10
    dec     rax             ; Obliczamy indeks ostatniego wiersza (height - 1)
    cmp     r11, rax        ; Jeśli bieżący wiersz >= ostatni wiersz, kończymy przetwarzanie
    jge     end_outer_loop

    ; Obliczamy adresy trzech wierszy obrazu wejściowego:
    ; 1) Wiersz powyżej bieżącego (r11 - 1)
    mov     rax, r11
    dec     rax             ; rax = r11 - 1
    imul    rax, rbx        ; rax = (r11 - 1) * width
    add     rax, rsi        ; rax = adres początku wiersza powyżej
    mov     qword ptr [rbp - 8], rax   ; Zapisujemy adres w lokalnej zmiennej (top row)

    ; 2) Bieżący wiersz (r11)
    mov     rax, r11
    imul    rax, rbx        ; rax = r11 * width
    add     rax, rsi        ; rax = adres początku bieżącego wiersza
    mov     qword ptr [rbp - 16], rax  ; Zapisujemy adres bieżącego wiersza

    ; 3) Wiersz poniżej bieżącego (r11 + 1)
    mov     rax, r11
    inc     rax             ; rax = r11 + 1
    imul    rax, rbx        ; rax = (r11 + 1) * width
    add     rax, rsi        ; rax = adres początku wiersza poniżej
    mov     qword ptr [rbp - 24], rax  ; Zapisujemy adres dolnego wiersza

    ; Obliczamy adres bieżącego wiersza obrazu wyjściowego
    mov     rax, r11
    imul    rax, rbx        ; rax = r11 * width
    add     rax, rdi        ; rax = adres początku bieżącego wiersza w obrazie wyjściowym
    mov     qword ptr [rbp - 32], rax  ; Zapisujemy ten adres w zmiennej lokalnej

    push    r11             ; Zachowujemy bieżący indeks wiersza na stosie

    ; ----------------- PRZETWARZANIE KOLUMN W BIEŻĄCYM WIERSZU -----------------
    ; Przetwarzamy piksele od kolumny 1 do (width - 2) (pomijamy kolumny krawędziowe)
    mov     r12, 1         ; Ustawiamy indeks kolumny na 1
inner_loop_start:
    mov     rax, rbx
    dec     rax             ; rax = width - 1 (ostatnia kolumna, którą pomijamy)
    cmp     r12, rax        ; Jeśli aktualna kolumna >= (width - 1), kończymy pętlę wewnętrzną
    jge     end_inner_loop

    ; Inicjalizacja akumulatorów na gradienty:
    ; [rbp - 48] – pomocnicza zmienna (przechowuje indeks kolumny, dla odniesienia)
    ; [rbp - 40] – akumulator dla poziomego gradientu (Gx)
    ; [rbp - 44] – akumulator dla pionowego gradientu (Gy)
    mov     dword ptr [rbp - 48], r12d ; Zapisujemy bieżący indeks kolumny (jako 32-bit)
    mov     dword ptr [rbp - 40], 0    ; Zerujemy akumulator Gx
    mov     dword ptr [rbp - 44], 0    ; Zerujemy akumulator Gy

    ; ----------------- PRZETWARZANIE SĄSIEDZTWA – WIERSZ GÓRNY -----------------
    ; Lewy górny piksel (wiersz powyżej, kolumna r12 - 1)
    mov     r13, qword ptr [rbp - 8]   ; Ładujemy adres wiersza powyżej (top row)
    mov     r14, r12
    dec     r14             ; Obliczamy indeks kolumny dla lewego sąsiada
    movzx   r15d, byte ptr [r13 + r14] ; Wczytujemy wartość piksela (rozszerzając do 32 bitów)
    imul    r15d, 3         ; Mnożymy wartość przez 3 (waga Scharr dla lewego górnego piksela)
    add     dword ptr [rbp - 40], r15d ; Dodajemy do akumulatora Gx
    add     dword ptr [rbp - 44], r15d ; Dodajemy do akumulatora Gy

    ; Górny środkowy piksel (wiersz powyżej, kolumna r12)
    mov     r13, qword ptr [rbp - 8]   ; Ponownie adres wiersza powyżej
    movzx   r15d, byte ptr [r13 + r12] ; Wczytujemy wartość piksela w kolumnie r12
    imul    r15d, 5         ; Mnożymy przez 5 (waga Scharr dla górnego środkowego piksela)
    add     dword ptr [rbp - 44], r15d ; Dodajemy do akumulatora Gy
    add     dword ptr [rbp - 44], r15d ; Dodajemy wynik jeszcze raz (efektywnie 5 * 2)

    ; Prawy górny piksel (wiersz powyżej, kolumna r12 + 1)
    mov     r13, qword ptr [rbp - 8]   ; Ładujemy adres wiersza powyżej
    mov     r14, r12
    inc     r14             ; Obliczamy indeks kolumny dla prawego sąsiada
    movzx   r15d, byte ptr [r13 + r14] ; Wczytujemy wartość piksela z prawej strony
    imul    r15d, 3         ; Mnożymy przez 3 (waga Scharr dla prawego górnego piksela)
    sub     dword ptr [rbp - 40], r15d ; Odejmujemy wynik od akumulatora Gx
    add     dword ptr [rbp - 44], r15d ; Dodajemy wynik do akumulatora Gy

    ; ----------------- PRZETWARZANIE SĄSIEDZTWA – WIERSZ ŚRODKOWY -----------------
    ; Lewy piksel bieżący (bieżący wiersz, kolumna r12 - 1)
    mov     r13, qword ptr [rbp - 16]  ; Ładujemy adres bieżącego wiersza
    mov     r14, r12
    dec     r14             ; Obliczamy indeks kolumny dla lewego sąsiada
    movzx   r15d, byte ptr [r13 + r14] ; Wczytujemy wartość piksela z lewej strony
    imul    r15d, 5         ; Mnożymy przez 5 (waga Scharr dla lewego piksela)
    add     dword ptr [rbp - 40], r15d ; Dodajemy wynik do Gx
    add     dword ptr [rbp - 40], r15d ; Dodajemy jeszcze raz (efektywnie 5 * 2)

    ; Prawy piksel bieżący (bieżący wiersz, kolumna r12 + 1)
    mov     r13, qword ptr [rbp - 16]  ; Ładujemy adres bieżącego wiersza
    mov     r14, r12
    inc     r14             ; Obliczamy indeks kolumny dla prawego sąsiada
    movzx   r15d, byte ptr [r13 + r14] ; Wczytujemy wartość piksela z prawej strony
    imul    r15d, 5         ; Mnożymy przez 5 (waga Scharr dla prawego piksela)
    sub     dword ptr [rbp - 40], r15d ; Odejmujemy wynik od Gx
    sub     dword ptr [rbp - 40], r15d ; Odejmujemy jeszcze raz (efektywnie 5 * 2)

    ; ----------------- PRZETWARZANIE SĄSIEDZTWA – WIERSZ DOLNY -----------------
    ; Lewy dolny piksel (wiersz poniżej, kolumna r12 - 1)
    mov     r13, qword ptr [rbp - 24]  ; Ładujemy adres dolnego wiersza
    mov     r14, r12
    dec     r14             ; Obliczamy indeks kolumny dla lewego sąsiada
    movzx   r15d, byte ptr [r13 + r14] ; Wczytujemy wartość piksela
    imul    r15d, 3         ; Mnożymy przez 3 (waga Scharr dla lewego dolnego piksela)
    add     dword ptr [rbp - 40], r15d ; Dodajemy wynik do Gx
    sub     dword ptr [rbp - 44], r15d ; Odejmujemy wynik od Gy

    ; Dolny środkowy piksel (wiersz poniżej, kolumna r12)
    mov     r13, qword ptr [rbp - 24]  ; Ładujemy adres dolnego wiersza
    movzx   r15d, byte ptr [r13 + r12] ; Wczytujemy wartość piksela w kolumnie r12
    imul    r15d, 5         ; Mnożymy przez 5 (waga Scharr dla środkowego dolnego piksela)
    sub     dword ptr [rbp - 44], r15d ; Odejmujemy wynik od Gy
    sub     dword ptr [rbp - 44], r15d ; Odejmujemy jeszcze raz (efektywnie 5 * 2)

    ; Prawy dolny piksel (wiersz poniżej, kolumna r12 + 1)
    mov     r13, qword ptr [rbp - 24]  ; Ładujemy adres dolnego wiersza
    mov     r14, r12
    inc     r14             ; Obliczamy indeks kolumny dla prawego sąsiada
    movzx   r15d, byte ptr [r13 + r14] ; Wczytujemy wartość piksela z prawej strony
    imul    r15d, 3         ; Mnożymy przez 3 (waga Scharr dla prawego dolnego piksela)
    sub     dword ptr [rbp - 40], r15d ; Odejmujemy wynik od Gx
    sub     dword ptr [rbp - 44], r15d ; Odejmujemy wynik od Gy

    ; ----------------- OBLICZANIE KOLEKTYWNEJ WARTOŚCI GRADIENTU -----------------
    ; Obliczamy wartość gradientu jako sumę wartości bezwzględnych akumulatorów Gx i Gy
    mov     eax, dword ptr [rbp - 40]  ; Przenosimy wartość Gx do EAX
    cmp     eax, 0
    jge     skip_abs1      ; Jeśli Gx ≥ 0, pomijamy negację
    neg     eax            ; Jeśli Gx < 0, zmieniamy znak, aby uzyskać wartość bezwzględną
skip_abs1:
    mov     edx, dword ptr [rbp - 44]  ; Przenosimy wartość Gy do EDX
    cmp     edx, 0
    jge     skip_abs2      ; Jeśli Gy ≥ 0, pomijamy negację
    neg     edx            ; Jeśli Gy < 0, zmieniamy znak, aby uzyskać wartość bezwzględną
skip_abs2:
    add     eax, edx       ; Dodajemy wartości bezwzględne Gx i Gy
    cmp     eax, 255       ; Sprawdzamy, czy wynik przekracza 255 (maksymalna wartość piksela)
    jbe     no_clamp       ; Jeśli wynik ≤ 255, nie ograniczamy
    mov     eax, 255       ; Jeśli wynik > 255, ograniczamy do 255
no_clamp:
    ; ----------------- ZAPIS WYNIKU -----------------
    ; Zapisujemy obliczoną wartość gradientu do odpowiedniego piksela obrazu wyjściowego
    mov     r13, qword ptr [rbp - 32]  ; Ładujemy adres bieżącego wiersza obrazu wyjściowego
    mov     byte ptr [r13 + r12], al   ; Zapisujemy wynikowy piksel (wartość w AL) w kolumnie r12

    inc     r12           ; Przechodzimy do następnej kolumny w bieżącym wierszu
    jmp     inner_loop_start ; Powtarzamy przetwarzanie piksela wewnątrz wiersza
end_inner_loop:
    pop     r11           ; Przywracamy zapisany indeks bieżącego wiersza
    inc     r11           ; Przechodzimy do następnego wiersza
    jmp     outer_loop    ; Powtarzamy przetwarzanie dla kolejnego wiersza
end_outer_loop:

    ; -------------------- EPILOG --------------------
    add     rsp, 64        ; Zwalniamy przydzielony obszar zmiennych lokalnych
    pop     r15            ; Przywracamy rejestr R15
    pop     r14            ; Przywracamy rejestr R14
    pop     r13            ; Przywracamy rejestr R13
    pop     r12            ; Przywracamy rejestr R12
    pop     rdi            ; Przywracamy rejestr RDI
    pop     rsi            ; Przywracamy rejestr RSI
    pop     rbx            ; Przywracamy rejestr RBX
    pop     rbp            ; Przywracamy poprzedni wskaźnik ramki stosu
    ret                   ; Zwracamy kontrolę do wywołującego
ASMScharrFunction ENDP

END
