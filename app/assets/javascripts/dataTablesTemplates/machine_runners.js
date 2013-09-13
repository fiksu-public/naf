// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "fnInitComplete" : function() {
      initPageSelect();
    },
    "aaSorting": [[1, 'desc']],
    "bSort": true,
    "aoColumnDefs": [
      { "bSortable": false, "aTargets": [2, 4, 5, 6, 7, 8] },
    ],
    "bAutoWidth": false,
    "aoColumns": [
        { "sWidth": "5%"},              // Id
        { "sWidth": "15%"},             // Started At
        { "sWidth": "15%"},             // Server Name
        { "sWidth": "50%"},             // Runner Cwd
        { "sWidth": "15%"},             // Runner Pid
        { "sWidth": "10%"},             // Runner Invocation Id
        { "sWidth": "15%"},             // Runner Invocation Status
        { "sWidth": "8%"},              // Jobs Running
        { "sWidth": "6%"},              // Action
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
      colorizationStatus(nRow, aData);
      return nRow;
    }
  };

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  // Action: Wind Down Runner
  jQuery(document).delegate('.wind_down', "click", function() {
    var answer = confirm("You are winding down this runner. Are you sure you want to do this?");
    if (!answer) {
      return false;
    }
    var id = jQuery(this).attr('id');
    var url = '/job_system/machine_runner_invocations/' + id;
    jQuery.ajax({
      url: url,
      type: 'POST',
      dataType: 'json',
      data: { "machine_runner_invocation[request_to_wind_down]": 1, "machine_runner_invocation_id": id, "_method": "put" },
      success:function (data) {
          if (data.success) {
              jQuery("<p id='notice'>The machine runner is winding down!</p>").
              appendTo('#flash_message').slideDown().delay(5000).slideUp();
              jQuery('#datatable').dataTable().fnDraw();
          }
      }
    });
  });
});

// Function that changes the color of the job status
function colorizationStatus(nRow, aData) {
  jQuery('td:nth-child(7)', nRow).wrapInner('<div class="">');
  switch(aData[6]) {
    case 'Running':
      jQuery('td:nth-child(7) div', nRow).addClass('running');
      break;
    case 'Winding Down':
      jQuery('td:nth-child(7) div', nRow).addClass('winding-down');
      break;
    case 'Dead':
      jQuery('td:nth-child(7) div', nRow).addClass('dead');
      break;
  }
}
