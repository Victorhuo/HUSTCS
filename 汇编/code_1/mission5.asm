.386

stack   segment use16 stack
        db 500 dup(0)
stack   ends

data    segment use16
        Bname           db 'GE SONG'
        Bpassword       db 'lulala'
        Sname           db 0aH, 0dH, 'shop', '$'
        N               equ 30

        username_hint   db 0ah, 0dh, 'Please enter your username', '$'
        password_hint   db 0ah, 0dh, 'Please enter your password', '$'
        fail_hint       db 0ah, 0dh, 'Auth fail, wrong username or password', '$'
        success_hint    db 0ah, 0dh, 'Auth success', '$'
        query_hint      db 0ah, 0dh, 'Please enter the item name you want to query', '$'
        in_name         db 80
                        db 0
                        db 80 dup(0)
        in_pwd          db 80
                        db 0
                        db 80 dup(0)
        in_item         db 80
                        db 0
                        db 80 dup(0)

        item1           db 'pen', 7 dup(0), 10
                        dw 35, 56, 70, 25, ?
        item2           db 'book', 6 dup(0), 9
                        dw 12, 30, 25, 5, ?
        rest_items      db N-2 dup('Temp-Value',8, 15, 0, 20, 0, 30, 0, 2, 0, ?, ?)
        item_size       dw 21
        auth            dw 0
data ends

code segment use16
        assume cs:code, ds:data, ss:stack

start:  mov ax, data
        mov ds, ax

login:  ;show the name of my shop
        lea dx, Sname
        mov ah, 9
        int 21h
        call newline
        ; show the hint for users to enter their username
        lea dx, username_hint
        mov ah, 9
        int 21h
        call newline
        
        ; user input username
        lea dx, in_name
        mov ah, 10
        int 21h
        
        mov si, offset in_name
        ; if the input is 'q', then quit
        cmp byte ptr 2[si], 'q'
        je exit
        ; if the input is '\n', then begin query

        cmp byte ptr 2[si], 13
        je cumtomer

        call check_username

        ; show the hint for users to enter their password
        lea dx, password_hint
        mov ah, 9
        int 21h
        call newline

        lea dx, in_pwd
        mov ah, 10
        int 21h

        call check_password
        jmp query

cumtomer:
    mov auth, 0
    jmp query

check_username proc 
        ; check the username
        ; the length of the input is stored in cx
        mov cl, in_name + 1
        mov ch, 0
        mov bx, 0
        
        cmp cx, 7
        jne auth_fail

        mov si, offset in_name
        mov di, offset Bname

    loopa:  mov ah, byte ptr 2[bx+si]
            mov al, byte ptr [bx+di]
            cmp ah, al
            jne  auth_fail

            inc bx
            cmp cx, bx
            jne loopa
    ret
check_username endp

check_password proc
        ; check the password
        ; the length of the input is stored in cx
        mov cl, in_pwd + 1
        mov ch, 0
        mov bx, 0
        
        cmp cx, 6
        jne auth_fail

        mov si, offset in_pwd
        mov di, offset Bpassword

    loopb:  mov ah, byte ptr 2[bx+si]
            mov al, byte ptr [bx+di]
            cmp ah, al
            jne  auth_fail

            inc bx
            cmp cx, bx
            jne loopb
    mov auth, 1
    ret
check_password endp  
        
auth_fail:
    mov auth, 0
    lea dx, fail_hint
    mov ah, 9
    int 21h
    call newline
    jmp login


query:
    lea dx, query_hint
    mov ah, 9
    int 21h
    call newline
    ; user enter item name
    lea dx, in_item
    mov ah, 10
    int 21h

    mov si, offset in_item
    ; if the input is \n return to login func
    cmp byte ptr 2[si], 13
    je login
    
    mov bx, offset item1
    mov cx, 1
    jmp compare_item

next_item:
    ; the cx = N, then it means didn't find, back to query func
    cmp cx, N
    je  query

    inc cx
    mov bx, di
    add bx, item_size
    jmp compare_item
    

compare_item:
    mov di, bx
    mov si, offset in_item
    mov bl, in_item + 1
    mov bh, 0
    mov byte ptr in_item + 2[bx], '$'
    mov bx, 0
    loopc:  
        mov ah, byte ptr [di+bx]
        mov al, byte ptr 2[si+bx]
        cmp ah, 0
        je check_item_length
        cmp bx, 10
        je find_item
        inc bx
        cmp ah, al
        je loopc
    jmp next_item
; check the length of the input
check_item_length:
    mov cl, in_item + 1
    mov ch, 0
    cmp bx, cx
    je find_item
    jmp next_item

find_item:
    mov bx, di
    cmp auth, 1
    je  show_item_name
    jmp calculate

show_item_name:
    call newline
    lea dx, in_item+2
    mov ah, 9
    int 21h
    jmp login

calculate:
    add bx, 10
    mov ax, 3[bx]
    mov dl, byte ptr [bx]
    mov dh, 0
    ; 销售价*折扣
    mul dx
    mov cx, 10
    ; 除以 10
    div cx
    ; 结果放在 cx
    mov cx, ax
    mov ax, 1[bx]
    mov dx, 128
    mul dx
    mov dx, 0
    div cx

    mov cx, ax
    mov ax, word ptr 5[bx]
    mov dx, 128
    mul dx
    mov dx, 0
    div word ptr 7[bx]
    add ax, cx

    cmp ax, 100
    jg print_A
    cmp ax, 50
    jg print_B
    cmp ax, 10
    jg print_C
    jmp print_F


print_A:
    call    newline
    mov     dl, 'A'
    mov     ah, 02h
    int     21h
    jmp     login

print_B:
    call    newline
    mov     dl, 'B'
    mov     ah, 02h
    int     21h
    jmp     login

print_C:
    call    newline
    mov     dl, 'C'
    mov     ah, 02h
    int     21h
    jmp     login

print_F:
    call    newline
    mov     dl, 'F'
    mov     ah, 02h
    int     21h
    jmp     login

; newline 
newline proc
    mov     dl, 13
    mov     ah, 02h
    int     21h

    mov     dl, 10
    mov     ah, 02h
    int     21h
    ret
newline endp

exit:
    mov auth, 0
    mov ah, 4ch
    int 21h

code ends

end start
          