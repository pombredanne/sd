package App::SD::CLI::Command::Ticket::Comment::Create;
use Moose;

extends 'Prophet::CLI::Command::Create';
with 'App::SD::CLI::Model::TicketComment';
with 'App::SD::CLI::Command';

# override args to feed in that ticket's uuid as an argument to the comment
override run => sub {
    my $self = shift;
    $self->args->{'ticket'} = $self->cli->uuid;
    $self->args->{'content'} = $self->get_content('comment');
    super(@_);
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

