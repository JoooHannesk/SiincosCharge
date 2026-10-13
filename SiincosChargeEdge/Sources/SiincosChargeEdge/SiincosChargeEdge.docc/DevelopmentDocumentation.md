# Development Documentation

## Simulating digital inputs on the GPIOs
Complying with §14 EnWG according to German law requires the edge controller to temporarily pause or limit the power drawn from the grid - when requested by the grid-operator. This is currently implemented via digital inputs through the GPIOs. To simulate this behavior without (attaching) real hardware I needed something to plug between the SiincosChargeEdge service and the actual GPIO subsystem.

### Current implementation in SiincosChargeEdge
The service doesn't talk to the GPIO hardware directly. It calls the standard libgpiod command-line tool `gpioget` and parses its output. Because that boundary is just an executable, I can swap it for a fake one on macOS for testing, simulating and debugging purposes. This lets me run the complete, unchanged service in Xcode and toggle the "contact" from a terminal while it runs.

The fake consists of two small POSIX shell scripts, which can be found in *Simulation/gpioget*:

- **`gpioget`** is a drop-in replacement for the real tool. It accepts the same arguments and produces the same output format, but reads line states from files instead of `/dev/gpiochipN`.
- **`fakegpio`** is a helper to create and change those states, e.g. to close the contact, simulate contact bounce, or make `gpioget` fail.

### How it works

Line states are stored as plain files in a `.fake-gpio` folder next to the scripts (`.fake-gpio/<chip>/<offset>`). Each file contains `0`, `1`, or `busy`. You can set `FAKE_GPIO_DIR` to use a different location.

On the reComputer, the DI protection circuit inverts the signal: an active (closed) contact pulls the line **low**. `fakegpio` mirrors this. You set *contact* states, and the fake line reads the inverted level, just like the real device:

| `fakegpio set 18 …` | Contact | `gpioget --numeric` reads |
|---------------------|---------|---------------------------|
| `1`                 | closed  | `0`                       |
| `0`                 | open    | `1`                       |

Set `FAKE_GPIO_INVERT=0` to disable the inversion.

### Setup

```bash
chmod +x gpioget fakegpio
./fakegpio init          # creates lines 18 and 19, contact open
```
TODO: probably add symlink to /usr/bin/gpioget on macOS? Check first.

### `gpioget` (fake)

It supports the libgpiod v2 syntax and the basic v1 form:

```bash
gpioget -c gpiochip0 18 19            # "18"=active "19"=active
gpioget -c gpiochip0 --numeric 18 19  # 1 1
gpioget -c gpiochip0 -l --numeric 18  # active-low: inverted logical value
gpioget --unquoted GPIO18             # lookup by line name
gpioget gpiochip0 18 19               # v1 syntax, numeric output
```

Errors behave like the real tool: a message on stderr and exit code 1 (unknown
line, unknown chip, or a line marked `busy`).

### `fakegpio`

```bash
fakegpio init [OFFSET...]             # create lines (default 18 19), contact open
fakegpio set OFFSET 0|1               # set contact state (1 = closed)
fakegpio toggle OFFSET                # flip contact state
fakegpio bounce OFFSET 0|1 [N] [MS]   # flip N times every MS ms, then settle
fakegpio busy OFFSET                  # make gpioget fail ("Device or resource busy")
fakegpio show                         # print contact state and raw line level
fakegpio reset                        # delete all fake state
```

Use `FAKE_GPIO_CHIP=gpiochip1` to work on a chip other than `gpiochip0`.

### Limitations

The fake tests my *assumptions* about the hardware, not the hardware itself.
Wiring, the actual chip/offset mapping, real bounce behavior, and timing still
need to be verified on the reComputer, e.g. with the real `gpioget` while
toggling the physical contact.
