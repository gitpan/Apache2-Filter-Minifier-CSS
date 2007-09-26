use 5.008;
use strict;
use warnings;
use ModPerl::MM qw();
use Apache::TestMM qw(test clean);
use Apache::TestRunPerl qw();

# configure tests based on incoming arguments
Apache::TestMM::filter_args();

# create test harness
Apache::TestRunPerl->generate_script();

# write Makefile
ModPerl::MM::WriteMakefile(
    'NAME'              => 'Apache2::Filter::Minifier::CSS',
    'VERSION_FROM'      => 'lib/Apache2/Filter/Minifier/CSS.pm',
    'AUTHOR'            => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'PREREQ_PM'         => {
        'Apache::Test'          => 1.12,
        'CSS::Minifier'         => 0,
        'mod_perl2'             => 2.0,
        },
    );
