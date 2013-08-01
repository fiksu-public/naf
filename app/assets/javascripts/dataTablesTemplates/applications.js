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
      { "bVisible": false, "aTargets": [ 13, 14 ] },    // turn off visibility
      { "sClass": "center", "aTargets": [ 6, 7, 8, 11, 12 ] }
    ],
    "aoColumns": [
        { "sWidth": "2%"},      // Id
        { "sWidth": "12%"},     // Title
        { "sWidth": "7%"},      // Short Name
        { "sWidth": "9%"},      // Script Type Name
        null,                   // Application Run Group Name
        { "sWidth": "12%"},     // Application Run Group Restriction Name
        { "sWidth": "7%"},      // Application Run Group Limit
        { "sWidth": "4%"},      // Priority
        { "sWidth": "4%"},      // Enabled
        { "sWidth": "8%"},      // Run Time
        { "sWidth": "8%"},      // Last Queued At
        { "sWidth": "8%"},      // Prerequisites
        { "sWidth": "4%"},      // Actions
        null,
        null
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
    }
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
    });
  });
});

function addLinkToApplication(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/applications/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}

function colorizationDeletedOrHidden(nRow, aData) {
  if (aData[11] == 'true' || aData[12] == 'false' || aData[13] == '') {
    jQuery(nRow).addClass('deleted_or_hidden');
  }
}

function checkTimeFormat(nRow, aData) {
  var l_q_a_array = jQuery(aData[9]).text().split(',');
  var last_queued_at;
  if(jQuery('#time_format').val() == 'lexically') {
    last_queued_at = l_q_a_array[0];
  } else {
    last_queued_at = l_q_a_array[1];
  }

  jQuery('td:nth-child(10)', nRow).empty().append(jQuery(aData[9]).text(last_queued_at));
}
