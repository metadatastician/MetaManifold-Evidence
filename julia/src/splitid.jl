# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# The identifiers MetaManifold's tree viewer gives tips and branches, so that
# evidence computed here can be keyed the way the viewer keys its own view
# state (`tip:<key>` and `split:<hex>`, MetaManifold-WebUI#27).
#
# This is a port of frontend/src/tree/model.ts (© 2026 Joshua Benjamin Jewell,
# AGPL-3.0): `parseNewick`, `parseJplace`, `hashName` and `indexTree`, kept in
# the same shape so the two can be read side by side. It is tested against a
# table that file itself produced (julia/test/fixtures/splitid_kat.json, see
# julia/gen/splitid_kat.ts), at the commit the table names. Two details are
# easy to get wrong and are deliberate:
#
#   * names are hashed and ordered as UTF-16 code units, because `charCodeAt`
#     and `<` on JavaScript strings are, so a name outside the Basic
#     Multilingual Plane hashes as its two surrogates;
#   * the `#n` suffix of a repeated name follows the viewer's traversal, a
#     stack that pops the last child first, not file order.

"A 64-bit tip-set hash as two 32-bit words, as the viewer keeps it."
const H64 = NTuple{2,UInt32}

"A node as written in the file. `parent` is 0 for the root."
mutable struct SrcNode
    name::String
    length::Union{Float64,Nothing}
    "jplace `{n}` edge number of the branch above this node."
    edge_num::Union{Int,Nothing}
    support::Union{String,Nothing}
    children::Vector{Int}
    parent::Int
end

struct Placement
    edge_num::Int
    lwr::Float64
    distal::Float64
    pendant::Float64
    log_lik::Union{Float64,Nothing}
end

struct PQuery
    names::Vector{String}
    "Sequences this query stands for: the jplace `nm` multiplicities, else one per name."
    mult::Float64
    "Candidates, best first."
    places::Vector{Placement}
end

struct SourceTree
    nodes::Vector{SrcNode}
    root::Int
    has_lengths::Bool
    pqueries::Vector{PQuery}
    meta::Dict{String,Any}
end

const _SUPPORT_RE = r"^\d+(\.\d+)?(/\d+(\.\d+)?)*$"

"""
    parse_newick(text) -> SourceTree

`parseNewick` from model.ts: quoted labels with doubled quotes, bracket
comments (a bare number, an NHX `B=` or a `support=` is bootstrap support),
`{n}` edge numbers, and numeric internal labels read as support. Throws an
`ArgumentError` where the viewer throws.
"""
function parse_newick(text::AbstractString)
    nodes = SrcNode[]
    chars = collect(strip(String(text)))
    L = length(chars)
    i = 1
    at(k) = k <= L ? chars[k] : '\0'
    mk(parent) = (push!(nodes, SrcNode("", nothing, nothing, nothing, Int[], parent)); length(nodes))
    fail(msg) = throw(ArgumentError("Newick, character $(i - 1): $msg"))
    skipspace() = (while i <= L && isspace(chars[i]); i += 1; end)

    function readcomment()
        e = findnext(==(']'), chars, i)
        isnothing(e) && fail("unclosed [")
        body = String(chars[i+1:e-1])
        i = e + 1
        body
    end

    function readlabel()
        skipspace()
        if at(i) == '\'' || at(i) == '"'
            q = chars[i]
            i += 1
            out = IOBuffer()
            while i <= L
                if chars[i] == q
                    if at(i + 1) == q
                        write(out, q); i += 2; continue
                    end
                    i += 1
                    return String(take!(out))
                end
                write(out, chars[i]); i += 1
            end
            fail("unclosed quote")
        end
        start = i
        while i <= L && !(chars[i] in ('(', ')', ':', ',', ';', '[', '{')); i += 1; end
        String(strip(String(chars[start:i-1])))
    end

    function readtail(n)
        node = nodes[n]
        label = readlabel()
        while true
            skipspace()
            c = at(i)
            if c == ':'
                i += 1
                skipspace()
                start = i
                while i <= L && (chars[i] in ('-', '+', '.', 'e', 'E') || isdigit(chars[i])); i += 1; end
                txt = String(chars[start:i-1])
                v = tryparse(Float64, txt)
                (isempty(txt) || isnothing(v) || !isfinite(v)) && fail("bad branch length")
                node.length = v
            elseif c == '{'
                e = findnext(==('}'), chars, i)
                isnothing(e) && fail("unclosed {")
                num = strip(String(chars[i+1:e-1]))
                node.edge_num = isempty(num) ? 0 : tryparse(Int, num)   # JS Number(): 0 for '', NaN for junk
                i = e + 1
            elseif c == '['
                cmt = String(strip(readcomment()))
                v = if occursin(_SUPPORT_RE, cmt)
                    cmt
                elseif startswith(cmt, "&&NHX")
                    m = match(r":B=([^:\]]+)", cmt)
                    isnothing(m) ? nothing : String(m[1])
                elseif startswith(cmt, "&")
                    m = match(r"(?:^|[&,])support=([^,\]]+)", cmt)
                    isnothing(m) ? nothing : String(m[1])
                else
                    nothing
                end
                if !isnothing(v) && isnothing(node.support)
                    node.support = v
                end
            else
                break
            end
        end
        if !isempty(node.children) && label != ""
            if occursin(_SUPPORT_RE, label)
                node.support = label
            else
                node.name = label
            end
        else
            node.name = label
        end
    end

    root = mk(0)
    stack = Int[]
    cur = root
    skipspace()
    # Leading comments such as FigTree's [&R] come before the tree.
    while at(i) == '['
        readcomment(); skipspace()
    end
    if at(i) != '('
        readtail(root)
    else
        while true
            skipspace()
            c = at(i)
            if c == '('
                i += 1
                push!(stack, cur)
                child = mk(cur)
                push!(nodes[cur].children, child)
                cur = child
            elseif c == ','
                i += 1
                isempty(stack) && fail("comma outside parentheses")
                parent = stack[end]
                child = mk(parent)
                push!(nodes[parent].children, child)
                cur = child
            elseif c == ')'
                i += 1
                isempty(stack) && fail("unbalanced )")
                cur = pop!(stack)
                readtail(cur)
            elseif c == ';' || i > L
                break
            elseif c == '['
                readcomment()
            else
                before = i
                readtail(cur)
                i == before && fail("unexpected '$c'")
            end
        end
        isempty(stack) || fail("unbalanced (")
    end
    has_lengths = any(k != root && !isnothing(nodes[k].length) && nodes[k].length > 0
                      for k in eachindex(nodes))
    SourceTree(nodes, root, has_lengths, PQuery[], Dict{String,Any}())
end

_num(x) = x isa Number ? Float64(x) : (x isa AbstractString ? something(tryparse(Float64, x), NaN) : NaN)

"""
    parse_jplace(text) -> SourceTree

`parseJplace` from model.ts: the `tree` string through `parse_newick`, and
each placement's candidates best first, with the `nm` multiplicities summed.
"""
parse_jplace(text::AbstractString) = parse_jplace_doc(JSON3.read(text))

"`parse_jplace` on an already parsed document (anything indexable by `Symbol`)."
function parse_jplace_doc(doc)
    tree = parse_newick(string(doc[:tree]))
    fields = String[string(f) for f in get(doc, :fields, [])]
    col(f) = something(findfirst(==(f), fields), 0)
    i_edge, i_lwr, i_dist = col("edge_num"), col("like_weight_ratio"), col("distal_length")
    i_pend, i_lik = col("pendant_length"), col("likelihood")
    i_edge == 0 && throw(ArgumentError("jplace fields lack edge_num"))
    pqueries = PQuery[]
    for pq in get(doc, :placements, [])
        rows = get(pq, :p, [])
        nm = get(pq, :nm, nothing)
        names = haskey(pq, :n) ? String[string(x) for x in pq[:n]] :
                !isnothing(nm) ? String[string(x[1]) for x in nm] : String[]
        mult = !isnothing(nm) ? sum((x -> (v = _num(x[2]); isnan(v) ? 0.0 : v)).(nm); init = 0.0) :
               Float64(max(1, length(names)))
        places = [Placement(Int(r[i_edge]),
                            i_lwr > 0 ? _num(r[i_lwr]) : 1.0,
                            i_dist > 0 ? _num(r[i_dist]) : 0.0,
                            i_pend > 0 ? _num(r[i_pend]) : 0.0,
                            i_lik > 0 ? _num(r[i_lik]) : nothing) for r in rows]
        sort!(places; alg = MergeSort, by = p -> -p.lwr)
        push!(pqueries, PQuery(names, mult, places))
    end
    meta = Dict{String,Any}(string(k) => v for (k, v) in pairs(get(doc, :metadata, Dict())))
    meta["version"] = get(doc, :version, nothing)
    SourceTree(tree.nodes, tree.root, tree.has_lengths, pqueries, meta)
end

"`parseTreeFile`: `format` is `\"newick\"` or `\"jplace\"`."
parse_tree(format::AbstractString, text::AbstractString) =
    format == "jplace" ? parse_jplace(text) : format == "newick" ? parse_newick(text) :
    throw(ArgumentError("unknown tree format '$format'"))

"""
    hash_name(name) -> H64

`hashName` from model.ts: two independent 32-bit FNV-1a variants over the
UTF-16 code units of `name`, each finalised with a murmur-style mix.
"""
function hash_name(name::AbstractString)
    a = 0x811c9dc5
    b = 0x01000193 ⊻ 0x5bd1e995
    for unit in transcode(UInt16, String(name))
        c = UInt32(unit)
        a = (a ⊻ c) * 0x01000193
        b = (b ⊻ c) * 0x5bd1e995
        b ⊻= b >> 15
    end
    a ⊻= a >> 13; a *= 0x85ebca6b; a ⊻= a >> 16
    b ⊻= b >> 13; b *= 0xc2b2ae35; b ⊻= b >> 16
    (a, b)
end

"The sixteen lowercase hex digits the viewer writes after `split:`."
split_hex(h::H64) = string(h[1]; base = 16, pad = 8) * string(h[2]; base = 16, pad = 8)

"JavaScript's `<` on strings: UTF-16 code units, a prefix before its extensions."
function _utf16_less(a::AbstractString, b::AbstractString)
    ua, ub = transcode(UInt16, String(a)), transcode(UInt16, String(b))
    for k in 1:min(length(ua), length(ub))
        ua[k] == ub[k] || return ua[k] < ub[k]
    end
    length(ua) < length(ub)
end

"""
    TreeIndex

`indexTree` from model.ts. `tip_key[v]` is the tip's name, suffixed `#2`,
`#3` for repeats; `split[v]` is the id of the branch above node `v` (`""` for
the root), the hash of whichever side of the bipartition lacks the reference
tip; `child_is_canonical[v]` says whether that side is the child side.
"""
struct TreeIndex
    src::SourceTree
    tip_key::Vector{String}
    tip_count::Int
    side::Vector{H64}
    total::H64
    split::Vector{String}
    split_edge::Dict{String,Int}
    "Every tip set that sits on one side of some branch."
    sides::Set{String}
    edge_by_num::Dict{Int,Int}
    child_is_canonical::Vector{Bool}
    support_by_split::Dict{String,String}
end

function index_tree(src::SourceTree)
    n = length(src.nodes)
    tip_key = fill("", n)
    seen = Dict{String,Int}()
    tip_count = 0
    order = Int[]
    stack = [src.root]
    while !isempty(stack)
        v = pop!(stack)
        push!(order, v)
        for c in src.nodes[v].children
            push!(stack, c)
        end
    end
    for v in order
        isempty(src.nodes[v].children) || continue
        tip_count += 1
        name = src.nodes[v].name
        k = get(seen, name, 0) + 1
        seen[name] = k
        tip_key[v] = k == 1 ? name : "$name#$k"
    end
    ref_tip = 0
    for v in order
        isempty(src.nodes[v].children) || continue
        if ref_tip == 0 || _utf16_less(tip_key[v], tip_key[ref_tip])
            ref_tip = v
        end
    end

    side = Vector{H64}(undef, n)
    has_ref = falses(n)
    for k in length(order):-1:1
        v = order[k]
        node = src.nodes[v]
        if isempty(node.children)
            side[v] = hash_name(tip_key[v])
            has_ref[v] = v == ref_tip
        else
            a, b, r = UInt32(0), UInt32(0), false
            for c in node.children
                a ⊻= side[c][1]; b ⊻= side[c][2]; r |= has_ref[c]
            end
            side[v] = (a, b)
            has_ref[v] = r
        end
    end
    total = side[src.root]
    split = fill("", n)
    child_is_canonical = falses(n)
    split_edge = Dict{String,Int}()
    sides = Set{String}()
    edge_by_num = Dict{Int,Int}()
    support_by_split = Dict{String,String}()
    for v in 1:n
        v == src.root && continue
        other = (total[1] ⊻ side[v][1], total[2] ⊻ side[v][2])
        child_is_canonical[v] = !has_ref[v]
        split[v] = split_hex(has_ref[v] ? other : side[v])
        # A degree-two source root joins two branches with the same bipartition; the first wins.
        haskey(split_edge, split[v]) || (split_edge[split[v]] = v)
        push!(sides, split_hex(side[v]))
        push!(sides, split_hex(other))
        node = src.nodes[v]
        isnothing(node.edge_num) || (edge_by_num[node.edge_num] = v)
        if !isnothing(node.support) && !isempty(node.children)
            support_by_split[split[v]] = node.support
        end
    end
    TreeIndex(src, tip_key, tip_count, side, total, split, split_edge, sides, edge_by_num,
              child_is_canonical, support_by_split)
end

"The `split:` ids of a tree, one per branch, as a set."
split_ids(ix::TreeIndex) = Set(keys(ix.split_edge))
split_ids(src::SourceTree) = split_ids(index_tree(src))

"""
    split_difference(a, b) -> (only_in_a, only_in_b)

The branches each tree has that the other lacks, by `split:` id. Empty on both
sides means an evidence overlay keyed on one tree's branches lands on the
other's, whatever the rooting: this is the check to run on a study's
`{ref}.treefile` and its jplace before drawing one's verdicts on the other.
"""
function split_difference(a::SourceTree, b::SourceTree)
    sa, sb = split_ids(a), split_ids(b)
    (sort!(collect(setdiff(sa, sb))), sort!(collect(setdiff(sb, sa))))
end
