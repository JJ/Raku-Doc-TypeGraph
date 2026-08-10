unit class Doc::TypeGraph::DeclActions;

#| Package type
has $.packagetype is rw;
#| Name of the type
has $.type is rw;
#| All parent classes found.
has @.super is rw;
#| All roles found.
has @.role is rw;

#| Detects name in the form Name::Of::The::Type
method longname($/) {
    $!type //= $/.Str;
}

#| Detects is Some::Class
method inherits($/) {
    @!super.append: $/<longname>.Str;
}

#| Detects does Some::Role
method roles($/) { 
    @!role.append: $/<longname>.Str;
}

#| Detects class, module, role or enum
method package($/) { 
    $!packagetype = $/.Str;
}
