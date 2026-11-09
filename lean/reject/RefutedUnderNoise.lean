-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import Counts

open MetaManifoldEvidence.ResidualEvidence
open MetaManifoldEvidence.Counts

-- Must fail: zero reads with noise bound 1 admit latent 1, so absence is not
-- established; refuted-sound covers only y = n = 0.
theorem invalid : Holds («case» 0 1) Absent := «refuted-sound»
