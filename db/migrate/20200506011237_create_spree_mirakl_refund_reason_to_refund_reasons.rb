class CreateSpreeMiraklRefundReasonToRefundReasons < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_refund_reason_to_refund_reasons do |t|
      t.references :mirakl_refund_reason, index: { name: :mirakl_refund_reason_to_refund }
      t.references :refund_reason, index: { name: :refund_reason_to_mirakl_refund }
      t.timestamps null: false
    end
  end
end