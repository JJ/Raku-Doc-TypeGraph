[![Test](https://github.com/JJ/Raku-Doc-TypeGraph/actions/workflows/test.yaml/badge.svg)](https://github.com/JJ/Raku-Doc-TypeGraph/actions/workflows/test.yaml)

# NAME

Doc::TypeGraph - Parse a description of the types for documentation.

# SYNOPSIS

```Raku

    use Doc::TypeGraph;

    # create and initialize it
    my $tg = Doc::TypeGraph.new-from-file("./resources/type-graph.txt");

    # and use it!
    say $tg.sorted;
```

# DESCRIPTION

Doc::TypeGraph creates a graph of all types in a file that describes
them. It gives you info about what classes a type inherits from and the roles it does. In addition, it also computes the inversion of this relations, which let you know what types inherit a given type and the types implementing a specific role.

All types are represented using a `Doc::Type` object. Categories are just
descriptive and are not really used in the generation of graphs. They will
probably be eliminated in later iterations of this library.

# Installation

You will need to have `graphviz` installed to generate the graphs; it uses
 `dot` 
# FILE SYNTAX

    [ Category ]
    # only one-line comments are supported
    packagetype typename[role-signature]
    packagetype typename[role-signature] is typename[role-signature] # inheritance
    packagetype typename[role-signature] does typename[role-signature] # roles

    [ Another category ]

- Supported categories: `Metamodel`, `Domain-specific`, `Basic`, `Composite`, `Exceptions` and `Core`.

- Supported packagetypes: `class`, `module`, `role` and `enum`.

- Supported typenames: whatever string following the syntax
  `class1::class2::class3 ...`; `class` follows the usual identifier
  format that might include apostrophes and dashes.

- `[role-signature]` is not processed, but you can add it anyway.

- If your type inherits from more than one type or implements several roles, you can add more `is` and `does` statements (separated by spaces).

Example:

    [Metamodel]
    # Metamodel
    class Metamodel::Archetypes
    role  Metamodel::AttributeContainer
    class Metamodel::GenericHOW       does Metamodel::Naming
    class Metamodel::MethodDispatcher is Metamodel::BaseDispatcher is Another::Something
    enum  Bool                          is Int
    module Test

(whitespace is only included for appearance, it does not have any
meaning)


### has Associative %.types

Format: \$name => Doc::Type.

### has Positional @.sorted

Sorted array of type names.

### method new-from-file

```raku
method new-from-file(
    $fn
) returns Mu
```

Initialize %.types from a file.

### method parse-from-file

```raku
method parse-from-file(
    $fn
) returns Mu
```

Parse the file (using the Decl grammar) and initialize %.types and @.sorted

### method topo-sort

```raku
method topo-sort() returns Mu
```

This method takes all Doc::Type objects in `%.types` and sort them
by its name. After that, recursively, add all roles and supers in the
object to `@!sorted` 

# AUTHOR

Moritz Lenz <@moritz> Antonio Gámiz <@antoniogamiz>

# COPYRIGHT AND LICENSE

This module is a spin-off from the Official Doc repo, if you want to see the 
past changes go to the [official doc](https://github.com/Raku/doc).

Copyright 2019 Moritz and Antonio This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
