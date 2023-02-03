# datacake
Connect your ESP32s to [Datacake](https://datacake.co/) and visualize your data in the
[Datacake dashboard](https://app.datacake.de/).

# Trying it out
First you need to install the Datacake service on your ESP32 using
[Jaguar](https://github.com/toitlang/jaguar).
The service runs in a separate container and handles the secure connection
to the MQTT broker.

``` sh
jag container install datacake src/service.toit \
    -D datacake.api.token=...                   \
    -D datacake.device.id=...                   \
    -D datacake.product.slug=...
```

Once you've installed the service on your device, you can run examples like:

``` sh
jag run examples/temperature.toit
```

If you follow along using `jag monitor`, you'll see output like this:

```
[jaguar] INFO: program da35d69f-d62e-5297-ae10-a54534123db6 started
[datacake.mqtt] INFO: connected {host: mqtt.datacake.co, port: 8883, client: ...}
[datacake.mqtt] INFO: packet published {field: TEMPERATURE, value: 23.7}
[jaguar] INFO: program da35d69f-d62e-5297-ae10-a54534123db6 stopped
[datacake.mqtt] INFO: disconnected {host: mqtt.datacake.co, port: 8883, client: ...}
```

The code for the [example](https://github.com/toitware/toit-datacake/blob/main/examples/temperature.toit)
is fairly straightforward.

# Using Datacake in your own projects
If you want to use Datacake in your own Toit-based project, you
can install the package in your project directory using:

```
cd $PROJECT_DIRECTORY
jag pkg install datacake
```

and import and use it like this:

```
import datacake

main:
  client := datacake.connect
  temperature := datacake.Float "TEMPERATURE" --precision=1
  try:
    20.repeat:
      temperature.publish client (random 150 350) / 10.0
      sleep --ms=2_000
  finally:
    client.close
```

You will still need to have the service running.
