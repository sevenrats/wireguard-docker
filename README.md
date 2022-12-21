Build the base image and tag it ubuntu-base:dev, which is what the wg dockerfile will build on.

```docker build -t ubuntu-base:dev .```

Then build the client container.

The vast majority of the hard work done for these containers was done by the team at LinuxServer.io, not me.