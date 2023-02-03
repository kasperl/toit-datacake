// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import system.services

interface DatacakeService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="340a370b-49d9-4584-86f5-cbbed0b9116e"
      --major=1
      --minor=0

  connect tls/bool -> int
  static CONNECT_INDEX ::= 0

  publish handle/int field/string value/string -> none
  static PUBLISH_INDEX ::= 1

class DatacakeServiceClient extends services.ServiceClient implements DatacakeService:
  static SELECTOR ::= DatacakeService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  connect tls/bool -> int:
    return invoke_ DatacakeService.CONNECT_INDEX tls

  publish handle/int field/string value/string -> none:
    invoke_ DatacakeService.PUBLISH_INDEX [handle, field, value]
