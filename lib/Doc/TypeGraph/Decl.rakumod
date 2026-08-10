unit grammar Doc::TypeGraph::Decl;

token ident      { <.alpha> \w*                         }
token apostrophe { <[ ' \- ]>                           }
token identifier { <.ident> [ <.apostrophe> <.ident> ]* }
token longname   { <identifier>+ % '::'                 }
token package    { class | module | role | enum         }
token rolesig    { '[' <-[ \[\] ]>* ']'                 }
rule  inherits   { 'is' <longname>                      }
rule  roles      { 'does' <longname><rolesig>?          }

rule TOP {
    ^
    <package>
    <longname><rolesig>?
    [ <inherits> | <roles> ]*
    $
}

