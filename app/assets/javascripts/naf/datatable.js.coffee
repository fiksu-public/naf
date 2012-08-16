jQuery ->


  $('#datatable').jTPS({
    perPages:  [10,20,'ALL'],
    scrollStep:1,
    scrollDelay:30
  })

  $.blockUI.defaults.css.top = '10%'

  if $('p#on_job_page').text() == 'true'
    $.blockUI({ message: $('div#loading_jobs') })
    search_form = $('form#job_search')
    url = search_form.attr('action')
    $.ajax({
      type: "GET"
      dataType: 'json'
      url: url,
      data: search_form.serialize(),
      success: (data) ->
        setTimeout (-> 
          job_root_url = data.job_root_url
          $('table#datatable tbody').text('')
          for job in data.jobs
            row = '<tr class=\"job_row\" id=\"' + job.id + '\"' + ' data-url=\"' + data.job_root_url + '/' + job.id +  '\">' 
            for col in data.cols
              value = if job[col] == null then "" else job[col]
              row += "<td>" + value + "</td>"
            row += '<td id=\"action\">'
            row += '<a href=\"http://www.papertrailapp.com\"><img alt=\"Application_view_list\" class=\"action\" src=\"/assets/application_view_list.png\" title=\"View Log in Papertrail\" /></a>'
            row += "</td>"
            row += "</tr>"
            row_object = $(row)
            row_object.hide().appendTo('table#datatable tbody').slideDown(1000)
          $.unblockUI();
        ), 1000;
    })
    

  $('.jTPS tbody tr td:not(#action)').live 'click', (event) ->
    window.location = $(this).parent().data('url');

  $('a.job_search').click ->
    $.blockUI({ message: $('form#job_search') })

  $('form#job_search input#cancel').click ->
    $.unblockUI();

  $('a.add_job').click ->
    $.blockUI( { message: $('form#add_job') } )
  
  $('form#add_job').submit (event) ->
    event.preventDefault()
    $.blockUI({ message: $('div#adding') })
    url = $(this).attr('action')
    $.ajax({
      type: "POST",
      dataType: 'json',
      url: url,
      data: $(this).serialize(),
      success: (data) ->
        setTimeout (->
          $.unblockUI();
          addedMessage = ' was added to the job queue'
          if data.saved
            $('td#main div#status').prepend('<p>' + '<a href=\"' + data.job_url + '\">' + data.post_source + '</a>'  + addedMessage + '</p>');
          else
            for msg in data.errors
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
    $.blockUI({ message: $('div#adding') })
    url = $(this).attr('action')
    $.ajax({
      type: "POST",
      dataType: 'json',
      url: url,
      data: $(this).serialize(),
      success: (data) ->
        setTimeout (-> 
          $.unblockUI();
          addedMessage = ' was added to the job queue'
          if data.saved
            $('td#main div#status').prepend('<p>' + '<a href=\"' + data.job_url + '\">' + data.post_source + '</a>'  + addedMessage + '</p>');
          else
            for msg in data.errors
              $('td#main div#status').prepend('<p style="color: red">' + msg + '</p>');
        ), 1000; 
    }) 

  $('form#job_search').submit (event) ->
    event.preventDefault()
    $.blockUI({ message: $('div#searching') })
    url = $(this).attr('action')
    $.ajax({
      type: "GET"
      dataType: 'json'
      url: url,
      data: $(this).serialize(),
      success: (data) ->
        setTimeout (-> 
          job_root_url = data.job_root_url
          $('table#datatable tbody').text('')
          for job in data.jobs
            row = '<tr class=\"job_row\" id=\"' + job.id + '\"' + ' data-url=\"' + data.job_root_url + '/' + job.id +  '\">' 
            for col in data.cols
              value = if job[col] == null then "" else job[col]
              row += "<td>" + value + "</td>"
            row += '<td id=\"action\">'
            row += '<a href=\"http://www.papertrailapp.com\"><img alt=\"Application_view_list\" class=\"action\" src=\"/assets/application_view_list.png\" title=\"View Log in Papertrail\" /></a>'
            row += "</td>"
            row += "</tr>"
            row_object = $(row)
            row_object.hide().appendTo('table#datatable tbody').slideDown(1000)
          $.unblockUI();
        ), 1000;
    })
  
  $('div#enqueue_form #cancel').click ->
    $.unblockUI();
    return false;
