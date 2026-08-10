use v6;
use Test;

use Doc::Type;

plan 6;

#    A
#  /   \
# B     C
# | \ / |   
# | / \ |
# D     E
#   \ /
#    F

my $A = Doc::Type.new(:name("A"));
   $A.super = [];

my $B = Doc::Type.new(:name("B"));
   $B.super = [$A];
my $C = Doc::Type.new(:name("C"));
   $C.super = [$A];

my $D = Doc::Type.new(:name("D"));
   $D.super = [$B, $C];
my $E = Doc::Type.new(:name("E"));
   $E.super = [$B, $C];

my $F = Doc::Type.new(:name("F"));
   $F.super = [$D, $E];

#subtest {
#    plan 6;
    is $A.mro».name, ["A"]                         , "No inheritance";
    is $B.mro».name, ["B", "A"]                    , "Single inheritance";
    is $C.mro».name, ["C", "A"]                    , "Single inheritance 2";
    is $D.mro».name, ["D", "B", "C", "A"]          , "Double inheritance";
    is $E.mro».name, ["E", "B", "C", "A"]          , "Double inheritance 2";
    is $F.mro».name, ["F", "D", "E", "B", "C", "A"], "All in one";
#}, "Mro and c3 merge algorithm";

done-testing;
