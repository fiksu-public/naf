// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "aoColumnDefs": [
      { "bVisible": false, "aTargets": [ 10 ] },
      { "sClass": "center", "aTargets": [ 11 ] }
    ],
    "bAutoWidth": false,
    "aoColumns": [
        { "sWidth": "2%"},
        { "sWidth": "7%"},
        { "sWidth": "4%"},
        { "sWidth": "14%"},
        { "sWidth": "25%"},
        null,
        null,
        null,
        null,
        null,
        null,
        { "sWidth": "6%"}
    ],
    "fnInitComplete" : function() {
      initPageSelect();
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
      return nRow;
    }
  }; // datatable

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  jQuery('.terminate').live("click", function(){
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
    case  'Canceled':
      break;
    case 'Finished':
      jQuery('td:nth-child(10) div', nRow).addClass('script-finished');
      break;
    default:
      jQuery('td:nth-child(10) div', nRow).addClass('script-error');
      break;
  }
}