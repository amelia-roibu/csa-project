.data
    nrOperatii: .zero 4
    operatie: .zero 4
    id: .zero 4
    dimensiune: .zero 4
    left: .zero 4
    right: .zero 4
    N: .space 4
    right_maxim: .zero 4
    vector_memorie: .zero 4096

    formatCitire: .asciz "%d"
    formatAfisare: .asciz "%d: (%d, %d)\n"
    formatGet: .asciz "(%d, %d)\n"
    formattest: .asciz "%d\n"

.text

.global main

main:
    lea vector_memorie, %edi

    pushl $nrOperatii
    pushl $formatCitire
    call scanf                        # citire nrOperatii = cate operatii se vor efectua
    popl %ebx
    popl %ebx

loopInitial:
    movl nrOperatii, %ecx  
    subl $1, nrOperatii               # for (i = nrOperatii; i > 0; i--)
    cmp $0, %ecx
    je exit

    pushl $operatie
    pushl $formatCitire
    call scanf                        # citire cod operatie actuala
    popl %ebx
    popl %ebx

    movl operatie, %eax
    cmp $1, %eax
    je ADD

    cmp $2, %eax                      # verificare cod operatie actuala
    je GET

    cmp $3, %eax
    je DELETE

    cmp $4, %eax
    je DEFRAGMENTATION

ADD:
    pushl $N
    pushl $formatCitire
    call scanf                       # citire N = cate fisiere vor fi adaugate
    popl %ebx
    popl %ebx

ADD_loop:
    movl N, %ecx  
    subl $1, N                       # for (i = N; i > 0; i--)
    cmp $0, %ecx
    je loopInitial                   # revenire pentru o operatie noua

    pushl $id
    pushl $formatCitire
    call scanf                       # citire id actual
    popl %ebx
    popl %ebx

    pushl $dimensiune
    pushl $formatCitire
    call scanf                       # citire dimensiune fisier actual
    popl %ebx
    popl %ebx
    movl dimensiune, %ebx

    cmpl $8192, dimensiune
    ja ADD_afisare_false

    shrl $3, dimensiune              # impart la 8 (2^3) dimensiunea in kB pentru a afla dimensiunea in blocuri
    andl $7, %ebx                    # verific daca dimensiunea e multiplu de 8
    jnz mamamia

    movl $0, %ecx                    # daca e, ma apuc sa-i aloc spatiu fisierului
    jmp cautareSpatiu

mamamia:
    incl dimensiune                  # daca nu e, aproximez nr de blocuri prin adaos si apoi ma apuc de alocare spatiu
    movl $0, %ecx
    jmp cautareSpatiu

ADD_afisare:
    pushl right                     
    pushl left
    pushl id
    pushl $formatAfisare
    call printf                      # afisarea pt fisierul curent din operatia ADD
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    movl right, %ebx
    cmpl %ebx, right_maxim
    jl actualizare_maxim

    jmp ADD_loop                    # revenire, adica citirea noului id si dimensiune
    
ADD_afisare_false:
    pushl $0                     
    pushl $0
    pushl id
    pushl $formatAfisare
    call printf                      # afisarea pt fisierul curent din operatia ADD
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    jmp ADD_loop                    # revenire, adica citirea noului id si dimensiune

actualizare_maxim:
    movl %ebx, right_maxim
    jmp ADD_loop

cautareSpatiu:
    cmpl $1024, %ecx
    je ADD_afisare_false

    movl (%edi, %ecx, 4), %edx      
    movl $1, %ebx                   # cand ebx == dimensiune, inseamna ca e suficient loc pt fisierul respectiv; mereu resetam ebx la o noua cautare
    cmp $0, %edx                    # verific daca locul curent din vector e gol  (ecx a fost initializat cu zero)
    je verificareSpatiu
    incl %ecx                       # daca nu e, continui cautarea pana gasesc un slot zero
    jmp cautareSpatiu

verificareSpatiu:
    movl id, %eax                   # aici presupun ca locul gol gasit este incapator pt tot fisierul si imi fac o copie a id-ului
    movl %ecx, %edx                 # si indexului de unde incepe
    cmp %ebx, dimensiune            
    je ADD_fr                       # conditia de oprire a cautarii de spatiu in memorie
    incl %ebx                       # altfel, tot e bine, doar trebuie verificat in continuare

    incl %ecx
    cmpl $1024, %ecx
    je cautareSpatiu
    movl (%edi, %ecx, 4), %edx
    cmp $0, %edx
    je verificareSpatiu
    jmp cautareSpatiu               # daca urmatorul element din vector nu e tot zero, reluam cautarea de la ecx curent

ADD_fr:                             # daca am ajuns aici, inseamna ca ne pregatim de afisare; intai salvam in vector id-ul din eax
    movl %eax, (%edi, %ecx, 4)
    decl dimensiune                 # pana cand dimensiune este zero, adica am ocupat toate blocurile
    decl %ecx
    cmpl $0, dimensiune
    jnz ADD_fr

    decl %ebx
    movl %edx, right
    subl %ebx, %edx
    movl %edx, left 
    jmp ADD_afisare

GET:
    pushl $id
    pushl $formatCitire
    call scanf                       # citire id actual
    popl %ebx
    popl %ebx

    movl id, %eax
    movl $0, %ecx

GET_loop:
    movl %ecx, left                # pp ca urmatorul ecx este cel bun...
    cmp %ecx, right_maxim          # for (i = 0; i < right_maxim; i++)
    je NO_GET

    movl (%edi, %ecx, 4), %ebx     # valoarea curenta din vector
    cmp %eax, %ebx
    je GET_gasit

    incl %ecx
    jmp GET_loop

NO_GET:
    movl $0, left
    movl $0, right
    jmp GET_afisare

GET_gasit:
    incl %ecx
    movl (%edi, %ecx, 4), %ebx     # valoarea curenta din vector
    cmp %eax, %ebx                 # cat timp e inca egala cu id
    je GET_gasit

    decl %ecx
    movl %ecx, right
    jmp GET_afisare

GET_afisare:
    pushl right
    pushl left
    pushl $formatGet
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    
    jmp loopInitial                 # revenire pentru o noua operatie

DELETE:
    pushl $id
    pushl $formatCitire
    call scanf                       # citire id actual
    popl %ebx
    popl %ebx

    cmpl $0, right_maxim
    je loopInitial

    movl id, %eax
    movl $0, %ecx
    jmp DELETE_loop

DELETE_loop:
    movl (%edi, %ecx, 4), %ebx       # %ebx = v[i]

    cmp %ecx, right_maxim          # for (i = 0; i < right_maxim; i++)
    jl loopInitial

    cmp %ebx, %eax
    je DELETE_gasit
    cmpl $0, %ebx
    jne DELETE_mamamia

    incl %ecx
    jmp DELETE_loop

DELETE_mamamia:
    movl %ebx, %edx
    movl %ecx, left
    jmp DELETE_while_loop

DELETE_while_loop:
    incl %ecx
    movl (%edi, %ecx, 4), %ebx

    cmp %ebx, %edx
    jne DELETE_afisare
    jmp DELETE_while_loop

DELETE_gasit:
    movl $0, (%edi, %ecx, 4)
    incl %ecx
    jmp DELETE_loop

DELETE_afisare:
    decl %ecx
    movl %ecx, right
    
    pushl right
    pushl left
    pushl %edx
    pushl $formatAfisare
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    movl right, %ecx
    movl id, %eax

    cmp %ecx, right_maxim          
    je loopInitial
    
    incl %ecx
    jmp DELETE_loop

DEFRAGMENTATION:
    movl $0, %ecx
    movl $0, %ebx
    cmpl $0, right_maxim
    je loopInitial

    jmp DEFRAG_loop_mutare

DEFRAG_loop_mutare:
    cmp %ecx, right_maxim           # for (i = 0; i < right_maxim; i++)
    jl DEFRAG_preg_afis
    cmpl $0, (%edi, %ecx, 4)        # if (v[i] == 0)
    je increment_ebx
    movl (%edi, %ecx, 4), %edx
    cmp %ebx, %ecx
    jne paralell

    incl %ecx                                  
    incl %ebx
    jmp DEFRAG_loop_mutare

paralell:
    movl %edx, (%edi, %ebx, 4)       # merg in paralel cu v[ebx] = v[ecx], unde v[ecx] sigur este nenul
    movl $0, (%edi, %ecx, 4)         # iar pe v[ecx] il golesc apoi
    incl %ecx                                  
    incl %ebx
    jmp DEFRAG_loop_mutare

increment_ebx:
    incl %ecx
    cmpl $0, (%edi, %ecx, 4)                # dupa ce am gasit un zero, caut prima valoare nenula de dupa
    jne DEFRAG_loop_mutare

    cmp %ecx, right_maxim
    jl DEFRAG_preg_afis

    jmp increment_ebx

DEFRAG_preg_afis:
    decl %ebx
    movl %ebx, right_maxim                  # in ebx voi avea acum capatul din dreapta actualizat

    movl $0, %ecx                           # for (i = 0; i < right_maxim; i++)
    movl (%edi, %ecx, 4), %eax              # eax = primul id
    movl $0, left                           # memoria incepe de la blocul zero

DEFRAG_loop_afisare:
    incl %ecx

    cmpl %ecx, right_maxim
    je DEFRAGMENTATION_afisare_finala

    cmp %eax, (%edi, %ecx, 4)
    jne DEFRAGMENTATION_afisare

    jmp DEFRAG_loop_afisare

DEFRAGMENTATION_afisare:
    decl %ecx
    movl %ecx, right
    movl %eax, id

    pushl right
    pushl left
    pushl id
    pushl $formatAfisare
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    movl right, %ecx
    incl %ecx
    movl %ecx, left
    movl (%edi, %ecx, 4), %eax

    jmp DEFRAG_loop_afisare

DEFRAGMENTATION_afisare_finala:
    movl %ecx, right
    movl %eax, id

    pushl right
    pushl left
    pushl id
    pushl $formatAfisare
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    jmp loopInitial

exit:
    pushl $0
    call fflush
    popl %ebx

    movl $1, %eax
    movl $0, %ebx
    int $0x80