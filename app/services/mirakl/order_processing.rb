module Mirakl
  class OrderProcessing < ApplicationService

    attr_reader :stores

    def initialize(args = {})
      super
      @stores = args[:stores]
    end

    def call
      begin
        @stores.each do |store|
          orders = get_orders(store)
          process_orders(orders, store)
        end
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      return completed_without_errors?
    end

    def get_orders(store)
      request = SpreeMirakl::Api.new(store).get_order_state("WAITING_ACCEPTANCE,SHIPPING")
      if request.success?
        begin
          return JSON.parse(request.body, {symbolize_names: true})[:orders]
        rescue
          raise ServiceError.new(["Error in getting Waiting Acceptance"])
        end
      else
        raise ServiceError.new(["Error in getting Waiting Acceptance"])
      end
    end

    def process_orders(orders, store)
      orders.each do |order|
        if order[:order_state] == "WAITING_ACCEPTANCE"
          can_fulfill = true
          order[:order_lines].each do |order_line|
            service = Mirakl::StockCheck.new({sku: order_line[:offer_sku], quantity: order_line[:quantity]})
            if service.call
              can_fulfill = service.can_fulfill
            else
              raise ServiceError.new(service.errors)
            end
            break unless can_fulfill
          end
          accept_or_reject_order(order, can_fulfill, store)
        elsif order[:order_state] == "SHIPPING" # do elsif just to be safe not making double order
          order_service = Mirakl::BuildOrder.new({mirakl_order_id: order[:order_id], store: store})
          unless order_service.call
            raise ServiceError.new(["Error processing order: #{order[:order_id]}", order_service.errors])
          end
        end
      end
    end

    def accept_or_reject_order(order, can_fulfill, store)
      request = SpreeMirakl::Api.new(store).accept_order(order[:order_id], accept_or_reject_order_json(order, can_fulfill))

      if request.success?
        order_service = Mirakl::BuildOrder.new({mirakl_order_id: order[:order_id], store: store})
        unless order_service.call
          raise ServiceError.new(["Error processing order: #{order[:order_id]}", order_service.errors])
        end
      else
        raise ServiceError.new(["Issue Processing #{order[:order_id]} can fulfill but request issue"])
      end
    end

    def accept_or_reject_order_json(order, can_fulfill)
      order_data = []

      order[:order_lines].each do |order_line|
        order_data << { 'accepted': can_fulfill, 'id': order_line[:order_line_id] }
      end
      order_data
    end

  end
end


{
  "acceptance_decision_date": "2020-05-20T17:30:04Z", "can_cancel": false, "channel": { "code": "madewell", "label": "Madewell" }, "commercial_id": "1589994114581-1589994114581", "created_date": "2020-05-20T17:01:55Z", "currency_iso_code": "USD", "customer": {
"billing_address":  nil,
"civility":  nil,
"customer_id": "9001",
"firstname": "Kelly",
"lastname": "Patten",
    "locale": "en_US",
    "shipping_address":  nil
  },
  "customer_debited_date":  nil,
  "fulfillment": {
    "center": {
      "code": "DEFAULT"
    }
  },
  "has_customer_message": false,
  "has_incident": false,
  "has_invoice": false,
  "last_updated_date": "2020-05-20T17:30:04Z",
  "leadtime_to_ship": 5,
  "order_additional_fields": [],
  "order_id": "1589994114581-1589994114581-A",
  "order_lines": [
    {
      "can_refund": false,
      "cancelations": [],
      "category_code": "SH1D4U8H5",
      "category_label": "W ITM EYE GLASSES",
      "commission_fee": 28.50,
      "commission_rate_vat": 0.0000,
      "commission_taxes": [
        {
          "amount": 0.00,
          "code": "TAXZERO",
          "rate": 0.0000
        }
      ],
      "commission_vat": 0.00,
      "created_date": "2020-05-20T17:01:55Z",
      "debited_date":  nil,
      "description":  nil,
      "last_updated_date": "2020-05-20T17:30:04Z",
      "offer_id": 2662,
      "offer_sku": "roebling_c2_2",
      "offer_state_code": "11",
      "order_line_additional_fields": [],
      "order_line_id": "1589994114581-1589994114581-A-1",
      "order_line_index": 1,
      "order_line_state": "REFUSED",
      "order_line_state_reason_code": "REFUSED",
      "order_line_state_reason_label": "Rejected",
      "price": 95.00,
      "price_additional_info":  nil,
      "price_amount_breakdown": {
        "parts": [
          {
            "amount": 95.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "price_unit": 95.00,
      "product_medias": [],
      "product_sku": "99106066518",
      "product_title": "Roebling Amber Toffee",
      "promotions": [],
      "quantity": 1,
      "received_date":  nil,
      "refunds": [],
      "shipped_date":  nil,
      "shipping_price": 0.00,
      "shipping_price_additional_unit":  nil,
      "shipping_price_amount_breakdown": {
        "parts": [
          {
            "amount": 0.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "shipping_price_unit":  nil,
      "shipping_taxes": [
        {
          "amount": 0.00,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 0.00,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "taxes": [
        {
          "amount": 8.43,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 8.43,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "total_commission": 28.50,
      "total_price": 95.00
    },
    {
      "can_refund": false,
      "cancelations": [],
      "category_code": "SH1D4U8H5",
      "category_label": "W ITM EYE GLASSES",
      "commission_fee": 28.50,
      "commission_rate_vat": 0.0000,
      "commission_taxes": [
        {
          "amount": 0.00,
          "code": "TAXZERO",
          "rate": 0.0000
        }
      ],
      "commission_vat": 0.00,
      "created_date": "2020-05-20T17:01:55Z",
      "debited_date":  nil,
      "description":  nil,
      "last_updated_date": "2020-05-20T17:30:04Z",
      "offer_id": 2662,
      "offer_sku": "roebling_c2_2",
      "offer_state_code": "11",
      "order_line_additional_fields": [],
      "order_line_id": "1589994114581-1589994114581-A-2",
      "order_line_index": 2,
      "order_line_state": "REFUSED",
      "order_line_state_reason_code": "REFUSED",
      "order_line_state_reason_label": "Rejected",
      "price": 95.00,
      "price_additional_info":  nil,
      "price_amount_breakdown": {
        "parts": [
          {
            "amount": 95.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "price_unit": 95.00,
      "product_medias": [],
      "product_sku": "99106066518",
      "product_title": "Roebling Amber Toffee",
      "promotions": [],
      "quantity": 1,
      "received_date":  nil,
      "refunds": [],
      "shipped_date":  nil,
      "shipping_price": 0.00,
      "shipping_price_additional_unit":  nil,
      "shipping_price_amount_breakdown": {
        "parts": [
          {
            "amount": 0.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "shipping_price_unit":  nil,
      "shipping_taxes": [
        {
          "amount": 0.00,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 0.00,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "taxes": [
        {
          "amount": 8.43,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 8.43,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "total_commission": 28.50,
      "total_price": 95.00
    },
    {
      "can_refund": false,
      "cancelations": [],
      "category_code": "SH1D4U8H5",
      "category_label": "W ITM EYE GLASSES",
      "commission_fee": 28.50,
      "commission_rate_vat": 0.0000,
      "commission_taxes": [
        {
          "amount": 0.00,
          "code": "TAXZERO",
          "rate": 0.0000
        }
      ],
      "commission_vat": 0.00,
      "created_date": "2020-05-20T17:01:55Z",
      "debited_date":  nil,
      "description":  nil,
      "last_updated_date": "2020-05-20T17:30:04Z",
      "offer_id": 2660,
      "offer_sku": "turing_c5_2",
      "offer_state_code": "11",
      "order_line_additional_fields": [],
      "order_line_id": "1589994114581-1589994114581-A-3",
      "order_line_index": 3,
      "order_line_state": "REFUSED",
      "order_line_state_reason_code": "REFUSED",
      "order_line_state_reason_label": "Rejected",
      "price": 95.00,
      "price_additional_info":  nil,
      "price_amount_breakdown": {
        "parts": [
          {
            "amount": 95.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "price_unit": 95.00,
      "product_medias": [],
      "product_sku": "99106066522",
      "product_title": "Turing Whiskey Tortoise",
      "promotions": [],
      "quantity": 1,
      "received_date":  nil,
      "refunds": [],
      "shipped_date":  nil,
      "shipping_price": 0.00,
      "shipping_price_additional_unit":  nil,
      "shipping_price_amount_breakdown": {
        "parts": [
          {
            "amount": 0.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "shipping_price_unit":  nil,
      "shipping_taxes": [
        {
          "amount": 0.00,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 0.00,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "taxes": [
        {
          "amount": 8.43,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 8.43,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "total_commission": 28.50,
      "total_price": 95.00
    },
    {
      "can_refund": false,
      "cancelations": [],
      "category_code": "SH1D4U8H5",
      "category_label": "W ITM EYE GLASSES",
      "commission_fee": 28.50,
      "commission_rate_vat": 0.0000,
      "commission_taxes": [
        {
          "amount": 0.00,
          "code": "TAXZERO",
          "rate": 0.0000
        }
      ],
      "commission_vat": 0.00,
      "created_date": "2020-05-20T17:01:55Z",
      "debited_date":  nil,
      "description":  nil,
      "last_updated_date": "2020-05-20T17:30:04Z",
      "offer_id": 2660,
      "offer_sku": "turing_c5_2",
      "offer_state_code": "11",
      "order_line_additional_fields": [],
      "order_line_id": "1589994114581-1589994114581-A-4",
      "order_line_index": 4,
      "order_line_state": "REFUSED",
      "order_line_state_reason_code": "REFUSED",
      "order_line_state_reason_label": "Rejected",
      "price": 95.00,
      "price_additional_info":  nil,
      "price_amount_breakdown": {
        "parts": [
          {
            "amount": 95.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "price_unit": 95.00,
      "product_medias": [],
      "product_sku": "99106066522",
      "product_title": "Turing Whiskey Tortoise",
      "promotions": [],
      "quantity": 1,
      "received_date":  nil,
      "refunds": [],
      "shipped_date":  nil,
      "shipping_price": 0.00,
      "shipping_price_additional_unit":  nil,
      "shipping_price_amount_breakdown": {
        "parts": [
          {
            "amount": 0.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "shipping_price_unit":  nil,
      "shipping_taxes": [
        {
          "amount": 0.00,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 0.00,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "taxes": [
        {
          "amount": 8.43,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 8.43,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "total_commission": 28.50,
      "total_price": 95.00
    },
    {
      "can_refund": false,
      "cancelations": [],
      "category_code": "SH1D4U8H5",
      "category_label": "W ITM EYE GLASSES",
      "commission_fee": 28.50,
      "commission_rate_vat": 0.0000,
      "commission_taxes": [
        {
          "amount": 0.00,
          "code": "TAXZERO",
          "rate": 0.0000
        }
      ],
      "commission_vat": 0.00,
      "created_date": "2020-05-20T17:01:55Z",
      "debited_date":  nil,
      "description":  nil,
      "last_updated_date": "2020-05-20T17:30:04Z",
      "offer_id": 2664,
      "offer_sku": "hamilton_c24_2",
      "offer_state_code": "11",
      "order_line_additional_fields": [],
      "order_line_id": "1589994114581-1589994114581-A-5",
      "order_line_index": 5,
      "order_line_state": "REFUSED",
      "order_line_state_reason_code": "REFUSED",
      "order_line_state_reason_label": "Rejected",
      "price": 95.00,
      "price_additional_info":  nil,
      "price_amount_breakdown": {
        "parts": [
          {
            "amount": 95.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "price_unit": 95.00,
      "product_medias": [],
      "product_sku": "99106064998",
      "product_title": "Hamilton Gold",
      "promotions": [],
      "quantity": 1,
      "received_date":  nil,
      "refunds": [],
      "shipped_date":  nil,
      "shipping_price": 0.00,
      "shipping_price_additional_unit":  nil,
      "shipping_price_amount_breakdown": {
        "parts": [
          {
            "amount": 0.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "shipping_price_unit":  nil,
      "shipping_taxes": [
        {
          "amount": 0.00,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 0.00,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "taxes": [
        {
          "amount": 8.43,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 8.43,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "total_commission": 28.50,
      "total_price": 95.00
    },
    {
      "can_refund": false,
      "cancelations": [],
      "category_code": "SH1D4U8H5",
      "category_label": "W ITM EYE GLASSES",
      "commission_fee": 28.50,
      "commission_rate_vat": 0.0000,
      "commission_taxes": [
        {
          "amount": 0.00,
          "code": "TAXZERO",
          "rate": 0.0000
        }
      ],
      "commission_vat": 0.00,
      "created_date": "2020-05-20T17:01:55Z",
      "debited_date":  nil,
      "description":  nil,
      "last_updated_date": "2020-05-20T17:30:04Z",
      "offer_id": 2664,
      "offer_sku": "hamilton_c24_2",
      "offer_state_code": "11",
      "order_line_additional_fields": [],
      "order_line_id": "1589994114581-1589994114581-A-6",
      "order_line_index": 6,
      "order_line_state": "REFUSED",
      "order_line_state_reason_code": "REFUSED",
      "order_line_state_reason_label": "Rejected",
      "price": 95.00,
      "price_additional_info":  nil,
      "price_amount_breakdown": {
        "parts": [
          {
            "amount": 95.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "price_unit": 95.00,
      "product_medias": [],
      "product_sku": "99106064998",
      "product_title": "Hamilton Gold",
      "promotions": [],
      "quantity": 1,
      "received_date":  nil,
      "refunds": [],
      "shipped_date":  nil,
      "shipping_price": 0.00,
      "shipping_price_additional_unit":  nil,
      "shipping_price_amount_breakdown": {
        "parts": [
          {
            "amount": 0.00,
            "commissionable": true,
            "debitable_from_customer": true,
            "payable_to_shop": true
          }
        ]
      },
      "shipping_price_unit":  nil,
      "shipping_taxes": [
        {
          "amount": 0.00,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 0.00,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "taxes": [
        {
          "amount": 8.43,
          "amount_breakdown": {
            "parts": [
              {
                "amount": 8.43,
                "commissionable": false,
                "debitable_from_customer": true,
                "payable_to_shop": false
              }
            ]
          },
          "code": "tax-amount"
        }
      ],
      "total_commission": 28.50,
      "total_price": 95.00
    }
  ],
  "order_state": "REFUSED",
  "order_state_reason_code":  nil,
  "order_state_reason_label":  nil,
  "paymentType": "Others",
  "payment_type": "Others",
  "payment_workflow": "PAY_ON_DELIVERY",
  "price": 570.00,
  "promotions": {
    "applied_promotions": [],
    "total_deduced_amount": 0
  },
  "quote_id":  nil,
  "shipping_carrier_code":  nil,
  "shipping_company":  nil,
  "shipping_deadline": "2020-05-25T17:01:55.611Z",
  "shipping_price": 0.00,
  "shipping_tracking":  nil,
  "shipping_tracking_url":  nil,
  "shipping_type_code": "SPST",
  "shipping_type_label": "SUREPOST",
  "shipping_zone_code": "US",
  "shipping_zone_label": "US Continental",
  "total_commission": 171.00,
  "total_price": 570.00
}