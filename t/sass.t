#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
$|++;
use lib ('../lib', '../../lib');

my $t = Test::Mojo->new;

my $app = $t->app;

$app->plugin('Sass');

my $c = Mojolicious::Controller->new;
$c->app($app);

my $scss = << 'SCSS';
p {
  color: black;
  a {
    color: red;
  }
}
p {
  font-size: 12pt;
}
SCSS

like($c->sass_stylesheet(sub { $scss }), qr/p a /, 'scss stylesheet' );
unlike($c->sass_stylesheet(compress => 1, sub { $scss }),
       qr/\s\s/, 'scss stylesheet (compressed)' );

like($c->render_to_string(
  inline => $scss,
  format => 'css',
  handler => 'sass'
), qr/p a /, 'scss handler');


unlike($c->render_to_string(
  partial => 1,
  inline => $scss,
  format => 'css',
  handler => 'sass',
  compress => 1
), qr/\s\s/, 'scssc handler');


done_testing;

__END__
