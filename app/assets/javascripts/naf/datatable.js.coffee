jQuery ->

  $('#application_application_schedule_attributes_run_start_minute').timepicker {'step': 5}

  # Some lengthy helper functions to search jobs, and create/enqueue them

  on_jobs_page = () ->
    $('p#on_job_page').text() == 'true'

  # Clear the search parameters
  reset_search = () ->
    $('input#search_direction_desc').attr('checked', 'checked')
    $('form#job_search input#reset').click()
    offset_element = $('input#search_offset')
    offset_element.val(0)
   

  # Job Search Function
  #   Make GET request to jobs/
  #   read JSON response, render the results

  last_job_id = 0;

  perform_job_search = (search_form, message, callback = () -> ) ->
    sort_attr = $('form#job_search select#search_order').val()
    sort_dir  = $("form#job_search input[name='search[direction]']:checked").val();
    $('#datatable thead th').each  ->
      element = $(@)
      element.removeClass();
    if sort_attr == "created_at"
      sort_attr = "queued_time"
    header_element = $('#datatable thead th#' + sort_attr)
    if sort_dir == "desc"
      header_element.attr('class', 'sortDesc') 
    else
      header_element.attr('class', 'sortAsc') 
    showing_message = message != null
    url = search_form.attr('action')
    $.ajax({
      type: "GET"
      dataType: 'json'
      url: url,
      data: search_form.serialize(),
      success: (data) ->
        job_root_url = data.job_root_url
        $('table#datatable tbody').text('')
        if data.jobs.length == 0
          $('a#page_forward').hide()
          $('span#result_numbers').text('')
        else
          $('a#page_forward').show()
          offset = parseInt($('input#search_offset').val())
          limit = parseInt($('select#search_limit').val())
          lower = offset*limit + 1
          upper = lower + data.jobs.length - 1
          $('span#result_numbers').text('Results ' + lower + ' - ' + upper)
          if last_job_id == 0
            showing_message = true
            message = 'Loading the Job Queue...'
          if showing_message
            show_loading_message(message)
          else
            if last_job_id != parseInt(data.jobs[0]['id'])
              showing_message = true
              show_loading_message('Showing new jobs on the queue')
          last_job_id = data.jobs[0]['id']
          for job in data.jobs
            class_label = job.status
            row = '<tr class=\"'+ class_label + '\" id=\"' + job.id + '\"' + ' data-url=\"' + data.job_root_url + '/' + job.id +  '\">' 
            for col in data.cols
              value = if job[col] == null then "" else job[col]
              if col == 'title' && job.application_url
                row += '<td><a href=\"' + job.application_url + '\">' + value + "</a></td>"
              else
                row += "<td>" + value + "</td>"
            row += '<td id=\"action\">'
            row += '<a href=\"#\" class=\"papertrail\" data-url=\"' + job.papertrail_url + '"><img alt=\"Application_view_list\" class=\"action\" src=\"/assets/application_view_list.png\" title=\"View Log in Papertrail\" /></a>'
            row += "</td>"
            row += "</tr>"
            row_object = $(row)
            row_object.hide().appendTo('table#datatable tbody').slideDown(1000)
          if showing_message
            setTimeout (() -> $.unblockUI()), 300
          callback()        
    })

  
  # Create Job Function
  #   Make POST request to jobs/
  #   read JSON response
  #   render link to job on successful creation
  #   or ActiveRecord validation error messages

  create_job = (form, callback = () ->) ->
    url = form.attr('action')
    $.ajax({
      type: "POST",
      dataType: 'json',
      url: url,
      data: form.serialize(),
      success: (data) ->
        setTimeout (-> 
          $.unblockUI();
          addedMessage = ' was added to the job queue'
          if data.saved
            if on_jobs_page()
              callback()
            else
              $('td#main div#status').prepend('<p>' + '<a href=\"' + data.job_url + '\">' + data.post_source + '</a>'  + addedMessage + '</p>');
          else
            for msg in data.errors
              $('td#main div#status').prepend('<p style="color: red">' + msg + '</p>');
        ), 500; 
    })

  # Show Loading Message

  show_loading_message = (message) ->
    output = '<h5>'
    output += message
    output += '</h5>'
    output += '<img alt=\"Loading\" src=\"/assets/loading.gif\" />'
    output += '<br />'
    output += '<br />'
    $.blockUI({ message: output});

  
  # Refresh the jobs table
  refresh_jobs = () ->
    reset_search()
    $('a#page_back').hide()
    # show_loading_message('Refreshing...')
    perform_job_search($('form#job_search'), null)

  refresh_timer = ""
  start_refresh_timer = () ->
    refresh_timer = setInterval (() -> refresh_jobs()), 30000
  stop_refresh_timer = () ->
    clearInterval(refresh_timer) 

  # --------------------------------------------------
  # Naf System UI Event Handlers


  # Mostly just adding .jTPS class, may remove soon
 
  #  $('#datatable').jTPS()

 
  # Place modal views of messages/forms at the top of the screen
 
  $.blockUI.defaults.css.top = '10%'

  # Upon Page Loaded (really Jquery loaded),
  # If we are on the job page, run empty job search
  # to populate the jobs table 
  

  if on_jobs_page()
    $('a#page_forward').show()
    # show_loading_message('Loading Jobs')
    perform_job_search($('form#job_search'), null)
    start_refresh_timer()
    
   
  # Provide modal view of Job Search form

  $('a.job_search').live 'click', (event) ->
    stop_refresh_timer()
    offset_element = $('input#search_offset')
    offset_element.val(0)
    $('a#page_back').hide()
    $.blockUI({ message: $('form#job_search') })

  
  # Exit from the Job Search form

  $('form#job_search input#cancel').click ->
    $.unblockUI();
    start_refresh_timer()   


  # Run the Job Search

  $('form#job_search').submit (event) ->
    stop_refresh_timer()
    event.preventDefault()
    perform_job_search($(this), 'Applying your searches and filters to find jobs...', start_refresh_timer())
    $.unblockUI();

    

  # Go to next page, rerun job search, ++offset
  $('a#page_forward').live 'click', (event) ->
    stop_refresh_timer()
    limit = $('select#search_limit').val()
    offset_element = $('input#search_offset')
    offset = parseInt(offset_element.val()) + 1
    if offset > 0
      $('a#page_back').show()
    offset_element.val(offset)
    perform_job_search($('form#job_search'), 'Loading the next ' + limit + ' jobs',  start_refresh_timer())
    



  # Go to the previous page, rerun job search, --offset
  $('a#page_back').live 'click', (event) ->
    stop_refresh_timer()
    limit = $('select#search_limit').val()
    offset_element = $('input#search_offset')
    offset = parseInt(offset_element.val()) - 1
    if offset < 1
      $(this).hide()
    offset_element.val(offset)
    perform_job_search($('form#job_search'), 'Loading the previous ' + limit + ' jobs', start_refresh_timer())
    


  # On index action view of resources, make the table row a link
  # to show a specific resource

  $('#datatable tbody tr td:not(#action)').live 'click', (event) ->
    window.location = $(this).parent().data('url');


  # Provide modal view of Job adding form

  $('a.add_job').click ->
    stop_refresh_timer()
    $.blockUI( { message: $('form#add_job') } )

  
  # Exit out from Job adding form

  $('form#add_job input#cancel').click ->
    $.unblockUI();
    start_refresh_timer()


  # Add the job to the job queue

  $('form#add_job').submit (event) ->
    event.preventDefault()
    show_loading_message('Adding job to the job queue')
    create_job($(this), () -> refresh_jobs())
    start_refresh_timer()


  # Request confirmation that you want to enqueue the application as a job

  $('a.enqueue').click ->
    application_id = $(this).attr('id');
    $('form#enqueue_form input#application_id').val(application_id);
    $.blockUI({ message: $('#enqueue_confirm'), css: { left: '30%', width: '700px' } });


  # Yes you want to enqueue

  $('div#enqueue_confirm #yes').click ->
    $.blockUI({ message: $('#enqueue_form') }); 
     

  # No you don't want to enqueue

  $('div#enqueue_confirm #no').click ->
    $.unblockUI(); 
    return false;


  # Cancel out from enqueuing form

  $('form#enqueue_form #cancel').click ->
    $.unblockUI();
    return false;


  # Enqueue an application as a job, on the job queue

  $('form#enqueue_form').submit (event) ->
    event.preventDefault()
    show_loading_message('Adding application as a job on the queue')    
    create_job($(this))

  popup_timer = ''

  show_tooltip = (event, url) ->
    x = (event.pageX - 1) + 'px'
    y = (event.pageY - 3) + 'px'
    $('div#tooltip').text('')
    body_text = ''
    $.ajax({
      type: "GET",
      dataType: 'json',
      url: url,
      success: (data) ->
        job = data.job
        for col in data.cols
          if col == 'title'
            body_text += '<h3>' + job[col] + '</h3>'
          else
            body_text += '<b>' + col + ': </b>'
            body_text += job[col]
            body_text += '<br />'
        body_text_object = $(body_text)
        body_text_object.appendTo('div#tooltip')
        $('div#tooltip').css({'display': 'block', 'top': y, 'left': x});
        $('div#tooltip').show()
    })

  hide_tooltip = () ->
    $('div#tooltip').hide()

  $('#datatable tbody tr').live 'mouseenter', (event) ->
    url = $(this).data('url')
    popup_timer = setTimeout (() -> show_tooltip(event, url)), 1500 
  
  $('#datatable tbody tr').live 'mouseout', (event) ->
    hide_tooltip()
    clearTimeout(popup_timer)
  
  $('#datatable thead th').live 'click', (event) ->
    id = $(this).attr('id');
    switch id
      when "queued_time", "started_at", "finished_at"
        if id == "queued_time"
          id = "created_at"
        $('form#job_search select#search_order').val(id)
        offset_element = $('input#search_offset')
        offset_element.val(0)
        $('a#page_back').hide()
        class_value = $(this).attr('class')
        if class_value == undefined
          $('input#search_direction_desc').attr('checked', 'checked')
          dir = 'descending'
        else
          if class_value == 'sortDesc'
            $('input#search_direction_asc').attr('checked', 'checked')
            dir = 'ascending'
          else
            $('input#search_direction_desc').attr('checked', 'checked')
            dir = 'descending'
        perform_job_search($('form#job_search'), 'Sorting by ' + id + ' ' + dir + '...',  null)


$('a.papertrail').live 'click', (event) ->
  url = $(this).data('url')
  $('iframe.papertrail').attr('src', url)
  $.blockUI( { message: $('div#iframeContainer'), css: { left: '5%', height: '75%', width: '90%'} } )

$('div#iframeContainer input#close').live 'click', (event) ->
  $.unblockUI();
                       
  

  