require 'spec_helper'

module Mirakl
  RSpec.describe BuildOrder do
    let(:store) { create(:mirakl_store) }

    let!(:product) { create(:product_in_stock, { sku: 'test-sku' }) }

    let!(:payment_method) { create(:mirakl_payment_method) }

    let!(:shipping_method) { create(:shipping_method, { admin_name: 'default' })}

    let!(:shipping_method_2) { create(:shipping_method, { name: 'two_day', admin_name: 'two_day' })}

    let(:service_arguments) {{
      mirakl_order_id: 'test',
      store: store
    }}

    let(:service) { described_class.new(service_arguments) }

    let(:order_data) {{
      orders: [
        {
          customer: {
            billing_address: {
              city: 'Washington',
              company: nil,
              country: 'US',
              country_iso_code: nil,
              firstname: 'AARON',
              lastname: 'FLORES',
              phone_secondary: '55555555',
              state: 'DC',
              street_1: '1600 Pennsylvania Ave NW',
              street_2: nil,
              zip_code: '20500'
            },
            firstname: 'AARON',
            lastname: 'FLORES',
            shipping_address: {
              additional_info: nil,
              city: 'Washington',
              company: nil,
              country: 'US',
              country_iso_code: nil,
              firstname: 'AARON',
              lastname: 'FLORES',
              phone_secondary: '555555555',
              state: 'DC',
              street_1: '1600 Pennsylvania Ave NW',
              street_2: nil,
              zip_code: '20500'
            }
          },
          order_id: 'AP00561912-318661410-A',
          created_date: Time.current,
          order_lines: [
            {
              offer_id: 2527,
              offer_sku: product.sku,
              order_line_id: '201807130411578146106997',
              quantity: 2,
              received_date: '2020-05-04T19:57:41Z',
              shipping_taxes: [
                {
                  amount: 0.30,
                  amount_breakdown: {
                    parts: [
                      {
                        amount: 0.30,
                        commissionable: false,
                        debitable_from_customer: true,
                        payable_to_shop: true
                      }
                    ]
                  },
                  code: 'shipping-tax-amount'
                }
              ],
              taxes: [
                {
                  amount: 0.72,
                  amount_breakdown: {
                    parts: [
                      {
                        amount: 0.72,
                        commissionable: false,
                        debitable_from_customer: true,
                        payable_to_shop: true
                      }
                    ]
                  },
                  code: 'product-tax-amount'
                }
              ]
            }
          ],
          total_price: 194.95
        }
      ]
    }.to_json}

    before do
      Spree::State.create!(name: 'Washington D.C', abbr: 'DC', country: Spree::Country.first)
      Spree::ZoneMember.create!(zoneable_id: Spree::Country.first.id, zone: Spree::Zone.first, zoneable: Spree::Country.first)
      
      stub_request(:get, "https://test.com/api/shipping/carriers").to_return(status: 200, body: '{ "carriers": [] }', headers: {})
      stub_request(:get, "#{store.url}/api/orders?order_ids=test&shop_id=#{store.shop_id}").
        to_return(status: 200, body: order_data, headers: {})
    end

    describe 'CLASS' do
      it 'inherits from ApplicationService' do
        expect(described_class.superclass).to eq(ApplicationService)
      end
    end

    describe 'CALL' do
      describe '#call' do
        it 'calls #get_order' do
          expect(service).to receive(:get_order).and_call_original
          service.call
        end

        context 'when a ServiceError is raised' do
          before do
            allow(service).to receive(:get_order).and_raise(ServiceError.new(['Something went wrong']))
          end

          it 'rescues the error and adds to the errors array' do
            service.call
            expect(service.errors).to eq(['Something went wrong'])
          end
        end

        context 'when no errors are present' do
          it 'returns true' do
            result = service.call
            expect(result).to eq(true)
          end
        end

        context 'when errors are present' do
          before do
            allow(service).to receive(:errors).and_return(['Something went wrong'])
          end

          it 'returns false' do
            result = service.call
            expect(result).to eq(false)
          end
        end
      end 

    end

    describe 'METHODS' do
      describe 'get_order' do
        it 'processes the json correctly' do
          json_results = service.send(:get_order, 'test', store)
          expect(json_results).to eq(JSON.parse(order_data, symbolize_names: true)[:orders][0])
        end

        describe 'when there is an error' do
          before do
            stub_request(:get, "#{store.url}/api/orders?order_ids=test&shop_id=#{store.shop_id}").
              to_return(status: 400, body: '{}', headers: {})
          end

          it 'raises an error' do
            service.call
            expect(service.errors).to eq(['Issue processing test'])
          end
        end
      end

      describe 'build_order_for_user' do
        it 'creates the order' do
          expect{service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)}.to change{Spree::Order.count}.by(1)
        end

        it 'creates a transaction' do
          expect{service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)}.to change{Spree::MiraklTransaction.count}.by(1)
        end

        it 'creates 2 addresses' do
          expect{service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)}.to change{Spree::Address.count}.by(2)
        end

        it 'sets the order channel correctly' do
          service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)
          expect(service.order.channel).to eq('mirakl')
        end

        it 'is a complete order' do
          service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)
          expect(service.order.state).to eq('complete')
        end

        describe 'shipping matching' do
          before do
            shipping_method = Spree::ShippingMethod.find_by(admin_name: 'default')
            calculator = Spree::Calculator::FlatRate.create(preferences: {currency: 'USD', amount: 10.0})
            shipping_method.calculator = calculator
          end

          it 'selects the correct shipping method' do
            service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)
            expect(service.order.shipments.first.shipping_method.id).to eq(shipping_method_2.id)
          end

          it 'has the correct shipping cost' do
            service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)
            expect(service.order.shipment_total).to eq(0.0)
          end

          describe 'mirakl mapping works' do
            let(:mirakl_shipping_option) { create(:mirakl_shipping_options, { mirakl_store: store })}

            let(:order_data) {{
              orders: [
                {
                  customer: {
                    billing_address: {
                      city: 'Washington',
                      company: nil,
                      country: 'US',
                      country_iso_code: nil,
                      firstname: 'AARON',
                      lastname: 'FLORES',
                      phone_secondary: '55555555',
                      state: 'DC',
                      street_1: '1600 Pennsylvania Ave NW',
                      street_2: nil,
                      zip_code: '20500'
                    },
                    firstname: 'AARON',
                    lastname: 'FLORES',
                    shipping_address: {
                      additional_info: nil,
                      city: 'Washington',
                      company: nil,
                      country: 'US',
                      country_iso_code: nil,
                      firstname: 'AARON',
                      lastname: 'FLORES',
                      phone_secondary: '555555555',
                      state: 'DC',
                      street_1: '1600 Pennsylvania Ave NW',
                      street_2: nil,
                      zip_code: '20500'
                    }
                  },
                  shipping_type_label: 'abc',
                  order_id: 'AP00561912-318661410-A',
                  created_date: Time.current,
                  order_lines: [
                    {
                      offer_id: 2527,
                      offer_sku: product.sku,
                      order_line_id: '201807130411578146106997',
                      quantity: 2,
                      received_date: '2020-05-04T19:57:41Z',
                      shipping_taxes: [
                        {
                          amount: 0.30,
                          amount_breakdown: {
                            parts: [
                              {
                                amount: 0.30,
                                commissionable: false,
                                debitable_from_customer: true,
                                payable_to_shop: true
                              }
                            ]
                          },
                          code: 'shipping-tax-amount'
                        }
                      ],
                      taxes: [
                        {
                          amount: 0.72,
                          amount_breakdown: {
                            parts: [
                              {
                                amount: 0.72,
                                commissionable: false,
                                debitable_from_customer: true,
                                payable_to_shop: true
                              }
                            ]
                          },
                          code: 'product-tax-amount'
                        }
                      ]
                    }
                  ],
                  total_price: 194.95
                }
              ]
            }.to_json}
  
            before do
              shipping_method_2 = Spree::ShippingMethod.find_by(admin_name: 'two_day')
              calculator_2 = Spree::Calculator::FlatRate.create(preferences: {currency: 'USD', amount: 30.0})
              shipping_method_2.calculator = calculator_2
              Spree::MiraklShippingOptionShippingMethod.create(shipping_method: shipping_method_2, mirakl_shipping_option: mirakl_shipping_option)
            end

            it 'applies the new shipping method cost' do
              service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)
              expect(service.order.shipment_total).to eq(30.0)
            end

            it 'applies the new shipping method' do
              service.send(:build_order_for_user, JSON.parse(order_data, symbolize_names: true)[:orders][0], store)
              expect(service.order.shipments.first.shipping_method.admin_name).to eq('two_day')
            end
          end
        end

        # TODO: Add error test. This will be done to have json missing some field
      end
    end

  end
end 