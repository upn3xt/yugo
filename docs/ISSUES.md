# Issues 

Dedicated part to let know issues be resolved.

## Feature: Download packages 

For a container, downloading packages is a big deal. Since it's what makes more complex programs to run, like: games and desktop apps. The thing is that this 
on the CLI will become messy and just won't work. So using the yugo.toml file as schema to declare dependencies, download and load them to the container and 
make the application run is the goal.

The test could be made using FNF as example. Some dependencies are not available in the rootfs and to load the container with them is the goal to make sure 
this feature works.

