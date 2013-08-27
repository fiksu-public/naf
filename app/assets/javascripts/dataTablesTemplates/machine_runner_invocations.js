// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "bSort": true,
    "aaSorting": [[1, 'desc']],
    "fnInitComplete" : function() {
      initPageSelect();
      setPageOrder();
    },
    "fnServerData": function ( sSource, aoData, fnCallback ) {
      _.each(jQuery('.datatable_variable').serializeArray(), function(dv) { aoData.push(dv); });
      jQuery.getJSON( sSource, aoData, function (json) {
        fnCallback(json);
        initPaging();
        addTitles();
      });
    },
    "bAutoWidth": false
  };

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);
});

function setPageOrder(){
  jQuery('#datatable').dataTable().fnSort([ [1,'desc'] ]);
}
