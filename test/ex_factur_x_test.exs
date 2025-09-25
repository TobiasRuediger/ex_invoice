defmodule ExFacturXTest do
  use ExUnit.Case, async: true

  @moduledoc """

  This test case includes the following test cases
  test cases
  - Creation of a ZUGFeRD/Factur-X e-invoice in the BASIC profile with only the most necessary information
  - Creation of a ZUGFeRD/Factur-X e-invoice in the EN16931 profile with only the most necessary information
  - Creation of a ZUGFeRD/Factur-X e-invoice in the EN16931 profile with 2 items
  - Creation of a ZUGFeRD/Factur-X e-invoice in the EN16931 profile with different tax rates for the items
  - Checking the date verification function
  - Creation of a ZUGFeRD/Factur-X e-invoice in BASIC profile with surcharges and discounts
  - Creation of a ZUGFeRD/Factur-X e-invoice in BASIC profile plus list field (exchanged_document_included_note)
  - Checking the date check conversion
  - Checking the content check function for amount fields
  - Checking the code check function
  - Checking the mandatory field check function for main and items
  - Creating a ZUGFeRD/Factur-X e-invoice in the MINIMUM profile with only the most necessary information
  - Creation of a ZUGFeRD/Factur-X e-invoice in BASICWL profile with only the most necessary information
  - Test case for handling when the transfer path is empty

  The test cases may occur several times: with expected positive or expected negative feedback.
  """

  # test "BASIC min Factur-X " do

  @basic_min_item %FacturXIsctli{
    b_specified_trade_product_name: Faker.Commerce.product_name(),
    b_net_price_product_trade_price_charge_amount: 1.00,
    b_billed_quantity: 1,
    b_billed_quantity_unit_code: "H87",
    b_specified_line_trade_settlement_applicable_trade_tax_category_code: "S",
    b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    b_specified_trade_settlement_line_monetary_summation_line_total_amount: 1.00
  }

  @basic_min_item_with_charge %FacturXIsctli{
    b_specified_trade_product_name: Faker.Commerce.product_name(),
    b_net_price_product_trade_price_charge_amount: 1.00,
    b_billed_quantity: 1,
    b_billed_quantity_unit_code: "H87",
    b_specified_line_trade_settlement_applicable_trade_tax_category_code: "S",
    b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    b_specified_trade_settlement_line_monetary_summation_line_total_amount: 1.11,
    b_specified_trade_allowance_charge: [
      [
        # true Charge / false Allowance
        b_specified_trade_allowance_charge_charge_indicator: "true",
        b_specified_trade_allowance_charge_actual_amount: 0.10,
        b_specified_trade_allowance_charge_reason_code: nil,
        b_specified_trade_allowance_charge_reason: "a man of his word"
      ],
      # true Charge / false Allowance
      [
        b_specified_trade_allowance_charge_charge_indicator: "true",
        b_specified_trade_allowance_charge_actual_amount: 0.01,
        b_specified_trade_allowance_charge_reason_code: nil,
        b_specified_trade_allowance_charge_reason: "a man of his second word"
      ]
    ]
  }

  @basic_min_item_with_allowance %FacturXIsctli{
    b_specified_trade_product_name: Faker.Commerce.product_name(),
    b_net_price_product_trade_price_charge_amount: 1.00,
    b_billed_quantity: 1,
    b_billed_quantity_unit_code: "H87",
    b_specified_line_trade_settlement_applicable_trade_tax_category_code: "S",
    b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    b_specified_trade_settlement_line_monetary_summation_line_total_amount: 0.90,
    b_specified_trade_allowance_charge: [
      [
        # true Charge / false Allowance
        b_specified_trade_allowance_charge_charge_indicator: "false",
        b_specified_trade_allowance_charge_actual_amount: 0.10,
        b_specified_trade_allowance_charge_reason_code: nil,
        b_specified_trade_allowance_charge_reason: "a man of his word"
      ]
    ]
  }

  @en16931_min_item_characteristics_list %FacturXIsctli{
    b_specified_trade_product_name: Faker.Commerce.product_name(),
    b_net_price_product_trade_price_charge_amount: 1.00,
    b_billed_quantity: 1,
    b_billed_quantity_unit_code: "H87",
    b_specified_line_trade_settlement_applicable_trade_tax_category_code: "S",
    b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    b_specified_trade_settlement_line_monetary_summation_line_total_amount: 1.00,
    e_applicable_product_characteristic: [
      [
        e_applicable_product_characteristic_description: "description1",
        e_value: "value1"
      ],
      [e_applicable_product_characteristic_description: "description2", e_value: "value2"]
    ]
  }

  @basic_min_invalid_item %FacturXIsctli{
    b_specified_trade_product_name: Faker.Commerce.product_name(),
    b_net_price_product_trade_price_charge_amount: 1.00,
    b_billed_quantity: nil,
    b_billed_quantity_unit_code: "H87",
    b_specified_line_trade_settlement_applicable_trade_tax_category_code: "S",
    b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    b_specified_trade_settlement_line_monetary_summation_line_total_amount: 1.00
  }

  @basic_min %CreateFacturX{
    m_profil_factur_x: "BASIC",
    m_business_process_specified_document_context_parameter_id: "BasicMinTest",
    m_exchanged_document_id: 123,
    m_exchanged_document_type_code: 380,
    m_issue_date_time_date_time_string: "20250801",
    m_seller_trade_party_name: Faker.Company.name(),
    w_seller_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    m_seller_trade_party_postal_trade_address_country_id: "DE",
    m_specified_tax_registration_vat_identifier_id: "DE351547385",
    m_specified_tax_registration_vat_identifier_id_scheme_id: "VA",
    m_buyer_trade_party_name: Faker.Company.name(),
    w_buyer_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    w_buyer_trade_party_postal_trade_address_country_id: "DE",
    # not by cardinality constraint, but by the note
    w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string:
      "20250801",
    m_invoice_currency_code: "EUR",
    w_applicable_header_trade_settlement_applicable_trade_tax_category_code: "S",
    w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    # Committed by positive payment amount BR-CO-25
    w_specified_trade_payment_terms_description: "asap",
    m_tax_total_amount_invoice_total_amount_currency_id: "EUR",
    b_included_supply_chain_trade_line_item: [@basic_min_item]
  }

  @basic_min_with_note_content %CreateFacturX{
    m_profil_factur_x: "BASIC",
    m_business_process_specified_document_context_parameter_id: "BasicMinTest",
    m_exchanged_document_id: 123,
    m_exchanged_document_type_code: 380,
    m_issue_date_time_date_time_string: "20250801",
    m_seller_trade_party_name: Faker.Company.name(),
    w_seller_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    m_seller_trade_party_postal_trade_address_country_id: "DE",
    m_specified_tax_registration_vat_identifier_id: "DE351547385",
    m_specified_tax_registration_vat_identifier_id_scheme_id: "VA",
    m_buyer_trade_party_name: Faker.Company.name(),
    w_buyer_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    w_buyer_trade_party_postal_trade_address_country_id: "DE",
    # not by cardinality constraint, but by the note
    w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string:
      "20250801",
    m_invoice_currency_code: "EUR",
    w_applicable_header_trade_settlement_applicable_trade_tax_category_code: "S",
    w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    # Committed by positive payment amount BR-CO-25
    w_specified_trade_payment_terms_description: "asap",
    m_tax_total_amount_invoice_total_amount_currency_id: "EUR",
    b_included_supply_chain_trade_line_item: [@basic_min_item],
    w_exchanged_document_included_note: [
      [
        w_exchanged_document_included_note_content: "test",
        w_exchanged_document_included_note_subject_code: nil
      ],
      [
        w_exchanged_document_included_note_content: "test2",
        w_exchanged_document_included_note_subject_code: nil
      ]
    ]
  }

  @basicwl_min %CreateFacturX{
    m_profil_factur_x: "BASICWL",
    m_business_process_specified_document_context_parameter_id: "BasicMinTest",
    m_exchanged_document_id: 123,
    m_exchanged_document_type_code: 380,
    m_issue_date_time_date_time_string: "23.08.2025",
    m_seller_trade_party_name: Faker.Company.name(),
    w_seller_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    m_seller_trade_party_postal_trade_address_country_id: "DE",
    m_specified_tax_registration_vat_identifier_id: "DE351547385",
    m_specified_tax_registration_vat_identifier_id_scheme_id: "VA",
    m_buyer_trade_party_name: Faker.Company.name(),
    w_buyer_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    w_buyer_trade_party_postal_trade_address_country_id: "DE",
    # not by cardinality constraint, but by the note
    w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string:
      "20250801",
    m_invoice_currency_code: "EUR",
    w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount: 0.19,
    w_applicable_trade_tax_basis_amount: 1.00,
    w_applicable_header_trade_settlement_applicable_trade_tax_category_code: "S",
    w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    # Committed by positive payment amount BR-CO-25
    w_specified_trade_payment_terms_description: "asap",
    w_specified_trade_settlement_header_monetary_summation_line_total_amount: 1.00,
    m_tax_basis_total_amount: 1.00,
    m_tax_total_amount_invoice_total_amount: 0.19,
    m_specified_trade_settlement_header_monetary_summation_grand_total_amount: 1.19,
    m_tax_total_amount_invoice_total_amount_currency_id: "EUR",
    m_due_payable_amount: 1.19
  }

  @minimum_min %CreateFacturX{
    m_profil_factur_x: "MINIMUM",
    m_business_process_specified_document_context_parameter_id: "BasicMinTest",
    m_exchanged_document_id: 123,
    m_exchanged_document_type_code: 380,
    m_issue_date_time_date_time_string: "20250801",
    m_seller_trade_party_name: Faker.Company.name(),
    m_seller_trade_party_postal_trade_address_country_id: "DE",
    m_specified_tax_registration_vat_identifier_id: "DE351547385",
    m_specified_tax_registration_vat_identifier_id_scheme_id: "VA",
    m_buyer_trade_party_name: Faker.Company.name(),
    m_invoice_currency_code: "EUR",
    m_tax_basis_total_amount: 1.00,
    m_tax_total_amount_invoice_total_amount: 0.19,
    m_specified_trade_settlement_header_monetary_summation_grand_total_amount: 1.19,
    m_tax_total_amount_invoice_total_amount_currency_id: "EUR",
    m_due_payable_amount: 1.19
  }

  @en16931_min_item %FacturXIsctli{
    b_specified_trade_product_name: Faker.Commerce.product_name(),
    b_net_price_product_trade_price_charge_amount: 100_000.00,
    b_billed_quantity: 1,
    b_billed_quantity_unit_code: "H87",
    b_specified_line_trade_settlement_applicable_trade_tax_category_code: "S",
    # becomes a mandatory field under rule BR-S-8
    b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent: 7,
    b_specified_trade_settlement_line_monetary_summation_line_total_amount: 100_000.00
  }

  @en16931_min %CreateFacturX{
    m_profil_factur_x: "EN16931",
    m_business_process_specified_document_context_parameter_id: "EN16931MinTest",
    m_exchanged_document_id: "2025_Q3_" <> Integer.to_string(:rand.uniform(1_000_000)),
    m_exchanged_document_type_code: 380,
    m_issue_date_time_date_time_string: "20250801",
    m_seller_trade_party_name: Faker.Company.name(),
    w_seller_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    m_seller_trade_party_postal_trade_address_country_id: "DE",
    # is made mandatory by rule BR-AE-2
    m_specified_tax_registration_vat_identifier_id: "DE351547385",
    # is made mandatory by rule BR-AE-2
    m_specified_tax_registration_vat_identifier_id_scheme_id: "VA",
    m_buyer_trade_party_name: Faker.Company.name(),
    w_buyer_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    w_buyer_trade_party_postal_trade_address_country_id: "DE",
    w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string:
      "20250801",
    m_invoice_currency_code: "EUR",
    w_applicable_header_trade_settlement_applicable_trade_tax_category_code: "S",
    w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    # Committed by positive payment amount BR-CO-25
    w_specified_trade_payment_terms_description: "asap",
    m_tax_total_amount_invoice_total_amount_currency_id: "EUR",
    b_included_supply_chain_trade_line_item: [@en16931_min_item]
  }
  @en16931_2_items %CreateFacturX{
    m_profil_factur_x: "EN16931",
    m_business_process_specified_document_context_parameter_id: "EN16931MinTest",
    m_exchanged_document_id: "2025_Q3_" <> Integer.to_string(:rand.uniform(1_000_000)),
    m_exchanged_document_type_code: 380,
    m_issue_date_time_date_time_string: "20250801",
    m_seller_trade_party_name: Faker.Company.name(),
    w_seller_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    m_seller_trade_party_postal_trade_address_country_id: "DE",
    # is made mandatory by rule BR-AE-2
    m_specified_tax_registration_vat_identifier_id: "DE351547385",
    # is made mandatory by rule BR-AE-2
    m_specified_tax_registration_vat_identifier_id_scheme_id: "VA",
    m_buyer_trade_party_name: Faker.Company.name(),
    w_buyer_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    w_buyer_trade_party_postal_trade_address_country_id: "DE",
    w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string:
      "20250801",
    m_invoice_currency_code: "EUR",
    w_applicable_header_trade_settlement_applicable_trade_tax_category_code: "S",
    w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    # Committed by positive payment amount BR-CO-25
    w_specified_trade_payment_terms_description: "asap",
    m_tax_total_amount_invoice_total_amount_currency_id: "EUR",
    b_included_supply_chain_trade_line_item: [@en16931_min_item, @basic_min_item]
  }

  @basic %CreateFacturX{
    m_profil_factur_x: "BASIC",
    m_business_process_specified_document_context_parameter_id: "BasicTest",
    m_exchanged_document_id: 123,
    m_exchanged_document_type_code: 380,
    m_issue_date_time_date_time_string: "20250801",
    m_buyer_reference: nil,
    w_seller_trade_party_id: nil,
    w_seller_trade_party_global_id: nil,
    w_seller_trade_party_global_id_scheme_id: "0002",
    m_seller_trade_party_name: Faker.Company.name(),
    m_seller_trade_party_specified_legal_organization_id: nil,
    m_seller_trade_party_specified_legal_organization_id_scheme_id: nil,
    w_seller_trade_party_specified_legal_organization_trading_business_name: nil,
    w_seller_trade_party_postal_trade_address_postcode_code: nil,
    w_seller_trade_party_postal_trade_address_line_one: nil,
    w_seller_trade_party_postal_trade_address_line_two: nil,
    w_seller_trade_party_postal_trade_address_line_three: nil,
    w_seller_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    m_seller_trade_party_postal_trade_address_country_id: "DE",
    w_seller_trade_party_postal_trade_address_country_sub_division_name: nil,
    w_seller_trade_party_uri_universal_communication_uriid: nil,
    w_seller_trade_party_uri_universal_communication_uriid_scheme_id: nil,
    m_specified_tax_registration_vat_identifier_id: "DE351547385",
    m_specified_tax_registration_vat_identifier_id_scheme_id: "VA",
    w_buyer_trade_party_id: nil,
    w_buyer_trade_party_global_id: nil,
    w_buyer_trade_party_global_id_scheme_id: nil,
    m_buyer_trade_party_name: Faker.Company.name(),
    m_buyer_trade_party_specified_legal_organization_id: nil,
    m_buyer_trade_party_specified_legal_organization_id_scheme_id: nil,
    w_buyer_trade_party_postal_trade_address_postcode_code: nil,
    w_buyer_trade_party_postal_trade_address_line_one: nil,
    w_buyer_trade_party_postal_trade_address_line_two: nil,
    w_buyer_trade_party_postal_trade_address_line_three: nil,
    w_buyer_trade_party_postal_trade_address_city_name: Faker.Address.city(),
    w_buyer_trade_party_postal_trade_address_country_id: "DE",
    w_buyer_trade_party_postal_trade_address_country_sub_division_name: nil,
    w_buyer_trade_partyuri_universal_communication_uriid: nil,
    w_buyer_trade_partyuri_universal_communication_uriid_scheme_id: nil,
    w_buyer_trade_party_specified_tax_registration_id: nil,
    w_buyer_trade_party_specified_tax_registration_id_scheme_id: nil,
    w_seller_tax_representative_trade_party_name: nil,
    w_seller_tax_representative_trade_party_postal_trade_address_postcode_code: nil,
    w_seller_tax_representative_trade_party_postal_trade_address_line_one: nil,
    w_seller_tax_representative_trade_party_postal_trade_address_line_two: nil,
    w_seller_tax_representative_trade_party_postal_trade_address_line_three: nil,
    w_seller_tax_representative_trade_party_postal_trade_address_city_name: nil,
    w_seller_tax_representative_trade_party_postal_trade_address_country_id: nil,
    w_seller_tax_representative_trade_party_postal_trade_address_country_sub_division_name: nil,
    w_seller_tax_representative_trade_party_specified_tax_registration_id: nil,
    w_seller_tax_representative_trade_party_specified_tax_registration_id_scheme_id: nil,
    m_applicable_header_trade_agreement_buyer_order_referenced_document_issuer_assigned_id: nil,
    w_applicable_header_trade_agreement_contract_referenced_document_issuer_assigned_id: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_id: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_global_id: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_global_id_scheme_id: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_name: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_postcode_code:
      nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_one: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_two: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_three: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_city_name: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_country_id: nil,
    w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_country_sub_division_name:
      nil,
    # not by cardinality constraint, but by the note
    w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string:
      "20250801",
    w_applicable_header_trade_delivery_despatch_advice_referenced_document_issuer_assigned_id:
      nil,
    w_creditor_reference_id: nil,
    w_payment_reference: nil,
    w_tax_currency_code: nil,
    m_invoice_currency_code: "EUR",
    w_applicable_header_trade_settlement_payee_trade_party_id: nil,
    w_applicable_header_trade_settlement_payee_trade_party_global_id: nil,
    w_applicable_header_trade_settlement_payee_trade_party_global_id_scheme_id: nil,
    w_applicable_header_trade_settlement_payee_trade_party_name: nil,
    w_applicable_header_trade_settlement_payee_trade_party_specified_legal_organization_id: nil,
    w_applicable_header_trade_settlement_payee_trade_party_specified_legal_organization_id_scheme_id:
      nil,
    w_specified_trade_settlement_payment_means_type_code: nil,
    w_payer_party_debtor_financial_account_iban_id: nil,
    w_payee_party_creditor_financial_account_iban_id: nil,
    w_proprietary_id: nil,
    w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount: 0.19,
    w_applicable_header_trade_settlement_applicable_trade_tax_exemption_reason: nil,
    w_applicable_trade_tax_basis_amount: 1.00,
    w_applicable_header_trade_settlement_applicable_trade_tax_category_code: "S",
    w_applicable_header_trade_settlement_applicable_trade_tax_exemption_reason_code: nil,
    w_due_date_type_code: nil,
    w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent: 19,
    w_applicable_header_trade_settlement_billing_specified_period_start_date_time_date_time_string:
      nil,
    w_applicable_header_trade_settlement_billing_specified_period_end_date_time_date_time_string:
      nil,
    w_specified_trade_allowance_charge_document_level_allowances_charge_indicator: nil,
    w_specified_trade_allowance_charge_document_level_allowances_charge_indicator_indicator: nil,
    w_specified_trade_allowance_charge_document_level_allowances_calculation_percent: nil,
    w_specified_trade_allowance_charge_document_level_allowances_basis_amount: nil,
    w_specified_trade_allowance_charge_document_level_allowances_actual_amount: nil,
    w_specified_trade_allowance_charge_document_level_allowances_reason_code: nil,
    w_specified_trade_allowance_charge_document_level_allowances_reason: nil,
    w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_type_code:
      nil,
    w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_category_code:
      nil,
    w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_rate_applicable_percent:
      nil,
    w_specified_trade_allowance_charge_document_level_charges_charge_indicator_indicator: nil,
    w_specified_trade_allowance_charge_document_level_charges_calculation_percent: nil,
    w_specified_trade_allowance_charge_document_level_charges_basis_amount: nil,
    w_specified_trade_allowance_charge_document_level_charges_actual_amount: nil,
    w_specified_trade_allowance_charge_document_level_charges_reason_code: nil,
    w_specified_trade_allowance_charge_document_level_charges_reason: nil,
    w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_type_code: nil,
    w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_category_code:
      nil,
    w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_rate_applicable_percent:
      nil,
    # Committed by positive payment amount BR-CO-25
    w_specified_trade_payment_terms_description: "asap",
    w_due_date_date_time_date_time_string: nil,
    w_direct_debit_mandate_id: nil,
    w_specified_trade_settlement_header_monetary_summation_line_total_amount: 1.00,
    w_specified_trade_settlement_header_monetary_summation_charge_total_amount: nil,
    w_specified_trade_settlement_header_monetary_summation_allowance_total_amount: nil,
    m_tax_basis_total_amount: 1.00,
    m_tax_total_amount_invoice_total_amount: nil,
    m_tax_total_amount_invoice_total_amount_currency_id: nil,
    w_tax_total_amount_invoice_total_amount_invat: nil,
    w_tax_total_amount_invoice_total_amount_invat_currency_id: nil,
    m_specified_trade_settlement_header_monetary_summation_grand_total_amount: 1.00,
    w_total_prepaid_amount: nil,
    m_due_payable_amount: 1.19,
    w_applicable_header_trade_settlement_invoice_referenced_document_issuer_assigned_id: nil,
    w_applicable_header_trade_settlement_invoice_referenced_document_formatted_issue_date_time_date_time_string:
      nil,
    w_applicable_header_trade_settlement_receivable_specified_trade_accounting_account_id: nil,
    b_included_supply_chain_trade_line_item: [@basic_min_item],
    w_exchanged_document_included_note: [
      [
        w_exchanged_document_included_note_content: nil,
        w_exchanged_document_included_note_subject_code: nil
      ]
    ]
  }

  # START - Main Testcases for developemnt

  # Test the BASIC profile with minimum requirements
  test "BASIC min" do
    assert CreateFacturX.create_factur_x(
             @basic_min,
             Path.join("invoices_output", "BASIC_min_Factur_x.xml")
           ) ==
             {:ok, "XML was exported to invoices_output/BASIC_min_Factur_x.xml"}
  end

  # Test the EN16931 profile with minimum requirements
  test "EN16931 min" do
    assert CreateFacturX.create_factur_x(
             @en16931_min,
             Path.join("invoices_output", "EN16931_min_Factur_x.xml")
           ) ==
             {:ok, "XML was exported to invoices_output/EN16931_min_Factur_x.xml"}
  end

  # Test the EN16931 profile wirh 2 invoice items
  test "EN16931 with 2 items" do
    assert CreateFacturX.create_factur_x(
             @en16931_2_items,
             Path.join("invoices_output", "EN16931_2_items_Factur_x.xml")
           ) ==
             {:ok, "XML was exported to invoices_output/EN16931_2_items_Factur_x.xml"}
  end

  # END - Main Testcases for developemnt

  # START - Testcases for validate checks, 2 Wege Test , erstmal alles richtig dann validierung Prüfen ob es auf Fehler reagiert

  # Test the BASIC profile for mandatory fields
  test "check profil BASIC mandatory content - ok " do
    assert CreateFacturX.check_mandatory(@basic_min, ["m", "w", "b"]) ==
             {:ok, "all mandatory fields filled"}
  end

  # Test the EN16931 profile for mandatory fields
  test "check profil EN16931 mandatory content - ok " do
    assert CreateFacturX.check_mandatory(@en16931_min, ["m", "w", "b", "e"]) ==
             {:ok, "all mandatory fields filled"}
  end

  # Test the BASIC profile for mandatory fields
  test "check profil BASIC mandatory content - error" do
    invalid_basic_min = Map.put(@basic_min, :m_issue_date_time_date_time_string, nil)

    assert CreateFacturX.check_mandatory(invalid_basic_min, ["m", "w", "b"]) ==
             {:error, {[m_issue_date_time_date_time_string: nil], "Mandatory field not filled"}}
  end

  # Test the EN16931 profile for mandatory fields
  test "check profil EN16931 mandatory content - error" do
    invalid_en16931_min = Map.put(@en16931_min, :m_issue_date_time_date_time_string, nil)

    assert CreateFacturX.check_mandatory(invalid_en16931_min, ["m", "w", "b", "e"]) ==
             {:error, {[m_issue_date_time_date_time_string: nil], "Mandatory field not filled"}}
  end

  # Test the BASIC profile for mandatory fields
  test "check profil BASIC item mandatory content - error" do
    invalid_basic_min =
      Map.put(@basic_min, :b_included_supply_chain_trade_line_item, [@basic_min_invalid_item])

    assert CreateFacturX.check_mandatory(invalid_basic_min, ["m", "w", "b"]) ==
             {:error, {[{1, [:b_billed_quantity]}], "Mandatory item field not filled"}}
  end

  # Test the EN16931 profile for mandatory fields
  test "check profil EN16931 item mandatory content - error" do
    invalid_en16931_min =
      Map.put(@en16931_min, :b_included_supply_chain_trade_line_item, [@basic_min_invalid_item])

    assert CreateFacturX.check_mandatory(invalid_en16931_min, ["m", "w", "b", "e"]) ==
             {:error, {[{1, [:b_billed_quantity]}], "Mandatory item field not filled"}}
  end

  # Test the BASIC profile for content consistency
  test "check profil BASiC min content consistency - ok " do
    assert CreateFacturX.check_content_consistency(@basic_min, ["m", "w", "b"]) ==
             {:ok, "content is consistent"}
  end

  # Test the EN16931 profile for content consistency
  test "check profil EN16931 min content consistency - ok " do
    assert CreateFacturX.check_content_consistency(@en16931_min, ["m", "w", "b"]) ==
             {:ok, "content is consistent"}
  end

  # Test the BASIC profile for content consistency
  test "check profil BASiC min content consistency telnumber - error " do
    invalid_basic_min =
      Map.put(
        @en16931_min,
        :e_buyer_trade_party_defined_trade_contact_telephone_universal_communication_complete_number,
        "04321/12340"
      )

    assert CreateFacturX.check_content_consistency(invalid_basic_min, ["m", "w", "b"]) ==
             {:error,
              {[
                 :e_buyer_trade_party_defined_trade_contact_telephone_universal_communication_complete_number
               ], "Wrong field is filled"}}
  end

  # Test the BASIC profile for content consistency
  test "check profil BASiC min content consistency - error " do
    assert CreateFacturX.check_content_consistency(@basic_min, ["m", "w"]) ==
             {:error,
              {%{
                 items: [
                   {1,
                    [
                      :b_billed_quantity_unit_code,
                      :b_specified_line_trade_settlement_applicable_trade_tax_category_code,
                      :b_specified_trade_product_name
                    ]}
                 ]
               }, "Wrong item field is filled"}}
  end

  # Test the EN16931 profile for content consistency
  test "check profil EN16931 content consistency - error " do
    assert CreateFacturX.check_content_consistency(@en16931_min, ["m", "w"]) ==
             {:error,
              {%{
                 items: [
                   {1,
                    [
                      :b_billed_quantity_unit_code,
                      :b_specified_line_trade_settlement_applicable_trade_tax_category_code,
                      :b_specified_trade_product_name
                    ]}
                 ]
               }, "Wrong item field is filled"}}
  end

  # Test the BASIC profile for float content consistency
  test "check float content consistency - ok " do
    invalid_basic_min =
      Map.put(
        @basic_min,
        :w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount,
        2.22
      )

    assert CreateFacturX.check_float_content_consistency(invalid_basic_min, ["m", "w", "b"]) ==
             {:ok, "float content is consistent"}
  end

  # Test the BASIC profile for float content consistency
  test "check BASIC float content consistency - error " do
    invalid_basic_min =
      Map.put(
        @basic_min,
        :w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount,
        1
      )

    assert CreateFacturX.check_float_content_consistency(invalid_basic_min, ["m", "w", "b"]) ==
             {:error,
              {[:w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount],
               "Invalid float field"}}
  end

  # Test the EN16931 profile for float content consistency
  test "check EN16931 float content consistency - error " do
    invalid_en16931_min =
      Map.put(
        @en16931_min,
        :w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount,
        1
      )

    assert CreateFacturX.check_float_content_consistency(invalid_en16931_min, ["m", "w", "b", "e"]) ==
             {:error,
              {[:w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount],
               "Invalid float field"}}
  end

  # Test the BASIC profile for float content consistency decimal point
  test "check BASIC float content consistency decimal point- error " do
    invalid_basic_min =
      Map.put(
        @basic_min,
        :w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount,
        "2,22"
      )

    assert CreateFacturX.check_float_content_consistency(invalid_basic_min, ["m", "w", "b"]) ==
             {:error,
              {[:w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount],
               "Invalid float field"}}
  end

  # Test the EN16931 profile for float content consistency decimal point
  test "check EN16931 float content consistency decimal point- error " do
    invalid_en16931_min =
      Map.put(
        @en16931_min,
        :w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount,
        "2,22"
      )

    assert CreateFacturX.check_float_content_consistency(invalid_en16931_min, ["m", "w", "b", "e"]) ==
             {:error,
              {[:w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount],
               "Invalid float field"}}
  end

  # Test the BASIC profile for float content consistency thousand point
  test "check BASIC float content consistency thousand point- error " do
    invalid_basic_min =
      Map.put(
        @basic_min,
        :w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount,
        "2.222.22"
      )

    assert CreateFacturX.check_float_content_consistency(invalid_basic_min, ["m", "w", "b"]) ==
             {:error,
              {[:w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount],
               "Invalid float field"}}
  end

  # Test the BASIC profile for float content consistency thousand point
  test "check EN16931 float content consistency thousand point- error " do
    invalid_en16931_min =
      Map.put(
        @en16931_min,
        :w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount,
        "2.222.22"
      )

    assert CreateFacturX.check_float_content_consistency(invalid_en16931_min, ["m", "w", "b", "e"]) ==
             {:error,
              {[:w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount],
               "Invalid float field"}}
  end

  # Test the check_code_list Function
  test "check BASIC codelist - ok " do
    invalid_basic = Map.put(@basic, :w_seller_trade_party_global_id_scheme_id, "0002")

    assert CreateFacturX.check_code_list(invalid_basic, ["m", "w", "b"]) ==
             {:ok, "complied codelist"}
  end

  # Test the check_code_list Function
  test "check EN16931 codelist - ok " do
    invalid_en16931 = Map.put(@basic, :w_seller_trade_party_global_id_scheme_id, "0002")

    assert CreateFacturX.check_code_list(invalid_en16931, ["m", "w", "b", "e"]) ==
             {:ok, "complied codelist"}
  end

  # Test the check_code_list Function
  test "check BASIC codelist - error " do
    invalid_basic = Map.put(@basic, :w_seller_trade_party_global_id_scheme_id, "0000")

    assert CreateFacturX.check_code_list(invalid_basic, ["m", "w", "b"]) ==
             {:error, {[:w_seller_trade_party_global_id_scheme_id], "Invalid code fields"}}
  end

  # Test the check_code_list Function
  test "check EN16931 codelist - error " do
    invalid_en16931 = Map.put(@basic, :w_seller_trade_party_global_id_scheme_id, "0000")

    assert CreateFacturX.check_code_list(invalid_en16931, ["m", "w", "b"]) ==
             {:error, {[:w_seller_trade_party_global_id_scheme_id], "Invalid code fields"}}
  end

  # Test the check_parse_date Function 1
  test "Invalid date 1 - ok " do
    assert CreateFacturX.check_parse_date("20250825") == "20250825"
  end

  # Test the check_parse_date Function 2
  test "Invalid date 2 - ok " do
    assert CreateFacturX.check_parse_date("25.08.2025") == "20250825"
  end

  # Test the check_parse_date Function 3
  test "Invalid date 3 - ok " do
    assert CreateFacturX.check_parse_date("25-08-2025") == "20250825"
  end

  # Test the check_parse_date Function 4
  test "Invalid date 4 - ok " do
    assert CreateFacturX.check_parse_date("25082025") == "20250825"
  end

  # Initial test profil basic minimum with empty path
  test "BASIC min with empty path" do
    assert CreateFacturX.create_factur_x(@basic_min, "") ==
             {:ok, "XML was exported to factur-x.xml"}
  end

  # Test nil profil
  test "check nil profil - error " do
    invalid_basic = Map.put(@basic_min, :m_profil_factur_x, nil)

    assert CreateFacturX.create_factur_x(
             invalid_basic,
             Path.join("invoices_output", "BASIC_min_Factur_x.xml")
           ) ==
             {:error,
              "XML invoices_output/BASIC_min_Factur_x.xml not created - No profile provided"}
  end

  # Test the BASIC profile with minimum requirements plus List field
  test "BASIC min wih list field" do
    assert CreateFacturX.create_factur_x(
             @basic_min_with_note_content,
             Path.join("invoices_output", "BASIC_min_Factur_x_Content_note.xml")
           ) ==
             {:ok,
              "XML was exported to invoices_output/BASIC_min_Factur_x_Content_note.xml"}
  end

  # Test the EN16931 profile with item and more than 1 product characteristics
  test "check profil EN16931 item with  more than 1 product characteristics - ok" do
    valid_en16931_min =
      Map.put(@en16931_min, :b_included_supply_chain_trade_line_item, [
        @en16931_min_item_characteristics_list
      ])

    assert CreateFacturX.create_factur_x(
             valid_en16931_min,
             Path.join("invoices_output", "EN16931_min_Factur_x_product_characteristics.xml")
           ) ==
             {:ok,
              "XML was exported to invoices_output/EN16931_min_Factur_x_product_characteristics.xml"}
  end

  # Test the BASIC profile with minimum requirements plus item Charge
  test "BASIC min with item Charge" do
    valid_basic_min =
      Map.put(@basic_min, :b_included_supply_chain_trade_line_item, [@basic_min_item_with_charge])

    assert CreateFacturX.create_factur_x(
             valid_basic_min,
             Path.join("invoices_output", "BASIC_min_Factur_x_Charge.xml")
           ) ==
             {:ok, "XML was exported to invoices_output/BASIC_min_Factur_x_Charge.xml"}
  end

  # Test the BASIC profile with minimum requirements plus item Allowance
  test "BASIC min with item Allowance" do
    valid_basic_min =
      Map.put(@basic_min, :b_included_supply_chain_trade_line_item, [
        @basic_min_item_with_allowance
      ])

    assert CreateFacturX.create_factur_x(
             valid_basic_min,
             Path.join("invoices_output", "BASIC_min_Factur_x_Allowance.xml")
           ) ==
             {:ok, "XML was exported to invoices_output/BASIC_min_Factur_x_Allowance.xml"}
  end

  # Test the MINIMUM profile with minimum requirements
  test "MINIMUM min" do
    assert CreateFacturX.create_factur_x(
             @minimum_min,
             Path.join("invoices_output", "MINIMUM_min_Factur_x.xml")
           ) ==
             {:ok, "XML was exported to invoices_output/MINIMUM_min_Factur_x.xml"}
  end

  # Test the MINIMUM profile for mandatory fields
  test "check profil MINIMUM mandatory content - ok " do
    assert CreateFacturX.check_mandatory(@minimum_min, ["m"]) ==
             {:ok, "all mandatory fields filled"}
  end

  # Test the MINIMUM profile for mandatory fields
  test "check profil MINIMUM mandatory content - error " do
    invalid_minimum_min = Map.put(@minimum_min, :m_issue_date_time_date_time_string, nil)

    assert CreateFacturX.check_mandatory(invalid_minimum_min, ["m"]) ==
             {:error, {[m_issue_date_time_date_time_string: nil], "Mandatory field not filled"}}
  end

  # Test the BASICWL profile for mandatory fields
  test "check profil BASICWL mandatory content - error " do
    assert CreateFacturX.check_mandatory(@basicwl_min, ["m", "w", "b"]) ==
             {
               :error,
               {[
                  {1,
                   [
                     :b_specified_trade_product_name,
                     :b_net_price_product_trade_price_charge_amount,
                     :b_billed_quantity,
                     :b_billed_quantity_unit_code,
                     :b_specified_line_trade_settlement_applicable_trade_tax_category_code,
                     :b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent,
                     :b_specified_trade_settlement_line_monetary_summation_line_total_amount
                   ]}
                ], "Mandatory item field not filled"}
             }
  end

  # Test the MINIMUM profile for content consistency
  test "check profil MINIMUM content consistency - ok " do
    assert CreateFacturX.check_content_consistency(@minimum_min, ["m"]) ==
             {:ok, "content is consistent"}
  end

  # Test the MINIMUM profile for float content consistency
  test "check profil MINIMUM float content consistency - ok " do
    assert CreateFacturX.check_float_content_consistency(@minimum_min, ["m"]) ==
             {:ok, "float content is consistent"}
  end

  # Test the BASICWL profile with minimum requirements
  test "BASICWL min" do
    assert CreateFacturX.create_factur_x(
             @basicwl_min,
             Path.join("invoices_output", "BASICWL_min_Factur_x.xml")
           ) ==
             {:ok, "XML was exported to invoices_output/BASICWL_min_Factur_x.xml"}
  end

  # Test the BASICWL profile for mandatory fields
  test "check profil BASICWL mandatory content - ok " do
    assert CreateFacturX.check_mandatory(@basicwl_min, ["m", "w"]) ==
             {:ok, "all mandatory fields filled"}
  end

  # Test the BASICWL profile for mandatory fields
  test "check profil BASIC WL mandatory content - error " do
    invalid_basicwl_min = Map.put(@basicwl_min, :m_issue_date_time_date_time_string, nil)

    assert CreateFacturX.check_mandatory(invalid_basicwl_min, ["m", "w"]) ==
             {:error, {[m_issue_date_time_date_time_string: nil], "Mandatory field not filled"}}
  end

  # Test the BASICWL profile for content consistency
  test "check profil BASICWL content consistency - ok " do
    assert CreateFacturX.check_content_consistency(@basicwl_min, ["m", "w"]) ==
             {:ok, "content is consistent"}
  end

  # Test the BASICWL profile for float content consistency
  test "check profil BASICWL float content consistency - ok " do
    assert CreateFacturX.check_float_content_consistency(@basicwl_min, ["m", "w"]) ==
             {:ok, "float content is consistent"}
  end
end
