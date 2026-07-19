# Signal Numbers

## Description

**Signal Numbers is a library mod intended for use by other mod developers. It does not make gameplay changes.**

**Signal Numbers** is a tool for CPU usage optimiziation in mods that make extensive use of `SignalID`s. During the data phase, it creates deterministic numerical hash codes for all possible `SignalID`s and stores it in `mod-data`. It also provides a small library that can be `require`d by consuming mods in the control phase to quickly map between `SignalID`s and corresponding numerical hash codes.

## Contributing

Please use the [GitHub repository](https://github.com/project-cybersyn/things) for questions, bug reports, or pull requests.
