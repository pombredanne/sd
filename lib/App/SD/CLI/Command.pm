package App::SD::CLI::Command;
use Moose::Role;
use Path::Class;
use Params::Validate qw(validate);

=head2 get_content %args

This is a helper routine for use in SD commands to enable getting records
in different ways such as from a file, on the commandline, or from an
editor. Returns the record content.

Valid keys in %args are type => str, default_edit => bool, and
prefill_props => $props_hash_ref, props_order => $order_array_ref,
footer => str, header => str.

Specifying props with prefill_props allows you to present lists of
key/value pairs (with possible default values) for a user to fill in.
If you need a specific ordering of props, specify it with
C<props_order>. Specifying C<header> and/or C<footer> allows you to
print some optional text before and/or after the list of props.

Note that you will have to post-process C<$content> from the routine
calling C<get_content> in order to extract the keys and values from
the returned text.

=cut

sub get_content {
    my $self = shift;
    my %args = @_;

    my $content;
    if (my $file = file($self->delete_arg('file'))) {
        $content = $file->slurp();
        $self->set_prop(name => $file->basename);
    } elsif ($content = $self->delete_arg('content')) {

    } elsif ($args{default_edit} || $self->has_arg('edit')) {
        my $text = '';
        if (my $header = $args{header}) {
            $text .= $header;
        }
        if (my $props = $args{prefill_props}) {
            my $props_order;
            my @ordering = ($props_order = $args{props_order}) ?
                                @$props_order : keys %$props;
            $text .= join "\n", map { "$_: $props->{$_}" } @ordering;
        }
        if (my $footer = $args{footer}) {
            $text .= $footer;
        }
        $content = $self->edit_text($text);
        # user aborted their text editor without changing anything; signify
        # this to the caller by returning nothing
        $content = '' if $content eq $text;
    } else {
        print "Please type your $args{type} and press ctrl-d.\n";
        $content = do { local $/; <> };
    }

    chomp $content;
    return $content;
}

=head2 create_new_comment content => str, uuid => str

A convenience method that takes a content string and a ticket uuid and creates
a new comment record, for use in other commands (such as ticket create
and ticket update).

=cut

sub create_new_comment {
    my $self = shift;
    validate(@_, { content => 1, uuid => 1 } );
    my %args = @_;

    use App::SD::CLI::Command::Ticket::Comment::Create;

    $self->cli->change_attributes( args => \%args );
    my $command = App::SD::CLI::Command::Ticket::Comment::Create->new(
        uuid => $args{uuid},
        cli => $self->cli,
        type => 'comment',
    );
    $command->run();
}

no Moose::Role;

1;

