// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// Known-answer table for the tree identifiers (`tip:` keys and `split:` ids)
// that MetaManifold's tree viewer derives in frontend/src/tree/model.ts.
// The table is produced by running that file itself, so the Julia port in
// julia/src/splitid.jl is tested against the viewer's own answers, not
// against a second reading of its code.
//
//   bun julia/gen/splitid_kat.ts /path/to/MetaManifold-WebUI > julia/test/fixtures/splitid_kat.json
//
// The checkout's commit is recorded in the table. Re-run after model.ts changes.

const webui = process.argv[2] ?? process.env.METAMANIFOLD_WEBUI
if (!webui) throw new Error('give the MetaManifold-WebUI checkout as the first argument')
const m = await import(`${webui}/frontend/src/tree/model.ts`)
const commit = new TextDecoder().decode(
  Bun.spawnSync(['git', '-C', webui, 'rev-parse', 'HEAD']).stdout).trim()

// A deterministic 64-tip tree: an LCG picks where each new tip is attached.
function randomTree(tips: number, seed: number): string {
  let s = seed >>> 0
  const next = () => { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s }
  type N = { name: string; kids: N[] }
  const leaves: N[] = []
  const root: N = { name: '', kids: [] }
  for (let i = 0; i < tips; i++) {
    const leaf: N = { name: `t${String(i).padStart(2, '0')}`, kids: [] }
    if (i < 3) { root.kids.push(leaf); leaves.push(leaf); continue }
    const target = leaves[next() % leaves.length]
    // Split the target's branch: the target becomes a sibling of the new tip.
    const inner: N = { name: '', kids: [{ ...target }, leaf] }
    target.name = ''; target.kids = inner.kids
    leaves.push(leaf)
    const len = (next() % 900 + 100) / 1000
    void len
  }
  let k = 0
  const show = (n: N): string => n.kids.length
    ? `(${n.kids.map(show).join(',')})${n === root ? '' : `${50 + (next() % 50)}`}:${(next() % 900 + 100) / 1000}`
    : `${n.name}:${(next() % 900 + 100) / 1000}`
  void k
  return show(root) + ';'
}

const jplace = (tree: string, placements: unknown[]) => JSON.stringify({
  version: 3,
  fields: ['edge_num', 'like_weight_ratio', 'distal_length', 'pendant_length'],
  tree, placements,
})

const cases: { name: string; format: 'newick' | 'jplace'; text: string; note?: string }[] = [
  { name: 'frontend-split-identity', format: 'newick',
    text: '((A:1,B:2)90:0.5,(C:1,(D:1,E:4)70:1)80:0.2,F:3);',
    note: 'the tree model.test.ts uses for split identity' },
  { name: 'jplace-fixture', format: 'jplace',
    text: jplace('((A:1{0},B:1{1}):1{2},C:1{3}){4};', [
      { p: [[1, 0.2, 0.1, 0.01], [0, 0.8, 0.5, 0.02]], n: ['q1'] },
      { p: [[3, 1, 0.3, 0.1]], nm: [['q2', 3], ['q3', 2]] },
    ]), note: 'the jplace document model.test.ts and test_trees.jl use' },
  { name: 'reference-newick', format: 'newick', text: '((a:1,b:1)90:1,c:1,d:1);',
    note: 'test_phylogeny.jl reference.treefile' },
  { name: 'placement-on-reference', format: 'jplace',
    text: jplace('(((a:1{0},b:1{1}):1{2},c:1{3}):0.0{5},d:1{4});', [{ p: [[2, 1, 0.5, 0.1]], n: ['q'] }]),
    note: 'the same tips as reference-newick, rooted elsewhere: the split sets must agree' },
  { name: 'duplicates', format: 'newick', text: '((A,A),(A,B));',
    note: 'repeated names get #2, #3 in the viewer traversal order' },
  { name: 'quoted', format: 'newick', text: "('A b':1,'it''s':2,\"C d\":3);" },
  { name: 'unicode-bmp', format: 'newick', text: '(é:1,日本:1,\'🦠\':1,Ａ:1);',
    note: 'names outside ASCII; the reference tip is still the smallest' },
  { name: 'unicode-surrogate-order', format: 'newick', text: '(Ａ:1,\'🦠\':1,Ｂ:1);',
    note: 'UTF-16 code units order the reference tip: U+D83E (the emoji) sorts before U+FF21, code points would not' },
  { name: 'comments-support', format: 'newick', text: '[&R] ((A,B):1[&&NHX:B=88],(C,D):1[70],E);' },
  { name: 'support-labels', format: 'newick', text: '((A,B)95:1,(C,D)Clade:1,E);' },
  { name: 'edge-numbers-in-newick', format: 'newick', text: '((A:1{0},B:1{1}):1{2},C:1{3}){4};' },
  { name: 'degree-two-root', format: 'newick', text: '((A,B),(C,D));',
    note: 'both root branches carry the same bipartition; the first keeps the splitEdge entry' },
  { name: 'two-tips', format: 'newick', text: '(A,B);' },
  { name: 'one-tip', format: 'newick', text: 'A;' },
  { name: 'nested-single', format: 'newick', text: '((((A:1,B:1)ab:1)u1:2)u2:3,C:1,D:1);' },
  { name: 'hash-in-name', format: 'newick', text: "((A,'A#2'),A);",
    note: 'a name that is literally A#2 collides with the key the second A is given' },
  { name: 'bom-prefixed', format: 'newick', text: '\ufeff((A:1,B:1):1,C:1);',
    note: 'a UTF-8 byte-order mark is whitespace to trim(); the tree behind it is still read' },
  { name: 'js-whitespace', format: 'newick', text: '(A\u00a0,\u2028B\u3000,\u2029 C\ufeff);',
    note: 'U+2028, U+2029 and U+FEFF are JavaScript whitespace, as every Zs character is' },
  { name: 'nel-is-not-space', format: 'newick', text: '(A\u0085,B);',
    note: 'U+0085 is whitespace to Julia isspace but not to JavaScript: the label keeps it' },
  { name: 'non-ascii-digit-labels', format: 'newick', text: '((A,B)\u0669\u0660:1,(C,D)\uff19\uff15:1,E);',
    note: 'JavaScript \\d is ASCII only, so these internal labels are names, not support' },
  { name: 'random-64', format: 'newick', text: randomTree(64, 20261014) },
]

const out = cases.map(c => {
  const src = m.parseTreeFile(c.format, c.text)
  const ix = m.indexTree(src)
  return {
    name: c.name, format: c.format, text: c.text, note: c.note ?? '',
    root: src.root, hasLengths: src.hasLengths,
    nodes: src.nodes.map((n: any, v: number) => ({
      name: n.name, length: n.length, edgeNum: n.edgeNum, support: n.support,
      children: n.children, parent: n.parent,
      tipKey: ix.tipKey[v], side: ix.side[v], split: ix.split[v], childIsCanonical: ix.childIsCanonical[v],
    })),
    total: ix.total, tipCount: ix.tipCount,
    splitEdge: [...ix.splitEdge.entries()],
    sides: [...ix.sides].sort(),
    edgeByNum: [...ix.edgeByNum.entries()],
    supportBySplit: [...ix.supportBySplit.entries()],
    pqueries: src.pqueries,
  }
})

console.log(JSON.stringify({
  generator: 'julia/gen/splitid_kat.ts',
  source: 'frontend/src/tree/model.ts',
  webui_commit: commit,
  cases: out,
}, null, 1))
