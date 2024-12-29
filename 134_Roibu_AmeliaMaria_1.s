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
    dim_max: .long 1024             
    dim_cur: .zero 4
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
    je DEFRAGMENTATION

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

    cmpl $1024, index_linie           
    je ADD_afisare_false

    movl index_linie, %ecx
    cmpl %ecx, down_maxim
    jl actualizare_down

    movl $0, %ecx                  
    jmp cautareSpatiu

cautareSpatiu:
    cmpl %ecx, dim_max                   
    je increment_index_linie

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

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
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

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
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

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
    cmpl %edx, index_linie                
    ja NO_GET

    movl %ecx, left                # pp ca urmatorul ecx este cel bun...

    cmp %ecx, right_maxim          # for (i = 0; i < right_maxim; i++)
    je increment_index_linie_get

    pushl %eax
    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

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
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

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
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

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
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

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
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

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

DEFRAGMENTATION:
    movl $0, index_linie
    movl $0, %ecx
    movl (%esi, %ecx, 4), %ebx
    movl %ebx, right_maxim
    movl $0, %ebx
    movl $0, %eax
    
DEFRAG_loop_mutare:
    cmpl $0, right_maxim          # daca right_maxim == 0, inseamna ca nu avem elemente pe linie
    je increment_index_linie_defrag

    cmp %ecx, right_maxim           # for (i = 0; i < right_maxim; i++)
    jl DEFRAG_preg_afis
    cmpl $0, (%edi, %ecx, 4)        # if (v[i][j] == 0)

    je increment_ebx
    movl (%edi, %ecx, 4), %edx
    cmp %ebx, %ecx
    jne paralell

    incl %ecx                                  
    incl %ebx
    jmp DEFRAG_loop_mutare

increment_index_linie_defrag:
    addl $1, index_linie
    movl index_linie, %eax
    cmpl %eax, down_maxim
    jl continuare_defrag                 # de aici va continua defragmentationul, dupa ce s a facut "unidimensional"
    movl (%esi, %eax, 4), %edx
    cmpl $0, %edx
    je increment_index_linie_defrag
    pushl %edx
    movl $0, %edx
    mull dim_max                         # eax = i*1024
    movl %eax, dim_cur
    movl %eax, %ebx
    movl %eax, %ecx
    popl %edx
    addl %eax, %edx
    movl %edx, right_maxim

    jmp DEFRAG_loop_mutare  

paralell:
    movl %edx, (%edi, %ebx, 4)       # merg in paralel cu v[i][ebx] = v[i][ecx], unde v[i][ecx] sigur este nenul
    movl $0, (%edi, %ecx, 4)         # iar pe v[i][ecx] il golesc apoi
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

ceva:
    movl index_linie, %ecx
    movl $0, (%esi, %ecx, 4)                # capatul din dreapta actualizat
    jmp increment_index_linie_defrag

DEFRAG_preg_afis:
    cmpl %ebx, %eax
    je ceva
    decl %ebx
   
    movl %ebx, right_maxim                  # in ebx voi avea acum capatul din dreapta actualizat
    subl %eax, %ebx
    movl index_linie, %ecx
    movl %ebx, (%esi, %ecx, 4)

    jmp increment_index_linie_defrag
    # movl %eax, %ecx                           # for (i = 0; i < right_maxim; i++)
    # movl (%edi, %ecx, 4), %eax              # eax = primul id
    # movl $0, left                           # memoria incepe de la blocul zero

continuare_defrag:
    movl $0, %ecx                   # ecx = indexul liniei in vector_right_maxim
    movl $0, index_linie
    
nr_zero_end:
    movl index_linie, %ecx
    cmpl %ecx, down_maxim
    je DEFRAG_loop_afisare

    movl (%esi, %ecx, 4), %edx      # edx este right_maxim local
    cmpl $0, %edx
    je baaaaaaaa
    movl $1023, %ebx
    subl %edx, %ebx
    movl %ebx, %edx
    cmpl $1, %edx                   # vedem daca avem loc la capatul liniei
    ja preg_nr_start               # inseamna ca avem loc si vedem ce e pe urmatoarea linie
    
    incl %ecx
    addl $1, index_linie
    
    jmp nr_zero_end

baaaaaaaa:
    movl dim_max, %edx
    jmp preg_nr_start

preg_nr_start:
    addl $1, index_linie
    movl index_linie, %eax
    pushl %edx
    movl (%esi, %eax, 4), %edx
    cmpl $0, %edx
    je nr_zero_end

    movl $0, %edx
    mull dim_max                         # eax = i*1024
    
    movl (%edi, %eax, 4), %ebp          # ebp = primul id
    popl %edx                           # edx = cate blocuri libere sunt pe randul de deasupra

    movl %eax, %ebx                     # ebx = indicele primului elementul de pe rand
    jmp nr_start

nr_start:
    incl %eax
    
    cmpl %ebp, (%edi, %eax, 4)
    je nr_start

    subl %ebx, %eax                     # eax = dimensiunea blocului care ipotetic ar putea fi mutat
    cmpl %eax, %edx
    jae modificare_intre_linii
    jmp nr_zero_end

modificare_intre_linii:
    pushl %ebx
    pushl %edx
    movl index_linie, %ecx
    movl (%esi, %ecx, 4), %edx
    incl %edx                           # edx = cate blocuri sunt ocupate pe rand
    cmpl %eax, %edx                     # daca eax = edx, inseamna ca e un singur element pe rand => right_maxim = 0
    je eticheta
    popl %edx
    movl $0, %ecx                            # (for i = 0; i < eax; i++)
    jmp loop_golire

eticheta:
    popl %edx
    movl $0, (%esi, %ecx, 4)
    movl $0, %ecx                            # (for i = 0; i < eax; i++)
    jmp loop_golire

loop_golire:
    movl $0, (%edi, %ebx, 4)
    incl %ecx
    incl %ebx
    cmpl %ecx, %eax
    je asdfghjkl

    jmp loop_golire

asdfghjkl:
    popl %ebx
    decl %ebx                       # ebx = indicele ultimului element de pe randul anterior
    movl index_linie, %ecx
    decl %ecx
    movl $1023, (%esi, %ecx, 4)        # actualizez right_maxim pe randul anterior
    movl $0, %ecx                   # (for i = 0; i < eax; i++)

    jmp loop_umplere

loop_umplere:
    movl %ebp, (%edi, %ebx, 4)
    incl %ecx
    decl %ebx
    cmpl %ecx, %eax
    je DEFRAGMENTATION

    jmp loop_umplere

DEFRAG_loop_afisare:
    movl $0, index_linie
    movl $0, %ecx

    movl (%esi, %ecx, 4), %ebx
    movl %ebx, right_maxim

DEFRAG_loop:
    cmp %ecx, right_maxim          # for (j = 0; j < right_maxim; j++)
    jl increment_index_linie_afisare_defrag

    pushl %edx
    pushl %eax

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

    movl (%edi, %eax, 4), %ebx       # %ebx = v[i][j]
    popl %eax
    popl %edx

    cmpl $0, %ebx
    jne AFIS_mamamia

    incl %ecx
    jmp DEFRAG_loop

increment_index_linie_afisare_defrag:
    addl $1, index_linie
    movl index_linie, %ecx
    cmpl %ecx, down_maxim
    jl loopInitial

    movl (%esi, %ecx, 4), %ebx
    movl %ebx, right_maxim

    movl $0, %ecx
    jmp DEFRAG_loop  

AFIS_mamamia:
    movl %ebx, %edx
    movl %ecx, left
    jmp DEFRAG_while_loop

DEFRAG_while_loop:
    incl %ecx

    pushl %edx
    pushl %eax

    movl index_linie, %eax
    movl $0, %edx
    mull dim_max                         # eax = i*1024
    addl %ecx, %eax                 # eax = i*1024 + j 

    movl (%edi, %eax, 4), %ebx       # %ebx = v[i][j]
    popl %eax
    popl %edx

    cmp %ebx, %edx
    jne DEFRAG_afisare
    jmp DEFRAG_while_loop

DEFRAG_afisare:
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

    cmp %ecx, right_maxim          
    je increment_index_linie_afisare_defrag
    
    incl %ecx
    jmp DEFRAG_loop

exit:
    pushl $0
    call fflush
    popl %ebx

    movl $1, %eax
    movl $0, %ebx
    int $0x80