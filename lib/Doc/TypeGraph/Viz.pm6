use v6.c;
use Doc::TypeGraph;

=begin pod

=head1 NAME

Doc::TypeGraph::Viz - Output graph in .dot format (from GraphViz)

=head1 SYNOPSIS

my $tg = Doc::TypeGraph.new-from-file('test-type-graph.txt');
my $viz = Doc::TypeGraph::Viz.new;

my $path = "/tmp";
$viz.write-type-graph-images(:$path, :force, type-graph => $tg);

=head1 DESCRIPTION

Class for rendering C<Doc::TypeGraph> objects in a rather rigid way;
GraphViz's C<.dot> format is used for expressing the relationships,
and they are then rendered using the C<dot> program.

=head1 METHODS

=head2 method new-for-type ($type, *%attrs)

Adds a new node for a type, with any attribute

=head2 method as-dot (:$size)

Renders as a dot document with the indicated size

=head2 method to-dot-file ($file)

Saves the dot representation to an actual file

=head2 method to-file ($file, :$format = 'svg', :$size --> Promise:D)

Runs C<dot> on the file, returning a C<Promise> so that it can be used
asynchronously.

=head2 method write-type-graph-images(:$type-graph, :$path, :$force) {

Write the images to storage.

=head2 sub viz-group($type)

Return the group depending on the type

=head2 sub viz-hints($group)

Return the hints depending on the group

=end pod

unit class Doc::TypeGraph::Viz;

has @.types;
has $.dot-hints;
has $.url-base    = '/type/';
has $.rank-dir    = 'BT';
has $.role-color  = '#6666FF';
has $.enum-color  = '#33BB33';
has $.class-color = '#000000';
has $.bg-color    = '#FFFFFF';
has $.node-style  = Nil;
has $.node-soft-limit = 20;
has $.node-hard-limit = 50;

method new-for-type ($type, *%attrs) {
    my $self = self.bless(:types[$type], |%attrs);
    $self!add-neighbors;
    return $self;
}

method !add-neighbors {
    # Add all ancestors (both class and role) to @.types
    sub visit ($n) {
        state %seen;
        return if %seen{$n}++;
        visit($_) for flat $n.super, $n.roles;
        @!types.append: $n;
    }

    # Work out in all directions from @.types,
    # trying to get a decent pool of type nodes
    my @seeds = flat @.types, @.types.map(*.sub), @.types.map(*.doers);
    while (@.types < $.node-soft-limit) {
        # Remember our previous node set
        my @prev = @.types;

        # Add ancestors of all seeds to the pool nodes
        visit($_) for @seeds;
        @.types .= unique;

        # Find a new batch of seed nodes
        @seeds = (flat @seeds.map(*.sub), @seeds.map(*.doers)).unique;

        # If we're not growing the node pool, stop trying
        last if @.types <= @prev or !@seeds;

        # If the pool got way too big, drop back to previous
        # pool snapshot and stop trying
        if @.types > $.node-hard-limit {
            @.types = @prev;
            last;
        }
    }
}

method as-dot (:$size) {
    my @dot;
    @dot.append: qq:to/END/;
digraph "raku-type-graph" \{
    rankdir=$.rank-dir;
    splines=polyline;
    overlap=false;
END

    @dot.append: “    size="$size"\n” if $size;

    if $.dot-hints -> $hints {
        @dot.append: "\n    // Layout hints\n";
        @dot.append: $hints;
    }

    @dot.append: "\n    graph [truecolor=true bgcolor=\"$!bg-color\"];";
    with $!node-style {
        @dot.append: "\nnode [style=$_];";
    }

    @dot.append: "\n    // Types\n";
    for @.types -> $type {
        next unless $type;
        my $color = do given $type.packagetype {
            when ‘role’ { $.role-color  }
            when ‘enum’ { $.enum-color  }
            default     { $.class-color }
        }
        @dot.append: “    "$type.name()" [color="$color", fontcolor="$color", href="{$.url-base ~ $type.name }", fontname="FreeSans"];\n”;
    }

    @dot.append: "\n    // Superclasses\n";
    for @.types -> $type {
        next unless $type;
        for $type.super -> $super {
            @dot.append: “    "$type.name()" -> "$super" [color="$.class-color"];\n”;
        }
    }

    @dot.append: "\n    // Roles\n";
    for @.types -> $type {
        next unless $type;
        for $type.roles -> $role {
            @dot.append: “    "$type.name()" -> "$role" [color="$.role-color"];\n”;
        }
    }

    @dot.append: "\}\n";
    return @dot.join;
}

method to-dot-file ($file) {
    spurt $file, self.as-dot;
}

method to-file ($file, :$format = 'svg', :$size --> Promise:D) {
    once {
        run 'dot', '-V', :!err or die 'dot command failed! (did you install Graphviz?)';
    }
    die "bad filename '$file'" unless $file;
    my $graphvizzer = ( $file ~~ /Metamodel\:\: || X\:\:Comp/ )??'neato'!!'dot';
    my $valid-file-name = $file.subst(:g, /\:\:/,"");
    spurt $valid-file-name ~ ‘.dot’, self.as-dot(:$size).encode; # raw .dot file for debugging
    my $dot = Proc::Async.new(:w, $graphvizzer, '-T', $format, '-o', $valid-file-name);
    my $promise = $dot.start;
    await($dot.write(self.as-dot(:$size).encode));
    $dot.close-stdin;
    $promise
}


method write-type-graph-images(:$type-graph, :$path, :$force) {

    for $type-graph.sorted -> $type {
        FIRST my @type-graph-images;

        my $this-path = "{$path}/type-graph-$type.svg";

        my $dest = $this-path.IO;
        if $dest.e and ! $force {
           say qq:to/EOT/;
Not writing image for $this-path, it seems to be up-to-date
To force writing of type graph images, supply the --force option at the
command line, or delete file 'html/images/type-graph-$type.svg'";
EOT
            next;
        }

        my $viz = Doc::TypeGraph::Viz.new-for-type($type,
                :$!class-color, :$!enum-color, :$!role-color, :$!bg-color, :$!node-style);
        @type-graph-images.push: $viz.to-file($this-path, format => 'svg');

        LAST await @type-graph-images;
    }

    my %by-group = $type-graph.sorted.classify(&viz-group);
    %by-group<Exception>.append: $type-graph.types< Exception Any Mu >;
    %by-group<Metamodel>.append: $type-graph.types< Any Mu >;

    for %by-group.kv -> $group, @types {
        FIRST my @specialized-visualizations;

        my $viz = Doc::TypeGraph::Viz.new(:@types,
                :dot-hints(viz-hints($group)),
                :rank-dir('LR'),
                :$!class-color, :$!enum-color, :$!role-color, :$!bg-color, :$!node-style);
        @specialized-visualizations.push: $viz.to-file("$path/type-graph-{$group}.svg", format => 'svg');

        LAST await @specialized-visualizations;
    }
}

sub viz-group($type) {
    return 'Metamodel' if $type.name ~~ /^ 'Perl6::Metamodel' /;
    return 'Exception' if $type.name ~~ /^ 'X::' /;
    return 'Any';
}

sub viz-hints($group) {
    return '' unless $group eq 'Any';

    return '
    subgraph "cluster: Mu children" {
        rank=same;
        style=invis;
        "Any";
        "Junction";
    }
    subgraph "cluster: Pod:: top level" {
        rank=same;
        style=invis;
        "Pod::Config";
        "Pod::Block";
    }
    subgraph "cluster: Date/time handling" {
        rank=same;
        style=invis;
        "Date";
        "DateTime";
        "DateTime-local-timezone";
    }
    subgraph "cluster: Collection roles" {
        rank=same;
        style=invis;
        "Positional";
        "Associative";
        "Baggy";
    }
';
}

# vim: expandtab shiftwidth=4 ft=perl6
