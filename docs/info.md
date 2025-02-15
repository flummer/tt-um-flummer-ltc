<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Multiple counters to maintain time and framecount, with serial output of the LTC (80 bit frames, biphase mark code)

## How to test

The project should have 50 MHz clock signal applied and after reset, will start out with a 00:00:00:00 timecode at starts to count.

Framerate is controlled by the ui[2] and ui[3]

| ui[3] | ui[2] | Framerate |
| ----- | ----- | --------- |
| 0     | 0     | 24        |
| 0     | 1     | 25        |
| 1     | 0     | 30        |
| 1     | 1     | 29.97     |

Hours, minutes and seconds can be incremented using ui[5], ui[6] and ui[7] respectively.

## External hardware

This should work with the audio PMOD connected to the bidirectional port, to give levels useable for audio gear.

If testing with logic analyzer or similar, uio[7] can be directly connected. The signal is a digital signal.
