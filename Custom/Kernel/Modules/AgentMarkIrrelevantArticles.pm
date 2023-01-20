# --
# Copyright (C) 2019 - 2023 Perl-Services.de, https://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentMarkIrrelevantArticles;
 
use strict;
use warnings;
 
our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;
 
    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}
 
sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $DBObject      = $Kernel::OM->Get('Kernel::System::DB');

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my @Params = qw(ArticleID TicketID);
    my %GetParam;

    for my $Param ( @Params ) {
        $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) // '';
    }

    # get ACL restrictions
    my %PossibleActions = ( 1 => $Self->{Action} );

    my $ACL = $TicketObject->TicketAcl(
        Data          => \%PossibleActions,
        Action        => $Self->{Action},
        TicketID      => $Self->{TicketID},
        ReturnType    => 'Action',
        ReturnSubType => '-',
        UserID        => $Self->{UserID},
    );

    my %AclAction = $TicketObject->TicketAclActionData();

    # check if ACL restrictions exist
    if ( $ACL || IsHashRefWithData( \%AclAction ) ) {

        my %AclActionLookup = reverse %AclAction;

        # show error screen if ACL prohibits this action
        if ( !$AclActionLookup{ $Self->{Action} } ) {
            return $LayoutObject->NoPermission( WithHeader => 'yes' );
        }
    }

    my $Backend = $ArticleObject->BackendForArticle(
        TicketID  => $GetParam{TicketID},
        ArticleID => $GetParam{ArticleID},
    );

    my %Article = $Backend->ArticleGet(
        TicketID      => $GetParam{TicketID},
        ArticleID     => $GetParam{ArticleID},
        DynamicFields => 1,
    );

    my $Name = $ConfigObject->Get('MarkIrrelevantArticles::DynamicField') || 'IsIrrelevantArticle';
    $GetParam{$Name} = $Article{"DynamicField_$Name"} ? 0 : 1;


    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet( Name => $Name );

    # set the value
    my $Success = $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $GetParam{ArticleID},
        Value              => $GetParam{$Name},
        UserID             => $Self->{UserID},
    );

    if ( $Success ) {
        my $OnOff = $GetParam{$Name} ? 'on' : 'off';

        $TicketObject->HistoryAdd(
            Name         => ( sprintf "Switched %s article relevance", $OnOff ),
            HistoryType  => 'Misc',
            TicketID     => $GetParam{TicketID},
            ArticleID    => $GetParam{ArticleID},
            CreateUserID => $Self->{UserID},
        );
    }

    return $LayoutObject->Redirect(
        OP => 'Action=AgentTicketZoom&TicketID=' . $GetParam{TicketID} . '&ArticleID=' . $GetParam{ArticleID},
    );
}
 
1;

