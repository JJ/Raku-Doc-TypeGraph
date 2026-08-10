use v6.c;

unit class Doc::Type;

=begin pod

=head1 NAME

Doc::Type - Used to represent different types in a typegraph

=head1 SYNOPSIS

    use Doc::Type;

    # create and name it
    my $type = Doc::Type.new(:name("Rat"));

    # add some properties
    $type.super.push(["Any", "Mu", "Numeric"]);
    $type.roles.push(["Role1", "Role2"]);

    # and get its MRO!
    say $type.mro;

=head1 DESCRIPTION

C<Doc::Type> represents a type in the Raku language. It stores
its parent classes and the role it's implementing. In addition, it also
stores the inverted relation, that's to say: all types inheriting from
this one, and if it's a role, all types implementing it.

=head1 AUTHOR

Moritz Lenz <@moritz>
Antonio Gámiz <@antoniogamiz>

=head1 COPYRIGHT AND LICENSE

This module has been spun off from the L<official Raku
documentation repository|https://github.com/Raku/doc>, check it out for past
history of this code..

Copyright 2019 Moritz and Antonio Gámiz.
This library is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=end pod

#| Name of the type.
has Str $.name handles <Str>;
#| All the classes of the type.
has @.super;
#| All classes inheriting from this type.
has @.sub;
#| All roles implemented by the type.
has @.roles;
#| If it's a role, all types implementing it.
has @.doers;
#| One of C<class>, C<role>, C<module> or C<enum>.
has $.packagetype is rw = 'class';
#| One of C<Metamodel>, C<Domain-specific>, C<Basic>, C<Composite>, C<Exceptions> or C<Core>.
has @.categories;
#| Method Resolution Order (MRO) of the type.
has @.mro;

#| Computes the MRO and stores it in @.mro.
method mro(Doc::Type:D:) {
    # do not recompute mro
    return @!mro if @!mro;
    # say "=";
    if @.super == 1 {
        if ($.name eq any(<Any>) and @.super[0].name eq "Any") {return []}
        @!mro = @.super[0].mro;
    } elsif @.super > 1 {
        if ($.name eq any(<Any>) and @.super[0].name eq "Any") {return []}
        my @merge_list = @.super.map: *.mro.item;
        @!mro = self.c3_merge(@merge_list);
    }

    @!mro.unshift: self;
    @!mro;
}

#| C3 linearization algorithm (L<more info|https://en.wikipedia.org/wiki/C3_linearization>).
method c3_merge(@merge_list) {
    my @result;
    my $accepted;
    my $something_accepted = 0;
    my $cand_count = 0;

    # find a candidate
    for @merge_list -> @cand_list {
        next unless @cand_list;
        my $rejected = 0;
        my $cand_class = @cand_list[0];
        $cand_count++;
        # search cyclic inheritance. If it's found then reject the candidate
        for @merge_list {
            say "List $_";
            next if $_ === @cand_list;
            for 1..+$_ -> $cur_pos {
                if $_[$cur_pos] === $cand_class {
                    say "$cur_pos, $cand_class";
                    $rejected = 1;
                    last;
                }
            }
        }
        # continue until some candidate is found
        unless $rejected {
            $accepted = $cand_class;
            $something_accepted = 1;
            last;
        }
    }

    # this means @merge_list was initially empty
    return () unless $cand_count;

    # no candidate was found
    unless $something_accepted {
        die("Could not build C3 linearization for {self}: ambiguous hierarchy");
    }

    # deletes accepted candidate from all elements in the list
    for @merge_list.keys -> $i {
        @merge_list[$i] = [@merge_list[$i].grep: { $_ ne $accepted }] ;
    }

    # repeat
    @result = self.c3_merge(@merge_list);
    @result.unshift: $accepted;
    @result;
}

method gist {
    my $supers     = @.super.map({.name}) || "None";
    my $sub        = @.sub.map({.name}) || "None";
    my $roles      = @.roles.map({.name}) || "None";
    my $doers      = @.doers.map({.name}) || "None";
    my $categories = @.categories || "None";
    my $mro        = @.mro.map({.name}) || "None";

    return "\{"                     ~
        "supers: $supers, "         ~
        "sub: $sub, "               ~
        "roles: $roles, "           ~
        "doers: $doers, "           ~
        "categories: $categories, " ~
        "mro: $mro"                 ~
        "\}"
}

# vim: expandtab shiftwidth=4 ft=Doc
