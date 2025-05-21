package LibTranslate;
use Mojo::Base 'Mojolicious', -signatures;

# This method will run once at server start
sub startup ($self) {
  my $config = $self->plugin('NotYAMLConfig');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('translate#index')->name('index_page');

  # Libretranslate
  $r->post('/translate')->to('translate#process_translation')->name('do_translation');
}

1;
