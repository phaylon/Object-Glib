use strictures 1;

package Object::Glib::Meta::Signal;
use Moo;

use namespace::clean;

has name => (is => 'ro', required => 1);

1;
