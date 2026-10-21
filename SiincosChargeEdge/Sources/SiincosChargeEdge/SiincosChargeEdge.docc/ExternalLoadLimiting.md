# External Load Limiting (§14a EnWG)

| physical input pin |   Purpose   | sysfs convention  |    chip    | `gpioget` convention    |
| ------------------ | ----------  | ----------------- | ---------- | ----------------------- |
| DI 1               |  cut off    | GPIO 530          | gpiochip0  |           18            |
| DI 2               |  derating   | GPIO 531          | gpiochip0  |           19            |
