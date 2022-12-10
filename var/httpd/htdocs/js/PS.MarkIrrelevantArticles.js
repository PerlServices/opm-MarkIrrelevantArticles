// --
// PS.MarkIrrelevantArticles.js 
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var PS = PS || {};

/**
 * @namespace
 * @exports TargetNS as PS.TicketChecklist
 * @description
 *      This namespace contains the special module functions for the time tracking add on
 */
PS.MarkIrrelevantArticles = (function (TargetNS) {
    TargetNS.Init = function() {
        var ArticleIDs = Core.Config.Get('IrrelevantArticles');
        console.debug( ArticleIDs );

        $.each( ArticleIDs, function ( index, ArticleID ) {
            $('input[type="hidden"][value="' + ArticleID +'"]').closest('tr').addClass("IrrelevantArticle")
            $('input[type="hidden"][value="' + ArticleID +'"]').closest('tr').find('td').addClass("IrrelevantArticleTd")
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(PS.MarkIrrelevantArticles || {}));
