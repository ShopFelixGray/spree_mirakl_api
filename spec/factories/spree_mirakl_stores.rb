FactoryBot.define do
  factory :mirakl_store, class: Spree::MiraklStore do
    name "Test Store"
    api_key "test_key"
    url "https://test.com"
    active true
    user  { FactoryBot.create(:user) }
  end
end