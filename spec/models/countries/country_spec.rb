require 'spec_helper'

describe 'Country' do
  describe '#country_for_code' do
    context 'when a supported code is provided' do
      it 'should return the relevant Country object' do
        expect(Country.country_for_code('US')).to eq(UsCountry)
      end
    end

    context 'when an unsupported code is provided' do
      it 'should raise a Country::NoCountryError' do
        expect do
          Country.country_for_code('XX')
        end.to raise_error(Country::NoCountryError)
      end
    end
  end

  describe '#supported_countries' do
    it 'should return a hash with all supported countries' do
      expect(Country.supported_countries).to eq('US' => 'United States')
    end
  end

  context 'unimplemented methods' do
    %w(code name bank).each do |method_name|
      describe "##{method_name}" do
        it 'should raise a NotImplementedError' do
          expect do
            Country.send(method_name)
          end.to raise_error(NotImplementedError)
        end
      end
    end
  end
end
