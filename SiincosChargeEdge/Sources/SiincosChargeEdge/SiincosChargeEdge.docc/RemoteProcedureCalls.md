# Remote Procedure Calls and required message payload
The following sections describe the message payload to request new charging sessions or to perform actions on the once which are active.

## Payload data
The payload for the RPCs mainly originate from ``ChargingSession`` which is designed to hold a whole session lifecycle.
- ``ChargingSession/userName``: The user, which initiated the charging session. Throughout a charging session lifecycle, this field acts as the session owner. Only the session owner is able to pause or terminate its own charging session.
- ``ChargingSession/startTime``: When scheduling a charging session, this field takes the desired starting time, provided as Unix time format.
- ``ChargingSession/endTime``:  When scheduling a charging session, this field takes the desired ending time, provided as Unix time format.
- ``ChargingSession/status``: The charging session action, either: `running`, `paused`, `finished`, `scheduled`
- ``ChargingSession/chargingCurrentSetpoint``: The desired charging current for the charging session. Once a charging session is initiated, the current setpoint cannot be modified. The current setpoint is set when initiating a charging session and is fixed throughout this session.

## Start a charging session
Start a charging session now. The charging session is finished by requesting a charging session termination (refer to <doc:RemoteProcedureCalls/Terminate-a-charging-session>) or by unplugging the vehicle. A state change from ``EVState/pluggedIn`` to ``EVState/unplugged`` while the charging session is active leads to an automatically terminated charging session. A charging session receipt will be generated and pushed to the cloud (as telemetry message).
```json
{
    "userName": "user@mockserver.com",
    "status": "running",
    "chargingCurrentSetpointA": 10
}    
```

## Start a timed charging session
```json
    // TODO: document
```

## Pause a charging session
```json
{
    "userName": "user@mockserver.com",
    "status": "paused",
    "chargingCurrentSetpointA": 10
}
```

## Terminate a charging session
```json
{
    "userName": "user@mockserver.com",
    "status": "finished",
    "chargingCurrentSetpointA": 10
}
```

## Schedule a charging session
```json
{
    "userName": "user@mockserver.com",
    "startTime": 1785150015000,
    "endTime": 1785150075000,
    "status": "scheduled",
    "chargingCurrentSetpointA": 10
}
```
