#!/usr/bin/perl

use lib '/usr/local/uravo/lib';
use MinorImpact;
use Uravo;

use Getopt::Long;

my $uravo = new Uravo;
my @args;
my $delim   = "\n";
my $params = {};

GetOptions("delim=s"   => \$delim,
           "verbose"   => \$verbose,
           "help"      => sub { usage(); },
           "flat"      => sub { $delim=' ' },
           "params=s%" => \$params
         ) || usage();


eval { &main(); };
print "$@\n" if ($@);
exit;


sub main {
    my $action  = shift @ARGV;

    foreach my $param (@ARGV)  {
        if ($param =~ /^(\w+)=(\S+)$/) {
            $params->{$1}  = $2;
        } else {
            push @args, $param;
        }
    }
    eval "do_$action(\$params)";
    print "$@\n" if ($@);
}

sub do_add {
    my $params = shift;
    my $local_params = MinorImpact::cloneHash($params);

    my $arg = shift(@ARGV);
    $arg =~s/s$//;
    if ($arg eq 'type') {
        die("you must specify type_id") unless (defined($params->{type_id}));
        Uravo::Serverroles::Type::add($params)
    }
}

sub do_del {
    do_delete(@_);
}

sub do_delete {
    my $params = shift;
    my $arg = shift(@ARGV);
    $arg =~s/s$//;
    if ($arg =~/^event$/ ) {
        if (length(@ARGV) > 0) {
            $id = shift(@ARGV);
        }
        elsif (defined($params->{Identifier})) {
            $id = $params->{Identifier};
        }
        elsif (defined($params->{Serial})) {
            $id = $params->{Serial};
        }
        my $event = $uravo->getEvent($id) if ($id);
        return unless $event;
        print("deleting " . $event->toString() . "\n") if ($verbose);
        $event->clear();
     }
    elsif ($arg eq 'type' ) {
        die("you must specify type_id") unless (defined($params->{type_id}));
        my $type = $uravo->getType($params->{type_id});
        die("invalid type") unless ($type);
        print("deleting " . $type->toString() . "\n") if ($verbose);
        $type->delete();
     }
}

sub do_edit {
    my $params = shift;
    my $local_params = MinorImpact::cloneHash($params);

    my $arg = shift(@ARGV);
    if ($arg eq "server" ) {
        if (defined($local_params->{server_id})) {
            my $server = $uravo->getServer($params->{server_id});
            if (defined($server)) {
                print("updating " . $server->hostname());
                $server->update($local_params);
            }
        }
    }
    elsif ($arg eq "type" ) {
        if (defined($local_params->{type_id})) {
            my $type = $uravo->getType($params->{type_id});
            if (defined($type)) {
                print("updating " . $type->name());
                $type->update($local_params);
            }
        }
    }
}

sub do_list {
    my $params  = shift;
    my $local_params = MinorImpact::cloneHash($params);
    $local_params->{id_only} = 1;
    if (!defined($params->{silo}) && !defined($params->{silo_id})) {
        $local_params->{all_silos} = 1;
    }

    foreach my $arg (@ARGV) {
	$arg =~s/s$//;
	if ($arg eq "check") {
	}
        if ($arg eq "cluster") {
            print join($delim, $uravo->getClusters($local_params, {id_only=>1}));
        }
        if ($arg eq "event" ) {
            my @events = $uravo->getEvents($local_params, {id_only=>1});
            my $output = "";
            foreach my $event (@events) {
                $output .= $event->toString() . $delim;
            }
            print $output;
        }
        if ($arg eq "server" ) {
            print join($delim, $uravo->getServers($local_params, {id_only=>1}));
        }
        if ($arg eq "type" ) {
            print join($delim, $uravo->getTypes($local_params, {id_only=>1}));
        }
    }
}

sub usage {
    my $error       = shift;
    $0              =~/([^\/]+)$/;
    my $shortname   = $1 || $0;

    print "$error" if ($error);
    print "\n" unless (!$error || $error =~/\n$/);
    print <<USAGE;
usage: $shortname [options] <command> [parameter [...] ]

OPTIONS
    --flat          Print the results horizontally (space delimited) rather than
                    vertically (\\n delimited).
    --help          Display this message.

COMMANDS
    One of the following must be passed to $shortname:
        list servers    
        list clusters
        list events
        list types

PARAMETERS
    Parameters can be passed to various commands in the form of a 'name=value' pairs.
    See the following examples.

EXAMPLES
    Print a list of clusters:
        $ $shortname list clusters
        cluster_id_1
        cluster_id_2

    Print a list of servers for a given cluster:
        $ $shortname list servers cluster=cluster_id_1
        server_id_1
        server_id_2

    Print a list of all servers, horizontally:
        $ $shortname --flat list servers 
        server_id_1 server_id_2 server_id_3 server_id_4

    Show all the servers of a particular type in a particular cluster:
        $ $shortname list servers type=type_id_1 cluster=cluster_id_2
        server_id_3

    Display the servers that are not of a certain type:
        $ $shortname list servers type=\!type_id_1
        server_id_1
        server_id_2
        server_id_4

       (Note the backslash to escape the '!' character.  Shells do weird things with
        '!'s.)


USAGE
    exit;
}
