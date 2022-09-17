// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import certificate_roots
import log
import monitor
import net

import mqtt
import mqtt.packets as mqtt

import .internal.api show DatacakeService

import system.services show ServiceDefinition ServiceResource
import system.base.network show NetworkModule NetworkState NetworkResource

ARGUMENT_ACCESS_TOKEN ::= "datacake.access.token"
ARGUMENT_DEVICE_ID    ::= "datacake.device.id"
ARGUMENT_PRODUCT_SLUG ::= "datacake.product.slug"

HOST ::= "mqtt.datacake.co"
PORT ::= 8883

main arguments:
  logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="datacake"
  logger.info "service starting"

  if arguments is not Map:
    logger.error "arguments are malformed" --tags={"arguments": arguments}
    exit 1

  access_token := arguments.get ARGUMENT_ACCESS_TOKEN
  if access_token is not string:
    logger.error "$ARGUMENT_ACCESS_TOKEN argument is not a string"
    exit 1

  device_id := arguments.get ARGUMENT_DEVICE_ID
  if device_id is not string:
    logger.error "$ARGUMENT_DEVICE_ID argument is not a string"
    exit 1

  product_slug := arguments.get ARGUMENT_PRODUCT_SLUG
  if product_slug is not string:
    logger.error "$ARGUMENT_PRODUCT_SLUG argument is not a string"
    exit 1

  credentials := DatacakeCredentials
      --access_token=access_token
      --device_id=device_id
      --product_slug=product_slug

  service := DatacakeServiceDefinition logger credentials
  service.install
  logger.info "service running"

class DatacakeCredentials:
  access_token/string
  device_id/string
  product_slug/string
  constructor --.access_token --.device_id --.product_slug:

class DatacakeServiceDefinition extends ServiceDefinition:
  logger_/log.Logger
  credentials_/DatacakeCredentials
  state_ ::= NetworkState

  constructor .logger_ .credentials_:
    super "datacake" --major=1 --minor=0
    provides DatacakeService.UUID DatacakeService.MAJOR DatacakeService.MINOR

  handle pid/int client/int index/int arguments/any -> any:
    if index == DatacakeService.CONNECT_INDEX:
      return connect arguments client
    if index == DatacakeService.PUBLISH_INDEX:
      resource := (resource client arguments[0]) as DatacakeClient
      return resource.module.publish arguments[1] arguments[2]
    unreachable

  connect tls/bool client/int -> ServiceResource:
    // TODO(kasper): Stop ignoring the $tls parameter.
    // TODO(kasper): Allow setting the logging level?
    module := state_.up: DatacakeMqttModule logger_ credentials_
    return DatacakeClient this client state_

class DatacakeMqttModule implements NetworkModule:
  logger_/log.Logger
  credentials_/DatacakeCredentials
  client_/mqtt.FullClient? := null

  task_/Task? := null
  done_/monitor.Latch? := null

  constructor logger/log.Logger .credentials_:
    logger_ = logger.with_name "mqtt"

  connect -> none:
    connected := monitor.Latch
    done := monitor.Latch
    done_ = done
    task_ = task::
      try:
        connect_ connected
      finally:
        client_ = task_ = done_ = null
        critical_do: done.set true
    // Wait until the MQTT task has connected and is running.
    client_ = connected.get
    client_.when_running: null

  disconnect -> none:
    if not task_: return
    // Cancel the MQTT task and wait until it has disconnected.
    task_.cancel
    done_.get

  connect_ connected/monitor.Latch -> none:
    network := net.open
    nonce := (random 0x1fff_ffff) ^ (Time.monotonic_us & 0x1fff_ffff)
    client_id ::= "$credentials_.device_id[0..8]-$(%x nonce)"
    transport/mqtt.TcpTransport? := null
    client/mqtt.FullClient? := null
    try:
      transport = mqtt.TcpTransport.tls network
          --host=HOST
          --port=PORT
          --root_certificates=[ certificate_roots.ISRG_ROOT_X1 ]
      client = mqtt.FullClient --transport=transport
      options := mqtt.SessionOptions
          --client_id=client_id
          --username=credentials_.access_token
          --password=credentials_.access_token
      client.connect --options=options
      logger_.info "connected" --tags={"host": HOST, "port": PORT, "client": client_id}
      connected.set client
      client.handle: | packet/mqtt.Packet |
        logger_.warn "packet received (ignored)" --tags={"type": packet.type}
    finally: | is_exception exception |
      if client: client.close
      else if transport: transport.close
      network.close
      // We need to call monitor operations to send exceptions
      // to the task that initiated the connection attempt, so
      // we have to do this in a critical section if we're being
      // canceled as part of a disconnect.
      critical_do:
        if connected.has_value:
          logger_.info "disconnected" --tags={"host": HOST, "port": PORT, "client": client_id}
        if is_exception:
          connected.set --exception exception
          return

  publish field/string value/string -> none:
    topic := "dtck-pub/$credentials_.product_slug/$credentials_.device_id/$field"
    client_.publish topic value.to_byte_array
    logger_.info "packet published" --tags={"field": field, "value": value}

class DatacakeClient extends NetworkResource:
  module/DatacakeMqttModule
  constructor service/DatacakeServiceDefinition client/int state/NetworkState:
    module = state.module as DatacakeMqttModule
    super service client state
