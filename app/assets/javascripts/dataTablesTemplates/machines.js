// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "fnInitComplete" : function() {
      initPageSelect();
      jQuery("#datatable").css("width","100%");
    },
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToMachines(nRow, aData);
      return nRow;
    }
  }; // datatable

   // Setup the datatable.
    jQuery('#datatable').addDataTable(dataTableOptions);
});

function addLinkToMachines(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/machines/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}