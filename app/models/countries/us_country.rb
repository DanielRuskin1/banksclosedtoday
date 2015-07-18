# Country class for the United States
class UsCountry < Country
  def self.code
    'US'
  end

  # Name of this country
  # Only implemented in subclasses.
  def self.name
    'United States'
  end

  # Bank for this country
  # Only implemented in subclasses
  def self.bank
    UsBank
  end
end
