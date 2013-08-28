// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "bSort": true,
    "aaSorting": [[1, 'desc']],
    "bAutoWidth": false,
    "aoColumns": [
        { "sWidth": "5%"},              // Id
        { "sWidth": "15%"},             // Started At
        { "sWidth": "10%"},             // Machine Runner Id
        { "sWidth": "12%"},             // Server Name
        { "sWidth": "10%"},             // Pid
        { "sWidth": "10%"},             // Status
        { "sWidth": "25%"},             // Latest Commit
        { "sWidth": "10%"},              // Deployment Tag
    ],
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
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      colorizationStatus(nRow, aData);
      return nRow;
    }
  };

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);
});

function setPageOrder(){
  jQuery('#datatable').dataTable().fnSort([ [1,'desc'] ]);
}

// Function that changes the color of the job status
function colorizationStatus(nRow, aData) {
  jQuery('td:nth-child(6)', nRow).wrapInner('<div class="">');
  switch(aData[5]) {
    case 'Running':
      jQuery('td:nth-child(6) div', nRow).addClass('running');
      break;
    case 'Winding Down':
      jQuery('td:nth-child(6) div', nRow).addClass('winding-down');
      break;
    case 'Dead':
      jQuery('td:nth-child(6) div', nRow).addClass('down');
      break;
  }
}
