#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION_FROM => 'lib/Mojolicious/Plugin/Sass.pm',
    NAME         => 'Mojolicious::Plugin::Sass',
    AUTHOR       => 'Nils Diewald',
    PREREQ_PM => {
        'Mojolicious' => 5.00,
	'Text::Sass::XS' => 0.10,
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t'}
);

