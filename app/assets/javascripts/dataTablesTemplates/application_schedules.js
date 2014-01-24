// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "fnInitComplete" : function() {
      initPageSelect();
    },
    "bAutoWidth": false,
    "bSort": true,
    "aoColumnDefs": [
      { "bSortable": false, "aTargets": [9, 10] },  // turn off sorting
      { "sClass": "center", "aTargets": [6, 7, 8] }
    ],
    "aoColumns": [
        { "sWidth": "2%"},      // Id
        { "sWidth": "15%"},     // Application
        { "sWidth": "15%"},     // Run Group Name
        { "sWidth": "9%"},      // Run Group Restriction
        { "sWidth": "10%"},     // Run Interval Style
        { "sWidth": "4%"},      // Run Interval
        { "sWidth": "5%"},      // Run Group Quantum
        { "sWidth": "5%"},      // Run Group Limit
        { "sWidth": "5%"},      // Enqueue Backlogs
        { "sWidth": "10%"},     // Affinities
        { "sWidth": "10%"}      // Prerequesites
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
      colorizationDisabled(nRow, aData);
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

function colorizationDisabled(nRow, aData) {
  if (aData[11] == false) {
    jQuery(nRow).addClass('deleted_or_hidden');
  }
}

