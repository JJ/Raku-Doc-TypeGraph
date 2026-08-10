use Doc::Type;
use Doc::TypeGraph::Decl;
use Doc::TypeGraph::DeclActions;

constant BASE_CLASS = "Any";

unit class Doc::TypeGraph;

=begin pod

=head1 NAME

Doc::TypeGraph - Parse a class description file, return a type graph.

=head1 SYNOPSIS

    use Doc::TypeGraph;

    # create and initialize it
    my $tg = Doc::TypeGraph.new-from-file("./resources/type-graph.txt");

    # and use it!
    say $tg.sorted;

=head1 DESCRIPTION

Doc::TypeGraph creates a graph of all types in a file. It gives you info
about what classes a type inherits from and the roles it does. In addition,
it also computes the inversion of this relations, which let you know what
types inherit a given type and the types implementing a specific role.

=head1 FILE SYNTAX

    [ Category ]
    # only one-line comments are supported
    packagetype typename[role-signature]
    packagetype typename[role-signature] is typename[role-signature] # inheritance
    packagetype typename[role-signature] does typename[role-signature] # roles

    [ Another cateogory ]

=item Supported categories: C<Metamodel>, C<Domain-specific>, C<Basic>, C<Composite>,
C<Exceptions> and C<Core>.
=item Supported packagetypes: C<class>, C<module>, C<role> and C<enum>.
=item Supported typenames: whatever string following the syntax C<class1::class2::class3 ...>.
=item C<[role-signature]> is not processed, but you can add it anyway.
=item If your type inherits from more than one type or implements several roles, you can
add more C<is> and C<does> statements (separated by spaces).

Example:

    [Metamodel]
    # Metamodel
    class Metamodel::Archetypes
    role  Metamodel::AttributeContainer
    class Metamodel::GenericHOW       does Metamodel::Naming
    class Metamodel::MethodDispatcher is Metamodel::BaseDispatcher is Another::Something
    enum  Bool                          is Int
    module Test

=head1 AUTHOR

Moritz <@moritz>
Antonio Gámiz <@antoniogamiz>

=head1 COPYRIGHT AND LICENSE

This module has been spun off from the Official Doc repo, if you want to see past changes go
to the L<official doc|https://github.com/Raku/doc>.

Copyright 2019-21 Raku Team
This library is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=end pod

#| Format: $name => Doc::Type.
has %.types;
#| Sorted array of type names.
has @.sorted;

#| Initialize %.types from a file.
method new-from-file($fn = "type-graph.txt") {
    my $filename = $fn.IO.e ?? $fn
                            !! %?RESOURCES<data/type-graph.txt>;
    my $n = self.bless;
    $n.parse-from-file($filename);
    $n;
}

#| Parse the file (using the C<Decl> grammar) and initialize C<%.types> and
#| C<@.sorted>. C<Any> will always be there, since any type (but Junctions)
#| subclass it.
method parse-from-file($fn) {
    my $f = open $fn;

    %!types{BASE_CLASS} = Doc::Type.new(:name(BASE_CLASS));

    my @categories;
    for $f.lines -> $l {
        # ignore comments
        next if $l ~~ / ^ '#' /;

        # ignore empty lines
        if $l ~~ / ^ \s* $ / {
            @categories = Empty;
            next;
        }

        # new [category]
        if $l ~~ / :s ^ '[' (\S+) + ']' $/ {
            @categories = @0>>.lc;
            next;
        }

        # parse line
        my $m = Doc::TypeGraph::Decl.parse($l, :actions(Doc::TypeGraph::DeclActions.new)).actions;

        # initialize the type
        my $type = %!types{$m.type} //= Doc::Type.new(:name($m.type));
        $type.packagetype = $m.packagetype;
        $type.categories = @categories;

        for $m.super -> $t {
            %!types{$t} //= Doc::Type.new(:name($t));
            $type.super.append: %!types{$t};
        }
        for $m.role -> $t {
            %!types{$t} //= Doc::Type.new(:name($t));
            $type.roles.append: %!types{$t};
        }

    }

    for %!types.values -> $t {
        # roles that have a superclass actually apply that superclass
        # to the class that does them, so mimic that here, including
        # parent roles
        my @roles = $t.roles;
        while @roles {
            my $r = @roles.shift;

            $t.super.append: $r.super if $r.super;
            @roles.append: $r.roles if $r.roles;
        }

        # non-roles default to superclass Any
        if $t.packagetype ne 'role' && !$t.super && $t ne 'Mu' && $t.name ne BASE_CLASS {
            $t.super.append: %!types<Any>;
        }
    }

    # this for loop initializes sub and doers attributes
    # of every Doc::Type object in %.types in order to
    # cache the inversion of all type relationships
    for %!types.values -> $t {
        $_.sub.append($t)   for $t.super;
        $_.doers.append($t) for $t.roles;
    }

    self!topo-sort;
}

#| This method takes all Doc::Type objects in %.types
#| and sort them by its name. After that, recursively,
#| add all roles and supers in the object to @!sorted
method !topo-sort {
    my %seen;
    sub visit($n) {
        return if %seen{$n};
        %seen{$n} = True;
        visit($_) for flat $n.super, $n.roles;
        @!sorted.append: $n;
    }
    visit($_) for %!types.values.sort(*.name);
}

method gist {
    @.sorted;
}
