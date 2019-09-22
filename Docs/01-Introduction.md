# OpenSwarm Documentation

## Introduction

OpenSwarm is an open-source library written by Andrew McDonald at the [D-CYPHER Lab](https://www.egr.msu.edu/d-cypher/) at Michigan State University to facilitate research in swarm robotics and human-robot interaction. By providing full-stack control software and models for robot and testbed construction, the repository aims to enable the curious individual to discover, prototype, and perfect swarm control algorithms in their lab, classroom, or home for under \$70 per robot.

### What is Swarm Robotics?

According to [Wikipedia](https://en.wikipedia.org/wiki/Swarm_robotics),

> Swarm robotics is an approach to the coordination of multiple robots as a system which consist of large numbers of mostly simple physical robots. It is supposed that a desired collective behavior emerges from the interactions between the robots and interactions of robots with the environment.

Research in swarm robotics centers on the concept of _swarm intelligence,_ wherein networked systems of individually-simple agents exhibit emergent properties of an intelligent mass. Such swarm intelligence is pervasive in nature, manifesting in

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

As such, areas ripe for the application of swarm robotics include [[1]](https://www.sciencedirect.com/science/article/pii/S221491471300024X?via%3Dihub):

- hazardous search-and-rescue operations
- environmental cleanup operations
- surveillance and monitoring operations
- operations in urban areas
- operations in inhabitable climates
- transportation and mobility

The goal of OpenSwarm is to advance the discovery and development of swarm control algorithms foundational to such applications by creating an accessible and configurable testing platform.

Swarm control algorithms cannot be fully validated by simulation alone; it is essential that metaphorical rubber meets the road, that abstraction meet concretion. By putting swarm theory into practice, OpenSwarm closes the gap in the loop of swarm innovation.

### What is OpenSwarm?

OpenSwarm consists of four primary components:

1. robot design schematics
2. testbed design schmatics
3. server-side control software
4. client-side control software

Together, they enable one to construct a fully-functional swarm research platform in which bi-wheeled, networked, Arduino-controlled robots drive around a testbed and

- are visually tracked by the server-side control program
- recieve algorithmically-determined navigational commands from the server via UDP broadcast
- parse and execute such commands with a client-side control program
- sample and record data describing their local environment
- transmit such local data back to the server via UDP broadcast

Such functionalities enable researchers to develop swarm control algorithms in Matlab that take

- current robot positions _(x,y)<sub>t</sub>_
- past robot positions _(x,y)<sub>t-k</sub>_ (for _k=1,2,..._)
- current robot sensor data (e.g., light levels from an LDR) _s<sub>t</sub>_
- past robot sensor data _s<sub>t-k</sub>_ (for _k=1,2,..._)

as parameters provided by OpenSwarm to generate a set of waypoints towards which robots should navigate. The algorithm can then return such waypoints to OpenSwarm, which will direct the robots to converge upon them.

From an algorithmic interfacing perspective, then, OpenSwarm can be conceptualized as a "black box" with

- **Input:**
  - Targets towards which robots should converge as a `dictionary<id_number, target_position>`
- **Output:**
  - Current position of each robot as a `dictionary<id_number, current_position>`
  - Past position of each robot as a `dictionary<time, dictionary<id_number, current_position>>`
  - Current readout of robot sensor data as a `dictionary<id_number, sensor_readout>`
  - Past readout of robot sensor data as a `dictionary<time, dictionary<id_number, sensor_readout>>`

which enables the control of a robotic swarm in discrete-time iterations.

Robot and testbed schematics are further detailed [here](03-Hardware.md), while software design and functionality is detailed [here](04-Software.md).

### What's Next?

If you're an aspiring swarm researcher, check out the rest of the documentation, clone the repository, and build yourself a swarm research platform! If you're new to the world of swarm robotics, do the same!

As the platform is leveraged to conduct swarm control research internally within the D-CYPHER Lab, problems involving multi-armed bandits, coverage control, collision avoidance, multi-agent cooperation, consensus-building, distributed leadership, traveling salesmen, and adversarial agents will be analyzed, with the ultimate goal of producing publications beginning fall 2019.

If you're interested in collaborating with OpenSwarm, please don't hesitate to [reach out!](A2-Contact.md)

<a href=00-Table-of-Contents.md>Previous: Table of Contents</a>

<a href=02-Getting-Started.md>Next: Getting Started</a>
