// When document is ready
jQuery(document).ready(function() {

  // Prepare for setup the datatable.
  var dataTableOptions = {
    "bSort": true,
    "sAjaxSource": sAjaxSource,
    "aaSorting": [[3,'asc']],
    "aoColumnDefs": [
      { "bSortable": false, "aTargets": [ 0, 1, 2, 4, 7, 9 ] },
      { "bVisible": false, "aTargets": [ 8 ] }
    ],
    "fnInitComplete" : function() {
      initPageSelect();
      jQuery("#datatable").css("width","100%");
    },
    "fnServerData": function ( sSource, aoData, fnCallback ) {
      _.each(jQuery('.datatable_variable').serializeArray(), function(dv) { aoData.push(dv); });
      jQuery.getJSON( sSource, aoData, function (json) {
        fnCallback(json);
        initPaging();
      });
    },
    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
      addLinkToJob(nRow, aData);
      addLinkToTitle(nRow, aData);
      jQuery('td:nth-child(9)', nRow).addClass('center');
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
      type: 'PUT',
      dataType: 'json',
      data: { "job[request_to_terminate]": 1, "job_id": id }
    });
    jQuery('#datatable').dataTable().fnDraw();
  });
});

function addLinkToJob(nRow, aData) {
  var id = aData[0];
  var row = jQuery('<a href="/job_system/jobs/' + id + '">' + id + '</a>' );
  jQuery('td:nth-child(1)', nRow).empty().append(row);
}

function addLinkToTitle(nRow, aData) {
  var link = aData[8];
  var title = aData[4];
  if ( link != "" ) {
    var row = jQuery('<a href="' + link + '">' + title + '</a>' );
    jQuery('td:nth-child(5)', nRow).empty().append(row);
  }
}