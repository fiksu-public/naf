// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "bSort": true,
    "sAjaxSource": sAjaxSource,
    "aaSorting": [[3,'asc']],
    "aoColumnDefs": [
      { "bSortable": false, "aTargets": [ 0, 1, 2, 4, 7, 9 ] },
      { "bVisible": false, "aTargets": [ 8 ] }
    ],
    "fnInitComplete" : function() {
      initPageSelect();
      jQuery("#datatable").css("width","100%");
    },
    "fnServerData": function ( sSource, aoData, fnCallback ) {
      _.each(jQuery('.datatable_variable').serializeArray(), function(dv) { aoData.push(dv); });
      jQuery.getJSON( sSource, aoData, function (json) {
        fnCallback(json);
        initPaging();
      });
    },
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToJob(nRow, aData);
      addLinkToTitle(nRow, aData);
      return nRow;
    }
  }; // datatable

   // Setup the datatable.
    jQuery('#datatable').addDataTable(dataTableOptions);
});

function addLinkToJob(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/jobs/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}

function addLinkToTitle(nRow, aData) {
  var link = aData[8];
  if ( link != "" ) {
    var row = jQuery('<a href="' + link + '">' + "Database Janitorial Work" + '</a>' );
    jQuery('td:nth-child(5)', nRow).empty().append(row);
  }
}