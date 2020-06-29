class CreateReturnAuthorizationReasonToMiraklRefundReasons < ActiveRecord::Migration
  def change
    create_table :spree_return_authorization_reason_to_mirakl_refund_reasons do |t|
      t.references :mirakl_refund_reason, index: { name: :mirakl_refund_reason_to_return_auth }
      t.references :return_authorization_reason, index: { name: :return_auth_to_mirakl_refund }
      t.timestamps null: false
    end
  end
end
