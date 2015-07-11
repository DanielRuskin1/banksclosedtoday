module ApplicationHelper
  def supported_country_select_options
    # Generate options hash
    country_options = {}
    country_options[''] = '' # Blank option is first
    country_options.merge!(Country.supported_countries.invert) # Add all supported country options
    country_options['Other'] = 'XX' # Unsupported country option (this will display an unsupported page)

    # Return options
    country_options
  end
end
