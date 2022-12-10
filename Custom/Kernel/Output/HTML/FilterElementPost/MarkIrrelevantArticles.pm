# --
# Copyright (C) 2019 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::MarkIrrelevantArticles;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::Language
    Kernel::Output::HTML::Layout
    Kernel::System::Web::Request
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');
    my $LayoutObject   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject    = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
    my $ArticleObject  = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    my $DynamicField   = $ConfigObject->Get('MarkIrrelevantArticles::DynamicField');

    return if !$DynamicField;

    my @ArticleIDs = ${ $Param{Data} } =~ m{<a \s name="Article(\d+)"}xms;
    my $TicketID   = $ParamObject->GetParam( Param => 'TicketID' );

    # mark irrelevant articles
    my @IrrelevantArticles;

    ARTICLEID:
    for my $ArticleID ( @ArticleIDs ) {
        my %Article = $ArticleObject->ArticleGet(
            ArticleID     => $ArticleID,
            TicketID      => $TicketID,
            UserID        => $Self->{UserID},
            DynamicFields => 1,
        );

        next ARTICLEID if !$Article{"DynamicField_" . $DynamicField};

        push @IrrelevantArticles, $ArticleID;
    }

    $LayoutObject->AddJSData(
        Key   => 'IrrelevantArticles',
        Value => \@IrrelevantArticles,
    );
    
    return 1 if $ConfigObject->Get('MarkIrrelevantArticles::HideArticleMenuItems');

    # add link to article menu
    my $Title    = $LanguageObject->Translate('Change article relevance');
    my $Baselink = $LayoutObject->{Baselink};

    ${ $Param{Data} } =~ s{
        ( <a \s name="Article(\d+)" .*? <ul \s class="Actions"> ) \s+
         <li([^>]*?)>
    }{$1 . $Self->__Linkify( $Baselink, $TicketID, $2, $Title, $3 ) . '<li>';}exmsg;

    return 1;
}

sub __Linkify {
    my ($Self, $Baselink, $TicketID, $ArticleID, $Title, $Attribute ) = @_;

    return '' if $Attribute =~ m{MarkIrrelevantArticles};

    my $Link = qq~
        <li class="MarkIrrelevantArticles">
            <a href="${Baselink}Action=AgentMarkIrrelevantArticles;TicketID=$TicketID;ArticleID=$ArticleID" title="$Title">$Title</a>
        </li>
    ~;

    return $Link;
}

1;
