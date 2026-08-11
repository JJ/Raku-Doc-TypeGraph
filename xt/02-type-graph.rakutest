use v6;
use Test;

use Doc::TypeGraph;

plan *;

my @categories := ("basic", "composite", "core", "domain-specific", "exceptions", "metamodel");
my @packages := ("class", "enum", "module", "role");
my @types = ["Any", "Attribute", "Bool", "C", "C::A", "C::B", "C::C", "R", "R::A", "R::B", "R::C", "Seq", "Test"];

my $test-type-graph-file-path = "t/test-type-graph.txt"??"t/test-type-graph.txt"!!"test-type-graph.txt";

my $tg = Doc::TypeGraph.new-from-file($test-type-graph-file-path);

subtest {
    is-deeply $tg.types.values».categories.flat.unique.sort,
    @categories,
    "All supported categories detected";

    is-deeply $tg.types.values».packagetype.flat.unique.sort,
    @packages,
    "All supported packagetypes detected";

    is-deeply $tg.types.values».name.sort.Array,
    @types,
    "All types detected";
}, "Supported values";

subtest {
    is $tg.types<C>.super[0].name, "Any", "Default inheritance to Any";
    is $tg.types<C::B>.super[0].name, "C", "Single inheritance";
    is $tg.types<C::C>.super».name.sort, ["C", "C::A"], "Multiple inheritance";
}, "Inheritance detection";

subtest {
    is $tg.types<R>.roles, "", "Default role undefined";
    is $tg.types<R::B>.roles[0].name, "R", "Single role";
    is $tg.types<R::C>.roles».name.sort, ["R", "R::A"], "Multiple roles";
}, "Role detection";

subtest {
    is $tg.types<C::A>.sub, ["C::C"], "Single class inversion";
    is $tg.types<C>.sub.sort, ["C::B", "C::C"], "Multiple class inversion";
    is $tg.types<Any>.sub.sort, ["Attribute", "Bool", "C", "C::A", "Seq", "Test"],
    "Any inversion";
}, "Inheritance inversion";

subtest {
    is $tg.types<R::A>.doers».name, ["R::C"], "Single role inversion";
    is $tg.types<R>.doers».name.sort, ["R::B", "R::C"], "Multiple role inversion";
}, "Role inversion";

is $tg.sorted,
    ["Any", "Attribute", "Bool", "C", "C::A", "C::B", "C::C", "R", "R::A", "R::B", "R::C", "Seq", "Test"],
    "topo-sort";

done-testing;
