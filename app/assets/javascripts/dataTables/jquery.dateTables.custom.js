jQuery.fn.addDataTable = function(dataTableOptions) {

  var defaultDataTableOptions = {
    "bJQueryUI": true,
    "bProcessing": true,
    "bServerSide": true,
    "bFilter": false,
    "bSort": false,
    "asStripClasses": [ '','tablerow-bg-shade' ],
    "bPaginate": true,
    "bLengthChange": false,
    "sPaginationType": "full_numbers",
    "iDisplayLength": eval("if(typeof getDisplayLength == 'function') { getDisplayLength() }"),
    "sDom": 'rpitip',
    "bInfo": true,
    "isPaginate": true,
    "fnInitComplete" : function() {
      addTitles();
    },
    "fnServerData": function ( sSource, aoData, fnCallback ) {
      jQuery.getJSON( sSource, aoData, function (json) {
        fnCallback(json);
        initPaging();
      });
    }
  };

  if(!dataTableOptions.sAjaxSource) {
    defaultDataTableOptions.bProcessing = false;
    defaultDataTableOptions.bServerSide = false;
    defaultDataTableOptions.bInfo = false;
    defaultDataTableOptions.bPaginate = false;
  }

  var settings = jQuery.extend(defaultDataTableOptions, dataTableOptions);

  // Setup the datatable.
  jQuery(this).dataTable(settings);
};

function initPaging() {
  jQuery('#datatable_wrapper > div.dataTables_paginate > span.fg-button').click(function(){
    return false;
  });

  jQuery('#datatable_wrapper > div.dataTables_paginate > span > span.fg-button').click(function(){
    jQuery('#datatable').dataTable().fnDraw();
    return false;
  });
}

function addTitles() {
  jQuery('#datatable tbody tr td').each( function() {
    this.setAttribute( 'title', $(this).text().trim());
  });

}