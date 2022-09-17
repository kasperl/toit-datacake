// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import system.services show ServiceResourceProxy
import .internal.api show DatacakeService DatacakeServiceClient

_client_/DatacakeServiceClient? ::= DatacakeServiceClient

connect --tls/bool=true -> Client:
  handle := _client_.connect tls
  return Client handle

class Client extends ServiceResourceProxy:
  constructor handle/int:
    super _client_ handle

class Field:
  identifier/string ::= ?
  constructor .identifier:

class Float extends Field:
  precision/int?

  constructor identifier/string --.precision/int?=2:
    super identifier

  publish client/Client value/float -> none:
    _client_.publish client.handle_ identifier (value.stringify precision)
