defmodule ExInvoice do
  @moduledoc """
  The `ExInvoice` module provides a set of functions to validate invoices according to various criteria, such as the seller and buyer addresses, tax information, dates, invoice numbers, payment terms, and item details. It supports both normal invoices (with a net amount over 250€) and simplified invoices (with a net amount under 250€).

  ## Features:

  - **Validation of Seller and Buyer Addresses**: Ensures that all required fields, such as business name, forename, surname, address, city, and postal code, are present and valid.
  - **Tax and VAT Validation**: Validates German tax numbers and VAT IDs, including checking tax rates and ensuring the proper application of tax exemptions if applicable.
  - **Date Validation**: Ensures that the invoice issue date and delivery date are valid and consistent, with special handling for the scenario where the delivery date is not provided and the invoice contains the note "Rechnungsdatum = Lieferdatum."
  - **Invoice Number Validation**: Checks the presence and length of the invoice ID.
  - **Payment Terms Validation**: Ensures that Skonto (discount) rates, Skonto days, and payment methods are valid.
  - **Item Validation**: Checks that all items in the invoice are valid, including names, quantities, and prices. Ensures the total net price of the items matches the expected invoice net.
  - **IBAN Validation**: Validates the IBAN using the `Bankster` library.

  - ** After successful validation, e-invoices are created in ZUGFeRD/Factur-X format using the “CreateFacturX.create_factur_x” function. The profile to be created and the invoice data are transferred to the CreateFacturX.create_factur_x structure in the
  “factur_x” function.

  ## Normal vs. Simplified Invoices:

  - **Normal Invoice**: Invoices with a net amount >= 250€ require a full set of validations, including the seller and buyer address, tax information, delivery and issue dates, invoice number, items, and payment terms.
  - **Simplified Invoice**: Invoices with a net amount < 250€ have fewer validation requirements, focusing on the seller's address, issue date, tax information, items, and payment details.

  ## Usage:

  To validate an invoice, the `validate_invoice/1` function processes the invoice and returns either:

  - `{:ok, "Validation successful"}` if all validations pass, and generates a PDF of the invoice.
  - `{:error, "Validation failed: [errors]"}` if one or more validations fail, providing details on the errors.

  """
  def validate_invoice(invoice) do
    # Check if its a normal invoice (>250€) or a simplified one (<250€)
    results =
      if invoice.line_total_amount >= 250 do
        # Normal Invoice
        [
          validate_address(invoice.seller_trade_party),
          validate_address(invoice.buyer_trade_party),
          validate_tax_information(
            invoice.seller_trade_party.vat_id,
            invoice.seller_trade_party.tax_id
          ),
          validate_date(invoice.issue_date_time),
          validate_date_delivery(
            invoice.issue_date_time,
            invoice.occurrence_date_time,
            invoice.note_date
          ),
          validate_length(invoice.id, 20, true, "Invoice number"),
          validate_tax(
            invoice.rate_applicable_percent,
            invoice.line_total_amount,
            invoice.tax_total_amount,
            invoice.invoice_tax_note,
            invoice.grand_total_amount
          ),
          validate_all_items(
            invoice.included_supply_chain_trade_line_item,
            invoice.line_total_amount
          ),
          validate_iban(invoice.seller_trade_party.iban_id),
          validate_email(invoice.seller_trade_party.uri_id),
          validate_payment_terms(
            invoice.invoice_payment_skonto_rate,
            invoice.invoice_payment_skonto_days,
            invoice.payment_methode
          )
        ]
      else
        # Simplified Invoice
        [
          validate_address(invoice.seller_trade_party),
          validate_date(invoice.issue_date_time),
          validate_address(invoice.buyer_trade_party),
          validate_tax(
            invoice.rate_applicable_percent,
            invoice.line_total_amount,
            invoice.tax_total_amount,
            invoice.invoice_tax_note,
            invoice.grand_total_amount
          ),
          validate_all_items(
            invoice.included_supply_chain_trade_line_item,
            invoice.line_total_amount
          ),
          validate_iban(invoice.seller_trade_party.iban_id),
          validate_email(invoice.seller_trade_party.uri_id)
        ]
      end

    # Collecting all errors
    errors =
      results
      |> Enum.filter(fn result -> match?({:error, _}, result) end)
      |> Enum.map(fn {:error, message} -> message end)

    case errors do
      [] ->
        # No error occured. PDF will be printed and factur_x xml will be generated

        CreateFacturX.create_factur_x(
          factur_x(invoice),
          Path.join("invoices_output", "#{invoice.id}.xml")
        )

         ExInvoicePDF.generate_pdf(invoice)
        {:ok, "Validation successful. PDF #{invoice.id}.pdf is created."}

      _ ->
        # Error occurre. Error feedback will be provided via a list.
        {:error, "Validation failed for invoice #{invoice.id}: #{Enum.join(errors, ", ")}"}
    end
  end

  defp validate_length(value, max_length, required, field_name) do
    cond do
      required and (is_nil(value) or value == "") ->
        {:error, "#{field_name} is required but is empty or nil."}

      not required and (is_nil(value) or value == "") ->
        {:ok, nil}

      is_binary(value) and String.length(value) > max_length ->
        {:error, "#{field_name} exceeds maximum length of #{max_length} characters."}

      true ->
        {:ok, value}
    end
  end

  # Functions to check if an adress is complete
  defp validate_address(%{
         trading_business_name: trading_business_name,
         name: name,
         line_one: line_one,
         city_name: city_name,
         post_code_code: post_code_code,
         country_id: country_id
       }) do
    with :ok <- validate_name(name),
         {:ok, _} <- validate_length(trading_business_name, 35, false, "trading_business_name"),
         {:ok, _} <- validate_length(name, 40, false, "name"),
         {:ok, _} <- validate_length(city_name, 20, true, "city_name"),
         {:ok, _} <- validate_length(line_one, 35, true, "line_one"),
         {:ok, _} <- validate_post_code_code(post_code_code, country_id) do
      {:ok, "Address is valid."}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  defp validate_address(_), do: {:error, "Address not complete."}
  defp validate_name(nil), do: {:error, "Missing field: name"}
  defp validate_name(""), do: {:error, "Missing field: name"}
  defp validate_name(_), do: :ok

  defp validate_post_code_code(nil, _country_id), do: {:error, "No postal code provided"}

  defp validate_post_code_code(post_code_code, "DE") do
    if Regex.match?(~r/^\d{5}$/, post_code_code) do
      {:ok, "Postal code is valid"}
    else
      {:error, "German postal code is not valid"}
    end
  end

  defp validate_post_code_code(_post_code_code, _country_id) do
    {:ok, "Address is valid, but postal code not checked as it's not a German postal code."}
  end

  # Validate German tax numbers and VAT IDs.

  defp validate_tax_information(vat_id, tax_id) do
    case {validate_tax_id(tax_id), validate_vat_id(vat_id)} do
      {{:ok, _}, {:ok, _}} ->
        {:ok, "Tax and VAT-number correct"}

      {{:ok, _}, {:error, _}} ->
        {:ok, "Tax number correct"}

      {{:error, _}, {:ok, _}} ->
        {:ok, "VAT-number correct"}

      {{:error, _}, {:error, _}} ->
        {:error, "Invalid tax number and invalid VAT number"}
    end
  end

  # Validation of german VAT
  defp validate_tax_id(nil), do: {:error, "Invalid tax number"}

  defp validate_tax_id(number) when is_binary(number) do
    # Pattern for german tax number(10 or 11 chars)
    tax_id_regex = ~r/^\d{3}\/\d{3}\/\d{5}$/

    if Regex.match?(tax_id_regex, number) do
      {:ok, "#{number} tax_id_valid"}
    else
      {:error, "Invalid tax number"}
    end
  end

  # Validation USt-IdNr. (german format)
  defp validate_vat_id(nil), do: {:error, "No VAT number provided"}

  defp validate_vat_id(number) when is_binary(number) do
    # IO.inspect(ExVatcheck.check(number), label: "ExVatcheck Result")

    case ExVatcheck.check(number) do
      %ExVatcheck.VAT{valid: true} ->
        {:ok, "#{number} vat_id_valid"}

      %ExVatcheck.VAT{valid: false} ->
        {:error, "Invalid VAT number"}

      _ ->
        {:error, "Unexpected response from VAT validation"}
    end
  end

  # Checks if the date is valid
  defp validate_date(%Date{} = _date) do
    {:ok, "Valid date."}
  end

  defp validate_date(nil) do
    {:error, "No date provided"}
  end

  defp validate_date(_) do
    {:error, "Invalid date format or value"}
  end

  # Invoice date equals delivery date, no delivery date provided
  defp validate_date_delivery(_invoice_date, nil, "Rechnungsdatum = Lieferdatum") do
    {:ok, "Invoice date equals delivery date"}
  end

  # No delivery date, missing hint 'Invoice date equals delivery date'
  defp validate_date_delivery(_invoice_date, nil, _note_date) do
    {:error, "No delivery date and hint 'Rechnungsdatum = Lieferdatum' is missing"}
  end

  # Valid delivery date and invoice date equals delivery date
  defp validate_date_delivery(invoice_date, delivery_date, _note_date) do
    case validate_date(delivery_date) do
      {:ok, "Valid date."} when delivery_date == invoice_date ->
        {:ok, "Invoice date equals delivery date"}

      {:ok, "Valid date."} when delivery_date > invoice_date ->
        {:ok, "Delivery Date #{delivery_date} is after Invoice Date #{invoice_date}"}

      {:ok, "Valid date."} ->
        {:error, "Delivery Date #{delivery_date} is not after Invoice Date #{invoice_date}"}

      _ ->
        {:error, "Date input error"}
    end
  end

  # Checks Skonto and payment method.
  defp validate_payment_terms(skonto_rate, skonto_days, payment_method) do
    with {:ok, _rate} <- validate_rate(skonto_rate),
         {:ok, _days} <- validate_days(skonto_days),
         {:ok, _payment_method} <- validate_payment_method(payment_method) do
      {:ok, "Valid Payment Terms"}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Validiaation of skonto rate in %
  defp validate_rate(rate) when is_number(rate) and rate >= 0 and rate <= 10 do
    {:ok, rate}
  end

  defp validate_rate(_), do: {:error, "Discount rate must be a number between 0 and 10."}

  # Validation skonto days
  defp validate_days(days) when is_integer(days) and days > 0 do
    {:ok, days}
  end

  defp validate_days(_), do: {:error, "Days must be a positive integer."}

  # Validation payment method
  defp validate_payment_method(payment_method) when is_binary(payment_method) do
    accepted_payment_methods = ["Überweisung", "Kreditkarte", "PayPal"]

    case payment_method in accepted_payment_methods do
      true ->
        {:ok, payment_method}

      false ->
        {:error, "Payment method must be one of #{Enum.join(accepted_payment_methods, ", ")}"}
    end
  end

  defp validate_payment_method(_), do: {:error, "Invalid payment method format."}

  # checks whether the tax rate has been calculated correctly and applied
  # checks whether the tax rate has been calculated correctly, applied, and if grand_total_amount matches
  defp validate_tax(tax_rate, total_net, total_tax, tax_note, grand_total_amount) do
    with :ok <- validate_tax_fields(tax_rate, total_net, total_tax, grand_total_amount),
         :ok <- validate_tax_values(tax_rate, total_net, total_tax),
         :ok <- validate_tax_note_if_exempt(tax_rate, tax_note),
         :ok <- validate_calculated_tax_rate(tax_rate, total_net, total_tax),
         :ok <- validate_grand_total_amount(total_net, total_tax, grand_total_amount) do
      {:ok, "#{tax_rate}% tax applied correctly"}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  # Check if tax, total_net, total_tax, and grand_total_amount fields are not nil
  defp validate_tax_fields(nil, _, _, _), do: {:error, "tax: missing field"}
  defp validate_tax_fields(_, nil, _, _), do: {:error, "tax: missing field"}
  defp validate_tax_fields(_, _, nil, _), do: {:error, "tax: missing field"}
  defp validate_tax_fields(_, _, _, nil), do: {:error, "grand_total_amount: missing field"}
  defp validate_tax_fields(_, _, _, _), do: :ok

  # Validate tax_rate, total_net, and total_tax values
  defp validate_tax_values(tax_rate, total_net, total_tax) do
    if total_net <= 0 or total_tax < 0 or tax_rate not in [0, 7, 19] do
      {:error, "Tax_rate must be 0, 7, or 19."}
    else
      :ok
    end
  end

  # Ensure a reason for tax exemption is provided if tax_rate is 0
  defp validate_tax_note_if_exempt(0, tax_note) do
    if String.trim(tax_note) == "" do
      {:error, "No reason for tax exemption provided"}
    else
      :ok
    end
  end

  defp validate_tax_note_if_exempt(_, _), do: :ok

  # Validate that the calculated tax_rate matches the provided tax_rate
  defp validate_calculated_tax_rate(tax_rate, total_net, total_tax) do
    if tax_rate != round(total_tax / total_net * 100) do
      {:error, "Tax_rate does not match the calculated tax rate"}
    else
      :ok
    end
  end

  # Validate that the total_net + total_tax matches the grand_total_amount
  defp validate_grand_total_amount(total_net, total_tax, grand_total_amount) do
    expected_total = total_net + total_tax

    formatted_expected_total =
      Decimal.to_string(Decimal.round(Decimal.from_float(expected_total), 2), :normal)

    #    |> Decimal.round(2)
    #    |> Decimal.to_string(:normal)

    if abs(expected_total - grand_total_amount) > 0.01 do
      {:error,
       "Invoice total does not match: expected #{formatted_expected_total}, but got #{grand_total_amount}"}
    else
      :ok
    end
  end

  # Emailcheck
  def validate_email(email) when is_binary(email) do
    email_regex = ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]+$/

    case Regex.match?(email_regex, email) do
      true ->
        {:ok, "Mail providedd"}

      false ->
        {:error, "Invalid email format"}
    end
  end

  # Checks items
  # Collects the results for allitems
  defp validate_all_items(items, expected_net) do
    if Enum.empty?(items) do
      {:error, "Invoice must contain at least one item."}
    else
      validations = Enum.map(items, &validate_item/1)

      errors =
        Enum.filter(validations, fn
          {:error, _} -> true
          {:ok, _} -> false
        end)

      if errors == [] do
        net_price =
          Enum.reduce(items, 0.00, fn item, acc ->
            acc + item[:line_total_amount]
          end)

        formatted_net_price =
          Decimal.to_string(Decimal.round(Decimal.from_float(net_price), 2), :normal)

        #     |> Decimal.round(2)
        #     |> Decimal.to_string(:normal)

        if net_price == expected_net do
          {:ok, "All items are valid. Net value of all items are #{net_price} €"}
        else
          {:error,
           "The calculated net price #{formatted_net_price} does not match the expected invoice net #{expected_net}."}
        end
      else
        error_messages =
          errors
          |> Enum.map(fn {:error, message} -> message end)
          |> Enum.join("; ")

        {:error, error_messages}
      end
    end
  end

  defp validate_item(item) do
    # Check for missing, nil, or invalid fields (excluding the length validation here)
    missing_or_invalid_fields =
      item
      |> Enum.filter(fn
        {:billed_quantity, quantity}
        when is_nil(quantity) or not is_number(quantity) or quantity < 0 ->
          true

        {:charge_amount, price} when is_nil(price) or not is_number(price) or price < 0 ->
          true

        {:line_total_amount, total_net} when is_nil(total_net) or not is_number(total_net) ->
          true

        _ ->
          false
      end)
      |> Enum.map(fn
        {:billed_quantity, _} -> "quantity"
        {:charge_amount, _} -> "price"
        {:line_total_amount, _} -> "total_net"
      end)

    case missing_or_invalid_fields do
      [] ->
        # First, validate the length of name using validate_length/4
        case validate_length(item[:name], 25, true, "name") do
          {:ok, _} ->
            # Proceed with further validation if name is valid
            quantity = item[:billed_quantity]
            price = item[:charge_amount]
            total_net = item[:line_total_amount]

            # Check if quantity * price equals line_total_amount
            calculated_total = quantity * price

            formatted_calculated_total =
              Decimal.to_string(Decimal.round(Decimal.from_float(calculated_total), 2), :normal)

            #     |> Decimal.round(2)
            #      |> Decimal.to_string(:normal)

            if calculated_total == total_net do
              {:ok, total_net}
            else
              {:error,
               "Invalid total net: expected #{formatted_calculated_total}, but got #{total_net}"}
            end

          {:error, msg} ->
            # Return the error from validate_length/4 if name is invalid
            {:error, msg}
        end

      fields ->
        # If there are missing or invalid fields, return an error
        {:error, "Item has missing or invalid fields: #{Enum.join(fields, ", ")}"}
    end
  end

  # Iban Validation with Bankster, is neede to provide feedback in the same way as other validations
  def validate_iban(iban) do
    case Bankster.Iban.validate(iban) do
      {:ok, iban_value} ->
        {:ok, "IBAN is valid: #{iban_value}"}

      {:error, reason} ->
        {:error, "IBAN validation failed: #{reason}"}

      _ ->
        {:error, "Unexpected response from IBAN validation."}
    end
  end

  #Transfers the invoice item data to the item group “b_included_supply_chain_trade_line_item”
  defp set_factur_x_items(%{included_supply_chain_trade_line_item: items}) do
    Enum.map(items, fn item -> factur_x_items(item) end)
  end

  #Struct from the FacturXIsctli module for transferring invoice item data for the creation of ZUGFeRD/Factur-X e-invoices
  def factur_x_items(item) do
    %FacturXIsctli{
      b_associated_document_line_document_line_id: nil,
      b_associated_document_line_document_included_note_content: nil,
      b_specified_trade_product_global_id: nil,
      b_specified_trade_product_global_id_scheme_id: nil,
      e_specified_trade_product_seller_assigned_id: item.seller_assigned_id,
      e_specified_trade_product_buyer_assigned_id: nil,
      b_specified_trade_product_name: item.name,
      e_specified_trade_product_description: item.description,
      e_class_code_list_id: nil,
      e_class_code_list_version_id: nil,
      e_origin_trade_country_id: nil,
      e_buyer_order_referenced_document_line_id: item.line_id,
      b_gross_price_product_trade_price_charge_amount: 11.90,
      b_gross_price_product_trade_price_basis_quantity: nil,
      b_gross_price_product_trade_price_basis_quantity_unit_code: nil,
      b_applied_trade_allowance_charge_price_allowance_charge_indicator_indicator: nil,
      b_applied_trade_allowance_charge_price_allowance_actual_amount: item.actual_amount,
      b_net_price_product_trade_price_charge_amount: item.charge_amount,
      b_net_price_product_trade_price_basis_quantity: nil,
      b_net_price_product_trade_price_basis_quantity_unit_code: nil,
      b_billed_quantity: item.billed_quantity,
      b_billed_quantity_unit_code: "H87",
      b_specified_line_trade_settlement_applicable_trade_tax_category_code: "S",
      # becomes a mandatory field under rule BR-S-8
      b_specified_line_trade_settlement_applicable_trade_tax_rate_applicable_percent:
        item.rate_applicable_percent,
      b_specified_line_trade_settlement_billing_specified_period_start_date_time_date_time_string:
        nil,
      b_specified_line_trade_settlement_billing_specified_period_end_date_time_date_time_string:
        nil,
      b_specified_trade_settlement_line_monetary_summation_line_total_amount:
        item.line_total_amount,
      e_specified_line_trade_settlement_additional_referenced_document_issuer_assigned_id: nil,
      e_specified_line_trade_settlement_additional_referenced_document_type_code: nil,
      e_specified_line_trade_settlement_additional_referenced_document_reference_type_code: nil,
      e_specified_line_trade_settlement_receivable_specified_trade_accounting_account_id: nil,
      e_applicable_product_characteristic: [
        e_applicable_product_characteristic_description: nil,
        e_value: nil
      ],
      b_specified_trade_allowance_charge: [
        # true Charge / false Allowance
        b_specified_trade_allowance_charge_charge_indicator: nil,
        e_specified_trade_allowance_charge_calculation_percent: item.calculation_percent,
        e_specified_trade_allowance_charge_basis_amount: nil,
        b_specified_trade_allowance_charge_actual_amount: item.actual_amount,
        # If a discount or charge applies, it must be filled in
        b_specified_trade_allowance_charge_reason_code: nil,
        # becomes a mandatory field under rule BR-S-8
        b_specified_trade_allowance_charge_reason: nil
      ]
    }
  end

  # Struct from the CreateFacturX module for transferring invoice data for the creation of ZUGFeRD/Factur-X e-invoices
  def factur_x(invoice) do
    %CreateFacturX{
      m_profil_factur_x: "EN16931",
      m_business_process_specified_document_context_parameter_id: "ex_invoice_test",
      m_exchanged_document_id: invoice.id,
      m_exchanged_document_type_code: invoice.typecode,
      m_issue_date_time_date_time_string: invoice.issue_date_time,
      m_buyer_reference: invoice.buyer_reference,
      w_seller_trade_party_id: nil,
      w_seller_trade_party_global_id: nil,
      w_seller_trade_party_global_id_scheme_id: nil,
      m_seller_trade_party_name: invoice.seller_trade_party.name,
      e_seller_trade_party_description: nil,
      m_seller_trade_party_specified_legal_organization_id: nil,
      m_seller_trade_party_specified_legal_organization_id_scheme_id: nil,
      w_seller_trade_party_specified_legal_organization_trading_business_name:
        invoice.seller_trade_party.trading_business_name,
      e_seller_trade_party_defined_trade_contact_person_name: nil,
      e_seller_trade_party_defined_trade_contact_department_name: nil,
      e_seller_trade_party_defined_trade_contact_telephone_universal_communication_complete_number:
        invoice.seller_trade_party.tel_complete_number,
      e_seller_trade_party_defined_trade_contact_emailuri_universal_communication_uriid:
        invoice.seller_trade_party.uri_id,
      w_seller_trade_party_postal_trade_address_postcode_code:
        invoice.seller_trade_party.post_code_code,
      w_seller_trade_party_postal_trade_address_line_one: invoice.seller_trade_party.line_one,
      w_seller_trade_party_postal_trade_address_line_two: nil,
      w_seller_trade_party_postal_trade_address_line_three: nil,
      w_seller_trade_party_postal_trade_address_city_name: invoice.seller_trade_party.city_name,
      m_seller_trade_party_postal_trade_address_country_id: invoice.seller_trade_party.country_id,
      w_seller_trade_party_postal_trade_address_country_sub_division_name:
        invoice.seller_trade_party.country_sub_division_name,
      w_seller_trade_party_uri_universal_communication_uriid: nil,
      w_seller_trade_party_uri_universal_communication_uriid_scheme_id: nil,
      m_specified_tax_registration_vat_identifier_id: invoice.seller_trade_party.vat_id,
      m_specified_tax_registration_vat_identifier_id_scheme_id: "VA",
      e_specified_tax_registration_local_tax_id: invoice.seller_trade_party.tax_id,
      e_specified_tax_registration_local_tax_id_scheme_id: "FC",
      w_buyer_trade_party_id: nil,
      w_buyer_trade_party_global_id: nil,
      w_buyer_trade_party_global_id_scheme_id: nil,
      m_buyer_trade_party_name: invoice.buyer_trade_party.name,
      m_buyer_trade_party_specified_legal_organization_id: nil,
      m_buyer_trade_party_specified_legal_organization_id_scheme_id: nil,
      e_buyer_trade_party_specified_legal_organization_trading_business_name:
        invoice.buyer_trade_party.trading_business_name,
      e_buyer_trade_party_defined_trade_contact_person_name: nil,
      e_buyer_trade_party_defined_trade_contact_department_name: nil,
      e_buyer_trade_party_defined_trade_contact_telephone_universal_communication: nil,
      e_buyer_trade_party_defined_trade_contact_telephone_universal_communication_complete_number:
        nil,
      e_buyer_trade_party_defined_trade_contact_emailuri_universal_communication: nil,
      e_buyer_trade_party_defined_trade_contact_emailuri_universal_communication_uriid: nil,
      w_buyer_trade_party_postal_trade_address_postcode_code:
        invoice.buyer_trade_party.post_code_code,
      w_buyer_trade_party_postal_trade_address_line_one: invoice.buyer_trade_party.line_one,
      w_buyer_trade_party_postal_trade_address_line_two: invoice.buyer_trade_party.line_two,
      w_buyer_trade_party_postal_trade_address_line_three: invoice.buyer_trade_party.line_three,
      w_buyer_trade_party_postal_trade_address_city_name: invoice.buyer_trade_party.city_name,
      w_buyer_trade_party_postal_trade_address_country_id: invoice.buyer_trade_party.country_id,
      w_buyer_trade_party_postal_trade_address_country_sub_division_name:
        invoice.buyer_trade_party.country_sub_division_name,
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
      e_applicable_header_trade_agreement_seller_order_referenced_document_issuer_assigned_id:
        invoice.seller_order_referenced_document,
      m_applicable_header_trade_agreement_buyer_order_referenced_document_issuer_assigned_id: nil,
      w_applicable_header_trade_agreement_contract_referenced_document_issuer_assigned_id: nil,
      e_additional_referenced_document_additional_supporting_documents_issuer_assigned_id: nil,
      e_additional_referenced_document_additional_supporting_documents_uriid: nil,
      e_additional_referenced_document_additional_supporting_documents_type_code: nil,
      e_additional_referenced_document_additional_supporting_documents_name: nil,
      e_additional_referenced_document_additional_supporting_documents_attachment_binary_object_mime_code:
        nil,
      e_additional_referenced_document_additional_supporting_documents_attachment_binary_object_filename:
        nil,
      e_additional_referenced_document_tender_lot_issuer_assigned_id: nil,
      e_additional_referenced_document_tender_lot_type_code: nil,
      e_additional_referenced_document_invoiced_object_issuer_assigned_id: nil,
      e_additional_referenced_document_invoiced_object_type_code: nil,
      e_additional_referenced_document_invoiced_object_reference_type_code: nil,
      e_specified_procuring_project_id: nil,
      e_specified_procuring_project_name: nil,
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
      w_applicable_header_trade_delivery_actual_delivery_supply_chain_event_occurrence_date_time_date_time_string:
        invoice.occurrence_date_time,
      w_applicable_header_trade_delivery_despatch_advice_referenced_document_issuer_assigned_id:
        nil,
      e_applicable_header_trade_delivery_receiving_advice_referenced_document_issuer_assigned_id:
        nil,
      w_creditor_reference_id: nil,
      w_payment_reference: nil,
      w_tax_currency_code: nil,
      m_invoice_currency_code: invoice.invoice_currency_code,
      w_applicable_header_trade_settlement_payee_trade_party_id: nil,
      w_applicable_header_trade_settlement_payee_trade_party_global_id: nil,
      w_applicable_header_trade_settlement_payee_trade_party_global_id_scheme_id: nil,
      w_applicable_header_trade_settlement_payee_trade_party_name: nil,
      w_applicable_header_trade_settlement_payee_trade_party_specified_legal_organization_id: nil,
      w_applicable_header_trade_settlement_payee_trade_party_specified_legal_organization_id_scheme_id:
        nil,
      w_specified_trade_settlement_payment_means_type_code: invoice.type_code,
      e_information: nil,
      e_applicable_trade_settlement_financial_card_id: nil,
      e_cardholder_name: nil,
      w_payer_party_debtor_financial_account_iban_id: nil,
      w_payee_party_creditor_financial_account_iban_id: invoice.seller_trade_party.iban_id,
      e_account_name: invoice.seller_trade_party.account_name,
      w_proprietary_id: nil,
      e_payee_specified_creditor_financial_institution: nil,
      e_bic_id: invoice.seller_trade_party.bic_id,
      w_applicable_header_trade_settlement_applicable_trade_tax_calculated_amount:
        invoice.tax_total_amount,
      w_applicable_header_trade_settlement_applicable_trade_tax_exemption_reason: nil,
      w_applicable_trade_tax_basis_amount: invoice.line_total_amount,
      w_applicable_header_trade_settlement_applicable_trade_tax_category_code: "S",
      w_applicable_header_trade_settlement_applicable_trade_tax_exemption_reason_code: nil,
      e_date_string: nil,
      w_due_date_type_code: nil,
      w_applicable_header_trade_settlement_applicable_trade_tax_rate_applicable_percent:
        invoice.rate_applicable_percent,
      w_applicable_header_trade_settlement_billing_specified_period_start_date_time_date_time_string:
        nil,
      w_applicable_header_trade_settlement_billing_specified_period_end_date_time_date_time_string:
        nil,
      w_specified_trade_allowance_charge_document_level_allowances_charge_indicator: nil,
      w_specified_trade_allowance_charge_document_level_allowances_charge_indicator_indicator:
        nil,
      w_specified_trade_allowance_charge_document_level_allowances_calculation_percent: nil,
      w_specified_trade_allowance_charge_document_level_allowances_basis_amount: nil,
      w_specified_trade_allowance_charge_document_level_allowances_actual_amount: nil,
      w_specified_trade_allowance_charge_document_level_allowances_reason_code: nil,
      w_specified_trade_allowance_charge_document_level_allowances_reason: nil,
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
      w_specified_trade_payment_terms_description:
      "Rechnungsbetrag zahlbar per #{invoice.payment_methode} abzüglich #{invoice.invoice_payment_skonto_rate}%
      Skonto innerhalb von #{invoice.invoice_payment_skonto_days} Tagen ab Rechnungsdatum",
      w_due_date_date_time_date_time_string: nil,
      w_direct_debit_mandate_id: nil,
      w_specified_trade_settlement_header_monetary_summation_line_total_amount:
        invoice.line_total_amount,
      w_specified_trade_settlement_header_monetary_summation_charge_total_amount: nil,
      w_specified_trade_settlement_header_monetary_summation_allowance_total_amount: nil,
      m_tax_basis_total_amount: invoice.line_total_amount,
      m_tax_total_amount_invoice_total_amount: invoice.tax_total_amount,
      m_tax_total_amount_invoice_total_amount_currency_id: "EUR",
      w_tax_total_amount_invoice_total_amount_invat: nil,
      w_tax_total_amount_invoice_total_amount_invat_currency_id: nil,
      e_rounding_amount: nil,
      m_specified_trade_settlement_header_monetary_summation_grand_total_amount:
        invoice.grand_total_amount,
      w_total_prepaid_amount: nil,
      m_due_payable_amount: nil,
      w_applicable_header_trade_settlement_invoice_referenced_document_issuer_assigned_id: nil,
      w_applicable_header_trade_settlement_invoice_referenced_document_formatted_issue_date_time_date_time_string:
        nil,
      w_applicable_header_trade_settlement_receivable_specified_trade_accounting_account_id: nil,
      b_included_supply_chain_trade_line_item: set_factur_x_items(invoice),
      w_exchanged_document_included_note: [
        [
          w_exchanged_document_included_note_content:
            to_string(invoice.seller_trade_party.legal_court) <>
              " " <> to_string(invoice.seller_trade_party.legal_HRB),
          w_exchanged_document_included_note_subject_code: nil
        ],
        [
          w_exchanged_document_included_note_content: invoice.included_note,
          w_exchanged_document_included_note_subject_code: nil
        ]
      ]
    }
  end
end
