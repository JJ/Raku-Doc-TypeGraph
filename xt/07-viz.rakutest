#!/usr/bin/env raku
use Test;
use Doc::TypeGraph;
use Doc::TypeGraph::Viz;

constant $any-type-graph = 'type-graph-Any.svg';

my $tg = Doc::TypeGraph.new-from-file('test-type-graph.txt');

sub testing-roundtrip($viz, $desc, $path, $test-graph, *@checks) {
    $viz.write-type-graph-images(:$path, :force, type-graph => $tg);

    ok $path.add($test-graph).e, "SVG was created by write-type-graph-images";
    ok $path.add("$test-graph.dot").e, "dot files are present";

    my $viz-output = $path.add("$test-graph.dot").slurp;
    subtest {
        for @checks.kv -> $i, $check {
            ok $check($viz-output), "Check {$i + 1}";
        }
    }, $desc;

}

# Default colors
my $path = $*TMPDIR.add('viz-test-dir');
mkdir $path;
my $viz = Doc::TypeGraph::Viz.new;
testing-roundtrip($viz, "Default coloring", $path, $any-type-graph,
        *.contains('graph [truecolor=true bgcolor="#FFFFFF"]'),
        *.contains('"Proc" -> "Any" [color="#000000"];'),
        *.contains('"Setty" [color="#6666FF", fontcolor="#6666FF", href="/type/Setty", fontname="FreeSans"];'),
        *.contains('"Signal" [color="#33BB33", fontcolor="#33BB33", href="/type/Signal", fontname="FreeSans"];'));

unlink $_ for dir $path;
rmdir $path;

# Custom colors
mkdir $path;
$viz = Doc::TypeGraph::Viz.new(class-color => '#030303', role-color => '#5503B3', enum-color => '#A30031',
        bg-color => '#fafafa', node-style => 'filled margin=0.2 fillcolor="#f2f2f2" shape=rectangle fontsize=16');
testing-roundtrip($viz, "Custom coloring", $path, $any-type-graph,
        *.contains('graph [truecolor=true bgcolor="#fafafa"]'),
        *.contains('node [style=filled margin=0.2 fillcolor="#f2f2f2" shape=rectangle fontsize=16]'),
        *.contains('"Proc" -> "Any" [color="#030303"];'),
        *.contains('"Setty" [color="#5503B3", fontcolor="#5503B3", href="/type/Setty", fontname="FreeSans"];'),
        *.contains('"Signal" [color="#A30031", fontcolor="#A30031", href="/type/Signal", fontname="FreeSans"];'));

$tg = Doc::TypeGraph.new-from-file('t/test-type-graph-one-more.txt');
$viz = Doc::TypeGraph::Viz.new;
testing-roundtrip($viz, "Add one", $path, "type-graph-D.svg",
        *.contains('"D"') );
testing-roundtrip($viz, "Add one", $path, $any-type-graph, *.contains('"D"') );

# unlink $_ for dir $path;
# rmdir $path;

done-testing;
