// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "bSort": true,
    "aaSorting": [[9, 'desc']],
    "aoColumnDefs": [
      { "bSortable": false, "aTargets": [1, 4, 7, 8, 11] },
      { "bVisible": false, "aTargets": [10] },
      { "sClass": "center", "aTargets": [11] }
    ],
    "bAutoWidth": false,
    "aoColumns": [
        { "sWidth": "4%"},
        { "sWidth": "7%"},
        { "sWidth": "4%"},
        { "sWidth": "13%"},
        { "sWidth": "25%"},
        { "sWidth": "13%"},
        { "sWidth": "13%"},
        null,
        null,
        { "asSorting": [ "desc" ] },
        null,
        { "sWidth": "6%"}
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
      addLinkToJob(nRow, aData);
      addLinkToTitle(nRow, aData);
      alignmentButtons(nRow, aData);
      colorizationStatus(nRow, aData);
      checkTimeFormat(nRow, aData);
      return nRow;
    }
  }; // datatable

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  jQuery(document).on("click", '.terminate', function(){
    var answer = confirm("You are terminating this job. Are you sure you want to do this?");
    if (!answer) {
      return false;
    }
    var id = jQuery(this).attr('id');
    var url = '/job_system/jobs/' + id;
    jQuery.ajax({
      url: url,
      type: 'POST',
      dataType: 'json',
      data: { "job[request_to_terminate]": 1, "job_id": id, "_method": "put" },
      success:function (data) {
          if (data.success) {
              var title = data.title ? data.title : data.command
              jQuery("<p id='notice'>A Job " + title + " was terminated!</p>").
              appendTo('#flash_message').slideDown().delay(5000).slideUp();
              jQuery('#datatable').dataTable().fnDraw();
          }
      }
    });
  });
});

function addLinkToJob(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/jobs/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}

function addLinkToTitle(nRow, aData) {
  var link = aData[10];
  var title = aData[4];
  if ( link != "" ) {
    var row = jQuery('<a href="' + link + '">' + title + '</a>' );
    jQuery('td:nth-child(5)', nRow).empty().append(row);
  }
}

function checkTimeFormat(nRow, aData) {
  var start_array = aData[5].split(',');
  var finish_array = aData[6].split(',');
  var started_at;
  var finished_at;
  if(jQuery('#time_format').val() == 'lexically') {
    started_at = start_array[0];
    finished_at = finish_array[0];
  } else {
    started_at = start_array[1];
    finished_at = finish_array[1];
  }

  jQuery('td:nth-child(6)', nRow).empty().append(started_at);
  jQuery('td:nth-child(7)', nRow).empty().append(finished_at);
}

function alignmentButtons(nRow, aData) {
  var data = aData[11];
  var row;
  if (aData[9] != "Canceled") {
      row = "<div style='text-align:left;width:50px;display: inline;'>" + data + "</div>";
  } else {
      row = "<div style='text-align:left;width:50px;display: inline;padding-right: 16px;'>" + data + "</div>";
  }
  jQuery('td:nth-child(11)', nRow).empty().append(row);
}

function colorizationStatus(nRow, aData) {
  jQuery('td:nth-child(10)', nRow).wrapInner('<div class="">');
  switch(aData[9]) {
    case 'Running':
      jQuery('td:nth-child(10) div', nRow).addClass('script-running');
      break;
    case 'Queued':
      jQuery('td:nth-child(10) div', nRow).addClass('script-queued');
      break;
    case 'Waiting':
      jQuery('td:nth-child(10) div', nRow).addClass('script-queued');
      break;
    case 'Canceled':
      break;
    case 'Finished':
      jQuery('td:nth-child(10) div', nRow).addClass('script-finished');
      break;
    default:
      jQuery('td:nth-child(10) div', nRow).addClass('script-error');
      break;
  }
}

function setPageOrder(){
  var status = jQuery("#search_status").val();
  if (status == 'finished' || status == 'errored') {
    jQuery('#datatable').dataTableSettings[0].aoColumns[9].bSortable = false;
    jQuery('#datatable thead tr th:nth-child(10) div span').css("display", "none");
    jQuery('#datatable').dataTable().fnSort([ [6,'desc'] ]);

  } else {
    jQuery('#datatable').dataTableSettings[0].aoColumns[9].bSortable = true;
    jQuery('#datatable').dataTable().fnSort([ [9,'desc'] ]);
    jQuery('#datatable thead tr th:nth-child(10) div span').css("display", "block");
  }
}