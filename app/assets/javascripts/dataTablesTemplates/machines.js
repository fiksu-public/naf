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
        { "sWidth": "8%"},
        { "sWidth": "14%"},
        { "sWidth": "4%"},
        { "sWidth": "10%"},
        { "sWidth": "12%"},
        { "sWidth": "12%"},
        { "sWidth": "6%"},
        { "sWidth": "10%"},
        { "sWidth": "6%"}
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
      addLinkToMachines(nRow, aData);
      colorizationDeletedOrHidden(nRow, aData);
      checkTimeFormat(nRow, aData);
      return nRow;
    },
    "sDom": "Rlfrtip"
  }; // datatable

   // Setup the datatable.
  jQuery('#datatable').addDataTable(dataTableOptions);

  jQuery(document).delegate('.terminate', "click", function(){
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

function colorizationDeletedOrHidden(nRow, aData) {
  if (aData[4] == false) {
    jQuery(nRow).addClass('deleted_or_hidden');
  }
}

function checkTimeFormat(nRow, aData) {
  var last_checked_array = aData[6].split(',');
  var last_seen_array = aData[7].split(',');
  var last_checked;
  var last_seen;
  if(jQuery('#time_format').val() == 'lexically') {
    last_checked = last_checked_array[0];
    last_seen = last_seen_array[0];
  } else {
    last_checked = last_checked_array[1];
    last_seen = last_seen_array[1];
  }

  jQuery('td:nth-child(7)', nRow).empty().append(last_checked);
  jQuery('td:nth-child(8)', nRow).empty().append(last_seen);
}
