# Yugo Development Journal

Today(2025-08-21), I pick up on the Yugo project. Each and each day I spent time using NixOs, this necessity grew more and more. I need this runtime to build my 
linux distribution around it just like Nix, but this time without that carying on nix problems and bad ecossytem.

The yugo idea file still needs to be worked on which is going to become the readme of this project.

Right now this is what I've achieved on the project so far:

- Can parse a yugo.toml file 
- Can create containers from scratch

With that in mind I plan to trace the current state of the project to map where I am(which is what im doing rn) and:

- Make a mapper that scans the file and creates the container based on the configuration that was passed to it

For this to be executed correctly and not fuck up my computer, I have to create a development environment in a docker container for safety and then 
start putting the containers to test. So the plan now is:

1º Create a development environment in a docker container
2º Create a mapper that can scan the file in a directory, read it and make a container of it
3º Test and evolve from there


## A model idea!

I guess by now that I have the architecture of yugo sort of ready. Before any file reading and container creation, I need to create the space for that to happen,
meaning, I need a file structure for using the yugo cli commands. Let's say I have a directory containing my game right, I have a yugo.toml file and say:
`yugo build`, then what's going to happen is: 

- Do checks for existing directories in .yugo/worlds and if it's setup
- Copy the game directory to that location
- Make it a container like a executable 

In other words, work first on the cli architecture and then start to make specifiers like container name and etc.


## This is messy

Yesterday I came back to the project because it's been a while since I thought about it or code in it and it's messier than ever. Idk how it would work but it 
just did and it was wrong. There was some argument confusion there but now it's fixed. Another issue is the execution of other code. I created a minimal http 
server to test it with other programs besides bash. As I'm writing this, I suspect that, that is happening because the file doesnt exist in the file system. 
So it can't execute. (Got this while I was shitting).

As I suspected, it was that! HAHAHAHAHHA, BACKGROUND J*BS BABY! 


## Still messy but this time...

Today I did the thing. Porting the objects to the container(a yugo one). Works as it should, when you do `yugo run directory/ bash` you get inside the container 
with the directory which was placed the yugo file and the call of the command and copy everything. Then you can call the object however you'd wish. But there's 
something missing, actually a couple of things: background jobs execution on the fly and a way to list instance of my containers. That's the next step.


## Too messy for not to do something about it

I guess is time to try a new approach with the CLI. Using the file to determine certain aspects of the container. 
