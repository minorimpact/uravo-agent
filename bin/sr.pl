#!/usr/bin/perl

use Data::Dumper;
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

    my $arg = shift(@args);
    $arg =~s/s$//;
    if ($arg eq 'server') {
        die("you must specify server_id") unless (defined($local_params->{server_id}));
        Uravo::Serverroles::Server::add($local_params);
    }
    elsif ($arg eq 'silo') {
        my $id = shift(@args);
        if ($id && !defined($local_params->{silo_id})) { $local_params->{silo_id} = $id; }
        die("you must specify silo_id") unless (defined($local_params->{silo_id}));
        $silo = Uravo::Serverroles::Silo::add($local_params);
        print("added " . $silo->id() . "\n") if ($verbose && $silo);
    }
    elsif ($arg eq 'threshold') {
        my $id = shift(@args);
        my $id2 = shift(@args);
        $local_params->{AlertGroup} = $id unless (defined($local_params->{AlertGroup}) and $local_params->{AlertGroup} != "");
        $local_params->{AlertKey} = $id2 unless (defined($local_params->{AlertKey}) and $local_params->{AlertKey} != "");
        die("you must specify an AlertGroup") unless ($local_params->{AlertGroup});
        print("adding $local_params->{AlertGroup}\n") if ($verbose);
        $uravo->updateThreshold($local_params);
    }
    elsif ($arg eq 'type') {
        die("you must specify type_id") unless (defined($local_params->{type_id}));
        Uravo::Serverroles::Type::add($local_params);
    }
}

sub do_del {
    do_delete(@_);
}

sub do_delete {
    my $params = shift;
    my $local_params = MinorImpact::cloneHash($params);
    my $arg = shift(@args);
    $arg =~s/s$//;
    if ($arg =~/^event$/ || $arg eq 'alert' ) {
        if (length(@args) > 0) {
            $id = shift(@args);
        }
        elsif (defined($local_params->{Identifier})) {
            $id = $local_params->{Identifier};
        }
        elsif (defined($local_params->{Serial})) {
            $id = $local_params->{Serial};
        }
        my $event = $uravo->getEvent($id) if ($id);
        return unless $event;
        print("deleting " . $event->toString() . "\n") if ($verbose);
        $event->clear();
    }
    elsif ($arg eq 'silo' ) {
        my $id = shift(@args) || $local_params->{silo_id};
        die("you must specify a silo_id") unless ($id);
        my $silo = $uravo->getSilo($id) || die "can't get $id";
        print("deleting " . $silo->toString() . "\n") if ($verbose);
        $silo->delete();
    }
    elsif ($arg eq 'threshold') {
        my $id = shift(@args);
        my $id2 = shift(@args);
        $local_params->{AlertGroup} = $id unless (defined($local_params->{AlertGroup}) and $local_params->{AlertGroup} != "");
        $local_params->{AlertKey} = $id2 unless (defined($local_params->{AlertKey}) and $local_params->{AlertKey} != "");
        die("you must specify an AlertGroup") unless ($local_params->{AlertGroup});
        print("deleting $local_params->{AlertGroup}\n") if ($verbose);
        $uravo->deleteThreshold($local_params);
    }
    elsif ($arg eq 'type' ) {
        die("you must specify type_id") unless (defined($local_params->{type_id}));
        my $type = $uravo->getType($local_params->{type_id});
        die("invalid type") unless ($type);
        print("deleting " . $type->toString() . "\n") if ($verbose);
        $type->delete();
    }
}

sub do_edit {
    my $params = shift;
    my $local_params = MinorImpact::cloneHash($params);

    my $arg = shift(@args);
    $arg =~s/s$//;
    if ($arg eq "bu") {
        $id = shift(@args);
        if ($id && !defined($local_params->{bu_id})) { $local_params->{bu_id} = $id; }
        die("you must specify bu_id") unless (defined($local_params->{bu_id}));
        $bu = new Uravo::Serverroles::BU($local_params->{bu_id});
        $bu->update($local_params);
        print("updated " . $bu->id() . "\n") if ($verbose);
    }
    elsif ($arg eq "server" ) {
        my $server = $uravo->getServer();
        if (defined($local_params->{server_id})) {
            $server = $uravo->getServer($local_params->{server_id});
        }
        if (defined($server)) {
            print("updating " . $server->hostname() . "\n");
            $server->update($local_params);
        }
    }
    elsif ($arg eq "silo") {
        my $id = shift(@args) || (defined($local_params->{silo_id})?$local_params->{silo_id}:undef);
        die("you must specify silo_id") unless ($id);
        my $silo = new Uravo::Serverroles::Silo($id);
        $silo->update($local_params);
        print("updated " . $silo->id() . "\n") if ($verbose);
    }
    elsif ($arg eq 'threshold') {
        unshift(@args, "threshold");
        return do_add($params)
    }
    elsif ($arg eq "type" ) {
        if (defined($local_params->{type_id})) {
            my $type = $uravo->getType($local_params->{type_id});
            if (defined($type)) {
                print("updating " . $type->name());
                $type->update($local_params);
            }
        }
    }
}

sub do_info {
    my $params  = shift;
    my $local_params = MinorImpact::cloneHash($params);
    my $arg = shift(@args);
    if ($arg eq "server") {
        my $id = shift(@args) || (defined($local_params->{server_id})?$local_params->{server_id}:$uravo->getServer()->id());
        my $server = $uravo->getServer($id);
        if ($server) {
            print($server->info());
        }
    }
}
sub do_list {
    my $params  = shift;
    my $local_params = MinorImpact::cloneHash($params);
    $local_params->{id_only} = 1;
    if (!defined($local_params->{silo}) && !defined($local_params->{silo_id})) {
        $local_params->{all_silos} = 1;
    }
    $arg = shift(@args);
    $arg =~s/s$//;
    if ($arg eq "check") {
    }
    elsif ($arg eq "cluster") {
        print join($delim, $uravo->getClusters($local_params, {id_only=>1}));
    }
    elsif ($arg eq "event" ) {
        my @events = $uravo->getEvents($local_params, {id_only=>1});
        my $output = "";
        foreach my $event (@events) {
            $output .= $event->toString() . $delim;
        }
        print $output;
    }
    elsif ($arg eq "server" ) {
        print join($delim, $uravo->getServers($local_params, {id_only=>1}));
        print "\n";
    }
    elsif ($arg eq "silo" ) {
        print join($delim, $uravo->getSilos($local_params, {id_only=>1}));
        print "\n";
    }
    elsif ($arg eq "threshold" ) {
        my $server = $local_params->{server_id} ? $uravo->getServer($oocal_params->{server_id}) : $uravo->getServer();
        my $monitoringValues = $server->getMonitoringValues($local_params);
        for $key (sort keys %$monitoringValues) {
            if ($monitoringValues->{$key}{red}){ # and !$monitoringValues->{$key}{disabled}) {
                print "$key: $monitoringValues->{$key}{yellow}/$monitoringValues->{$key}{red}";
                print $monitoringValues->{$key}{disabled} ? " DISABLED" : "";
                print $delim;
            }
        }
    }
    elsif ($arg eq "type" ) {
        print join($delim, $uravo->getTypes($local_params, {id_only=>1}));
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

    Miscelaneous:
        $ $shortname info server [server_id]
        $ $shortname add threshold disk_temp /dev/sdb --params server_id=mincemeat red=115 yellow=110
        $ $shortname delete threshold disk_temp --params AlertKey=/dev/sdb
        $ $shortname list thresholds --params server_id=pumpkin

USAGE
    exit;
}
