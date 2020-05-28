require 'spec_helper'

module Mirakl
  RSpec.describe UpdateInventory do

    let!(:store) { create(:mirakl_store) }

    let(:service_arguments) {{
      store: store
    }}

    let!(:product) { create(:product_in_stock) }

    let(:offers_data) {{
      offers: [
        {
          all_prices: [
            {
              channel_code: nil,
              discount_end_date: nil,
              discount_start_date: nil,
              price: 95.00,
              unit_discount_price: nil,
              unit_origin_price: 95.00,
              volume_prices: [
                {
                  price: 95.00,
                  quantity_threshold: 1,
                  unit_discount_price: nil,
                  unit_origin_price: 95.00
                }
              ]
            }
          ],
          allow_quote_requests: false,
          description: nil,
          discount: nil,
          offer_id: 'test',
          price: product.price,
          product_sku: product.sku,
          quantity: product.master.quantity_check,
          shop_sku: product.sku,
          state_code: '11'
        }
      ]
    }.to_json}

    let(:offer_data) {
        {
          all_prices: [
          ],
          allow_quote_requests: false,
          description: nil,
          discount: nil,
          offer_id: 'test',
          price: product.price,
          product_sku: product.sku,
          quantity: product.master.quantity_check,
          shop_sku: product.sku,
          state_code: '11'
        }.to_json}

    let(:service) { described_class.new(service_arguments) }

    before do
      stub_request(:get, "#{store.url}/api/offers?limit=100&max=100&shop_id=#{store.shop_id}").
        to_return(status: 200, body: '{ "offers": [] }', headers: {})
      stub_request(:post, "#{store.url}/api/offers?shop_id=#{store.shop_id}").
        to_return(status: 204, headers: {})
    end

    describe 'CLASS' do

      it 'inherits from ApplicationService' do
        expect(described_class.superclass).to eq(ApplicationService)
      end

    end

    describe 'CALL' do
      describe '#initialize' do
        it 'sets @stores using the provided arguments' do
          result = service.store
          expect(result).to eq(service_arguments[:store])
        end
      end

      describe '#call' do

        context 'when a ServiceError is raised' do
          before do
            allow(service).to receive(:get_offers).and_raise(ServiceError.new(['Something went wrong']))
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
      describe 'get_offers' do
        before do
          stub_request(:get, "#{store.url}/api/offers?limit=100&max=100&shop_id=#{store.shop_id}").
            to_return(status: 200, body: offers_data, headers: {})
        end

        it 'returns the correct json' do
          json_results = service.send(:get_offers)
          expect(json_results).to eq(JSON.parse(offers_data, symbolize_names: true)[:offers])
        end

        describe 'get_offers bad_data' do
          before do
            stub_request(:get, "#{store.url}/api/offers?limit=100&max=100&shop_id=#{store.shop_id}").
              to_return(status: 500, body: '', headers: {})
          end

          it 'errors correctly' do
            service.call
            expect(service.errors).to eq(["Error in getting Mirakl Offers for shop id: #{store.shop_id}"])
          end
        end

      end

      describe 'update_inventory' do
        before do
          stub_request(:get, "#{store.url}/api/offers/test?shop_id=#{store.shop_id}").
            to_return(status: 200, body: offer_data, headers: {})
        end

        it 'builds the json correctly' do
          service.send(:update_inventory, JSON.parse(offers_data, symbolize_names: true)[:offers])
          expect(service.update_json).to eq([{
            all_prices: [
            ],
            allow_quote_requests: false,
            available_ended: nil,
            available_started: nil,
            description: nil,
            internal_description: nil,
            price: product.price,
            product_id: nil,
            product_id_type: nil,
            product_tax_code: nil,
            quantity: product.master.quantity_check,
            shop_sku: product.sku,
            state_code: '11',
            update_delete: 'update'
          }])
        end
      end

      describe 'when sku doesnt exist' do
        let(:offers_data) {{
          offers: [
            {
              all_prices: [
              ],
              allow_quote_requests: false,
              description: nil,
              discount: nil,
              offer_id: 'test',
              price: '95.00',
              product_sku: 'not_here',
              quantity: '50',
              shop_sku: 'not_here',
              state_code: '11'
            }
          ]
        }.to_json}

        let(:offer_data) {
          {
            all_prices: [
            ],
            allow_quote_requests: false,
            description: nil,
            discount: nil,
            offer_id: 'test',
            price: '95.00',
            product_sku: 'not_here',
            quantity: '50',
            shop_sku: 'not_here',
            state_code: '11'
          }.to_json}

        before do
          stub_request(:get, "#{store.url}/api/offers?limit=100&max=100&shop_id=#{store.shop_id}").
            to_return(status: 200, body: offers_data, headers: {})
          stub_request(:get, "#{store.url}/api/offers/test?shop_id=#{store.shop_id}").
            to_return(status: 200, body: offer_data, headers: {})
        end

        it 'returns an out of stock json object' do
          service.send(:update_inventory, JSON.parse(offers_data, symbolize_names: true)[:offers])
          expect(service.update_json).to eq([{
            all_prices: [
            ],
            allow_quote_requests: false,
            available_ended: nil,
            available_started: nil,
            description: nil,
            internal_description: nil,
            price: '95.00',
            product_id: nil,
            product_id_type: nil,
            product_tax_code: nil,
            quantity: 0,
            shop_sku: 'not_here',
            state_code: '11',
            update_delete: 'update'
          }])
        end

      end

      describe 'when the inventory throws an error' do
        before do
          stub_request(:get, "#{store.url}/api/offers/test?shop_id=#{store.shop_id}").
            to_return(status: 200, body: offer_data, headers: {})
          stub_request(:post, "#{store.url}/api/offers?shop_id=#{store.shop_id}").
            to_return(status: 403, headers: {})
        end

        it 'throws an error correctly' do
          service.call
          expect(service.errors).to eq(['Issue updating inventory: '])
        end
      end
    end

  end
end 