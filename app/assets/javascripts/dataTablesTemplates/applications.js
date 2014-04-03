// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "fnInitComplete" : function() {
      initPageSelect();
    },
    "bAutoWidth": false,
    "aoColumnDefs": [
      { "sClass": "center", "aTargets": [ 6 ] }
    ],
    "aoColumns": [
        { "sWidth": "3%"},      // Id
        null,                   // Title
        { "sWidth": "15%"},     // Short Name
        { "sWidth": "10%"},     // Script Type Name
        { "sWidth": "15%"},     // Application Schedules
        { "sWidth": "15%"},     // Last Queued At
        { "sWidth": "5%"}       // Actions

    ],
    "fnServerData": function ( sSource, aoData, fnCallback ) {
      _.each(jQuery('.datatable_variable').serializeArray(), function(dv) { aoData.push(dv); });
      jQuery.getJSON( sSource, aoData, function (json) {
        fnCallback(json);
        initPaging();
        addTitles();
      });
    },
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToApplication(nRow, aData);
      colorizationDeletedOrHidden(nRow, aData);
      checkTimeFormat(nRow, aData);
      return nRow;
    },
    "sDom": "Rlfrtip"
  };

  // Setup the datatable
  jQuery('#datatable').addDataTable(dataTableOptions);

  jQuery(document).delegate('.enqueue', "click", function(){
    var answer = confirm("Adding application as a job on the queue?");
    if (!answer) {
      return false;
    }
    jQuery.post(postSource, { "historical_job[application_id]": jQuery(this).attr('id') }, function(data) {
      if (data.success) {
        jQuery("<p id='notice'>Congratulations, a Job " + data.title + " was added!</p>").
                appendTo('#flash_message').slideDown().delay(5000).slideUp();
        jQuery('#datatable').dataTable().fnDraw();
      }
      else {
        jQuery("<div class='error'>Sorry, \'" +  data.title + "\' cannot add a Job to the queue right now!</div>").
                appendTo('#flash_message').slideDown().delay(5000).slideUp();
        jQuery('#datatable').dataTable().fnDraw();
      }
    });
  });
});

function addLinkToApplication(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/applications/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}

function colorizationDeletedOrHidden(nRow, aData) {
  if (aData[6] == 'true') {
    jQuery(nRow).addClass('deleted_or_hidden');
  }
}

function checkTimeFormat(nRow, aData) {
  var l_q_a_array = jQuery(aData[5]).text().split(',');
  var last_queued_at;
  if(jQuery('#time_format').val() == 'lexically') {
    last_queued_at = l_q_a_array[0];
  } else {
    last_queued_at = l_q_a_array[1];
  }

  jQuery('td:nth-child(6)', nRow).empty().append(jQuery(aData[5]).text(last_queued_at));
}
