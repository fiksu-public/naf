// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "aoColumnDefs": [
      { "bVisible": false, "aTargets": [ 0 ] }
    ],
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
  var ip = aData[2];
  var row = jQuery('<a href="/job_system/machines/' + id + '">' + ip + '</a>' );
  jQuery('td:nth-child(2)', nRow).empty().append(row);
}