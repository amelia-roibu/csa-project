.data
    nrOperatii: .zero 4
    operatie: .zero 4
    id: .zero 4
    dimensiune: .zero 4
    left: .zero 4
    right: .zero 4
    N: .space 4
    right_maxim: .zero 4
    down_maxim: .zero 4
    index_linie: .zero 4
    dim_max: .long 1024                  # modificare
    vector_memorie: .zero 4194304
    vector_right_maxim: .zero 1024

    formatCitire: .asciz "%d"
    formatAfisare: .asciz "%d: ((%d, %d), (%d, %d))\n"
    formatGet: .asciz "((%d, %d), (%d, %d))\n"
    formattest: .asciz "%d\n"

.text

.global main

main:
    lea vector_memorie, %edi
    lea vector_right_maxim, %esi

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
    je gresit

ADD:
    pushl $N
    pushl $formatCitire
    call scanf                       # citire N = cate fisiere vor fi adaugate
    popl %ebx
    popl %ebx

ADD_loop:
    movl $0, index_linie
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

    cmpl $8192, dimensiune
    ja ADD_afisare_false

    movl dimensiune, %ebx
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
    pushl index_linie                   
    pushl left
    pushl index_linie
    pushl id
    pushl $formatAfisare
    call printf                      # afisarea pt fisierul curent din operatia ADD
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    movl right, %ebx
    movl index_linie, %ecx
    movl (%esi, %ecx, 4), %eax
    cmpl %ebx, %eax
    jl actualizare_maxim

    jmp ADD_loop                    # revenire, adica citirea noului id si dimensiune
    
ADD_afisare_false:
    pushl $0                     
    pushl $0
    pushl $0                     
    pushl $0
    pushl id
    pushl $formatAfisare
    call printf                      # afisarea pt fisierul curent din operatia ADD
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    jmp ADD_loop                    # revenire, adica citirea noului id si dimensiune

actualizare_maxim:
    movl %ebx, (%esi, %ecx, 4)
    
    jmp ADD_loop

actualizare_down:
    movl %ecx, down_maxim
    movl $0, %ecx                   
    jmp cautareSpatiu

increment_index_linie:
    addl $1, index_linie

    cmpl $1024, index_linie            # modificare
    je ADD_afisare_false

    movl index_linie, %ecx
    cmpl %ecx, down_maxim
    jl actualizare_down

    movl $0, %ecx                  
    jmp cautareSpatiu

cautareSpatiu:
    cmpl %ecx, dim_max                   # aici va fi $1024
    je increment_index_linie

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*8
    addl %ecx, %eax                 # eax = i*8 + j 

    movl (%edi, %eax, 4), %edx

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
    cmpl %ecx, dim_max
    je cautareSpatiu

    pushl %eax

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*8
    addl %ecx, %eax                 # eax = i*8 + j 

    movl (%edi, %eax, 4), %edx
    popl %eax

    
    cmp $0, %edx
    je verificareSpatiu
    jmp cautareSpatiu               # daca urmatorul element din vector nu e tot zero, reluam cautarea de la ecx curent

ADD_fr:                             # daca am ajuns aici, inseamna ca ne pregatim de afisare; intai salvam in vector id-ul din eax
    pushl %edx
    pushl %eax

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*8
    addl %ecx, %eax                 # eax = i*8 + j 

    popl %edx
    movl %edx, (%edi, %eax, 4)

    movl %edx, %eax
    popl %edx

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

    movl $0, %ecx
    movl $0, index_linie

    movl (%esi, %ecx, 4), %eax
    movl %eax, right_maxim
    movl id, %eax

GET_loop:
    movl down_maxim, %edx
    cmpl %edx, index_linie                # modificare
    ja NO_GET

    movl %ecx, left                # pp ca urmatorul ecx este cel bun...

    cmp %ecx, right_maxim          # for (i = 0; i < right_maxim; i++)
    je increment_index_linie_get

    pushl %eax
    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*8
    addl %ecx, %eax                 # eax = i*8 + j 

    movl (%edi, %eax, 4), %ebx     # valoarea curenta din vector
    popl %eax

    cmp %eax, %ebx
    je GET_gasit

    incl %ecx
    jmp GET_loop

increment_index_linie_get:
    addl $1, index_linie

    movl index_linie, %ecx
    movl (%esi, %ecx, 4), %ebx
    movl %ebx, right_maxim

    movl $0, %ecx
    jmp GET_loop

NO_GET:
    movl $0, left
    movl $0, right
    movl $0, index_linie
    jmp GET_afisare

GET_gasit:
    incl %ecx

    pushl %eax
    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*8
    addl %ecx, %eax                 # eax = i*8 + j 

    movl (%edi, %eax, 4), %ebx     # valoarea curenta din vector
    popl %eax

    cmp %eax, %ebx                 # cat timp e inca egala cu id
    je GET_gasit

    decl %ecx
    movl %ecx, right
    jmp GET_afisare

GET_afisare:
    pushl right
    pushl index_linie
    pushl left
    pushl index_linie
    pushl $formatGet
    call printf
    popl %ebx
    popl %ebx
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

    movl $0, index_linie
    movl $0, %ecx

    movl (%esi, %ecx, 4), %ebx
    movl %ebx, right_maxim

    movl id, %eax

DELETE_loop:
    cmp %ecx, right_maxim          # for (j = 0; j < right_maxim; j++)
    jl increment_index_linie_delete

    pushl %edx
    pushl %eax

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*8
    addl %ecx, %eax                 # eax = i*8 + j 

    movl (%edi, %eax, 4), %ebx       # %ebx = v[i][j]
    popl %eax
    popl %edx

    cmp %ebx, %eax
    je DELETE_gasit
    cmpl $0, %ebx
    jne DELETE_mamamia

    incl %ecx
    jmp DELETE_loop

increment_index_linie_delete:
    addl $1, index_linie
    movl index_linie, %ecx
    cmpl %ecx, down_maxim
    jl loopInitial

    movl (%esi, %ecx, 4), %ebx
    movl %ebx, right_maxim

    movl $0, %ecx
    jmp DELETE_loop  

DELETE_mamamia:
    movl %ebx, %edx
    movl %ecx, left
    jmp DELETE_while_loop

DELETE_while_loop:
    incl %ecx

    pushl %edx
    pushl %eax

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*8
    addl %ecx, %eax                 # eax = i*8 + j 

    movl (%edi, %eax, 4), %ebx       # %ebx = v[i][j]
    popl %eax
    popl %edx

    cmp %ebx, %edx
    jne DELETE_afisare
    jmp DELETE_while_loop

DELETE_gasit:
    pushl %edx
    pushl %eax

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*8
    addl %ecx, %eax                 # eax = i*8 + j 

    movl $0, (%edi, %eax, 4)
    popl %eax
    popl %edx

    incl %ecx
    jmp DELETE_loop

DELETE_afisare:
    decl %ecx
    movl %ecx, right
    
    pushl right
    pushl index_linie
    pushl left
    pushl index_linie
    pushl %edx
    pushl $formatAfisare
    call printf
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx
    popl %ebx

    movl right, %ecx
    movl id, %eax

    cmp %ecx, right_maxim          
    je increment_index_linie_delete
    
    incl %ecx
    jmp DELETE_loop

exit:

    pushl $0
    call fflush
    popl %ebx

    movl $1, %eax
    movl $0, %ebx
    int $0x80

gresit:
    pushl $0
    pushl $formattest
    call printf                      
    popl %ebx
    popl %ebx
    jmp exit

#    pushl %eax
 #   pushl %ebx
  #  pushl %ecx
   # pushl %edx

#    pushl %edx
#    pushl $formattest
#    call printf                      
 #   popl %ebx
  #  popl %ebx

   # pop %edx
    #pop %ecx
#    pop %ebx
 #   pop %eax