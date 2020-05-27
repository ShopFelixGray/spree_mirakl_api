module SpreeMirakl
  class Address

    attr_accessor :data, :address, :address_data, :user

    def initialize(address_data, user)
      @user = user
      @data = address_data
      @address_data = {}
      @address = nil
    end

    def build_address
      country = get_country_for(@data[:country_iso_code] || @data[:country])
      state = get_state_for(@data[:state], country)
      # Start with these fields cause they are safe
      @address_data = {
        address1: @data[:street_1],
        address2: @data[:street_2],
        city: @data[:city],
        zipcode: @data[:zip_code],
        firstname: (@data[:firstname] || 'Mirakl'),
        lastname: (@data[:lastname] || 'User'),
        state_name: state.name,
        state: state,
        company: @data[:company],
        country: country,
        phone: convert_phone(@data[:phone] || @data[:phone_secondary]) || '0000000000'
      }

      # Check if we are using spree address book
      if `gem list`.include? 'spree_address_book'
        @address_data = @address_data.merge({ user: @user, default: false })
      end

      @address = Spree::Address.create!(@address_data)
      @address
    end

    def get_country_for(country_iso)
      Spree::Country.find_by(iso: country_iso) || Spree::Country.find_by(iso3: country_iso)
    end

    def get_state_for(state_abbr, country)
      Spree::State.find_by(abbr: state_abbr, country: country) || Spree::State.find_by(name: state_abbr, country: country)
    end

    def convert_phone(phone_number)
      return nil if phone_number.blank? ||
                    phone_number.length < 10 ||
                    phone_number.length > 15
      phone_number
    end
  end
end
