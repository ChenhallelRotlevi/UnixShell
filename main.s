.section .rodata
    terminal: .string "myshell~"
    terminal_end: .string ">$ "
    delim: .string " "
    delim_path: .string ":"
    testString: .string "%s\n"
    exit_str: .string "exit"
    cd_str: .string "cd"
    text_cd: .string "i love choclate\n"
    cdNoArgs_str: .string "cd Error: no arguments\n" 
    cdPathNotFound_str: .string "cd Error: path not found\n"
    ErrorExec_str: .string "Error execve: Command not found\n"
.section .bss 
    cwd_buffer: .skip 2048
    buffer: .skip 1024
    argv: .skip 48
    PATH_token: .skip 64
    buffer_fullpath: .skip 1024

.section .text
.global main


main: 
	push %rbp 
	movq %rsp, %rbp
#    movq %rsp, %rbx
/*
find_envp_index:
    movq (%rbx), %rdx
    cmpq $0, %rdx
    je find_path_loop
    addq $8, %rbx
    jmp find_envp_index
*/
find_path_loop:
#   addq $8, %rdx
    movq (%rdx), %rbx
    
    cmpq $0, %rbx        
    je   mainLoop        

    cmpb $'P', (%rbx)
    jne next_env

    cmpb $'P', (%rbx)
    jne next_env
    cmpb $'A', 1(%rbx)
    jne next_env
    cmpb $'T', 2(%rbx)
    jne next_env
    cmpb $'H', 3(%rbx)
    jne next_env
    cmpb $'=', 4(%rbx)
    jne next_env
    jmp found_path 

next_env:
    addq $8, %rdx
    jmp find_path_loop
    
found_path:
    addq $5, %rbx
    movq $0, %rdx
    movq %rbx, %rdi
    movq $delim_path, %rsi
    push %rbx
    push %rdx
    xor %rax, %rax
    call strtok
    pop %rdx
    pop %rbx
    movq %rax, PATH_token(,%rdx, 8)
token_loop:
    incq %rdx
    movq $0, %rdi
    movq $delim_path, %rsi
    push %rdx
    push %rbx
    xor %rax, %rax
    call strtok
    pop %rbx
    pop %rdx
    movq %rax, PATH_token(,%rdx, 8)
    cmpq $0, %rax
    jg token_loop

mainLoop:
    movq $0, %rax             
    movq $256, %rcx           
    movq $cwd_buffer, %rdi         
    rep stosq   

    movq $79, %rax
    movq $cwd_buffer, %rdi
    movq $2048, %rsi
    syscall 

	movq $1, %rax  
	movq $1, %rdi
	movq $terminal, %rsi
  	movq $8, %rdx
	syscall 

    movq $1, %rax  
	movq $1, %rdi
    movq $cwd_buffer, %rsi
  	movq $2048, %rdx
	syscall 

    movq $1, %rax  
	movq $1, %rdi
    movq $terminal_end, %rsi
  	movq $3, %rdx
	syscall 

    movq $0, %rax
    movq $0, %rdi
    movq $buffer, %rsi
    movq $1024, %rdx
    syscall 

    cmp $0, %rax
    jle exit_program
    dec %rax
    movb $0, buffer(,%rax, 1)
    
    movq $0, %rbx
    movq $delim, %rsi
    movq $buffer, %rdi 
    xor %rax, %rax
    call strtok
    movq %rax, argv(,%rbx, 8)
    
parseLoop:
    incq %rbx

    movq $delim, %rsi   
    movq $0, %rdi
    xor %rax, %rax 
    push %rbx 
    call strtok
    pop %rbx
    
    movq %rax, argv(, %rbx, 8)
    cmpq $0, %rax
    jg parseLoop

    movq argv(%rip), %rbx
    cmp $0, %rbx
    je mainLoop
    
    movq $exit_str, %rdx
    movl (%rbx), %eax
    movl (%rdx), %ecx
    cmpl %eax, %ecx
    jne cd_check 
    movb 4(%rbx), %al
    movb 4(%rdx), %cl
    cmpb %cl, %al
    je do_exit 
    
cd_check:
    movq $cd_str, %rdx
    movb (%rbx), %al
    movb (%rdx), %cl
    cmpb %cl, %al
    jne default
    movb 1(%rbx), %al
    movb 1(%rdx), %cl
    cmpb %cl, %al
    jne default
    movb 2(%rbx), %al
    movb 2(%rdx), %cl
    cmpb %cl, %al
    jne default
    jmp do_cd

default:
    
    movq $57, %rax
    syscall
    cmpq $0, %rax
    jl do_exit
    jg parent
child:
    movq $0, %rbx
find_right_path_loop:
    movq PATH_token(,%rbx, 8), %rcx
    movq $0, %rdx
copy_dir_loop:
    movb (%rcx), %al                     
    cmpb $0, %al                        
    je copy_dir_done                  
    
    movb %al, buffer_fullpath(,%rdx,1)   
    incq %rcx                            
    incq %rdx                            
    jmp  copy_dir_loop
copy_dir_done:

    movb $'/', buffer_fullpath(,%rdx, 1) 
    incq %rdx

    movq argv(%rip), %rcx                

copy_cmd_loop:
    movb (%rcx), %al                     
    cmpb $0, %al                        
    je   copy_cmd_done
    
    movb %al, buffer_fullpath(,%rdx,1)   
    incq %rcx
    incq %rdx
    jmp  copy_cmd_loop
copy_cmd_done:
    movq $21, %rax
    movq $buffer_fullpath, %rdi
    movq $1, %rsi
    syscall
    cmpq $0, %rax
    je right_path

    movq $0, %rax             
    movq $128, %rcx           
    movq $buffer_fullpath, %rdi         
    rep stosq 

    incq %rbx
    cmpq $0, %rbx 
    jle ErrorExec 
    jmp find_right_path_loop

right_path:
    movq $59, %rax
    movq $0, %rbx
    movq $buffer_fullpath, %rdi
    movq $argv, %rsi
    movq $0, %rdx
    syscall
    jmp ErrorExec
parent:
    movq %rax, %rdi
    movq $0, %rsi
    movq $0, %rdx
    movq $0, %r10
    movq $61, %rax
    syscall
    jmp end_command


do_exit:
    movq $60, %rax
    movq $0, %rdi
    syscall
do_cd:
    movq $1, %rbx
    cmpb $0, argv(,%rbx ,8)
    jle cdNoArgs
    movq $80, %rax
    movq argv(,%rbx, 8), %rdi
    syscall 
    cmpq $0, %rax
    jl cdPathNotFound
    jmp end_command

cdNoArgs:
    movq $1, %rax  
	movq $2, %rdi
	movq $cdNoArgs_str, %rsi
  	movq $23, %rdx
	syscall 
    jmp end_command
cdPathNotFound:
    movq $1, %rax  
	movq $2, %rdi
	movq $cdPathNotFound_str, %rsi
  	movq $25, %rdx
	syscall 
    jmp end_command

ErrorExec:
    movq $1, %rax  
	movq $2, %rdi
	movq $ErrorExec_str, %rsi
  	movq $32, %rdx
	syscall 
    jmp do_exit

end_command:
    jmp mainLoop
exit_program:
	movq %rbp, %rsp
	pop %rbp
	ret
