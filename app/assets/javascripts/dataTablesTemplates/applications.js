// When document is ready
jQuery(document).ready(function() {
//  var isUpdateDataTable = null;
  // Prepare for setup the datatable.
  var dataTableOptions = {
    "bProcessing": true,
    "isPaginate": true,
    "sAjaxSource": sAjaxSource,
    "bSort": true,
    "bJQueryUI": true,
    "bFilter": false,
    'bLengthChange': false,
    "fnInitComplete" : function() {
      jQuery("#datatable").css("width","100%");
    }

  }; // datatable

   // Setup the datatable.
    jQuery('#datatable').dataTable(dataTableOptions);
});