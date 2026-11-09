-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import CountsCertificate

open MetaManifoldEvidence.ResidualEvidence (Verdict)
open MetaManifoldEvidence.CountsGrid

-- Must fail: the certificate's rfl is not vacuous. On the 0..1 grid the cell
-- y = 1, n = 1 is unresolved with interval [0, 2]; this table says entailed.
theorem invalid : grid 1 = [Row.row 0 0 Verdict.refuted 0 0, Row.row 0 1 Verdict.unresolved 0 1, Row.row 1 0 Verdict.entailed 1 1, Row.row 1 1 Verdict.entailed 0 2] := rfl
