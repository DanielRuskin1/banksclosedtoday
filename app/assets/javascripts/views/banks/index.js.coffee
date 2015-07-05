$(document).ready () ->
  $("#country_select_form").change(-> $(this).submit())