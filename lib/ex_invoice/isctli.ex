defmodule FacturXIsctli do
  @moduledoc """

  This module contains the structure for invoice items up to and including the ZUGFeRD/Factur-X profile EN16931.
  This is also the only task of this module.
  """
  defstruct [
    :b_associated_document_line_document_line_id,
    :b_associated_document_line_document_included_note_content,
    :b_specified_trade_product_global_id,
    :b_specified_trade_product_global_id_scheme_id,
    :e_specified_trade_product_seller_assigned_id,
    :e_specified_trade_product_buyer_assigned_id,
    :b_specified_trade_product_name,
    :e_specified_trade_product_description,
    :e_class_code_list_id,
    :e_class_code_list_version_id,
    :e_origin_trade_country_id,
    :e_buyer_order_referenced_document_line_id,
    :b_gross_price_product_trade_price_charge_amount,
    :b_gross_price_product_trade_price_basis_quantity,
    :b_gross_price_product_trade_price_basis_quantity_unit_code,
    :b_applied_trade_allowance_charge_price_allowance_charge_indicator_indicator,
    :b_applied_trade_allowance_charge_price_allowance_actual_amount,
    :b_net_price_product_trade_price_charge_amount,
    :b_net_price_product_trade_price_basis_quantity,
    :b_net_price_product_trade_price_basis_quantity_unit_code,
    :b_billed_quantity,
    :b_billed_quantity_unit_code,
    :b_specified_line_trade_settlement_applicable_trade_tax_category_code,
    :b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent,
    :b_specified_line_trade_settlement_billing_specified_period_start_date_time_date_time_string,
    :b_specified_line_trade_settlement_billing_specified_period_end_date_time_date_time_string,
    :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
    :e_specified_line_trade_settlement_additional_referenced_document_issuer_assigned_id,
    :e_specified_line_trade_settlement_additional_referenced_document_type_code,
    :e_specified_line_trade_settlement_additional_referenced_document_reference_type_code,
    :e_specified_line_trade_settlement_receivable_specified_trade_accounting_account_id,
    e_applicable_product_characteristic: [
      :e_applicable_product_characteristic_description,
      :e_value
    ],
    b_specified_trade_allowance_charge: [
      :b_specified_trade_allowance_charge_charge_indicator,
      :e_specified_trade_allowance_charge_calculation_percent,
      :e_specified_trade_allowance_charge_basis_amount,
      :b_specified_trade_allowance_charge_actual_amount,
      :b_specified_trade_allowance_charge_reason_code,
      :b_specified_trade_allowance_charge_reason
    ]
  ]
end
