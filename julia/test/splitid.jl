# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# The tree identifiers against the viewer's own answers. The table was made by
# running frontend/src/tree/model.ts (julia/gen/splitid_kat.ts); every field
# `indexTree` exposes is compared, on every node of every case.

const SPLITID_KAT = JSON3.read(read(joinpath(@__DIR__, "fixtures", "splitid_kat.json"), String))

_kat_case(name) = only(c for c in SPLITID_KAT.cases if c.name == name)
_h64(a) = (UInt32(a[1]), UInt32(a[2]))
_opt(x) = x === nothing ? nothing : x

@testset "tree identifiers agree with model.ts at $(SPLITID_KAT.webui_commit[1:7])" begin
    @test length(SPLITID_KAT.cases) == 21
    for c in SPLITID_KAT.cases
        @testset "$(c.name)" begin
            src = parse_tree(String(c.format), String(c.text))
            ix = index_tree(src)
            @test src.root == c.root + 1
            @test src.has_lengths == c.hasLengths
            @test length(src.nodes) == length(c.nodes)
            @test ix.tip_count == c.tipCount
            @test ix.total == _h64(c.total)
            for (k, kn) in enumerate(c.nodes)
                node = src.nodes[k]
                @test node.name == kn.name
                @test node.length == _opt(kn.length)
                @test node.edge_num == _opt(kn.edgeNum)
                @test node.support == _opt(kn.support)
                @test node.children == [v + 1 for v in kn.children]
                @test node.parent == kn.parent + 1
                @test ix.tip_key[k] == kn.tipKey
                @test ix.side[k] == _h64(kn.side)
                @test ix.split[k] == kn.split
                @test ix.child_is_canonical[k] == kn.childIsCanonical
            end
            @test ix.split_edge == Dict(String(p[1]) => p[2] + 1 for p in c.splitEdge)
            @test ix.sides == Set(String.(c.sides))
            @test ix.edge_by_num == Dict(Int(p[1]) => p[2] + 1 for p in c.edgeByNum)
            @test ix.support_by_split == Dict(String(p[1]) => String(p[2]) for p in c.supportBySplit)
            @test length(src.pqueries) == length(c.pqueries)
            for (pq, kq) in zip(src.pqueries, c.pqueries)
                @test pq.names == String.(kq.names)
                @test pq.mult == kq.mult
                @test [(p.edge_num, p.lwr, p.distal, p.pendant, p.log_lik) for p in pq.places] ==
                      [(Int(p.edgeNum), Float64(p.lwr), Float64(p.distal), Float64(p.pendant), _opt(p.logLik)) for p in kq.places]
            end
        end
    end
end

@testset "what the table shows about the identifiers" begin
    # Split ids do not depend on rooting: the placement rooted elsewhere has
    # exactly the reference tree's branches (MetaManifold-WebUI#27, question 3).
    ref = parse_tree("newick", _kat_case("reference-newick").text)
    pl = parse_tree("jplace", _kat_case("placement-on-reference").text)
    @test split_difference(ref, pl) == (String[], String[])
    @test index_tree(ref).total == index_tree(pl).total
    # A changed tip set is reported on the side that has it: with d replaced
    # by e, the branches above a, (a,b) and d/e change id, while b and c keep
    # theirs, since their canonical side is the single tip.
    other = parse_newick("((a:1,b:1)90:1,c:1,e:1);")
    only_ref, only_other = split_difference(ref, other)
    @test length(only_ref) == length(only_other) == 3
    @test length(intersect(split_ids(ref), split_ids(other))) == 2

    # The viewer's own tree: as many ids as branches, all distinct.
    ix = index_tree(parse_newick(_kat_case("frontend-split-identity").text))
    @test length(ix.split_edge) == length(ix.src.nodes) - 1

    # Names are ordered as UTF-16 code units when the reference tip is chosen:
    # the emoji's high surrogate U+D83E sorts before U+FF21 (fullwidth A).
    ix = index_tree(parse_newick(_kat_case("unicode-surrogate-order").text))
    tips = [k for k in eachindex(ix.src.nodes) if isempty(ix.src.nodes[k].children)]
    @test [(ix.tip_key[k], ix.child_is_canonical[k]) for k in tips] == [("Ａ", true), ("🦠", false), ("Ｂ", true)]
    @test hash_name("🦠") != hash_name("\ud83e") && length(transcode(UInt16, "🦠")) == 2

    # Repeated names are suffixed in the viewer's traversal order, which pops
    # the last child first, so the first A in the file is A#3.
    ix = index_tree(parse_newick(_kat_case("duplicates").text))
    @test [ix.tip_key[k] for k in eachindex(ix.src.nodes) if isempty(ix.src.nodes[k].children)] == ["A#3", "A#2", "A", "B"]

    # Recorded, not endorsed: a name that is literally "A#2" gets the same key
    # as the second "A", the two hashes cancel, and two branches share the id
    # of the empty tip set. Reported upstream as a contract question.
    ix = index_tree(parse_newick(_kat_case("hash-in-name").text))
    @test count(==("0000000000000000"), ix.split) == 2
    @test ix.tip_key[[k for k in eachindex(ix.src.nodes) if isempty(ix.src.nodes[k].children)]] == ["A#2", "A#2", "A"]
end

@testset "whitespace and digits are JavaScript's, not Julia's" begin
    # A byte-order mark is whitespace to trim(), so the tree behind it is read.
    @test length(parse_newick(_kat_case("bom-prefixed").text).nodes) == 5
    @test length(parse_newick("\ufeffA;").nodes) == 1 && parse_newick("\ufeffA;").nodes[1].name == "A"
    # U+0085 is not JavaScript whitespace, so a label keeps it.
    @test [n.name for n in parse_newick("(A\u0085,B);").nodes if isempty(n.children)] == ["A\u0085", "B"]
    # \d is ASCII only there, so a label in other digits is a name.
    t = parse_newick(_kat_case("non-ascii-digit-labels").text)
    @test [(n.name, n.support) for n in t.nodes if !isempty(n.children) && n.parent != 0] ==
          [("\u0669\u0660", nothing), ("\uff19\uff15", nothing)]
    @test parse_newick("((A,B)95,C);").nodes[2].support == "95"
end

@testset "parsers refuse what the viewer refuses" begin
    @test_throws ArgumentError parse_newick("((A,B);")
    @test_throws ArgumentError parse_newick("(A,B)):1;")
    @test_throws ArgumentError parse_newick("(A:x,B);")
    @test_throws ArgumentError parse_newick("('A,B);")
    @test_throws ArgumentError parse_jplace("{\"tree\": \"(A,B);\", \"fields\": []}")
    @test_throws ArgumentError parse_tree("nexus", "(A,B);")
end
