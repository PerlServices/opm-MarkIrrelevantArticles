# --
# Copyright (C) 2019 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterContent::MarkIrrelevantArticles;

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

    my $Action = $ParamObject->GetParam( Param => 'Action' );

    return 1 if !$Param{Templates}->{$Action};
    return 1 if ${$Param{Data}} !~ m{PS.MarkIrrelevantArticles\.js};

    my $DynamicField = $ConfigObject->Get('MarkIrrelevantArticles::DynamicField');

    return if !$DynamicField;

    my @ArticleIDs = ${ $Param{Data} } =~ m{<input \s+ type="hidden" \s+ class="ArticleID" \s+ value="(\d+)"}xmsg;
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

Kernel::LOG( [ $Param{Data}, \@ArticleIDs, $TicketID, \@IrrelevantArticles ] );

    my $IrrelevantArticlesJSON = $LayoutObject->JSONEncode(
        Data => \@IrrelevantArticles,
    );

    ${ $Param{Data} } =~ s{Core\.Init\.ExecuteInit\('DOCUMENT_READY'\);\K}{

        Core.Config.AddConfig({"IrrelevantArticles":$IrrelevantArticlesJSON});
    }xms;

    return 1;
}

1;
