jQuery ->
  $('#datatable').jTPS({
    perPages:  [5,12,15,50,'ALL'],
    scrollStep:1,
    scrollDelay:30
  })

  $('.jTPS tbody tr td:not(:last-of-type)').click ->
    window.location = $(this).parent().data('url');