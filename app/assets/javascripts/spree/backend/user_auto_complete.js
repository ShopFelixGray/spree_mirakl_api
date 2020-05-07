$(document).ready(function () {
  'use strict';

  function formatUser(user) {
    return Select2.util.escapeMarkup(user.email);
  }

  if ($('#mirakl_store_user_id').length > 0) {
    // Init selection will be depreciated in upgrades
    $('#mirakl_store_user_id').select2({
      initSelection: function (element, callback) {
        var url = Spree.url(Spree.routes.user_search, {
          ids: element.val(),
          token: Spree.api_key
        });
        return $.getJSON(url, null, function (data) {
          return callback(data.users[0]);
        });
      },
      placeholder: Spree.translations.choose_a_customer,
      ajax: {
        url: Spree.routes.user_search,
        datatype: 'json',
        data: function(term, page) {
          return {
            q: term,
            token: Spree.api_key
          }
        },
        results: function(data, page) {
          return { results: data.users }
        }
      },
      dropdownCssClass: 'customer_search',
      formatResult: formatUser,
      formatSelection: formatUser
    }).select2('val', $('#mirakl_store_user_id').val());
  }
});