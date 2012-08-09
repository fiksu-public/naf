jQuery ->
  $('#datatable').jTPS({
    perPages:  [10,20,'ALL'],
    scrollStep:1,
    scrollDelay:30
  })

  $('.jTPS tbody tr td:not(#action)').click ->
    window.location = $(this).parent().data('url');