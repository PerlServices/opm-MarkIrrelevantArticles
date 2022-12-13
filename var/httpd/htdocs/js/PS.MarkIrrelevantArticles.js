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

        $.each( ArticleIDs, function ( index, ArticleID ) {
            var Selector = '#ArticleTree input[type="hidden"][class="ArticleID"][value="' + ArticleID +'"]';
            var TableRow = $(Selector).closest('tr');
            TableRow.addClass("IrrelevantArticle");
            TableRow.find('td').addClass("IrrelevantArticleTd");
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(PS.MarkIrrelevantArticles || {}));
