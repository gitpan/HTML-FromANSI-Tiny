use strict;
use warnings;
use Test::More 0.96;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $h = new_ok($mod, []);

my @css = $h->css;
my @colors = do { no warnings 'once'; @HTML::FromANSI::Tiny::COLORS; };

# (fg + bg) + bold + dark + underline + concealed
my $exp_lines = ((@colors * 2) + 1 + 1 + 1 + 1);

is scalar @css, $exp_lines, 'got all styles';

my $color = '[0-9a-fA-F]{3}';
my @rgb;

ok find_style(qr/.bold { font-weight: bold; }/), 'bold';

ok find_style(qr/.yellow { color: #($color); }/                    ), 'fg color';
ok $rgb[0] == $rgb[1] && $rgb[0] >  $rgb[2], 'yellow';

ok find_style(qr/.on_red { background-color: #($color); }/         ), 'bg color';
ok $rgb[0] >  $rgb[1] && $rgb[0] >  $rgb[2], 'red';

ok find_style(qr/.bright_green { color: #($color); }/              ), 'bright fg color';
ok $rgb[1] >  $rgb[0] && $rgb[1] >  $rgb[2], 'green';

my @bg  = @rgb;

ok find_style(qr/.on_bright_green { background-color: #($color); }/), 'bright bg color';
ok $rgb[1] >  $rgb[0] && $rgb[1] >  $rgb[2], 'green';

my @obg = @rgb;

ok $obg[$_] == $bg[$_], 'same color' for 0 .. 2;

ok find_style(qr/.on_green { background-color: #($color); }/       ), 'bg color';
ok $rgb[1] >  $rgb[0] && $rgb[1] >  $rgb[2], 'green';

my @og = @rgb;

ok $obg[$_] > $og[$_], 'brighter color' for 0 .. 2;

my $under = 'underline { text-decoration: underline; }';

# no prefixes
ok find_style(qr/^\.$under$/), 'underline';

# class_prefix
$h = new_ok($mod, [class_prefix => 'term-']);
@css = $h->css;

ok!find_style(qr/^\.$under$/), 'bare selector not found';
ok find_style(qr/^\.term-$under$/), 'prefixed underline found';

# selector_prefix
$h = new_ok($mod, [selector_prefix => '#term ']);
@css = $h->css;

ok!find_style(qr/^\.$under$/), 'bare selector not found';
ok find_style(qr/^#term \.$under$/), 'prefixed underline found';

$h = new_ok($mod, [selector_prefix => 'div:hover .t']);
@css = $h->css;

ok!find_style(qr/^\.$under$/), 'bare selector not found';
ok find_style(qr/^div:hover \.t\.$under$/), 'prefixed underline found (no space)';

# class_prefix and selector_prefix
$h = new_ok($mod, [class_prefix => 'term-', selector_prefix => '#output ']);
@css = $h->css;

ok!find_style(qr/^\.$under$/), 'bare selector not found';
ok find_style(qr/^#output \.term-$under$/), 'prefixed underline found';

$h = new_ok($mod, [class_prefix => 'tt', selector_prefix => 'div:hover .t']);
@css = $h->css;

ok!find_style(qr/^\.$under$/), 'bare selector not found';
ok find_style(qr/^div:hover \.t\.tt$under$/), 'prefixed underline found (no space)';

# style_tag

my @old_css = @css;
@css = $h->style_tag;
is scalar @css, $exp_lines + 2, 'css plus style open/close';

is_deeply \@css, ['<style type="text/css">', @old_css, '</style>'], 'style wraps css';

ok!find_style(qr/^\.$under$/), 'bare selector not found';
ok find_style(qr/^div:hover \.t\.tt$under$/), 'prefixed underline found (no space)';

done_testing;

sub find_style {
  my $r = shift;
  @rgb = ();
  my $found = 0;
  for my $css (@css) {
    if( $css =~ $r ){
      @rgb = map { hex $_ } split //, $1
        if $1;
      ++$found;
    }
  }
  $found;
}
