require 'spec_helper'

module Mirakl
  RSpec.describe StockCheck do

    let!(:store) { create(:mirakl_store) }

    let(:product) { create(:product_in_stock) }

    let(:service_arguments) {{
      sku: product.sku,
      quantity: 1
    }}

    let(:service) { described_class.new(service_arguments) }

    describe 'CLASS' do

      it 'inherits from ApplicationService' do
        expect(described_class.superclass).to eq(ApplicationService)
      end

    end

    describe 'CALL' do
      describe '#call' do
        it 'calls #check_stock' do
          expect(service).to receive(:check_stock).and_call_original
          service.call
        end

        context 'when a ServiceError is raised' do
          before do
            allow(service).to receive(:check_stock).and_raise(ServiceError.new(["Something went wrong"]))
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
      describe 'check_stock' do
        it 'returns true when the item is in stock' do
          service.call
          expect(service.can_fulfill).to eq(true)
        end

        describe 'when item doesnt exist' do
          let(:service_arguments) {{
            sku: 'doesnt_exist',
            quantity: 1
          }}

          it 'returns false cause sku doesnt exist' do
            service.call
            expect(service.can_fulfill).to eq(false)
          end
        end

        describe 'when the item is out of stock' do
          let(:product) { create(:product_no_backorder) }

          it 'returns false cause sku doesnt exist' do
            service.call
            expect(service.can_fulfill).to eq(false)
          end
        end
      end
    end

  end
end 