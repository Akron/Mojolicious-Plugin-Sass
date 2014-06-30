package Mojolicious::Plugin::Sass;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';
use Text::Sass::XS ':const';

our $VERSION = '0.03';

our $COMPRESS = {
  output_style    => SASS_STYLE_COMPRESSED,
  source_comments => SASS_SOURCE_COMMENTS_NONE
};

# Register Plugin
sub register {
  my ($plugin, $mojo) = @_;

  # Sass converter object
  my $text_sass = Text::Sass::XS->new;

  # Add 'sass' handler
  $mojo->renderer->add_handler(
    sass => sub {
      my ($r, $c, $output, $options) = @_;

      # Get styles from cache
      my ($cache_result, $path) = _get_from_cache($r, $options);

      # Set cache as output
      if ($cache_result) {
	$$output = $cache_result;
	return 1;
      };

      # Get data
      my $sass =
	$options->{inline} ? $path : _get_data($r, $c, $path, $options);

      # No data found
      return unless $sass;

      # Convert sass to css
      my $css = $text_sass->compile(
	$sass, $options->{compress} ? $COMPRESS : {}
      );

      # Set styles to cache
      $r->cache->set($options->{cache} => $css);

      $$output = $css;

      return 1;
    });


  # Stylesheet helper
  $mojo->helper(
    sass_stylesheet => sub {
      my $c = shift;
      my $style = pop;

      # No content
      return unless ref $style eq 'CODE';

      my %param = @_;
      my $compress = delete $param{compress} || 0;

      # Convert sass to css
      my $css = $text_sass->compile($style->(), $compress ? $COMPRESS : {});

      # Surround content with CDATA
      my $cb = sub { "/*<![CDATA[*/\n" . $css . "\n/*]]>*/" };

      # 'style' tag
      return $c->tag(style => %param, $cb);
    }
  );
};


# Get data from cache
sub _get_from_cache {
  my ($r, $options) = @_;

  $options ||= {};

  # Todo: First render using ep!

  # Get path
  my $path = $options->{inline} || $r->template_path($options);

  # No path defined
  return unless defined $path;

  # Generate caching key from path
  my $key = $options->{cache} =
    b(
      $path .
	($options->{format} // 'css') .
	  ($options->{handler} // 'scss')
	)->encode('UTF-8')->md5_sum;

  # Compile helpers and stash values
  return (($r->cache->get($key) || undef), $path);
};


# Get data from file or data section
sub _get_data {
  my ($r, $c, $path, $options) = @_;

  # Not found
  return unless my $t = $r->template_name($options);

  # Try template
  if (-r $path) {
    $c->app->log->debug(qq{Rendering sass template "$t".});
    return b($path)->slurp;
  }

  # Try DATA section
  elsif (my $sass = $r->get_data_template($options)) {
    $c->app->log->debug(qq{Rendering sass template "$t" from DATA section.});
    return $sass;
  };

  return;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::Sass - Use C<Sass> in your Mojolicious templates

B<This plugin isn't maintained. Please use L<Mojolicious::Plugin::AssetPack> for Sass processing instead!>

=head1 SYNOPSIS

  $app->plugin('Sass');


=head1 DESCRIPTION

L<Mojolicious::Plugin::Sass> is a simple plugin to use Sass
(L<http://sass-lang.com/>) in your Mojolicious app.


=head1 METHODS

=head2 C<register>

  # Mojolicious
  $app->plugin('sass');

  # Mojolicious::Lite
  plugin 'sass';

Called when registering the plugin.


=head1 HANDLER

=head2 C<sass>

Converts a Sass stylesheet (as SCSS) to CSS on the fly.


=head1 HELPERS

=head2 C<sass_stylesheet>

  # In a template
  %= sass_stylesheet compress => 1, begin
    p {
      color: #000;
      a {
        color: red;
      }
    }
    p {
      font-size: 12pt;
    }
  % end

Renders Sass stylesheet (SCSS) code inline.

Optional parameters include C<compress =E<gt> "1"|"0">
(the default is C<0>).


=head1 DEPENDENCIES

L<Mojolicious>,
L<Text::Sass::XS>.


=head1 SEE ALSO

The functionality of this plugin is similar to
L<Mojolicious::Plugin::SassRenderer>, but supports template caching,
C<DATA> templates, stylesheet helpers, and compression.
It only supports SCSS.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Sass


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Nils Diewald.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
