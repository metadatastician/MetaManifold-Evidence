-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import CheckerBridge

open MetaManifoldEvidence.ResidualEvidence.Checker (presence)
open MetaManifoldEvidence.Counts (verdict)
open MetaManifoldEvidence.CheckerBridge

-- Must fail: the range premise of presence-agrees cannot be dropped. With
-- y = 7 and n = 0 the checker has no candidate inside −6..6 (inconsistent),
-- while the counts verdict is entailed.
theorem invalid : presence (asConfig 7 0) = verdict 7 0 := rfl
