# Unix Shell x86-64 Assembly

## Project Description
### Goals
* **Implement Unix Shell** in pure x86-64 assembly using Linux system calls.
* **True Experience:** Explore the depth of hardware/software capabilities and their connection without C library abstractions.
* **Understanding:** Master the low-level interactions between the OS (Kernel) and user space programs.

### Functionality
* **Write:** Use syscall 1 (`sys_write`) to output to stdout.
* **Read:** Use syscall 0 (`sys_read`) to capture user input.
* **Exit:** Use syscall 60 (`sys_exit`) for clean termination.
* **Navigation:** Built-in `cd` command using syscall 80 (`sys_chdir`).
* **Execution:** Run external programs via the `fork` -> `execve` -> `wait4` lifecycle.

## Implementation Details

### Project Structure
* **`Makefile`**: Handles compilation (linking with `-no-pie` to prevent position-independent executable complications).
* **`main.s`**: Contains the core logic, data sections (`.rodata`, `.bss`), and text sections.

### 1. The Infinite Loop (REPL)
The shell operates on a "Read-Eval-Print Loop":
1.  **Prompt:** Prints `myshell>` (or dynamic path) to the screen.
2.  **Input:** Reads raw bytes into a buffer via `sys_read`.
3.  **Sanitization:** Manually replaces the detected newline character (`\n`) with a null terminator (`0`) to ensure C-string compatibility.

### 2. Parsing Logic (Tokenization)
Since standard C libraries are forbidden (except `strtok`), parsing is handled manually:
* **Strategy:** Uses `strtok` to destructively split the input string by spaces.
* **Storage:** Pointers to each token are stored in an `argv` array in the `.bss` section.
* **Termination:** The `argv` array is explicitly NULL-terminated to meet `execve` requirements.

### 3. Command Dispatcher (The Router)
A logical dispatcher routes the command based on the first token (`argv[0]`):
* **Comparison:** Manual byte-by-byte comparison is performed (without `strcmp`) to detect built-in commands.
* **Flow:**
    * If `argv[0] == "exit"` -> Jump to Exit Handler.
    * If `argv[0] == "cd"` -> Jump to Change Directory Handler.
    * **Default** -> Jump to External Command Handler.

### 4. Built-in Commands
* **Exit:** Invokes `sys_exit` to terminate the shell process.
* **CD (Change Directory):**
    * Uses `sys_chdir` to change the parent process's directory.
    * Includes error handling (checking for negative `rax`) to report "Path not found" to the user.

### 5. External Commands (Process Management)
Implements the standard Unix process lifecycle for running external programs:
* **Fork (Syscall 57):** Clones the shell.
    * **Child Process:** Executes the command logic and calls `sys_execve` (Syscall 59).
    * **Parent Process:** Calls `sys_wait4` (Syscall 61) to pause execution until the child process terminates, preventing "zombie" processes and output corruption.

---

## Extra Features (Advanced Implementation)

### 6. Dynamic PATH Resolution (The "Which" Logic)
To enable running commands like `ls` instead of the full path `/bin/ls`, the shell implements a manual search algorithm that mimics real shells:
1.  **Environment Parsing:** Iterates through the stack's `envp` array (found via `%rdx` in `main`) to locate the `PATH=` string.
2.  **Tokenization:** Splits the PATH variable by the colon (`:`) delimiter to get a list of system directories.
3.  **Trial Loop:** For every command:
    * Constructs a potential full path (e.g., `/usr/bin` + `/` + `ls` + `\0`).
    * Uses **Syscall 21 (`sys_access`)** with flag `X_OK` (1) to check if the file exists and is executable.
    * If found, the valid path is passed to `execve`.