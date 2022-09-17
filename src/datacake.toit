// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import encoding.json

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

class Integer extends Field:
  constructor identifier/string:
    super identifier

  publish client/Client value/int -> none:
    _client_.publish client.handle_ identifier "$value"

class Boolean extends Field:
  constructor identifier/string:
    super identifier

  publish client/Client value/bool -> none:
    _client_.publish client.handle_ identifier "$value"

class String extends Field:
  constructor identifier/string:
    super identifier

  publish client/Client value/string -> none:
    // We use the more expense JSON stringify method here to get the
    // correct behavior for all the things that need to be escaped.
    _client_.publish client.handle_ identifier (json.stringify value)
