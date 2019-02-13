#!/usr/bin/perl

#
# user_git_commits.pl
#
# Developed by Dinesh D
# All rights reserved.
#
# Changelog:
# 2019-02-13 - created
#

use strict;
use warnings;
use Net::GitHub;
use Template;
use DateTime::Format::Strptime qw( );

my $stop = 0;
foreach (qw/GITHUB_USER GITHUB_ORG GITHUB_TOKEN/) {
    if(!$ENV{$_}) {
        print "Please set ENV $_ (export $_=)\n";
        $stop = 1;
    }
}

exit if($stop);

my $no_html = $ARGV[1] || 0;
 
my $gh = Net::GitHub->new( access_token => $ENV{GITHUB_TOKEN}, per_page => 100);
my $event = $gh->event;
my $result;

my @events = $event->user_orgs_events($ENV{GITHUB_USER}, $ENV{GITHUB_ORG});

my $format = DateTime::Format::Strptime->new(
    pattern   => '%Y-%m-%dT%H:%M:%SZ',
    on_error  => 'croak',
);

my $user_info;

# Github api allows only 3 pages for events and 100 events per page max
foreach (1,2,3) {
    print STDERR "Page $_\n";
    foreach my $ev (@events) {
        my $type = $ev->{type};

        next if($type ne 'PushEvent');

        my $repo_name = $ev->{repo}->{name};
        my $time = $ev->{created_at};
        my $dt = $format->parse_datetime($time);
        my $date = $dt->format_cldr('YYYY-MM-dd');
        my $commits = $ev->{payload}->{commits};
        my $branch = $ev->{payload}->{ref};
        $branch =~ s/refs\/heads\///;
        my $pushed_by = $ev->{actor}->{login};
        if(!$user_info->{$pushed_by}) {
            $user_info->{$pushed_by} = {
                url => $ev->{actor}->{url},
                logo => $ev->{actor}->{avatar_url},
                display_login => $ev->{actor}->{display_login}
            };
        }

        push(@{$result->{$pushed_by}->{$date}->{$repo_name}->{commits}}, @{$commits});
        $result->{$pushed_by}->{$date}->{$repo_name}->{branches}->{$branch} = 1;
    }
    if(!$event->has_next_page) {
        print STDERR "No more pages\n";
        last;
    }
    @events = $event->next_page;
}

print "Git Push details\n" if($no_html);

@events = ();
foreach my $name (sort keys %{$result}) {
    print "$name\n" if($no_html);
    my $pushed = $result->{$name};
    foreach my $date (sort keys %{$pushed}) {
        print "\tOn $date\n" if($no_html);
        my $repos = $pushed->{$date};
        foreach my $repo (sort keys %{$repos}) {
            my $commits_count = scalar(@{$repos->{$repo}->{commits}});
            push(@events, {
                    User => $name,
                    CreatedTime => $date,
                    Repository => $repo,
                    Branches => [keys %{$repos->{$repo}->{branches}}],
                    Commits => $commits_count
                });
            print "\t\tTo $repo -> $commits_count commits\n" if($no_html);
        }
    }
}

if($no_html) {
    exit;
}

my $template_file = 'user_push.tt';
my $html_file = 'user_push.html';

my $vars = {
    events => \@events,
    organization => ucfirst($ENV{GITHUB_ORG}),
    user_info => $user_info,
};

open my $F, ">$html_file" or die "Unable to open file $!";
my $template = Template->new(
    OUTPUT => $F
);

my $html = $template->process($template_file, $vars)
|| die "Template process failed: ", $template->error(), "\n";

close $F;
print "HTML File created\n";