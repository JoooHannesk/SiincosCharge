# External Load Limiting (§14a EnWG grid compliance)

Designed with German grid regulations in mind. The system is designed to interface with a grid operator receiver / ripple control receiver (digital inputs on the edge hardware) to temporarily pause or dim charging sessions down to the legally mandated minimum (e.g., 4.2 kW). Two digital inputs (DIs) on the reComputer allow to either reduce the charging current or pause all charging sessions during an active external load limiting signal.

| Physical input pin |   Purpose                                                 | `gpioget` convention    |
| ------------------ | --------------------------------------------------------- | ----------------------- |
| DI 1               |  cut off (pauses all running charging sessions)           |           18            |
| DI 2               |  derating (limits charging current to a defined maximum)  |           19            |

Derating defaults to 6A (can be changed in the config file) which equals approx. 4.2 kWh in a 3-phase power grid and is the maximum allowed grid-power during an operator-forced grid stablizing procedure. If you are an developer and want to check how this is implemented, have a look at <doc:DevelopmentDocumentation#External-Load-Limiting-through-GPIOs>.
