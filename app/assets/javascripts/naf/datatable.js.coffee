jQuery ->

  $('#datatable').jTPS({
    perPages:  [10,20,'ALL'],
    scrollStep:1,
    scrollDelay:30
  })

  $('.jTPS tbody tr td:not(#action)').click ->
    window.location = $(this).parent().data('url');

  $.blockUI.defaults.css.top = '10%'

  $('a.enqueue').click ->
    application_id = $(this).attr('id');
    $('form#enqueue_form input#application_id').val(application_id);
    $.blockUI({ message: $('#enqueue_confirm'), css: { left: '30%', width: '700px' } });

  $('div#enqueue_confirm #yes').click ->
    $.blockUI({ message: $('#enqueue_form') }); 
     
  $('div#enqueue_confirm #no').click ->
    $.unblockUI(); 
    return false;

  $('form#enqueue_form').submit (event) ->
    event.preventDefault()
    $.blockUI({ message: '<h5>Adding application to job queue...</h5>' })
    url = '/job_system/jobs'
    $.ajax({
      type: "POST",
      dataType: 'json',
      url: url,
      data: $(this).serialize(),
      success: (data) ->
        setTimeout (-> 
          $.unblockUI();
          $('td#main div#status').prepend('<p>Application: ' + data.title +  ', added to job queue</p>');
        ), 1000;
    }) 
      

    
  
  $('div#enqueue_form #cancel').click ->
    $.unblockUI();
    return false;
