-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import Counts

open MetaManifoldEvidence.ResidualEvidence
open MetaManifoldEvidence.Counts
open Le

-- Must fail: with y = n = 2 a zero latent is admissible, so presence is not
-- entailed; the premise n < y (here 3 ≤ 2) does not hold.
theorem invalid : Holds («case» 2 2) Present := «entailed-sound» («s≤s» («s≤s» «z≤n»))
