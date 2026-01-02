# Static Builder for ra1nsn0w

A portable build script that compiles `ra1nsn0w` and all its dependencies into static binaries. Supports `macOS` and `Linux`.


## Guide

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/9LogM/ra1nsn0w.git
    cd ra1nsn0w
    ```

2.  **Make the build script executable:**
    ```bash
    chmod +x ./build.sh
    ```

3.  **Run the build script:**
    ```bash
    ./build.sh
    ```

## Output

The script creates a `_install` directory containing the full suite, but the static tools are located in their respective source folders:

* **ra1nsn0w:** `./ra1nsn0w/ra1nsn0w`
* **iBootPatcher:** `./tools/iBootPatcher/iBootPatcher`
* **kernelPatcher:** `./tools/kernelPatcher/kernelPatcher`

You can now copy these files anywhere; they are self-contained.