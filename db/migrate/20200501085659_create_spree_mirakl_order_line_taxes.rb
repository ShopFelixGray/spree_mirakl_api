class CreateSpreeMiraklOrderLineTaxes < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_order_line_taxes do |t|
      t.string :amount
      t.string :code
      t.string :tax_type
      t.references :mirakl_order_line, null: false
      t.timestamps null: false
    end
  end
end