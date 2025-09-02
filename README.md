# Run test using docker 

you can run the tests on the published docker image, simply by running this command

```bash
docker run --rm -v ./target/release/ziskemu:/program ghcr.io/0xpolygonhermez/ziskof:latest
```

where `./target/release/ziskemu` is the path to the `ziskemu` binary.

you should get something like this:

```bashc
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/I/src/xori-01.S : b91f98f3a0e908bad4680c2e3901fbc24b63a563 : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/div-01.S : 9b503d7890296e53aa8a06e49ebef3c61ce5d3fd : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/divu-01.S : 4e61c25bdd4ec4e7b9894a6c85a997b496a83bb2 : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/divuw-01.S : 9b503d7890296e53aa8a06e49ebef3c61ce5d3fd : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/divw-01.S : 9b503d7890296e53aa8a06e49ebef3c61ce5d3fd : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/mul-01.S : 4e61c25bdd4ec4e7b9894a6c85a997b496a83bb2 : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/mulh-01.S : 4e61c25bdd4ec4e7b9894a6c85a997b496a83bb2 : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/mulhsu-01.S : 4e61c25bdd4ec4e7b9894a6c85a997b496a83bb2 : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/mulhu-01.S : 4e61c25bdd4ec4e7b9894a6c85a997b496a83bb2 : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/mulw-01.S : 9b503d7890296e53aa8a06e49ebef3c61ce5d3fd : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/rem-01.S : 4e61c25bdd4ec4e7b9894a6c85a997b496a83bb2 : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/remu-01.S : 4e61c25bdd4ec4e7b9894a6c85a997b496a83bb2 : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/remuw-01.S : 9b503d7890296e53aa8a06e49ebef3c61ce5d3fd : Passed
    INFO | /workspace/riscv-arch-test/riscv-test-suite/rv64i_m/M/src/remw-01.S : 9b503d7890296e53aa8a06e49ebef3c61ce5d3fd : Passed
    INFO | Test report generated at /workspace/output/riscof_work/report.html.
    INFO | Opening test report in web-browser

```

by running an `echo $?` you will know if all tests have been passed (0) or if there was an error (=!0).

# Extract elf and signatures
```
docker run --rm -v ${ABSOLUTE_PATH}/ziskemu:/program -v ${ABSOLUTE_PATH}/ziskof_workspace/:/workspace/output 
ghcr.io/0xpolygonhermez/ziskof
```

You will obtain the result of the execution in `~/ziskof_workspace`.

# Build docker image
    
```bash
$ docker build -t ziskof:latest .
```

# Tutorial for running Riscof test suit [Manually]

## Intro

[riscof](https://github.com/riscv-software-src/riscof) is a set of tests designed to check the riscV standard.

The Zisk riscV simulator passes all the copliance tests provided in this test suit.

You can follow this instructions to run the tests yourself.

At the end of this tutorial there are a set of instructions and tips to help to debug and fix any bug.

## Install riscof

First of all install

Follow instructions [here](https://riscof.readthedocs.io/en/latest/installation.html)

go to the riscof directory

```console
$ cd $ZISKJS/riscof
```

And now prepare all the test:

```console
$ riscof --verbose info arch-test --clone
$ riscof validateyaml --config=config.ini
$ riscof testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env
```

And finally run the tests:

```console
$ riscof run --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env
```


## Steps to fix a test

This procedure is important to follow when want to debug a specific program.


Set ZISKJS endvirotment variable

```console
$ ZISKJS=~/ziskjs
```

Create a directory of it does not exist

```console
$ mkdir -p $ZISKJS/work
```

Delete the files if any

```console
$ rm $ZISKJS/work/*
```



### Copy the elf file to work directory

```console
$ cp $ZISKJS/riscof/riscof_work/rv64i_m/A/src/amoadd.d-01.S/dut/my.elf $ZISKJS/work
```

### Disassembly

```console
$ riscv32-unknown-elf-objdump --disassemble-all $ZISKJS/work/my.elf >$ZISKJS/work/my.asm
```


### Extract the qemu trace

In one terminal:

```console
$ qemu-system-riscv64 -cpu rv64 -machine virt -m 1G -nographic -bios $ZISKJS/work/my.elf -gdb tcp:localhost:2222 -S
```

In another terminal

Make sure in the other terminal you also defined the env var ZISKJS
```console
$ riscv64-unknown-elf-gdb --batch -ex "py traceFile=\"$ZISKJS/work/qemu.tr\"" -x $ZISKJS/test/zisk_trace_gdb.py
```

In the original window, the qemu should end if the program terminates succefully

### Extract the zisk trace

First convert the elf to a rom
```console
$ node $ZISKJS/src/rv2zisk/main.js $ZISKJS/work/my.elf -r $ZISKJS/work/my.ziskrom
```

Now execute the simulator in trace mode

```console
$ node $ZISKJS/src/sim/main.js -r $ZISKJS/work/my.ziskrom -n 100000 -t $ZISKJS/work/zisk.tr
```


### Compare the traces

```console
$ diff $ZISKJS/work/qemu.tr $ZISKJS/work/zisk.tr
```

You  can also use visual code to compare two files: [chack here](https://learn.microsoft.com/en-us/visualstudio/ide/compare-with?view=vs-2022)

In the simulator, tou can put a conditional breakpoint of the form:

```js
ctx.pc == 0x800000020
```

And debug the code at a given point.

For reference, this is how my configurations file looks like to debug:

```json
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [

        {
            "type": "node",
            "request": "launch",
            "name": "rv2zisk my.elf",
            "skipFiles": [
                "<node_internals>/**"
            ],
            "args": [
                "work/my.elf",
                "-r work/my.ziskrom"
            ],
            "program": "src/rv2zisk/main.js"
        },
        {
            "type": "node",
            "request": "launch",
            "name": "sim my.elf",
            "skipFiles": [
                "<node_internals>/**"
            ],
            "args": [
                "-r work/my.ziskrom",
                "-n 100000",
                "-t work/zisk.tr",
                "-p 0"
            ],
            "cwd": "${workspaceFolder}",
            "program": "src/sim/main.js"
        },
        {
            "type": "node",
            "request": "launch",
            "name": "test test0",
            "skipFiles": [
                "<node_internals>/**"
            ],
            "args": [
                "/home/jbaylina/ziskjs/work/my.elf",
            ],
            "cwd": "${workspaceFolder}",
            "program": "riscof/zisk_tester.js"
        }
    ]
}
```
