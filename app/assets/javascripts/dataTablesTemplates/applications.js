// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "sAjaxSource": sAjaxSource,
    "fnInitComplete" : function() {
      initPageSelect();
    },
    "bAutoWidth": false,
    "aoColumns": [
        { "sWidth": "2%"},
        { "sWidth": "12%"},
        { "sWidth": "9%"},
        { "sWidth": "15%"},
        { "sWidth": "20%"},
        null,
        null,
        { "sWidth": "8%"},
        { "sWidth": "50px"}
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
      jQuery('td:nth-child(9)', nRow).addClass('center');
      return nRow;
    }
  }; // datatable

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  jQuery('.enqueue').live("click", function(){
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