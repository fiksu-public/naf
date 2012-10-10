// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "bJQueryUI": true,
    "bProcessing": true,
    "bServerSide": true,
    "bFilter": false,
    "bSort": true,
    "asStripClasses": [ '','tablerow-bg-shade' ],
    "bPaginate": true,
    "bLengthChange": false,
    "sPaginationType": "full_numbers",
    "iDisplayLength": eval("if(typeof getDisplayLength == 'function') { getDisplayLength() }"),
    "sDom": 'rpitip',
    "bInfo": true,
    "isPaginate": true,
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

function initPaging() {
  jQuery('#datatable_wrapper > div.dataTables_paginate > span.fg-button').click(function(){
    return false;
  });

  jQuery('#datatable_wrapper > div.dataTables_paginate > span > span.fg-button').click(function(){
    jQuery('#datatable').dataTable().fnDraw();
    return false;
  });
}