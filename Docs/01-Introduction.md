# OpenSwarm Documentation

## Introduction

OpenSwarm is an open-source library produced by the [D-CYPHER Lab](https://www.egr.msu.edu/d-cypher/) at Michigan State University to facilitate research in swarm robotics and human-robot interaction. By providing end-to-end control software and models for robot and testbed construction, the repository aims to enable the curious individual to discover, prototype, and perfect swarm control algorithms in their lab, classroom, or home for under \$70 per robot.

### What is Swarm Robotics?

According to [Wikipedia](https://en.wikipedia.org/wiki/Swarm_robotics),

> Swarm robotics is an approach to the coordination of multiple robots as a system which consist of large numbers of mostly simple physical robots. It is supposed that a desired collective behavior emerges from the interactions between the robots and interactions of robots with the environment.

Research in swarm robotics revolves around the concept of _swarm intelligence,_ wherein networked systems of individually-simple agents exhibit emergent properties of an intelligent mass. Such swarm intelligence is pervasive in nature, manifesting in

- baterial colonies
- ant colonies
- honeybee colonies
- schools of fish
- flocks of birds

According to [[1]](https://www.sciencedirect.com/science/article/pii/S221491471300024X?via%3Dihub), in fact, the field of swarm intelligence evolved into an interdisciplinary hub of research after drawing its original inspiration from nature in the 1980s:

> It has been observed a long time ago that some species survive in the cruel nature taking the advantage of the power of swarms, rather than the wisdom of individuals. The individuals in such swarm are not highly intelligent, yet they complete the complex tasks through cooperation and division of labor and show high intelligence as a whole swarm which is highly self-organized and self-adaptive.

Swarm robotics is especially useful in accomplishing tasks which [[1]](https://www.sciencedirect.com/science/article/pii/S221491471300024X?via%3Dihub):

- cover a large geographic area
- impose danger on the agent
- require repetitive, self-similar behavior
- require distributed, decentralized control
- require high degrees of autonomy
- require adaptive, flexible behaviors
- are prone to local variance
- are best carried out in parallel sequences
- leverage emergent behavior
- are embedded in complex systems

As such, areas ripe to the application of swarm robotics include [[1]](https://www.sciencedirect.com/science/article/pii/S221491471300024X?via%3Dihub):

- hazardous search-and-rescue operations
- environmental cleanup operations
- surveillance and monitoring operations
- operations in urban areas
- operations in inhabitable climates
- transportation and mobility

The goal of OpenSwarm is to make the discovery and development of swarm control algorithms behind such applications more accessible.

### What is OpenSwarm?

OpenSwarm consists of four primary components: robot design schematics, testbed design schmatics, server-side control software, and client-side control software. Together, they enable one to construct a fully-functional swarm robotics experimentation station.

<a href=00-Table-of-Contents.md>Previous: Table of Contents</a>

<a href=02-Getting-Started.md>Next: Getting Started</a>
