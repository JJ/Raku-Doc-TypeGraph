#!/usr/bin/env Doc

use v6;
use Test;
use lib 'lib';
use Doc::TypeGraph;

plan 2;

constant $file-name = "test-infinite-loop.txt";
my $original-tg-file = $file-name.IO.e??$file-name!!"t/$file-name";
my $t = Doc::TypeGraph.new-from-file($original-tg-file);
ok $t.types<Any>.mro, 'No infinite loop';
is $t.types<Any>.mro, "Any", "Contains correctc mro";
