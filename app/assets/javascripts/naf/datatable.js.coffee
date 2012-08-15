jQuery ->

  $('#datatable').jTPS({
    perPages:  [10,20,'ALL'],
    scrollStep:1,
    scrollDelay:30
  })

  $('.jTPS tbody tr td:not(#action)').click ->
    window.location = $(this).parent().data('url');

  $.blockUI.defaults.css.top = '10%'

  $('a.job_search').click ->
    $.blockUI({ message: $('form#job_search') })

  $('form#job_search input#cancel').click ->
    $.unblockUI();

  $('a.add_job').click ->
    $.blockUI( { message: $('form#add_job') } )
  
  $('form#add_job').submit (event) ->
    event.preventDefault()
    $.blockUI({ message: '<h5>Adding job to the job queue...</h5>' })
    url = $(this).attr('action')
    $.ajax({
      type: "POST",
      dataType: 'json',
      url: url,
      data: $(this).serialize(),
      success: (data) ->
        setTimeout (->
          $.unblockUI();
          for msg in data.messages
            if data.saved
              $('td#main div#status').prepend('<p>' + msg + '</p>');
            else
              $('td#main div#status').prepend('<p style="color: red">' + msg + '</p>');
        ), 1000;
    })

  $('form#add_job input#cancel').click ->
    $.unblockUI();

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
    url = $(this).attr('action')
    $.ajax({
      type: "POST",
      dataType: 'json',
      url: url,
      data: $(this).serialize(),
      success: (data) ->
        setTimeout (-> 
          $.unblockUI();
          for msg in data.messages
            if data.saved
              $('td#main div#status').prepend('<p>' + msg + '</p>');
            else
              $('td#main div#status').prepend('<p style="color: red">' + msg + '</p>');
        ), 1000; 
    }) 

  $('form#job_search').submit (event) ->
    event.preventDefault()
    $.blockUI({ message: '<h5>Applying your search and filters to find jobs...</h5>' })
    url = $(this).attr('action')
    $.ajax({
      type: "GET"
      dataType: 'json'
      url: url,
      data: $(this).serialize(),
      success: (data) ->
        setTimeout (-> 
          alert(JSON.stringify(data))
          $.unblockUI();
        ), 1000;
    })
  
  $('div#enqueue_form #cancel').click ->
    $.unblockUI();
    return false;
