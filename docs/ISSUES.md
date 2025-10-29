# Issues 

Dedicated part to let know issues be resolved.

## Feature: Download packages 

For a container, downloading packages is a big deal. Since it's what makes more complex programs to run, like: games and desktop apps. The thing is that this 
on the CLI will become messy and just won't work. So using the yugo.toml file as schema to declare dependencies, download and load them to the container and 
make the application run is the goal.

The test could be made using FNF as example. Some dependencies are not available in the rootfs and to load the container with them is the goal to make sure 
this feature works.

## Feature: Build the container without running it

Right now, yugo just runs the application in a containerized environment. This good. But later becomes a pain in the ass to have to navigate the folder, load 
deps, yada yada yada. Just like docker, I'd like to make 'container executables'. It would be like `yugo start <container-name>:<version>`. This would make one 
able to start the container anywhere and to create a 'container executable' it would be like `yugo build [args]`. This would scan the directory for the yugo 
file, read the file, prepare the environment, add it to the `/home/USER/.yugo/containers/` and just be there. The start command would just look into the 
container and version and execute it.

## Issue: Parser is not working due version mismatch

Fix this when connected to internet.
