require 'rails_helper'

module Mirakl
  RSpec.describe OrderProcessing do

    let!(:store) { create(:mirakl_store) }

    let(:service_arguments) {{
      stores: [store]
    }}

    let(:service) { described_class.new(service_arguments) }

    before do
      stub_request(:get, "#{store.url}/api/orders?order_state_codes=WAITING_ACCEPTANCE").
        with(headers: { 'Authorization': store.api_key, 'Accept': 'application/json' }).
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
            allow(service).to receive(:get_orders).and_raise(ServiceError.new(["Something went wrong"]))
          end

          it 'rescues the error and adds to the errors array' do
            service.call
            expect(service.errors).to eq(["Something went wrong"])
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
            allow(service).to receive(:errors).and_return(["Something went wrong"])
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
            stub_request(:get, "#{store.url}/api/orders?order_state_codes=WAITING_ACCEPTANCE").
              with(headers: { 'Authorization': store.api_key, 'Accept': 'application/json' }).
              to_return(status: 200, body: '{ "orders": [{ "test_data": "testing" }] }', headers: {})
          end

          it 'gets the correct json' do
            data_call = service.send(:get_orders, store)
            expect(data_call).to eq(JSON.parse('[{ "test_data": "testing" }]'))
          end
        end

        describe 'when empty json is returned' do
          before do
            stub_request(:get, "#{store.url}/api/orders?order_state_codes=WAITING_ACCEPTANCE").
              with(headers: { 'Authorization': store.api_key, 'Accept': 'application/json' }).
              to_return(status: 200, body: '{ }', headers: {})
          end

          it 'gets the correct json' do
            data_call = service.send(:get_orders, store)
            expect(data_call).to eq(nil)
          end
        end

        describe 'when json is empty or a string' do
          before do
            stub_request(:get, "#{store.url}/api/orders?order_state_codes=WAITING_ACCEPTANCE").
              with(headers: { 'Authorization': store.api_key, 'Accept': 'application/json' }).
              to_return(status: 200, body: 'error string', headers: {})
          end

          it 'gets the correct json' do
            service.call
            expect(service.errors).to eq(['Error in getting Waiting Acceptance'])
          end
        end
      end

      describe "process_orders" do 
        let!(:product) { create(:lens_product) }
        context 'when a single item is sent correctly' do
          before do
            stub_request(:get, "#{store.url}/api/orders?order_state_codes=WAITING_ACCEPTANCE").
              with(headers: { 'Authorization': store.api_key, 'Accept': 'application/json' }).
              to_return(status: 200, body: ({ "orders": [{ "order_lines": [{ "offer_sku": product.sku, "quantity": 1 }]}] }).to_json, headers: {})
          end

          it 'loops through once' do
            expect_any_instance_of(Mirakl::StockCheck).to receive(:call).once
            service.call
          end
        end
      end
    end

  end
end 