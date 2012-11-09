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
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        { "sWidth": "70px"}
    ],
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToMachines(nRow, aData);
      alignmentButtons(nRow, aData);
      return nRow;
    }
  }; // datatable

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  jQuery('.terminate').live("click", function(){
    var answer = confirm("You are going to mark machine down. Are you sure you want to do this?");
    if (!answer) {
      return false;
    }
    var id = jQuery(this).attr('id');
    var url = '/job_system/machines/' + id;
    jQuery.ajax({
      url: url,
      type: 'POST',
      dataType: 'json',
      data: { "machine[marked_down]": 1, "terminate": true, "_method": "put" },
      success:function (data) {
          if (data.success) {
              jQuery("<p id='notice'>Machine was marked down!</p>").
                  appendTo('#flash_message').slideDown().delay(5000).slideUp();
              jQuery('#datatable').dataTable().fnDraw();
          }
      }
    });
  });
});

function addLinkToMachines(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/machines/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}

function alignmentButtons(nRow, aData) {
  var data = aData[10];
  var row;
//  if (aData[8] != "Canceled") {
      row = "<div style='text-align:left;width:70px;display: inline;'>" + data + "</div>";
//  } else {
//      row = "<div style='text-align:left;width:50px;display: inline;padding-right: 16px;'>" + data + "</div>";
//  }
  jQuery('td:nth-child(11)', nRow).empty().append(row);
}