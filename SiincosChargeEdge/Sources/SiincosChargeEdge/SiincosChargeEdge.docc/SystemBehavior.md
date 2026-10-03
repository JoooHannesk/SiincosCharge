# System Behavior
This file tries to describe the system's behavior. This is based on own project decision, but – in quite a lot of cases – on how the charging hardware behaves:

## Locking and unlocking the EV charger
- A **locked** charger (`chargingPermission == .disabled`) never sends its plug state to the cloud, so the plug state is unknown at that point.
- Starting a session **unlocks** the charger (`chargingPermission == .enabled`). The charger then checks for a vehicle. If it finds none, it locks itself again.
- Once the charger is unlocked with a vehicle plugged in, the **car** decides whether to draw current (BMS conditioning, battery full, …). So there's no real "ready to charge" state. It's really "unlocked, waiting for the car".
