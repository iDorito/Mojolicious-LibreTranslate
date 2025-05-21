package LibTranslate::Controller::Translate;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent; # Para hacer peticiones HTTP
use Mojo::JSON;
use Try::Tiny;       # Para un mejor manejo de excepciones

# Idioma de origen
my %source_languages = (
    it => 'Italiano',
);

# Idiomas de destino
my %target_languages = (
    de => 'Alemán',
    fr => 'Francés',
    en => 'Inglés',
    es => 'Español',
);

# Acción para mostrar el formulario de traducción (GET /)
sub index {
    my $c = shift;

    $c->stash(
        source_langs => \%source_languages,
        target_langs => \%target_languages,
        source_text  => $c->flash('source_text') // '',
        translated_text => $c->flash('translated_text') // '',
        selected_source_lang => $c->flash('selected_source_lang') // 'it',
        selected_target_lang => $c->flash('selected_target_lang') // 'en',
    );
    $c->render(template => 'translate/index');
}

# Acción para procesar la traducción (POST /translate)
sub process_translation {
    my $c = shift;

    my $source_text      = $c->param('source_text') // '';
    my $source_lang_code = lc($c->param('source_lang') // 'it'); # lc para asegurar minúsculas
    my $target_lang_code = lc($c->param('target_lang') // 'en'); # lc para asegurar minúsculas
    my $translated_text  = '';

    if ($source_text ne '' && $target_lang_code && $source_lang_code) {
        my $ua = Mojo::UserAgent->new;

        $c->app->log->debug("Query ready, trying to fetch query");

        try{
            # Making the POST query
            my $tx = $ua->post(
                "http://192.168.168.204:5000/translate" =>
                {
                    'Content-Type' => 'application/json'
                }
                => json => {
                    'q'        => $source_text,
                    'source'   => $source_lang_code, # 'auto' también es una opción si lo permites
                    'target'   => $target_lang_code
                }
            );

            $c->app->log->debug("Query made");
            if ($tx->res->code == 200){
                my $res = $tx->res->json;

                $translated_text = $res->{translatedText};
            }
        }
        catch{
            my $e = $_;
            $c->app->log->error("An exception occurred during LibreTranslate API call: $e");
        };

    } elsif ($source_text eq '') {
        $translated_text = "Por favor, ingresa texto para traducir.";
    } else {
        $translated_text = "Por favor, selecciona un idioma de origen y destino válidos.";
    }

    # Guardar en flash para persistir tras la redirección
    $c->flash(
        source_text  => $source_text,
        translated_text => $translated_text,
        selected_source_lang => $source_lang_code,
        selected_target_lang => $target_lang_code,
    );

    $c->redirect_to('index_page');
}

1;