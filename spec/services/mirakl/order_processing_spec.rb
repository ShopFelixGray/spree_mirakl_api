require 'spec_helper'

module Mirakl
  RSpec.describe OrderProcessing do

    let(:store) { create(:mirakl_store) }

    let(:service_arguments) {{
      stores: [store]
    }}

    let(:service) { described_class.new(service_arguments) }

    before do
      stub_request(:get, "https://test.com/api/shipping/carriers").to_return(status: 200, body: '{ "carriers": [] }', headers: {})
      stub_request(:get, "#{store.url}/api/orders?limit=50&max=50&order_state_codes=WAITING_ACCEPTANCE,SHIPPING&shop_id=#{store.shop_id}").
        to_return(status: 200, body: '{ "orders": [] }', headers: {})
    end

    describe 'CLASS' do

      it 'inherits from ApplicationService' do
        expect(described_class.superclass).to eq(ApplicationService)
      end

    end

    describe 'CALL' do
      describe '#initialize' do
        it 'sets @stores using the provided arguments' do
          result = service.stores
          expect(result).to eq(service_arguments[:stores])
        end
      end

      describe '#call' do
        it 'calls #get_orders' do
          expect(service).to receive(:get_orders).and_call_original
          service.call
        end

        it 'calls #process_orders' do
          expect(service).to receive(:process_orders).and_call_original
          service.call
        end

        context 'when a ServiceError is raised' do
          before do
            allow(service).to receive(:get_orders).and_raise(ServiceError.new(['Something went wrong']))
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
      describe 'get_orders' do

        describe 'when correct json is returned' do
          before do
            stub_request(:get, "#{store.url}/api/orders?limit=50&max=50&order_state_codes=WAITING_ACCEPTANCE,SHIPPING&shop_id=#{store.shop_id}").
              to_return(status: 200, body: '{ "orders": [{ "test_data": "testing" }] }', headers: {})
          end

          it 'gets the correct json' do
            data_call = service.send(:get_orders, store)
            expect(data_call).to eq(JSON.parse('[{ "test_data": "testing" }]', {symbolize_names: true}))
          end
        end

        describe 'when empty json is returned' do
          before do
            stub_request(:get, "#{store.url}/api/orders?limit=50&max=50&order_state_codes=WAITING_ACCEPTANCE,SHIPPING&shop_id=#{store.shop_id}").
              to_return(status: 200, body: '{ }', headers: {})
          end

          it 'gets the correct json' do
            data_call = service.send(:get_orders, store)
            expect(data_call).to eq(nil)
          end
        end

        describe 'when json is empty or a string' do
          before do
            stub_request(:get, "#{store.url}/api/orders?limit=50&max=50&order_state_codes=WAITING_ACCEPTANCE,SHIPPING&shop_id=#{store.shop_id}").
              to_return(status: 500, body: 'error string', headers: {})
          end

          it 'gets the correct json' do
            service.call
            expect(service.errors).to eq(['Error in getting Waiting Acceptance and Shipping'])
          end
        end
      end
    end

    describe 'process_orders' do
      let(:product) { create(:product_in_stock) }

      let(:order_data_waiting) {
        JSON.parse([{ order_id: 'test', order_state: 'WAITING_ACCEPTANCE',  order_lines: [offer_sku: product.sku, quantity: 1 ] }].to_json, symbolize_names: true)
      }

      let(:order_data_shipping) {
        JSON.parse([{ order_id: 'test', order_state: 'SHIPPING',  order_lines: [offer_sku: product.sku, quantity: 1] }].to_json, symbolize_names: true)
      }

      let(:order_data) {{
        orders: [{
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
        stub_request(:put, "#{store.url}/api/orders/test/accept?shop_id=#{store.shop_id}").
          to_return(status: 204, body: '', headers: {})
        stub_request(:get, "#{store.url}/api/orders?order_ids=test&shop_id=#{store.shop_id}").
          to_return(status: 200, body: order_data, headers: {})
      end

      describe 'waiting_acceptance' do
        it 'calls build order correctly' do
          expect_any_instance_of(Mirakl::BuildOrder).to receive(:call).once.and_return(true)
          service.send(:process_orders, order_data_waiting, store)
        end

        describe 'out of stock product' do
          let(:product) { create(:product) }

          it 'doesnt call build order correctly' do
            expect_any_instance_of(Mirakl::BuildOrder).not_to receive(:call)
            service.send(:process_orders, order_data_waiting, store)
          end
        end
      end

      describe 'shipping' do
        it 'calls build order correctly' do
          expect_any_instance_of(Mirakl::BuildOrder).to receive(:call).once.and_return(true)
          service.send(:process_orders, order_data_shipping, store)
        end
      end
    end

    describe 'accept_or_reject_order' do
      before do
        stub_request(:put, "#{store.url}/api/orders/123/accept?shop_id=#{store.shop_id}").
          with(body: { order_lines: [] } ).
          to_return(status: 400, body: '{}', headers: {})
      end

      it 'correctly pushes the order to mirakl' do
        expect { service.send(:accept_or_reject_order, JSON.parse({ order_id: '123' ,order_lines: [] }.to_json, symbolize_names: true), true, store) }.to raise_exception
      end
    end

    describe 'accept_or_reject_order_json' do
      describe 'building the json' do
        it 'processes true correctly' do
          json_data = service.send(:accept_or_reject_order_json, JSON.parse({ order_lines: [{ order_line_id: '201807130411578146106997' }] }.to_json, symbolize_names: true), true)
          expect(json_data).to eq([{ accepted: true, id: '201807130411578146106997' }])
        end

        it 'processes false correctly' do
          json_data = service.send(:accept_or_reject_order_json, JSON.parse({ order_lines: [{ order_line_id: '201807130411578146106997' }] }.to_json, symbolize_names: true), false)
          expect(json_data).to eq([{accepted: false, id: '201807130411578146106997' }])
        end
      end
    end

  end
end 