# Remote Procedure Calls and required message payload

## RPC Message Payload to schedule a charging session
```json
    {
        "cpId": 1,
        "userName": "user@mockserver.com",
        "startTime": 1785150015000,
        "endTime": 1785150075000,
        "status": "scheduled",
        "chargingCurrentSetpointA": 10
    }
```
