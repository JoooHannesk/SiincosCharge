# Remote Procedure Calls and required message payload
The following sections describe the client RPC message payload to request new charging sessions or to perform actions on active charging sessions.

## Payload data
The payload for the RPCs mainly originate from ``ChargingSession`` which is designed to hold a whole session lifecycle.
- ``ChargingSession/userName``: The user, which initiated the charging session. Throughout a charging session lifecycle, this field acts as the session owner. Only the session owner is able to pause or terminate its own charging session.
- ``ChargingSession/startTime``: When scheduling a charging session, this field takes the desired starting time, provided as Unix time format.
- ``ChargingSession/endTime``:  When scheduling a charging session, this field takes the desired ending time, provided as Unix time format.
- ``ChargingSession/status``: The charging session action, either: `running`, `paused`, `finished`, `scheduled`
- ``ChargingSession/chargingCurrentSetpoint``: The desired charging current for the charging session. Once a charging session is initiated, the current setpoint cannot be modified. The current setpoint is set when initiating a charging session and is fixed throughout this session.

## Start a charging session
To initiate a charging session, it is required to have a vehicle connected to the charger.

Start a charging session now. The charging session is finished by requesting a charging session termination (refer to <doc:RemoteProcedureCalls/Terminate-a-charging-session>) or by unplugging the vehicle. A state change from `EVState.pluggedIn` to `EVState.unplugged` while the charging session is active leads to an automatically terminated charging session. A charging session receipt will be generated and pushed to the cloud (as telemetry message).
```json
{
    "userName": "user@mockserver.com",
    "status": "running",
    "chargingCurrentSetpointA": 10
}    
```

## Start a timed charging session
To initiate a charging session, it is required to have a vehicle connected to the charger.

Start a charging session now and terminate the charging session at `endTime` o'clock automatically.
```json
    {
        "userName": "user@mockserver.com",
        "endTime": 1785150075000,
        "status": "running",
        "chargingCurrentSetpointA": 10
    }
```

## Pause a charging session
Pause a running charging session.
```json
{
    "userName": "user@mockserver.com",
    "status": "paused",
    "chargingCurrentSetpointA": 10
}
```

## Terminate a charging session
A charging session will be ended either by unplugging the vehicle from the charger or by manually requesting through the following RPC.

A state change from `EVState.pluggedIn` to `EVState.unplugged` while the charging session is active leads to an automatically terminated charging session. A charging session receipt will be generated and pushed to the cloud (as telemetry message).

```json
{
    "userName": "user@mockserver.com",
    "status": "finished",
    "chargingCurrentSetpointA": 10
}
```

## Schedule a charging session
Initiate a charging session in the future. Start charging at `startTime` o'clock and end charging at `endTime` o'clock. As soon as charging is started, the `status` will be switched from `.scheduled` to `.running`
```json
{
    "userName": "user@mockserver.com",
    "startTime": 1785150015000,
    "endTime": 1785150075000,
    "status": "scheduled",
    "chargingCurrentSetpointA": 10
}
```
