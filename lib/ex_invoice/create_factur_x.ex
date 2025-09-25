defmodule CreateFacturX do
  import XmlBuilder

  @moduledoc """
  ## General:
  This module uses the invoice data provided to create a legally compliant and valid e-invoice in accordance with the ZUGFeRD/Factur-X standard.
  In addition to the invoice data, the profile to be created is also provided.
  This prototype is capable of creating ZUGFeRD/Factur-X e-invoices up to and including profile EN16931.

  Additional notes have been added to the program code to improve comprehensibility.

  ## Naming convention:
  This structure is based on the official Cross Industry Invoice field names. In some cases, a full fqdn is deliberately used to avoid confusion with the variables.
  The prefix of the variable names and function names indicates the smallest possible profile.
  This means:
  Meaning:
  The abbreviations are: MINIMUM = “m”, BASIC WL = “w”, BASIC = “b”, EN 16931 = ‘e’ and EXTENDED = “x”.
  If a variable begins with “m,” it can be used in all larger profiles.
  If it begins with “b,” it applies to BASIC, EN 16931, and EXTENDED, but not to MINIMUM and BASIC WL.

  ## Data transfer:
  The struct contains all variables that can occur in the EN16931 profile for creating an e-invoice.
  The exception is “guideline_specified_document_context_parameter,” which is determined based on the transferred target profile.
  The transferred target profile is also the only additional parameter that has been added.
  The invoice item data is integrated with the struct from FacturXIsctli via the invoice item node “b_included_supply_chain_trade_line_item”.

  ## Program flow:

  After the data has been transferred to the module via the struct, this data is checked and then assigned to its
  respective XML elements. Once this has been done, all unfilled elements are removed again. The parent variable was chosen because
  checking the data each time the elements were filled would have generated unnecessary program code, which is now done in a compact manner.
  Finally, the XML file is generated.

  Data transfer -> Checks -> Creation of XML file -> Removal of empty XML elements -> Generation of XML file.

  Program structure:

  The process of creating the XML file is based on the XML tree structure, whereby each node has its own function.
  """
  # Struct with invoice data for ZUGFeRD/Factur-X up to and including profile EN16931
  defstruct [
    :m_profil_factur_x,
    :m_business_process_specified_document_context_parameter_id,
    :m_exchanged_document_id,
    :m_exchanged_document_type_code,
    :m_issue_date_time_date_time_string,
    :m_buyer_reference,
    :w_seller_trade_party_id,
    :w_seller_trade_party_global_id,
    :w_seller_trade_party_global_id_scheme_id,
    :m_seller_trade_party_name,
    :e_seller_trade_party_description,
    :m_seller_trade_party_specified_legal_organization_id,
    :m_seller_trade_party_specified_legal_organization_id_scheme_id,
    :w_seller_trade_party_specified_legal_organization_trading_business_name,
    :e_seller_trade_party_defined_trade_contact_person_name,
    :e_seller_trade_party_defined_trade_contact_department_name,
    :e_seller_trade_party_defined_trade_contact_telephone_universal_communication_complete_number,
    :e_seller_trade_party_defined_trade_contact_emailuri_universal_communication_uriid,
    :w_seller_trade_party_postal_trade_address_postcode_code,
    :w_seller_trade_party_postal_trade_address_line_one,
    :w_seller_trade_party_postal_trade_address_line_two,
    :w_seller_trade_party_postal_trade_address_line_three,
    :w_seller_trade_party_postal_trade_address_city_name,
    :m_seller_trade_party_postal_trade_address_country_id,
    :w_seller_trade_party_postal_trade_address_country_sub_division_name,
    :w_seller_trade_party_uri_universal_communication_uriid,
    :w_seller_trade_party_uri_universal_communication_uriid_scheme_id,
    :m_specified_tax_registration_vat_identifier_id,
    :m_specified_tax_registration_vat_identifier_id_scheme_id,
    :e_specified_tax_registration_local_tax_id,
    :e_specified_tax_registration_local_tax_id_scheme_id,
    :w_buyer_trade_party_id,
    :w_buyer_trade_party_global_id,
    :w_buyer_trade_party_global_id_scheme_id,
    :m_buyer_trade_party_name,
    :m_buyer_trade_party_specified_legal_organization_id,
    :m_buyer_trade_party_specified_legal_organization_id_scheme_id,
    :e_buyer_trade_party_specified_legal_organization_trading_business_name,
    :e_buyer_trade_party_defined_trade_contact_person_name,
    :e_buyer_trade_party_defined_trade_contact_department_name,
    :e_buyer_trade_party_defined_trade_contact_telephone_universal_communication,
    :e_buyer_trade_party_defined_trade_contact_telephone_universal_communication_complete_number,
    :e_buyer_trade_party_defined_trade_contact_emailuri_universal_communication,
    :e_buyer_trade_party_defined_trade_contact_emailuri_universal_communication_uriid,
    :w_buyer_trade_party_postal_trade_address_postcode_code,
    :w_buyer_trade_party_postal_trade_address_line_one,
    :w_buyer_trade_party_postal_trade_address_line_two,
    :w_buyer_trade_party_postal_trade_address_line_three,
    :w_buyer_trade_party_postal_trade_address_city_name,
    :w_buyer_trade_party_postal_trade_address_country_id,
    :w_buyer_trade_party_postal_trade_address_country_sub_division_name,
    :w_buyer_trade_partyuri_universal_communication_uriid,
    :w_buyer_trade_partyuri_universal_communication_uriid_scheme_id,
    :w_buyer_trade_party_specified_tax_registration_id,
    :w_buyer_trade_party_specified_tax_registration_id_scheme_id,
    :w_seller_tax_representative_trade_party_name,
    :w_seller_tax_representative_trade_party_postal_trade_address_postcode_code,
    :w_seller_tax_representative_trade_party_postal_trade_address_line_one,
    :w_seller_tax_representative_trade_party_postal_trade_address_line_two,
    :w_seller_tax_representative_trade_party_postal_trade_address_line_three,
    :w_seller_tax_representative_trade_party_postal_trade_address_city_name,
    :w_seller_tax_representative_trade_party_postal_trade_address_country_id,
    :w_seller_tax_representative_trade_party_postal_trade_address_country_sub_division_name,
    :w_seller_tax_representative_trade_party_specified_tax_registration_id,
    :w_seller_tax_representative_trade_party_specified_tax_registration_id_scheme_id,
    :e_applicable_header_trade_agreement_seller_order_referenced_document_issuer_assigned_id,
    :m_applicable_header_trade_agreement_buyer_order_referenced_document_issuer_assigned_id,
    :w_applicable_header_trade_agreement_contract_referenced_document_issuer_assigned_id,
    :e_additional_referenced_document_additional_supporting_documents_issuer_assigned_id,
    :e_additional_referenced_document_additional_supporting_documents_uriid,
    :e_additional_referenced_document_additional_supporting_documents_type_code,
    :e_additional_referenced_document_additional_supporting_documents_name,
    :e_additional_referenced_document_additional_supporting_documents_attachment_binary_object_mime_code,
    :e_additional_referenced_document_additional_supporting_documents_attachment_binary_object_filename,
    :e_additional_referenced_document_tender_lot_issuer_assigned_id,
    :e_additional_referenced_document_tender_lot_type_code,
    :e_additional_referenced_document_invoiced_object_issuer_assigned_id,
    :e_additional_referenced_document_invoiced_object_type_code,
    :e_additional_referenced_document_invoiced_object_reference_type_code,
    :e_specified_procuring_project_id,
    :e_specified_procuring_project_name,
    :w_applicable_header_trade_delivery_ship_to_trade_party_id,
    :w_applicable_header_trade_delivery_ship_to_trade_party_global_id,
    :w_applicable_header_trade_delivery_ship_to_trade_party_global_id_scheme_id,
    :w_applicable_header_trade_delivery_ship_to_trade_party_name,
    :w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_postcode_code,
    :w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_one,
    :w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_two,
    :w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_three,
    :w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_city_name,
    :w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_country_id,
    :w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_country_sub_division_name,
    :w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string,
    :w_applicable_header_trade_delivery_despatch_advice_referenced_document_issuer_assigned_id,
    :e_applicable_header_trade_delivery_receiving_advice_referenced_document_issuer_assigned_id,
    :w_creditor_reference_id,
    :w_payment_reference,
    :w_tax_currency_code,
    :m_invoice_currency_code,
    :w_applicable_header_trade_settlement_payee_trade_party_id,
    :w_applicable_header_trade_settlement_payee_trade_party_global_id,
    :w_applicable_header_trade_settlement_payee_trade_party_global_id_scheme_id,
    :w_applicable_header_trade_settlement_payee_trade_party_name,
    :w_applicable_header_trade_settlement_payee_trade_party_specified_legal_organization_id,
    :w_applicable_header_trade_settlement_payee_trade_party_specified_legal_organization_id_scheme_id,
    :w_specified_trade_settlement_payment_means_type_code,
    :e_information,
    :e_applicable_trade_settlement_financial_card_id,
    :e_cardholder_name,
    :w_payer_party_debtor_financial_account_iban_id,
    :w_payee_party_creditor_financial_account_iban_id,
    :e_account_name,
    :w_proprietary_id,
    :e_payee_specified_creditor_financial_institution,
    :e_bic_id,
    :w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount,
    :w_applicable_header_trade_settlement_applicable_trade_tax_exemption_reason,
    :w_applicable_trade_tax_basis_amount,
    :w_applicable_header_trade_settlement_applicable_trade_tax_category_code,
    :w_applicable_header_trade_settlement_applicable_trade_tax_exemption_reason_code,
    :e_date_string,
    :w_due_date_type_code,
    :w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent,
    :w_applicable_header_trade_settlement_billing_specified_period_start_date_time_date_time_string,
    :w_applicable_header_trade_settlement_billing_specified_period_end_date_time_date_time_string,
    :w_specified_trade_allowance_charge_document_level_allowances_charge_indicator,
    :w_specified_trade_allowance_charge_document_level_allowances_charge_indicator_indicator,
    :w_specified_trade_allowance_charge_document_level_allowances_calculation_percent,
    :w_specified_trade_allowance_charge_document_level_allowances_basis_amount,
    :w_specified_trade_allowance_charge_document_level_allowances_actual_amount,
    :w_specified_trade_allowance_charge_document_level_allowances_reason_code,
    :w_specified_trade_allowance_charge_document_level_allowances_reason,
    :w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_type_code,
    :w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_category_code,
    :w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_rate_applicable_percent,
    :w_specified_trade_allowance_charge_document_level_charges_charge_indicator_indicator,
    :w_specified_trade_allowance_charge_document_level_charges_calculation_percent,
    :w_specified_trade_allowance_charge_document_level_charges_basis_amount,
    :w_specified_trade_allowance_charge_document_level_charges_actual_amount,
    :w_specified_trade_allowance_charge_document_level_charges_reason_code,
    :w_specified_trade_allowance_charge_document_level_charges_reason,
    :w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_type_code,
    :w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_category_code,
    :w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_rate_applicable_percent,
    :w_specified_trade_payment_terms_description,
    :w_due_date_date_time_date_time_string,
    :w_direct_debit_mandate_id,
    :w_specified_trade_settlement_header_monetary_summation_line_total_amount,
    :w_specified_trade_settlement_header_monetary_summation_charge_total_amount,
    :w_specified_trade_settlement_header_monetary_summation_allowance_total_amount,
    :m_tax_basis_total_amount,
    :m_tax_total_amount_invoice_total_amount,
    :m_tax_total_amount_invoice_total_amount_currency_id,
    :w_tax_total_amount_invoice_total_amount_invat,
    :w_tax_total_amount_invoice_total_amount_invat_currency_id,
    :e_rounding_amount,
    :m_specified_trade_settlement_header_monetary_summation_grand_total_amount,
    :w_total_prepaid_amount,
    :m_due_payable_amount,
    :w_applicable_header_trade_settlement_invoice_referenced_document_issuer_assigned_id,
    :w_applicable_header_trade_settlement_invoice_referenced_document_formatted_issue_date_time_date_time_string,
    :w_applicable_header_trade_settlement_receivable_specified_trade_accounting_account_id,
    b_included_supply_chain_trade_line_item: [%FacturXIsctli{}],
    w_exchanged_document_included_note: [
      :w_exchanged_document_included_note_content,
      :w_exchanged_document_included_note_subject_code
    ]
  ]

  # List for code verification according to ISOIEC6523
  @code_list_iso_iec_6523 [
    "0002",
    "0003",
    "0004",
    "0005",
    "0006",
    "0007",
    "0008",
    "0009",
    "0010",
    "0011",
    "0012",
    "0013",
    "0014",
    "0015",
    "0016",
    "0017",
    "0018",
    "0019",
    "0020",
    "0021",
    "0022",
    "0023",
    "0024",
    "0025",
    "0026",
    "0027",
    "0028",
    "0029",
    "0030",
    "0031",
    "0032",
    "0033",
    "0034",
    "0035",
    "0036",
    "0037",
    "0038",
    "0039",
    "0040",
    "0041",
    "0042",
    "0043",
    "0044",
    "0045",
    "0046",
    "0047",
    "0048",
    "0049",
    "0050",
    "0051",
    "0052",
    "0053",
    "0054",
    "0055",
    "0056",
    "0057",
    "0058",
    "0059",
    "0060",
    "0061",
    "0062",
    "0063",
    "0064",
    "0065",
    "0066",
    "0067",
    "0068",
    "0069",
    "0070",
    "0071",
    "0072",
    "0073",
    "0074",
    "0075",
    "0076",
    "0077",
    "0078",
    "0079",
    "0080",
    "0081",
    "0082",
    "0083",
    "0084",
    "0085",
    "0086",
    "0087",
    "0088",
    "0089",
    "0090",
    "0091",
    "0093",
    "0094",
    "0095",
    "0096",
    "0097",
    "0098",
    "0099",
    "0100",
    "0101",
    "0102",
    "0104",
    "0105",
    "0106",
    "0107",
    "0108",
    "0109",
    "0110",
    "0111",
    "0112",
    "0113",
    "0114",
    "0115",
    "0116",
    "0117",
    "0118",
    "0119",
    "0120",
    "0121",
    "0122",
    "0123",
    "0124",
    "0125",
    "0126",
    "0127",
    "0128",
    "0129",
    "0130",
    "0131",
    "0132",
    "0133",
    "0134",
    "0135",
    "0136",
    "0137",
    "0138",
    "0139",
    "0140",
    "0141",
    "0142",
    "0143",
    "0144",
    "0145",
    "0146",
    "0147",
    "0148",
    "0149",
    "0150",
    "0151",
    "0152",
    "0153",
    "0154",
    "0155",
    "0156",
    "0157",
    "0158",
    "0159",
    "0160",
    "0161",
    "0162",
    "0163",
    "0164",
    "0165",
    "0166",
    "0167",
    "0168",
    "0169",
    "0170",
    "0171",
    "0172",
    "0173",
    "0174",
    "0175",
    "0176",
    "0177",
    "0178",
    "0179",
    "0180",
    "0183",
    "0184",
    "0185",
    "0186",
    "0187",
    "0188",
    "0189",
    "0190",
    "0191",
    "0192",
    "0193",
    "0194",
    "0195",
    "0196",
    "0197",
    "0198",
    "0199",
    "0200",
    "0201",
    "0202",
    "0203",
    "0204",
    "0205",
    "0206",
    "0207",
    "0208",
    "0209",
    "0210",
    "0211",
    "0212",
    "0213",
    "0214",
    "0215",
    "0216",
    "XR01",
    "XR02",
    "XR03",
    "XR03"
  ]

  # Main Funktion
  def create_factur_x(%CreateFacturX{} = factur_x, path) do
    if is_nil(factur_x.m_profil_factur_x) do
      {:error, "XML #{path} not created - No profile provided"}
    else
      # Treating variables with the smallest possible profile makes it possible to check filled variables for consistency with the transferred profile
      # The permissible abbreviations are determined based on the submitted profile.
      profil_identifier =
        case factur_x.m_profil_factur_x do
          "MINIMUM" -> ["m"]
          "BASICWL" -> ["m", "w"]
          "BASIC" -> ["m", "w", "b"]
          "EN16931" -> ["m", "w", "b", "e"]
        end

      # Checking the data content
      with {:ok, "all mandatory fields filled"} <- check_mandatory(factur_x, profil_identifier),
           {:ok, "content is consistent"} <-
             check_content_consistency(factur_x, profil_identifier),
           {:ok, "float content is consistent"} <-
             check_float_content_consistency(factur_x, profil_identifier),
           {:ok, "complied codelist"} <- check_code_list(factur_x, profil_identifier) do
        # Start creating XML file

        # The purpose of the following functions and their subfunctions is self-explanatory from their names.
        xml_content =
          XmlBuilder.document(
            # solid block
            :"rsm:CrossIndustryInvoice",
            [
              {"xmlns:rsm", "urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100"},
              {"xmlns:qdt", "urn:un:unece:uncefact:data:standard:QualifiedDataType:100"},
              {"xmlns:ram",
               "urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"},
              {"xmlns:xsi", "http://www.w3.org/2001/XMLSchema"},
              {"xmlns:udt", "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100"}
            ],
            [
              create_m_exchanged_document_context(factur_x),
              create_m_exchanged_document(factur_x),
              create_m_supply_chain_trade_transaction(factur_x)
            ]
          )
          # Not nested for clarity of the program flow, therefore with pipe
          |> remove_empty_elements()
          |> XmlBuilder.generate()

        # End creating XML file
        path = if path == "", do: "factur-x.xml", else: path

        File.write!(path, xml_content)
        {:ok, "XML was exported to #{path}"}
      else
        {:error, reason} ->
          #   IO.puts(" XML #{path} wurde nicht erstellt. Grund: #{inspect(reason)}") # aktivate for better testing feedbacks
          {:error, "XML #{path} was not created see previous messages "}
      end
    end
  end

  # start checks #
  # Start check mandatory #
  # Check whether all fields required for the profile have been filled in; if not, return an error.
  # The required data is identified by the abbreviation at the beginning with reference to the transferred profile.

  # specify which fields should be checked
  def check_mandatory(factur_x, profil_identifier) do
    mandatory_fields = [
      {:m_profil_factur_x, factur_x.m_profil_factur_x},
      {:m_business_process_specified_document_context_parameter_id,
       factur_x.m_business_process_specified_document_context_parameter_id},
      {:m_exchanged_document_id, factur_x.m_exchanged_document_id},
      {:m_exchanged_document_type_code, factur_x.m_exchanged_document_type_code},
      {:m_issue_date_time_date_time_string, factur_x.m_issue_date_time_date_time_string},
      {:m_seller_trade_party_name, factur_x.m_seller_trade_party_name},
      {:w_seller_trade_party_postal_trade_address_city_name,
       factur_x.w_seller_trade_party_postal_trade_address_city_name},
      {:m_seller_trade_party_postal_trade_address_country_id,
       factur_x.m_seller_trade_party_postal_trade_address_country_id},
      {:m_specified_tax_registration_vat_identifier_id,
       factur_x.m_specified_tax_registration_vat_identifier_id},
      {:m_specified_tax_registration_vat_identifier_id_scheme_id,
       factur_x.m_specified_tax_registration_vat_identifier_id_scheme_id},
      {:m_buyer_trade_party_name, factur_x.m_buyer_trade_party_name},
      {:w_buyer_trade_party_postal_trade_address_city_name,
       factur_x.w_buyer_trade_party_postal_trade_address_city_name},
      {:w_buyer_trade_party_postal_trade_address_country_id,
       factur_x.w_buyer_trade_party_postal_trade_address_country_id},
      {:w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string,
       factur_x.w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string},
      {:m_invoice_currency_code, factur_x.m_invoice_currency_code},
      {:w_applicable_header_trade_settlement_applicable_trade_tax_category_code,
       factur_x.w_applicable_header_trade_settlement_applicable_trade_tax_category_code},
      {:w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent,
       factur_x.w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent},
      {:w_specified_trade_payment_terms_description,
       factur_x.w_specified_trade_payment_terms_description},
      {:m_tax_total_amount_invoice_total_amount_currency_id,
       factur_x.m_tax_total_amount_invoice_total_amount_currency_id}
    ]

    # Filter out only fields that are nil or empty
    # the field belongs to the list
    empty_fields =
      Enum.filter(mandatory_fields, fn {key, value} ->
        # does the field match the profile
        Enum.any?(profil_identifier, fn identifier ->
          # If the field belongs to the profile and is empty, then error
          String.starts_with?(Atom.to_string(key), identifier)
        end) and (is_nil(value) or value == "")
      end)

    if empty_fields != [] do
      {:error, {empty_fields, "Mandatory field not filled"}}
    else
      mandatory_item_fields = [
        :b_specified_trade_product_name,
        :b_net_price_product_trade_price_charge_amount,
        :b_billed_quantity,
        :b_billed_quantity_unit_code,
        :b_specified_line_trade_settlement_applicable_trade_tax_category_code,
        :b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent,
        :b_specified_trade_settlement_line_monetary_summation_line_total_amount
      ]

      # Start check mandatory item fields
      # Check whether all item fields required for the profile are filled in; if not, return an error.
      # create a list starting with 1
      empty_item_fields =
        Enum.with_index(factur_x.b_included_supply_chain_trade_line_item, 1)
        # go through the list
        |> Enum.map(fn {isctli, idx} ->
          # the field belongs to the list
          missing_fields =
            Enum.filter(mandatory_item_fields, fn field ->
              # does the field match the profile
              Enum.any?(profil_identifier, fn identifier ->
                # If the field belongs to the profile and is empty, then error
                String.starts_with?(Atom.to_string(field), identifier)
              end) and (is_nil(Map.get(isctli, field)) or Map.get(isctli, field) == "")
            end)

          {idx, missing_fields}
        end)
        |> Enum.reject(fn {_idx, missing} -> missing == [] end)

      if empty_item_fields == [] do
        {:ok, "all mandatory fields filled"}
      else
        {:error, {empty_item_fields, "Mandatory item field not filled"}}
      end
    end
  end

  # Start check content consistency
  # Check whether variables are filled that are not permitted for the transferred profile.
  # Example: Profile BASIC is transferred and a variable that
  # is only valid from EN16931 onwards is filled; this is detected and an error is issued.
  def check_content_consistency(factur_x, profil_identifier) do
    wrong_filled_fields =
      factur_x
      |> Map.from_struct()
      # go through the list
      |> Enum.filter(fn {key, value} ->
        # Are there any fields filled in that do not match the profile
        Enum.all?(profil_identifier, fn identifier ->
          not String.starts_with?(Atom.to_string(key), identifier)
        end) and not (is_nil(value) or value == "")
      end)
      |> Enum.map(fn {key, _} -> key end)

    # Exclude certain list fields from the check
    # Special rule for minimum: the list values are not nil
    cleaned_wrong_filled_fields =
      if profil_identifier in ["m", :m] or
           (is_list(profil_identifier) and "m" in profil_identifier) do
        Enum.reject(wrong_filled_fields, fn key ->
          #
          key in [:w_exchanged_document_included_note, :b_included_supply_chain_trade_line_item]
        end)
      else
        wrong_filled_fields
      end

    # Ensure that alphabetical order is always returned, which is important for test cases.
    sorted_wrong_filled_fields =
      cleaned_wrong_filled_fields
      # Atome → Strings
      |> Enum.map(&Atom.to_string/1)
      |> Enum.sort()
      # Strings -> Atome
      |> Enum.map(&String.to_atom/1)

    if sorted_wrong_filled_fields != [] do
      {:error, {sorted_wrong_filled_fields, "Wrong field is filled"}}
    else
      # Check the items now.
      wrong_filled_item_fields =
        factur_x.b_included_supply_chain_trade_line_item
        |> Enum.with_index(1)
        |> Enum.map(fn {isctli, idx} ->
          filled_fields =
            isctli
            |> Map.from_struct()
            |> Map.keys()
            |> Enum.filter(fn field ->
              # Are there any fields filled in that do not match the profile
              # distinguish whether there are multiple entries or only one
              Enum.all?(profil_identifier, fn identifier ->
                not String.starts_with?(Atom.to_string(field), identifier)
              end) and
                case Map.get(isctli, field) do
                  nil ->
                    false

                  "" ->
                    false

                  # more than one
                  value when is_list(value) ->
                    Enum.any?(value, fn
                      val when is_binary(val) and val != "" -> true
                      {_, val} when is_binary(val) and val != "" -> true
                      _ -> false
                    end)

                  # is one
                  val when is_binary(val) and val != "" ->
                    true

                  _ ->
                    false
                end
            end)

          {idx, filled_fields}
        end)
        |> Enum.reject(fn {_idx, fields} -> fields == [] end)

      # Ensure that alphabetical order is always returned, which is important for test cases.
      sorted_wrong_filled_item_fields =
        wrong_filled_item_fields
        |> Enum.map(fn {idx, fields} ->
          {idx,
           fields
           |> Enum.map(&Atom.to_string/1)
           |> Enum.sort()
           |> Enum.map(&String.to_atom/1)}
        end)

      if sorted_wrong_filled_item_fields == [] do
        {:ok, "content is consistent"}
      else
        {:error, {%{items: sorted_wrong_filled_item_fields}, "Wrong item field is filled"}}
      end
    end
  end

  # checking float content consistency
  # To ensure that decimal conversion for decimal places is guaranteed,
  # the amount fields are checked in advance to see whether they contain float values, which is a prerequisite for decimal conversion.
  def check_float_content_consistency(factur_x, profil_identifier) do
    invalid_float_fields =
      factur_x
      |> Map.from_struct()
      # go through the list
      |> Enum.filter(fn {key, value} ->
        # Are there any fields filled in that do not match the profile
        # Only check fields that contain the amount but not amount currency_id -> does not contain an amount
        Enum.any?(profil_identifier, fn identifier ->
          String.starts_with?(Atom.to_string(key), identifier)
        end) and String.contains?(Atom.to_string(key), "amount") and
          not String.contains?(Atom.to_string(key), "amount_currency_id") and
          not is_float(value) and
          not (is_nil(value) or value == "")
      end)
      |> Enum.map(fn {key, _} -> key end)

    if invalid_float_fields != [] do
      {:error, {invalid_float_fields, "Invalid float field"}}
    else
      invalid_float_item_fields =
        factur_x.b_included_supply_chain_trade_line_item
        |> Enum.with_index(1)
        |> Enum.map(fn {isctli, idx} ->
          filled_fields =
            isctli
            |> Map.from_struct()
            |> Map.keys()
            # go through the list
            |> Enum.filter(fn field ->
              # Are there any fields filled in that do not match the profile
              # Only check fields that contain the amount but not amount currency_id -> does not contain an amount
              Enum.any?(profil_identifier, fn identifier ->
                String.starts_with?(Atom.to_string(field), identifier)
              end) and not (is_nil(Map.get(isctli, field)) or Map.get(isctli, field) == "") and
                String.contains?(Atom.to_string(field), "amount") and
                not String.contains?(Atom.to_string(field), "amount_currency_id") and
                not is_float(Map.get(isctli, field))
            end)

          {idx, filled_fields}
        end)
        |> Enum.reject(fn {_idx, fields} -> fields == [] end)

      if invalid_float_item_fields == [] do
        {:ok, "float content is consistent"}
      else
        {:error, {%{items: invalid_float_item_fields}, "Invalid float item fields"}}
      end
    end
  end

  # Check the scheme_id fields for valid content (isoiec6523) using the list defined at the beginning.
  def check_code_list(factur_x, profil_identifier) do
    invalid_code_fields =
      factur_x
      |> Map.from_struct()
      |> Enum.filter(fn {key, value} ->
        # only check relevant fields, e.g. global_id_scheme_id
        # Value not in reference list
        Enum.any?(profil_identifier, fn identifier ->
          # Only check fields that contain the scheme_id but not vat_identifier_id_scheme_id and local_tax_id_scheme_id  -> use a different code list
          String.starts_with?(Atom.to_string(key), identifier)
        end) and String.contains?(Atom.to_string(key), "scheme_id") and
          not String.contains?(Atom.to_string(key), "vat_identifier_id_scheme_id") and
          not String.contains?(Atom.to_string(key), "local_tax_id_scheme_id") and
          not (is_nil(value) or value == "") and
          value not in @code_list_iso_iec_6523
      end)
      |> Enum.map(fn {key, _} -> key end)

    # check items
    invalid_item_code_fields =
      factur_x.b_included_supply_chain_trade_line_item
      |> Enum.with_index(1)
      |> Enum.map(fn {isctli, idx} ->
        filled_fields =
          isctli
          |> Map.from_struct()
          |> Enum.filter(fn {key, value} ->
            # Only check fields that contain the scheme_id but not vat_identifier_id_scheme_id  -> use a different code list
            # Value not in reference list
            Enum.any?(profil_identifier, fn identifier ->
              String.starts_with?(Atom.to_string(key), identifier)
            end) and String.contains?(Atom.to_string(key), "scheme_id") and
              not String.contains?(Atom.to_string(key), "vat_identifier_id_scheme_id") and
              not (is_nil(value) or value == "") and
              value not in @code_list_iso_iec_6523
          end)
          |> Enum.map(fn {key, _} -> key end)

        {idx, filled_fields}
      end)
      |> Enum.reject(fn {_idx, fields} -> fields == [] end)

    cond do
      invalid_code_fields != [] ->
        {:error, {invalid_code_fields, "Invalid code fields"}}

      invalid_item_code_fields != [] ->
        {:error, {%{items: invalid_item_code_fields}, "Invalid item code fields"}}

      true ->
        {:ok, "complied codelist"}
    end
  end

  # Start function remove_empty_elements
  # Function for cleaning up empty elements
  # empty elements are also created during the process if no data is available for them.
  # These are cleaned up with this function
  defp remove_empty_elements({xml_element, xml_attribute, xml_kinds}) do
    xml_cleaned_kinds = remove_empty_elements(xml_kinds)

    if xml_cleaned_kinds in [nil, "", [], "0.00"] and
         not String.contains?(to_string(xml_element), "ram:ApplicableHeaderTradeDelivery") do
      nil
    else
      {xml_element, xml_attribute, xml_cleaned_kinds}
    end
  end

  defp remove_empty_elements({xml_element, xml_kinds}) do
    xml_cleaned_kinds = remove_empty_elements(xml_kinds)

    if xml_cleaned_kinds in [nil, "", [], "0.00"] do
      nil
    else
      {xml_element, xml_cleaned_kinds}
    end
  end

  defp remove_empty_elements(list) when is_list(list) do
    list
    |> Enum.map(&remove_empty_elements/1)
    |> Enum.reject(&is_nil/1)
  end

  defp remove_empty_elements(value), do: value
  # End function remove_empty_elements

  # Start Parse Datei
  # convert the passed date to the correct format
  def check_parse_date(date) when is_binary(date) do
    case Timex.parse(date, "{YYYY}{0M}{0D}") do
      {:ok, parsed_date} ->
        Timex.format!(parsed_date, "{YYYY}{0M}{0D}")

      {:error, _} ->
        case Timex.parse(date, "{YYYY}-{0M}-{0D}") do
          {:ok, parsed_date} ->
            Timex.format!(parsed_date, "{YYYY}{0M}{0D}")

          {:error, _} ->
            case Timex.parse(date, "{0D}{0M}{YYYY}") do
              {:ok, parsed_date} ->
                Timex.format!(parsed_date, "{YYYY}{0M}{0D}")

              {:error, _} ->
                case Timex.parse(date, "{0D}.{0M}.{YYYY}") do
                  {:ok, parsed_date} ->
                    Timex.format!(parsed_date, "{YYYY}{0M}{0D}")

                  {:error, _} ->
                    case Timex.parse(date, "{0D}-{0M}-{YYYY}") do
                      {:ok, parsed_date} ->
                        Timex.format!(parsed_date, "{YYYY}{0M}{0D}")

                      {:error, _} ->
                        "00000000"
                    end
                end
            end
        end
    end
  end

  def check_parse_date(%Date{} = date) do
    Timex.format!(date, "{YYYY}{0M}{0D}")
  end

  def check_parse_date(nil), do: ""

  # End Parse Datei

  # Properties that affect the whole document
  def create_m_exchanged_document_context(factur_x) do
    guideline_specified_document_context_parameter =
      cond do
        factur_x.m_profil_factur_x == "MINIMUM" ->
          "urn:factur-x.eu:1p0:minimum"

        factur_x.m_profil_factur_x == "BASICWL" ->
          "urn:factur-x.eu:1p0:basicwl"

        factur_x.m_profil_factur_x == "BASIC" ->
          "urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basic"

        factur_x.m_profil_factur_x == "EN16931" ->
          "urn:cen.eu:en16931:2017"
      end

    element(
      "rsm:ExchangedDocumentContext",
      [
        element("ram:BusinessProcessSpecifiedDocumentContextParameter", [
          element("ram:ID", factur_x.m_business_process_specified_document_context_parameter_id)
        ]),
        element("ram:GuidelineSpecifiedDocumentContextParameter", [
          element("ram:ID", guideline_specified_document_context_parameter)
        ])
      ]
    )
  end

  def create_m_exchanged_document(factur_x) do
    # set every entry as a list
    notes_list =
      case factur_x.w_exchanged_document_included_note do
        entry when is_list(entry) ->
          if Keyword.keyword?(hd(entry)) do
            entry
          else
            [entry]
          end

        _ ->
          []
      end

    # create notes
    included_notes =
      notes_list
      |> Enum.filter(fn entry ->
        Enum.any?(
          [
            Keyword.get(entry, :w_exchanged_document_included_note_content),
            Keyword.get(entry, :w_exchanged_document_included_note_subject_code)
          ],
          fn variable -> variable not in [nil, ""] end
        )
      end)
      |> Enum.map(fn entry ->
        note_content = Keyword.get(entry, :w_exchanged_document_included_note_content)
        note_subject_code = Keyword.get(entry, :w_exchanged_document_included_note_subject_code)

        elements = []

        elements =
          if note_content in [nil, ""],
            do: elements,
            else: elements ++ [element("ram:Content", note_content)]

        elements =
          if note_subject_code in [nil, ""],
            do: elements,
            else: elements ++ [element("ram:SubjectCode", note_subject_code)]

        element("ram:IncludedNote", elements)
      end)

    # set the ExchandedDocument content
    exchanded_document_content =
      [
        element("ram:ID", factur_x.m_exchanged_document_id),
        element("ram:TypeCode", factur_x.m_exchanged_document_type_code),
        element("ram:IssueDateTime", [
          element(
            "udt:DateTimeString",
            [format: "102"],
            check_parse_date(factur_x.m_issue_date_time_date_time_string)
          )
        ])
      ] ++ included_notes

    element("rsm:ExchangedDocument", exchanded_document_content)
  end

  # To ensure clarity and maintainability of the function,
  # the tree structure of the XML file was used as the structure

  def create_m_supply_chain_trade_transaction(factur_x) do
    element("rsm:SupplyChainTradeTransaction", [
      if factur_x.m_profil_factur_x not in ["MINIMUM", "BASICWL"] do
        create_b_included_supply_chain_trade_line_item(factur_x)
      end,
      create_m_applicable_header_trade_agreement(factur_x),
      create_m_applicable_header_trade_delivery(factur_x),
      create_m_applicable_header_trade_settlement(factur_x)
    ])
  end

  defp create_b_included_supply_chain_trade_line_item(factur_x) do
    factur_x.b_included_supply_chain_trade_line_item
    # set index at 1
    |> Enum.with_index(1)
    |> Enum.map(fn {isctli, idx} ->
      associated_document_line_document_elements = [
        create_b_associated_document_line_document(isctli, idx)
      ]

      specified_trade_product = [create_b_specified_trade_product(isctli)]
      specified_line_trade_agreement = [create_b_specified_line_trade_agreement(isctli)]
      specified_line_trade_delivery = [create_b_specified_line_trade_delivery(isctli)]
      specified_line_trade_settlement = [create_b_specified_line_trade_settlement(isctli)]

      element("ram:IncludedSupplyChainTradeLineItem", [
        element("ram:AssociatedDocumentLineDocument", associated_document_line_document_elements),
        element("ram:SpecifiedTradeProduct", specified_trade_product),
        element("ram:SpecifiedLineTradeAgreement", specified_line_trade_agreement),
        element("ram:SpecifiedLineTradeDelivery", specified_line_trade_delivery),
        element("ram:SpecifiedLineTradeSettlement", specified_line_trade_settlement)
      ])
    end)
  end

  defp create_b_associated_document_line_document(isctli, idx) do
    [
      element(
        "ram:LineID",
        if isctli.b_associated_document_line_document_line_id in [nil, "", 0] do
          idx
        else
          isctli.b_associated_document_line_document_line_id
        end
      ),
      element("ram:IncludedNote", [
        element("ram:Content", isctli.b_associated_document_line_document_included_note_content)
      ])
    ]
  end

  defp create_b_specified_trade_product(isctli) do
    [
      element(
        "ram:GlobalID",
        [schemeID: isctli.b_specified_trade_product_global_id_scheme_id],
        isctli.b_specified_trade_product_global_id
      ),
      element("ram:SellerAssignedID", isctli.e_specified_trade_product_seller_assigned_id),
      element("ram:BuyerAssignedID", isctli.e_specified_trade_product_buyer_assigned_id),
      element("ram:Name", isctli.b_specified_trade_product_name),
      element("ram:Description", isctli.e_specified_trade_product_description),
      create_e_applicable_product_characteristic(isctli),
      create_e_designated_product_classification(isctli),
      element("ram:OriginTradeCountry", [
        element("ram:ID", isctli.e_origin_trade_country_id)
      ])
    ]
  end

  defp create_e_applicable_product_characteristic(isctli) do
    # set every entry as a list
    product_characteristic_list =
      case isctli.e_applicable_product_characteristic do
        entry when is_list(entry) ->
          if Keyword.keyword?(hd(entry)) do
            entry
          else
            [entry]
          end

        _ ->
          []
      end

    # create product characteristic
    product_characteristic_list
    |> Enum.filter(fn entry ->
      Enum.any?(
        [
          Keyword.get(entry, :e_applicable_product_characteristic_description),
          Keyword.get(entry, :e_value)
        ],
        fn variable -> variable not in [nil, ""] end
      )
    end)
    |> Enum.map(fn entry ->
      description = Keyword.get(entry, :e_applicable_product_characteristic_description)
      value = Keyword.get(entry, :e_value)

      elements = []

      elements =
        if description in [nil, ""],
          do: elements,
          else: elements ++ [element("ram:Description", description)]

      elements =
        if value in [nil, ""],
          do: elements,
          else: elements ++ [element("ram:Value", value)]

      element("ram:ApplicableProductCharacteristic", elements)
    end)
  end

  defp create_e_designated_product_classification(isctli) do
    element(
      "ram:ClassCode",
      [listID: isctli.e_class_code_list_id],
      listVersionID: isctli.e_class_code_list_version_id
    )
  end

  defp create_b_specified_line_trade_agreement(isctli) do
    create_e_specified_line_trade_agreement_buyer_order_referenced_document(isctli)
    create_b_gross_price_product_trade_price(isctli)
    create_b_net_price_product_trade_price(isctli)
  end

  defp create_e_specified_line_trade_agreement_buyer_order_referenced_document(isctli) do
    element(
      "ram:BuyerOrderReferencedDocument",
      [
        element("ram:LineID", isctli.e_buyer_order_referenced_document_line_id)
      ]
    )
  end

  defp create_b_gross_price_product_trade_price(isctli) do
    element(
      "ram:GrossPriceProductTradePrice",
      [
        element(
          "ram:ChargeAmount",
          if isctli.b_gross_price_product_trade_price_charge_amount not in [
               nil,
               "",
               0,
               0.00,
               0.0000
             ] do
            Decimal.to_string(
              Decimal.round(
                Decimal.from_float(isctli.b_gross_price_product_trade_price_charge_amount),
                4
              ),
              :normal
            )
          end
        ),
        element(
          "ram:BasisQuantity",
          [unitCode: isctli.b_gross_price_product_trade_price_basis_quantity_unit_code],
          isctli.b_gross_price_product_trade_price_basis_quantity
        ),
        create_b_applied_trade_allowance_charge_price_allowance(isctli)
      ]
    )
  end

  defp create_b_net_price_product_trade_price(isctli) do
    element("ram:NetPriceProductTradePrice", [
      element(
        "ram:ChargeAmount",
        if isctli.b_net_price_product_trade_price_charge_amount not in [nil, "", 0, 0.00, 0.0000] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(isctli.b_net_price_product_trade_price_charge_amount),
              4
            ),
            :normal
          )
        end
      ),
      element(
        "ram:BasisQuantity",
        [unitCode: isctli.b_net_price_product_trade_price_basis_quantity_unit_code],
        isctli.b_net_price_product_trade_price_basis_quantity
      )
    ])
  end

  defp create_b_applied_trade_allowance_charge_price_allowance(isctli) do
    element(
      "ram:AppliedTradeAllowanceCharge",
      [
        element(
          "ram:ChargeIndicator",
          [
            element(
              "udt:Indicator",
              isctli.b_applied_trade_allowance_charge_price_allowance_charge_indicator_indicator
            )
          ]
        ),
        element(
          "ram:ActualAmount",
          if isctli.b_applied_trade_allowance_charge_price_allowance_actual_amount not in [
               nil,
               "",
               0,
               0.00
             ] do
            Decimal.to_string(
              Decimal.round(
                Decimal.from_float(
                  isctli.b_applied_trade_allowance_charge_price_allowance_actual_amount
                ),
                2
              ),
              :normal
            )
          end
        )
      ]
    )
  end

  defp create_b_specified_line_trade_delivery(isctli) do
    element(
      "ram:BilledQuantity",
      [unitCode: isctli.b_billed_quantity_unit_code],
      isctli.b_billed_quantity
    )
  end

  defp create_b_specified_line_trade_settlement(isctli) do
    [
      create_b_specified_line_trade_settlement_applicable_trade_tax(isctli),
      create_b_specified_line_trade_settlement_billing_specified_period(isctli),
      create_b_specified_trade_allowance_charge(isctli),
      create_b_specified_trade_settlement_line_monetary_summation(isctli),
      create_e_specified_line_trade_settlement_additional_referenced_document(isctli),
      create_e_specified_line_trade_settlement_receivable_specified_trade_accounting_account(
        isctli
      )
    ]
  end

  defp create_b_specified_line_trade_settlement_applicable_trade_tax(isctli) do
    element("ram:ApplicableTradeTax", [
      element(
        "ram:TypeCode",
        "VAT"
      ),
      element(
        "ram:CategoryCode",
        isctli.b_specified_line_trade_settlement_applicable_trade_tax_category_code
      ),
      element(
        "ram:RateApplicablePercent",
        isctli.b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent
      )
    ])
  end

  defp create_b_specified_line_trade_settlement_billing_specified_period(isctli) do
    element("ram:BillingSpecifiedPeriod", [
      element("ram:StartDateTime", [
        element(
          "udt:DateTimeString",
          [format: "102"],
          check_parse_date(
            isctli.b_specified_line_trade_settlement_billing_specified_period_start_date_time_date_time_string
          )
        )
      ]),
      element("ram:EndDateTime", [
        element(
          "udt:DateTimeString",
          [format: "102"],
          check_parse_date(
            isctli.b_specified_line_trade_settlement_billing_specified_period_end_date_time_date_time_string
          )
        )
      ])
    ])
  end

  # allowance and charge can occur n times,
  # the process is based on a list, so even if there is only one entry, a list is created.
  # The existing values are then assigned to the corresponding variables.
  # Keywords because ordered and list data are available.
  defp create_b_specified_trade_allowance_charge(isctli) do
    items_allowance_charge_list =
      case isctli.b_specified_trade_allowance_charge do
        entry when is_list(entry) ->
          if Keyword.keyword?(hd(entry)) do
            entry
          else
            [entry]
          end

        _ ->
          []
      end

    items_allowance_charge_list
    |> Enum.filter(fn entry ->
      Enum.any?(
        [
          Keyword.get(entry, :b_specified_trade_allowance_charge_charge_indicator),
          Keyword.get(entry, :e_specified_trade_allowance_charge_calculation_percent),
          Keyword.get(entry, :e_specified_trade_allowance_charge_basis_amount),
          Keyword.get(entry, :b_specified_trade_allowance_charge_actual_amount),
          Keyword.get(entry, :b_specified_trade_allowance_charge_reason_code),
          Keyword.get(entry, :b_specified_trade_allowance_charge_reason)
        ],
        fn val -> val not in [nil, "", 0, 0.00] end
      )
    end)
    |> Enum.map(fn entry ->
      charge_indicator = Keyword.get(entry, :b_specified_trade_allowance_charge_charge_indicator)
      calc_percent = Keyword.get(entry, :e_specified_trade_allowance_charge_calculation_percent)
      basis_amount = Keyword.get(entry, :e_specified_trade_allowance_charge_basis_amount)
      actual_amount = Keyword.get(entry, :b_specified_trade_allowance_charge_actual_amount)
      reason_code = Keyword.get(entry, :b_specified_trade_allowance_charge_reason_code)
      reason = Keyword.get(entry, :b_specified_trade_allowance_charge_reason)

      elements = []

      elements =
        if charge_indicator in [nil, ""] do
          elements
        else
          elements ++
            [element("ram:ChargeIndicator", [element("udt:Indicator", charge_indicator)])]
        end

      elements =
        if calc_percent in [nil, ""],
          do: elements,
          else: elements ++ [element("ram:CalculationPercent", calc_percent)]

      elements =
        if basis_amount in [nil, ""],
          do: elements,
          else: elements ++ [element("ram:BasisAmount", basis_amount)]

      elements =
        if actual_amount in [nil, ""],
          do: elements,
          else: elements ++ [element("ram:ActualAmount", actual_amount)]

      elements =
        if reason_code in [nil, ""],
          do: elements,
          else: elements ++ [element("ram:ReasonCode", reason_code)]

      elements =
        if reason in [nil, ""],
          do: elements,
          else: elements ++ [element("ram:Reason", reason)]

      element("ram:SpecifiedTradeAllowanceCharge", elements)
    end)
  end

  defp create_b_specified_trade_settlement_line_monetary_summation(factur_x) do
    element("ram:SpecifiedTradeSettlementLineMonetarySummation", [
      element(
        "ram:LineTotalAmount",
        if factur_x.b_specified_trade_settlement_line_monetary_summation_line_total_amount not in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.b_specified_trade_settlement_line_monetary_summation_line_total_amount
              ),
              2
            ),
            :normal
          )
        end
      )
    ])
  end

  defp create_e_specified_line_trade_settlement_additional_referenced_document(isctli) do
    element("ram:AdditionalReferencedDocument", [
      element(
        "ram:IssuerAssignedID",
        isctli.e_specified_line_trade_settlement_additional_referenced_document_issuer_assigned_id
      ),
      element(
        "ram:TypeCode",
        isctli.e_specified_line_trade_settlement_additional_referenced_document_type_code
      ),
      element(
        "ram:ReferenceTypeCode",
        isctli.e_specified_line_trade_settlement_additional_referenced_document_reference_type_code
      )
    ])
  end

  defp create_e_specified_line_trade_settlement_receivable_specified_trade_accounting_account(
         isctli
       ) do
    element("ram:ReceivableSpecifiedTradeAccountingAccount", [
      element(
        "ram:ID",
        isctli.e_specified_line_trade_settlement_receivable_specified_trade_accounting_account_id
      )
    ])
  end

  defp create_m_applicable_header_trade_agreement(factur_x) do
    element("ram:ApplicableHeaderTradeAgreement", [
      element("ram:BuyerReference", factur_x.m_buyer_reference),
      create_m_seller_trade_party(factur_x),
      create_m_buyer_trade_party(factur_x),
      create_w_seller_tax_representative_trade_party(factur_x),
      create_e_applicable_header_trade_agreement_seller_order_referenced_document(factur_x),
      create_m_applicable_header_trade_agreement_buyer_order_referenced_document(factur_x),
      create_w_applicable_header_trade_agreement_contract_referenced_document(factur_x),
      create_e_additional_referenced_document_additional_supporting_documents(factur_x),
      create_e_additional_referenced_document_tender_lot(factur_x),
      create_e_additional_referenced_document_invoiced_object(factur_x),
      create_e_specified_procuring_project(factur_x)
    ])
  end

  defp create_m_seller_trade_party(factur_x) do
    element(
      "ram:SellerTradeParty",
      [
        element("ram:ID", factur_x.w_seller_trade_party_id),
        element(
          "ram:GlobalID",
          [schemeID: factur_x.w_seller_trade_party_global_id_scheme_id],
          factur_x.w_seller_trade_party_global_id
        ),
        element("ram:Name", factur_x.m_seller_trade_party_name),
        element("ram:Description", factur_x.e_seller_trade_party_description),
        create_m_seller_trade_party_specified_legal_organization(factur_x),
        create_e_seller_trade_party_defined_trade_contact(factur_x),
        create_m_seller_trade_party_postal_trade_address(factur_x),
        element("ram:URIUniversalCommunication", [
          element(
            "ram:URIID",
            [schemeID: factur_x.w_seller_trade_party_uri_universal_communication_uriid_scheme_id],
            factur_x.w_seller_trade_party_uri_universal_communication_uriid
          )
        ]),
        element("ram:SpecifiedTaxRegistration", [
          element(
            "ram:ID",
            [schemeID: factur_x.m_specified_tax_registration_vat_identifier_id_scheme_id],
            factur_x.m_specified_tax_registration_vat_identifier_id
          )
        ]),
        element("ram:SpecifiedTaxRegistration", [
          element(
            "ram:ID",
            [schemeID: factur_x.e_specified_tax_registration_local_tax_id_scheme_id],
            factur_x.e_specified_tax_registration_local_tax_id
          )
        ])
      ]
    )
  end

  defp create_m_seller_trade_party_specified_legal_organization(factur_x) do
    element(
      "ram:SpecifiedLegalOrganization",
      [
        element(
          "ram:ID",
          [schemeID: factur_x.m_seller_trade_party_specified_legal_organization_id_scheme_id],
          factur_x.m_seller_trade_party_specified_legal_organization_id
        ),
        element(
          "ram:TradingBusinessName",
          factur_x.w_seller_trade_party_specified_legal_organization_trading_business_name
        )
      ]
    )
  end

  defp create_e_seller_trade_party_defined_trade_contact(factur_x) do
    element(
      "ram:DefinedTradeContact",
      [
        element(
          "ram:PersonName",
          factur_x.e_seller_trade_party_defined_trade_contact_person_name
        ),
        element(
          "ram:DepartmentName",
          factur_x.e_seller_trade_party_defined_trade_contact_department_name
        ),
        element("ram:TelephoneUniversalCommunication", [
          element(
            "ram:CompleteNumber",
            factur_x.e_seller_trade_party_defined_trade_contact_telephone_universal_communication_complete_number
          )
        ]),
        element("ram:EmailURIUniversalCommunication", [
          element(
            "ram:URIID",
            factur_x.e_seller_trade_party_defined_trade_contact_emailuri_universal_communication_uriid
          )
        ])
      ]
    )
  end

  defp create_m_seller_trade_party_postal_trade_address(factur_x) do
    element(
      "ram:PostalTradeAddress",
      [
        element(
          "ram:PostcodeCode",
          factur_x.w_seller_trade_party_postal_trade_address_postcode_code
        ),
        element("ram:LineOne", factur_x.w_seller_trade_party_postal_trade_address_line_one),
        element("ram:LineTwo", factur_x.w_seller_trade_party_postal_trade_address_line_two),
        element("ram:LineThree", factur_x.w_seller_trade_party_postal_trade_address_line_three),
        element("ram:CityName", factur_x.w_seller_trade_party_postal_trade_address_city_name),
        element("ram:CountryID", factur_x.m_seller_trade_party_postal_trade_address_country_id),
        element(
          "ram:CountrySubDivisionName",
          factur_x.w_seller_trade_party_postal_trade_address_country_sub_division_name
        )
      ]
    )
  end

  defp create_m_buyer_trade_party(factur_x) do
    element(
      "ram:BuyerTradeParty",
      [
        element("ram:ID", factur_x.w_buyer_trade_party_id),
        element(
          "ram:GlobalID",
          [schemeID: factur_x.w_buyer_trade_party_global_id_scheme_id],
          factur_x.w_buyer_trade_party_global_id
        ),
        element("ram:Name", factur_x.m_buyer_trade_party_name),
        create_m_buyer_trade_party_specified_legal_organization(factur_x),
        create_e_buyer_trade_party_defined_trade_contact(factur_x),
        create_w_buyer_trade_party_postal_trade_address(factur_x),
        element("ram:URIUniversalCommunication", [
          element(
            "ram:URIID",
            [schemeID: factur_x.w_buyer_trade_partyuri_universal_communication_uriid_scheme_id],
            factur_x.w_buyer_trade_partyuri_universal_communication_uriid
          )
        ]),
        element("ram:SpecifiedTaxRegistration", [
          element(
            "ram:ID",
            [schemeID: factur_x.w_buyer_trade_party_specified_tax_registration_id_scheme_id],
            factur_x.w_buyer_trade_party_specified_tax_registration_id
          )
        ])
      ]
    )
  end

  defp create_m_buyer_trade_party_specified_legal_organization(factur_x) do
    element(
      "ram:SpecifiedLegalOrganization",
      [
        element(
          "ram:ID",
          [schemeID: factur_x.m_buyer_trade_party_specified_legal_organization_id_scheme_id],
          factur_x.m_buyer_trade_party_specified_legal_organization_id
        ),
        element(
          "ram:TradingBusinessName",
          factur_x.e_buyer_trade_party_specified_legal_organization_trading_business_name
        )
      ]
    )
  end

  defp create_e_buyer_trade_party_defined_trade_contact(factur_x) do
    element(
      "ram:DefinedTradeContact",
      [
        element("ram:PersonName", factur_x.e_buyer_trade_party_defined_trade_contact_person_name),
        element(
          "ram:DepartmentName",
          factur_x.e_buyer_trade_party_defined_trade_contact_department_name
        ),
        element(
          "ram:TelephoneUniversalCommunication",
          factur_x.e_buyer_trade_party_defined_trade_contact_telephone_universal_communication
        ),
        element(
          "ram:CompleteNumber",
          factur_x.e_buyer_trade_party_defined_trade_contact_telephone_universal_communication_complete_number
        ),
        element(
          "ram:EmailURIUniversalCommunication",
          factur_x.e_buyer_trade_party_defined_trade_contact_emailuri_universal_communication
        ),
        element(
          "ram:URIID",
          factur_x.e_buyer_trade_party_defined_trade_contact_emailuri_universal_communication_uriid
        )
      ]
    )
  end

  defp create_w_buyer_trade_party_postal_trade_address(factur_x) do
    element(
      "ram:PostalTradeAddress",
      [
        element(
          "ram:PostcodeCode",
          factur_x.w_buyer_trade_party_postal_trade_address_postcode_code
        ),
        element("ram:LineOne", factur_x.w_buyer_trade_party_postal_trade_address_line_one),
        element("ram:LineTwo", factur_x.w_buyer_trade_party_postal_trade_address_line_two),
        element("ram:LineThree", factur_x.w_buyer_trade_party_postal_trade_address_line_three),
        element("ram:CityName", factur_x.w_buyer_trade_party_postal_trade_address_city_name),
        element("ram:CountryID", factur_x.w_buyer_trade_party_postal_trade_address_country_id),
        element(
          "ram:CountrySubDivisionName",
          factur_x.w_buyer_trade_party_postal_trade_address_country_sub_division_name
        )
      ]
    )
  end

  defp create_w_seller_tax_representative_trade_party(factur_x) do
    element(
      "ram:SellerTaxRepresentativeTradeParty",
      [
        element("ram:Name", factur_x.w_seller_tax_representative_trade_party_name),
        create_w_seller_tax_representative_trade_party_postal_trade_address(factur_x),
        element("ram:SpecifiedTaxRegistration", [
          element(
            "ram:ID",
            [
              mimeCode:
                factur_x.e_additional_referenced_document_additional_supporting_documents_attachment_binary_object_mime_code
            ],
            filename:
              factur_x.e_additional_referenced_document_additional_supporting_documents_attachment_binary_object_filename
          )
        ])
      ]
    )
  end

  defp create_w_seller_tax_representative_trade_party_postal_trade_address(factur_x) do
    element(
      "ram:PostalTradeAddress",
      [
        element(
          "ram:PostcodeCode",
          factur_x.w_seller_tax_representative_trade_party_postal_trade_address_postcode_code
        ),
        element(
          "ram:LineOne",
          factur_x.w_seller_tax_representative_trade_party_postal_trade_address_line_one
        ),
        element(
          "ram:LineTwo",
          factur_x.w_seller_tax_representative_trade_party_postal_trade_address_line_two
        ),
        element(
          "ram:LineThree",
          factur_x.w_seller_tax_representative_trade_party_postal_trade_address_line_three
        ),
        element(
          "ram:CityName",
          factur_x.w_seller_tax_representative_trade_party_postal_trade_address_city_name
        ),
        element(
          "ram:CountryID",
          factur_x.w_seller_tax_representative_trade_party_postal_trade_address_country_id
        ),
        element(
          "ram:CountrySubDivisionName",
          factur_x.w_seller_tax_representative_trade_party_postal_trade_address_country_sub_division_name
        )
      ]
    )
  end

  defp create_e_applicable_header_trade_agreement_seller_order_referenced_document(factur_x) do
    element(
      "ram:IssuerAssignedID",
      factur_x.e_applicable_header_trade_agreement_seller_order_referenced_document_issuer_assigned_id
    )
  end

  defp create_m_applicable_header_trade_agreement_buyer_order_referenced_document(factur_x) do
    element(
      "ram:IssuerAssignedID",
      factur_x.m_applicable_header_trade_agreement_buyer_order_referenced_document_issuer_assigned_id
    )
  end

  defp create_w_applicable_header_trade_agreement_contract_referenced_document(factur_x) do
    element(
      "ram:IssuerAssignedID",
      factur_x.w_applicable_header_trade_agreement_contract_referenced_document_issuer_assigned_id
    )
  end

  defp create_e_additional_referenced_document_additional_supporting_documents(factur_x) do
    element("ram:AdditionalReferencedDocumentAdditionalSupportingDocuments", [
      element(
        "ram:IssuerAssignedID",
        factur_x.e_additional_referenced_document_additional_supporting_documents_issuer_assigned_id
      ),
      element(
        "ram:URIID",
        factur_x.e_additional_referenced_document_additional_supporting_documents_uriid
      ),
      element(
        "ram:TypeCode",
        factur_x.e_additional_referenced_document_additional_supporting_documents_type_code
      ),
      element(
        "ram:Name",
        factur_x.e_additional_referenced_document_additional_supporting_documents_name
      ),
      element(
        "ram:AttachmentBinaryObject",
        [schemeID: factur_x.w_buyer_trade_partyuri_universal_communication_uriid_scheme_id],
        factur_x.w_buyer_trade_partyuri_universal_communication_uriid
      )
    ])
  end

  defp create_e_additional_referenced_document_tender_lot(factur_x) do
    element("ram:AdditionalReferencedDocumentTenderLot", [
      element(
        "ram:IssuerAssignedID",
        factur_x.e_additional_referenced_document_tender_lot_issuer_assigned_id
      ),
      element("ram:TypeCode", factur_x.e_additional_referenced_document_tender_lot_type_code)
    ])
  end

  defp create_e_additional_referenced_document_invoiced_object(factur_x) do
    element("ram:AdditionalReferencedDocumentInvoicedObject", [
      element(
        "ram:IssuerAssignedID",
        factur_x.e_additional_referenced_document_invoiced_object_issuer_assigned_id
      ),
      element(
        "ram:TypeCode",
        factur_x.e_additional_referenced_document_invoiced_object_type_code
      ),
      element(
        "ram:ReferenceTypeCode",
        factur_x.e_additional_referenced_document_invoiced_object_reference_type_code
      )
    ])
  end

  defp create_e_specified_procuring_project(factur_x) do
    element("ram:SpecifiedProcuringProject", [
      element("ram:ID", factur_x.e_specified_procuring_project_id),
      element("ram:Name", factur_x.e_specified_procuring_project_name)
    ])
  end

  defp create_m_applicable_header_trade_delivery(factur_x) do
    element("ram:ApplicableHeaderTradeDelivery", [
      create_w_applicable_header_trade_delivery_ship_to_trade_party(factur_x),
      create_w_applicable_header_trade_delivery_despatch_advice_referenced_document(factur_x),
      create_e_applicable_header_trade_delivery_receiving_advice_referenced_document(factur_x),
      element("ram:ActualDeliverySupplyChainEvent", [
        element("ram:OccurrenceDateTime", [
          element(
            "udt:DateTimeString",
            [format: "102"],
            check_parse_date(
              factur_x.w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string
            )
          )
        ])
      ]),
      element("ram:DespatchAdviceReferencedDocument", [
        element(
          "ram:IssuerAssignedID",
          factur_x.w_applicable_header_trade_delivery_despatch_advice_referenced_document_issuer_assigned_id
        )
      ]),
      element("ram:ReceivingAdviceReferencedDocument", [
        element(
          "ram:IssuerAssignedID",
          factur_x.e_applicable_header_trade_delivery_receiving_advice_referenced_document_issuer_assigned_id
        )
      ])
    ])
  end

  defp create_w_applicable_header_trade_delivery_ship_to_trade_party(factur_x) do
    element(
      "ram:ShipToTradeParty",
      [
        element("ram:ID", factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_id),
        element(
          "ram:GlobalID",
          [
            schemeID:
              factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_global_id_scheme_id
          ],
          factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_global_id
        ),
        element("ram:Name", factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_name)
      ]
    )

    create_w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address(factur_x)
  end

  defp create_w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address(
         factur_x
       ) do
    element(
      "ram:PostalTradeAddress",
      [
        element(
          "ram:PostcodeCode",
          factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_postcode_code
        ),
        element(
          "ram:LineOne",
          factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_one
        ),
        element(
          "ram:LineTwo",
          factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_two
        ),
        element(
          "ram:LineThree",
          factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_line_three
        ),
        element(
          "ram:CityName",
          factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_city_name
        ),
        element(
          "ram:CountryID",
          factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_country_id
        ),
        element(
          "ram:CountrySubDivisionName",
          factur_x.w_applicable_header_trade_delivery_ship_to_trade_party_postal_trade_address_country_sub_division_name
        )
      ]
    )
  end

  defp create_w_applicable_header_trade_delivery_despatch_advice_referenced_document(factur_x) do
    element("ram:DespatchAdviceReferencedDocument", [
      element(
        "ram:IssuerAssignedID",
        factur_x.w_applicable_header_trade_delivery_despatch_advice_referenced_document_issuer_assigned_id
      )
    ])
  end

  defp create_e_applicable_header_trade_delivery_receiving_advice_referenced_document(factur_x) do
    element("ram:ReceivingAdviceReferencedDocument", [
      element(
        "ram:IssuerAssignedID",
        factur_x.e_applicable_header_trade_delivery_receiving_advice_referenced_document_issuer_assigned_id
      )
    ])
  end

  defp create_m_applicable_header_trade_settlement(factur_x) do
    element("ram:ApplicableHeaderTradeSettlement", [
      element("ram:CreditorReferenceID", factur_x.w_creditor_reference_id),
      element("ram:PaymentReference", factur_x.w_payment_reference),
      element("ram:TaxCurrencyCode", factur_x.w_tax_currency_code),
      element("ram:InvoiceCurrencyCode", factur_x.m_invoice_currency_code),
      create_w_applicable_header_trade_settlement_payee_trade_party(factur_x),
      create_w_specified_trade_settlement_payment_means(factur_x),
      create_w_applicable_header_trade_settlement_applicable_trade_tax(factur_x, 7),
      create_w_applicable_header_trade_settlement_applicable_trade_tax(factur_x, 19),
      create_w_applicable_header_trade_settlement_billing_specified_period(factur_x),
      create_w_specified_trade_allowance_charge_document_level_allowances(factur_x),
      create_w_specified_trade_allowance_charge_document_level_charges(factur_x),
      create_w_specified_trade_payment_terms(factur_x),
      create_m_specified_trade_settlement_header_monetary_summation(factur_x),
      create_w_applicable_header_trade_settlement_invoice_referenced_document(factur_x),
      create_w_applicable_header_trade_settlement_receivable_specified_trade_accounting_account(
        factur_x
      )
    ])
  end

  defp create_w_applicable_header_trade_settlement_payee_trade_party(factur_x) do
    element("ram:PayeeTradeParty", [
      element("ram:ID", factur_x.w_applicable_header_trade_settlement_payee_trade_party_id),
      element(
        "ram:GlobalID",
        [
          schemeID:
            factur_x.w_applicable_header_trade_settlement_payee_trade_party_global_id_scheme_id
        ],
        factur_x.w_applicable_header_trade_settlement_payee_trade_party_global_id
      ),
      element("ram:Name", factur_x.w_applicable_header_trade_settlement_payee_trade_party_name),
      element(
        "ram:SpecifiedLegalOrganization",
        [
          schemeID:
            factur_x.w_applicable_header_trade_settlement_payee_trade_party_specified_legal_organization_id_scheme_id
        ],
        factur_x.w_applicable_header_trade_settlement_payee_trade_party_specified_legal_organization_id
      )
    ])
  end

  defp create_w_specified_trade_settlement_payment_means(factur_x) do
    element("ram:SpecifiedTradeSettlementPaymentMeans", [
      element("ram:TypeCode", factur_x.w_specified_trade_settlement_payment_means_type_code),
      element("ram:Informationen", factur_x.e_information),
      element("ram:ApplicableTradeSettlementFinancialCard", [
        element(
          "ram:ID",
          factur_x.e_applicable_trade_settlement_financial_card_id
        ),
        element(
          "ram:CardholderName",
          factur_x.e_cardholder_name
        )
      ]),
      element("ram:PayerPartyDebtorFinancialAccount", [
        element(
          "ram:IBANID",
          factur_x.w_payer_party_debtor_financial_account_iban_id
        )
      ]),
      create_w_payee_party_creditor_financial_account(factur_x),
      element("ram:PayeeSpecifiedCreditorFinancialInstitution", [
        element(
          "ram:BICID",
          factur_x.e_bic_id
        )
      ])
    ])
  end

  defp create_w_payee_party_creditor_financial_account(factur_x) do
    element("ram:PayeePartyCreditorFinancialAccount", [
      element(
        "ram:IBANID",
        factur_x.w_payee_party_creditor_financial_account_iban_id
      ),
      element(
        "ram:AccountName",
        factur_x.e_account_name
      ),
      element(
        "ram:ProprietaryID",
        factur_x.w_proprietary_id
      )
    ])
  end

  defp create_w_applicable_header_trade_settlement_applicable_trade_tax(factur_x, tax_rate) do
    b_specified_trade_settlement_line_monetary_summation_line_total_amount =
      sum_isctli_tax_field(
        factur_x,
        :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
        tax_rate
      )

    if b_specified_trade_settlement_line_monetary_summation_line_total_amount > 0 or
         (factur_x.m_profil_factur_x in ["BASICWL"] and
            factur_x.w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent ==
              tax_rate) do
      element("ram:ApplicableTradeTax", [
        element(
          "ram:CalculatedAmount",
          if factur_x.w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount in [
               nil,
               "",
               0,
               0.00
             ] do
            Decimal.to_string(
              Decimal.round(
                Decimal.from_float(
                  sum_isctli_tax_field(
                    factur_x,
                    :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
                    tax_rate
                  ) / 100 * tax_rate
                ),
                2
              ),
              :normal
            )
          else
            factur_x.w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount
          end
        ),
        element(
          "ram:TypeCode",
          "VAT"
        ),
        element(
          "ram:ExemptionReason",
          factur_x.w_applicable_header_trade_settlement_applicable_trade_tax_exemption_reason
        ),
        element(
          "ram:BasisAmount",
          if factur_x.w_applicable_trade_tax_basis_amount in [
               nil,
               "",
               0,
               0.00
             ] do
            Decimal.to_string(
              Decimal.round(
                Decimal.from_float(
                  b_specified_trade_settlement_line_monetary_summation_line_total_amount
                ),
                2
              ),
              :normal
            )
          else
            Decimal.to_string(
              Decimal.round(
                Decimal.from_float(factur_x.w_applicable_trade_tax_basis_amount),
                2
              ),
              :normal
            )
          end
        ),
        element(
          "ram:CategoryCode",
          factur_x.w_applicable_header_trade_settlement_applicable_trade_tax_category_code
        ),
        element(
          "ram:ExemptionReasonCode",
          factur_x.w_applicable_header_trade_settlement_applicable_trade_tax_exemption_reason_code
        ),
        element("ram:TaxPointDate", [
          element(
            "udt:DateTimeString",
            [format: "102"],
            check_parse_date(factur_x.e_date_string)
          )
        ]),
        element("ram:DueDateTypeCode", factur_x.w_due_date_type_code),
        element(
          "ram:RateApplicablePercent",
          tax_rate
        )
      ])
    end
  end

  defp create_w_applicable_header_trade_settlement_billing_specified_period(factur_x) do
    element("ram:BillingSpecifiedPeriod", [
      element("ram:StartDateTime", [
        element(
          "udt:DateTimeString",
          [format: "102"],
          check_parse_date(
            factur_x.w_applicable_header_trade_settlement_billing_specified_period_start_date_time_date_time_string
          )
        )
      ]),
      element("ram:EndDateTime", [
        element(
          "udt:DateTimeString",
          [format: "102"],
          check_parse_date(
            factur_x.w_applicable_header_trade_settlement_billing_specified_period_end_date_time_date_time_string
          )
        )
      ])
    ])
  end

  defp create_w_specified_trade_allowance_charge_document_level_allowances(factur_x) do
    element("ram:SpecifiedTradeAllowanceChargeDocumentLevelAllowances", [
      element("ram:ChargeIndicator", [
        element(
          "udt:Indicator",
          factur_x.w_specified_trade_allowance_charge_document_level_allowances_charge_indicator_indicator
        )
      ]),
      element(
        "ram:CalculationPercent",
        factur_x.w_specified_trade_allowance_charge_document_level_allowances_calculation_percent
      ),
      element(
        "ram:BasisAmount",
        if factur_x.w_specified_trade_allowance_charge_document_level_allowances_basis_amount not in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.w_specified_trade_allowance_charge_document_level_allowances_basis_amount
              ),
              2
            ),
            :normal
          )
        end
      ),
      element(
        "ram:ActualAmount",
        if factur_x.w_specified_trade_allowance_charge_document_level_allowances_actual_amount not in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.w_specified_trade_allowance_charge_document_level_allowances_actual_amount
              ),
              2
            ),
            :normal
          )
        end
      ),
      element(
        "ram:ReasonCode",
        factur_x.w_specified_trade_allowance_charge_document_level_allowances_reason_code
      ),
      element(
        "ram:Reason",
        factur_x.w_specified_trade_allowance_charge_document_level_allowances_reason
      ),
      create_w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax(
        factur_x
      )
    ])
  end

  defp create_w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax(
         factur_x
       ) do
    element("ram:CategoryTradeTax", [
      element(
        "ram:TypeCode",
        factur_x.w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_type_code
      ),
      element(
        "ram:CategoryCode",
        factur_x.w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_category_code
      ),
      element(
        "ram:RateApplicablePercent",
        factur_x.w_specified_trade_allowance_charge_document_level_allowances_category_trade_tax_rate_applicable_percent
      )
    ])
  end

  defp create_w_specified_trade_allowance_charge_document_level_charges(factur_x) do
    element("ram:SpecifiedTradeAllowanceChargeDocumentLevelCharges", [
      element("ram:ChargeIndicator", [
        element(
          "udt:Indicator",
          factur_x.w_specified_trade_allowance_charge_document_level_charges_charge_indicator_indicator
        )
      ]),
      element(
        "ram:CalculationPercent",
        factur_x.w_specified_trade_allowance_charge_document_level_charges_calculation_percent
      ),
      element(
        "ram:BasisAmount",
        if factur_x.w_specified_trade_allowance_charge_document_level_charges_basis_amount not in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.w_specified_trade_allowance_charge_document_level_charges_basis_amount
              ),
              2
            ),
            :normal
          )
        end
      ),
      element(
        "ram:ActualAmount",
        if factur_x.w_specified_trade_allowance_charge_document_level_charges_actual_amount not in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.w_specified_trade_allowance_charge_document_level_charges_actual_amount
              ),
              2
            ),
            :normal
          )
        end
      ),
      element(
        "ram:ReasonCode",
        factur_x.w_specified_trade_allowance_charge_document_level_charges_reason_code
      ),
      element(
        "ram:Reason",
        factur_x.w_specified_trade_allowance_charge_document_level_charges_reason
      ),
      create_w_specified_trade_allowance_charge_document_level_charges_category_trade_tax(
        factur_x
      )
    ])
  end

  defp create_w_specified_trade_allowance_charge_document_level_charges_category_trade_tax(
         factur_x
       ) do
    element(
      "ram:CategoryTradeTax",
      [
        element(
          "ram:TypeCode",
          factur_x.w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_type_code
        ),
        element(
          "ram:CategoryCode",
          factur_x.w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_category_code
        ),
        element(
          "ram:RateApplicablePercent",
          factur_x.w_specified_trade_allowance_charge_document_level_charges_category_trade_tax_rate_applicable_percent
        )
      ]
    )
  end

  defp create_w_specified_trade_payment_terms(factur_x) do
    element("ram:SpecifiedTradePaymentTerms", [
      element(
        "ram:Description",
        factur_x.w_specified_trade_payment_terms_description
      ),
      element("ram:DueDateDateTime", [
        element(
          "udt:DateTimeString",
          [format: "102"],
          check_parse_date(factur_x.w_due_date_date_time_date_time_string)
        )
      ]),
      element(
        "ram:DirectDebitMandateID",
        factur_x.w_direct_debit_mandate_id
      )
    ])
  end

  defp create_m_specified_trade_settlement_header_monetary_summation(factur_x) do
    element("ram:SpecifiedTradeSettlementHeaderMonetarySummation", [
      element(
        "ram:LineTotalAmount",
        if factur_x.w_specified_trade_settlement_header_monetary_summation_line_total_amount in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                sum_isctli_field(
                  factur_x,
                  :b_specified_trade_settlement_line_monetary_summation_line_total_amount
                )
              ),
              2
            ),
            :normal
          )
        else
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.w_specified_trade_settlement_header_monetary_summation_line_total_amount
              ),
              2
            ),
            :normal
          )
        end
      ),

      # is mandatory, but does not have to be submitted, as it can be calculated independently
      element(
        "ram:ChargeTotalAmount",
        if factur_x.w_specified_trade_settlement_header_monetary_summation_charge_total_amount not in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.w_specified_trade_settlement_header_monetary_summation_charge_total_amount
              ),
              2
            ),
            :normal
          )
        end
      ),
      element(
        "ram:AllowanceTotalAmount",
        if factur_x.w_specified_trade_settlement_header_monetary_summation_allowance_total_amount not in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.w_specified_trade_settlement_header_monetary_summation_allowance_total_amount
              ),
              2
            ),
            :normal
          )
        end
      ),
      element(
        # Calculation according to business rule BR-CO-13
        "ram:TaxBasisTotalAmount",
        if factur_x.m_tax_basis_total_amount in [nil, "", 0, 0.00] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                (sum_isctli_field(
                   factur_x,
                   :b_specified_trade_settlement_line_monetary_summation_line_total_amount
                 ) || 0.00) +
                  (factur_x.w_specified_trade_settlement_header_monetary_summation_charge_total_amount ||
                     0.00) +
                  (factur_x.w_specified_trade_settlement_header_monetary_summation_allowance_total_amount ||
                     0.00)
              ),
              2
            ),
            :normal
          )
        else
          Decimal.to_string(
            Decimal.round(Decimal.from_float(factur_x.m_tax_basis_total_amount), 2),
            :normal
          )
        end
      ),
      element(
        # Calculation according to business rule BR-CO-14
        "ram:TaxTotalAmount",
        [currencyID: factur_x.m_tax_total_amount_invoice_total_amount_currency_id],
        if factur_x.m_tax_total_amount_invoice_total_amount in [nil, "", 0, 0.00] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                sum_isctli_tax_field(
                  factur_x,
                  :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
                  7
                ) / 100 * 7 +
                  sum_isctli_tax_field(
                    factur_x,
                    :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
                    19
                  ) / 100 * 19
              ),
              2
            ),
            :normal
          )
        else
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(factur_x.m_tax_total_amount_invoice_total_amount),
              2
            ),
            :normal
          )
        end
      ),
      element(
        "ram:TaxTotalAmount",
        [currencyID: factur_x.w_tax_total_amount_invoice_total_amount_invat_currency_id],
        if factur_x.w_tax_total_amount_invoice_total_amount_invat not in [nil, "", 0, 0.00] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(factur_x.w_tax_total_amount_invoice_total_amount_invat),
              2
            ),
            :normal
          )
        end
      ),
      element(
        "ram:RoundingAmount",
        if factur_x.e_rounding_amount not in [nil, "", 0, 0.00] do
          Decimal.to_string(
            Decimal.round(Decimal.from_float(factur_x.e_rounding_amount), 2),
            :normal
          )
        end
      ),
      element(
        # Calculation according to business rule BR-CO-15
        "ram:GrandTotalAmount",
        if factur_x.m_specified_trade_settlement_header_monetary_summation_grand_total_amount in [
             nil,
             "",
             0,
             0.00
           ] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                (sum_isctli_field(
                   factur_x,
                   :b_specified_trade_settlement_line_monetary_summation_line_total_amount
                 ) || 0.00) +
                  (factur_x.w_specified_trade_settlement_header_monetary_summation_charge_total_amount ||
                     0.00) +
                  (factur_x.w_specified_trade_settlement_header_monetary_summation_allowance_total_amount ||
                     0.00) +
                  (sum_isctli_tax_field(
                     factur_x,
                     :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
                     7
                   ) / 100 * 7 +
                     sum_isctli_tax_field(
                       factur_x,
                       :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
                       19
                     ) / 100 * 19)
              ),
              2
            ),
            :normal
          )
        else
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                factur_x.m_specified_trade_settlement_header_monetary_summation_grand_total_amount
              ),
              2
            ),
            :normal
          )
        end
      ),
      element(
        "ram:TotalPrepaidAmount",
        if factur_x.w_total_prepaid_amount not in [nil, "", 0, 0.00] do
          Decimal.to_string(
            Decimal.round(Decimal.from_float(factur_x.w_total_prepaid_amount), 2),
            :normal
          )
        end,
        factur_x.w_total_prepaid_amount
      ),
      element(
        # Calculation according to business rule BR-CO-16
        "ram:DuePayableAmount",
        if factur_x.m_due_payable_amount in [nil, "", 0, 0.00] do
          Decimal.to_string(
            Decimal.round(
              Decimal.from_float(
                (sum_isctli_field(
                   factur_x,
                   :b_specified_trade_settlement_line_monetary_summation_line_total_amount
                 ) || 0.00) +
                  (factur_x.w_specified_trade_settlement_header_monetary_summation_charge_total_amount ||
                     0.00) +
                  (factur_x.w_specified_trade_settlement_header_monetary_summation_allowance_total_amount ||
                     0.00) +
                  (sum_isctli_tax_field(
                     factur_x,
                     :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
                     7
                   ) / 100 * 7 +
                     sum_isctli_tax_field(
                       factur_x,
                       :b_specified_trade_settlement_line_monetary_summation_line_total_amount,
                       19
                     ) / 100 * 19) - (factur_x.w_total_prepaid_amount || 0.00) +
                  (factur_x.e_rounding_amount || 0.00)
              ),
              2
            ),
            :normal
          )
        else
          Decimal.to_string(
            Decimal.round(Decimal.from_float(factur_x.m_due_payable_amount), 2),
            :normal
          )
        end
      )
    ])
  end

  defp create_w_applicable_header_trade_settlement_invoice_referenced_document(factur_x) do
    element("ram:InvoiceReferencedDocument", [
      element(
        "ram:IssuerAssignedID",
        factur_x.w_applicable_header_trade_settlement_invoice_referenced_document_issuer_assigned_id
      ),
      element("ram:FormattedIssueDateTime", [
        element(
          "qdt:DateTimeString",
          [format: "102"],
          check_parse_date(
            factur_x.w_applicable_header_trade_settlement_invoice_referenced_document_formatted_issue_date_time_date_time_string
          )
        )
      ])
    ])
  end

  defp create_w_applicable_header_trade_settlement_receivable_specified_trade_accounting_account(
         factur_x
       ) do
    element("ram:ReceivableSpecifiedTradeAccountingAccount", [
      element(
        "ram:ID",
        factur_x.w_applicable_header_trade_settlement_receivable_specified_trade_accounting_account_id
      )
    ])
  end

  # Support function - Calculate totals from the item fields
  defp sum_isctli_field(factur_x, field) do
    factur_x.b_included_supply_chain_trade_line_item
    |> Enum.map(fn isctli ->
      Map.get(isctli, field) || 0.00
    end)
    |> Enum.sum()
  end

  # Support function - Calculate totals from the item fields depending on the tax rate
  defp sum_isctli_tax_field(factur_x, field, tax_rate) do
    factur_x.b_included_supply_chain_trade_line_item
    |> Enum.filter(fn isctli ->
      Map.get(
        isctli,
        :b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent
      ) == tax_rate
    end)
    |> Enum.map(fn isctli ->
      value = Map.get(isctli, field) || 0.0

      cond do
        is_list(value) ->
          Enum.map(value, fn
            %{} = charge -> charge[field] || 0.0
            kw when is_list(kw) -> Keyword.get(kw, field, 0.0)
            num when is_number(num) -> num
            _ -> 0.0
          end)

        is_number(value) ->
          [value]

        true ->
          [0.0]
      end
    end)
    |> List.flatten()
    |> Enum.sum()
  end
end
