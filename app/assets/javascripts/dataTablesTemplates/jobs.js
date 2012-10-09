// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "bProcessing": true,
    "isPaginate": true,
    "sAjaxSource": sAjaxSource,
    "bSort": true,
    "bJQueryUI": true,
    "bFilter": false,
    'bLengthChange': false,
    "bServerSide": true,
    "bPaginate": true,
    "sPaginationType": "full_numbers",
    "bInfo": true,
    "sDom": 'rpitip',
    "aoColumnDefs": [
      { "bVisible": false, "aTargets": [ 8 ] }
    ],
    "fnInitComplete" : function() {
      jQuery("#datatable").css("width","100%");
    },
    "fnServerData": function ( sSource, aoData, fnCallback ) {
      _.each(jQuery('.datatable_variable').serializeArray(), function(dv) { aoData.push(dv); });
      jQuery.getJSON( sSource, aoData, function (json) {
        fnCallback(json);
      });
    },
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToJob(nRow, aData);
      addLinkToTitle(nRow, aData);
      return nRow;
    }

  }; // datatable

   // Setup the datatable.
    jQuery('#datatable').dataTable(dataTableOptions);
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