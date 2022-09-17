// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import datacake

main:
  client := datacake.connect
  temperature := datacake.Float "TEMPERATURE" --precision=1
  temperature.publish client (random 150 350) / 10.0
