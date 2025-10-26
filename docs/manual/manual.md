# Yugo codebase manual

This is a manual for both future contributors and for me for whenever lost.

## The intent

The goal is to make yugo a working containerization tool. To run things in a safe environment, download packages when missing, read images for more complex 
containers and overall make a lightweight container environment to run "anything".


## How it works 

By now, you can run things using `yugo run <path> <executable>` command. Like, using bash as executable allows you to be inside the file system for the process.


## Technical details

The flow of the code is like this:

When running a container, you use the `run` function to wrap the arguments, make a copy of the file system and then call the `cloneWrapper` and actually make the container creation process.

Speaking of process, the `process` function unwraps the arguments then calls the `containerize` function to prepare the environment. After the environment is 
ready the `runCommand` function is called to execute the main file(executable).
