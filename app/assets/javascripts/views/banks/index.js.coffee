$(document).ready () ->
  # Hide "Go" button if JS is enabled and this runs
  $("#country_form_submit").remove();

  # Set callback to auto-submit form
  $("#country_form").change () ->
    $("#country_form").submit();