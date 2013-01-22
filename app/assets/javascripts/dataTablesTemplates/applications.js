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
      { "bVisible": false, "aTargets": [ 12, 13 ] },
      { "sClass": "center", "aTargets": [ 6, 7, 11 ] }
    ],
    "aoColumns": [
        { "sWidth": "2%"},
        { "sWidth": "12%"},
        { "sWidth": "7%"},
        { "sWidth": "9%"},
        null,
        { "sWidth": "14%"},
        { "sWidth": "8%"},
        { "sWidth": "4%"},
        { "sWidth": "8%"},
        { "sWidth": "8%"},
        { "sWidth": "7%"},
        { "sWidth": "50px"},
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
  }; // datatable

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  jQuery(document).on("click", '.enqueue', function(){
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
  if (aData[12] == 'true' || aData[13] == 'false' || aData[13] == '') {
    jQuery(nRow).addClass('deleted_or_hidden');
  }
}
