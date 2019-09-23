# OpenSwarm Documentation: Getting Started


## Testbed Setup

### Bill of Materials

| Item                                                                                                                                                                                                                                                                                                                                                                                                    | Quantity | Price |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----- |
| [Generic Webcam (resolution ≥ 1024x768)](https://www.amazon.com/LARMTEK-Webcam-Computer-Conference-Calling/dp/B07P84DN2K/ref=sxin_2_ac_d_pm?ac_md=2-0-VW5kZXIgJDUw-ac_d_pm&keywords=webcam+1080p&pd_rd_i=B07P84DN2K&pd_rd_r=7355076c-f61d-4db2-a713-7bf372be113c&pd_rd_w=3ffow&pd_rd_wg=xa1kL&pf_rd_p=eeff02d5-070a-45ea-a79e-d591974b877e&pf_rd_r=BVP14A6HNQECBXCC8MRB&psc=1&qid=1568577545&s=gateway) | 1        | \$30  |
| [Generic Router](https://www.amazon.com/TP-Link-N450-Wi-Fi-Router-TL-WR940N/dp/B001FWYGJS/ref=sr_1_5?keywords=router&qid=1568577613&s=gateway&sr=8-5&th=1)                                                                                                                                                                                                                                              | 1        | \$20  |
| Control Computer [(Intel/AMD x86/x64, 4GB RAM)](https://www.mathworks.com/support/requirements/matlab-system-requirements.html) | 1 | -
| Open Floor Space (25-100 ft<sup>2</sup>) with Overhead Mount for Webcam                                                                                                                                                                                                                                                                                                                                 | 1        | -     |
| **Total**                                                                                                                                                                                                                                                                                                                                                                                               |          | \$50  |

### Directions 

To utilize OpenSwarm, one must first designate an area in which to construct a physical testbed. Any flat, indoor space of size 25-100ft<sup>2</sup> will work, provided that a webcam may be mounted on the ceiling or suspended above the space in some other manner. Marking the perimeter of this space with masking tape is not necessary, but is recommended to form a frame of reference later on.

Once a location for the physical testbed has been chosen, a generic USB webcam of resolution ≥ 1024x768 must be mounted facing downwards directly above the center of the field. This will enable the OpenSwarm server software to visually track robots as they move about the field and monitor the position of each robot in discrete-time iterations.

Next, a generic router must be configured within range of the testbed to enable local communications across a wireless network; note that an internet connection is not necessary. The router will support UDP communication between the OpenSwarm server and each client robot.

Finally, a [computer capable of running Matlab](https://www.mathworks.com/support/requirements/matlab-system-requirements.html), connecting to the local network, and receiving video input from the mounted webcam must be configured; chances are that the PC you're reading this on will work just fine for such tasks.

At this stage, your testbed should reflect the conceptual diagram included below (computer not pictured).

![](Images/Testbed.png)

Next, it's time to construct the swarm itself: the robots.

## Robot Setup

## Software Setup

## Testing

<a href=01-Introduction.md>Previous: Introduction</a>

<a href=03-Hardware.md>Next: Hardware</a>
