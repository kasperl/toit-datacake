// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import system.services

interface DatacakeService:
  static UUID/string ::= "340a370b-49d9-4584-86f5-cbbed0b9116e"
  static MAJOR/int   ::= 1
  static MINOR/int   ::= 0

  static CONNECT_INDEX ::= 0
  connect tls/bool -> int

  static PUBLISH_INDEX ::= 1
  publish handle/int field/string value/string -> none

class DatacakeServiceClient extends services.ServiceClient implements DatacakeService:
  constructor --open/bool=true:
    super --open=open

  open -> DatacakeServiceClient?:
    return (open_ DatacakeService.UUID DatacakeService.MAJOR DatacakeService.MINOR) and this

  connect tls/bool -> int:
    return invoke_ DatacakeService.CONNECT_INDEX tls

  publish handle/int field/string value/string -> none:
    invoke_ DatacakeService.PUBLISH_INDEX [handle, field, value]
