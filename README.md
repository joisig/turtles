# Turtles

Turtles is a home automation solution, initially for controlling Shelly dimmers
(hence the name), now also for Philips Hue and other Zigbee lights using the
Hue Zigbee bridge.

Right now, supports only dimmers, controlling on/off state and brightness.
Would likely work with color lights but wouldn't change their color.

Lights' state can be controlled through a little web-based GUI.

Scenes can be created based on all or a subset of the current state of dimmers,
and can later be applied or deleted.

There's a horrible amount of Phoenix boilerplate still in this project, haven't
had time to rip out all the unnecessary bits, but the system works reliably
and is usable.
