-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import Counts

open MetaManifoldEvidence.ResidualEvidence
open MetaManifoldEvidence.Counts

-- Must fail: 3 reads with noise bound 1 is entailed, not unresolved.
theorem invalid : verdict 3 1 = Verdict.unresolved := rfl
