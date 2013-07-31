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
      { "bVisible": false, "aTargets": [ 10, 11 ] },  // turn off visibility
      { "sClass": "center", "aTargets": [ 9 ] }
    ],
    "aoColumns": [
        { "sWidth": "2%"},      // Id
        { "sWidth": "15%"},     // Title
        { "sWidth": "9%"},      // Script Type Name
        { "sWidth": "15%"},     // Application Run Group Name
        { "sWidth": "20%"},     // Application Run Group Restriction Name
        null,                   // Enabled
        null,                   // Run Time
        null,                   // Last Queued At
        { "sWidth": "8%"},      // Prerequisites
        { "sWidth": "50px"},    // Actions
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
    jQuery.post(postSource, { "job[application_id]": jQuery(this).attr('id') }, function(data) {
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
  console.log(aData);
  if (aData[10] == 'true' || aData[11] == 'false' || aData[11] == '') {
    jQuery(nRow).addClass('deleted_or_hidden');
  }
}
