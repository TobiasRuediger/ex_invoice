defmodule ExInvoiceTest do
  use ExUnit.Case

  @valid_invoice %{
    id: "2025_Q3_234234",
    typecode: 380,
    buyer_reference: "2INTER00",
    seller_order_referenced_document: nil,
    delivery_type_code: nil,
    invoice_currency_code: "EUR",
    issue_date_time: ~D[2025-08-10],
    occurrence_date_time: ~D[2025-08-12],
    note_date: nil,
    seller_trade_party: %{
      name: "Biller_name",
      trading_business_name: "Biller_trading_business_name",
      line_one: "Biller_line_one",
      city_name: "Biller_city_name",
      post_code_code: "80333",
      country_sub_division_name: "Bayern",
      country_id: "DE",
      notes: nil,
      vat_id: "DE812526315",
      tax_id: "123/456/78910",
      legal_court: "Amtsgericht München",
      legal_HRB: "1234567",
      bank_name: "Sparkasse München",
      iban_id: "DE89370400440532013000",
      bic_id: "1234",
      account_name: "biller_account_name",
      uri_id: "Biller_Mail@test.de",
      tel_complete_number: "1234567890",
      fax_complete_number: "0987654321",
      contact_web: "http://example.com"
    },
    buyer_trade_party: %{
      # Pflichtfeld
      name: "customer name",
      trading_business_name: "customer trading name",
      line_one: "Customer_line_one. 345",
      line_two: nil,
      line_three: nil,
      city_name: "München",
      post_code_code: "80333",
      country_sub_division_name: "Bayern",
      country_id: "DE",
      notes: nil
    },
    included_supply_chain_trade_line_item: [
      %{
        seller_assigned_id: "A1314",
        name: "Test",
        description: "Item1_Description",
        item_comments: "",
        billed_quantity: 2,
        charge_amount: 500.00,
        actual_amount: 0.00,
        calculation_percent: 0,
        line_id: nil,
        rate_applicable_percent: 19.0,
        line_total_amount: 1000.00,
        tax_total_amount: 190.00
      },
      %{
        seller_assigned_id: "B2324",
        name: "Zweite Artikel",
        description: "Item2_Description",
        item_comments: "",
        billed_quantity: 1,
        charge_amount: 1000.00,
        # actual_amount: 10,
        # Set to 0 so that it fits the PDF display
        actual_amount: 0.00,
        # calculation_percent: 5,
        # Set to 0 so that it fits the PDF display
        calculation_percent: 0,
        line_id: nil,
        rate_applicable_percent: 19.0,
        line_total_amount: 1000.00,
        tax_total_amount: 190.00
      }
    ],
    line_total_amount: 2000.00,
    tax_total_amount: 380.00,
    rate_applicable_percent: 19,
    grand_total_amount: 2380.00,
    invoice_payment_skonto_rate: 2,
    invoice_payment_skonto_days: 14,
    type_code: 30,
    payment_methode: "Überweisung",
    invoice_tax_note: nil,
    included_note:
      "Sie sind gesetzlich verpflichtet diese Rechnung mindestens 2 Jahre – als umsatzsteuerlicher Unternehmer 10 Jahre – aufzubewahren. Die Aufbewahrungsfrist beginnt mit Schluss dieses Kalenderjahres."
  }

  # Initial test without changes
  test "Valid invoice structure" do
    assert ExInvoice.validate_invoice(@valid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # invoice ID too long
  test "Invalid invoice number too long" do
    invalid_invoice = Map.put(@valid_invoice, :id, "12346789101111111111111111111111111111111111")

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invoice number exceeds maximum length of 20 characters."}
  end

  test "Invalid invoice number" do
    # id = nil
    invalid_invoice = Map.put(@valid_invoice, :id, nil)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invoice number is required but is empty or nil."}
  end

  # Dates
  # Test issue_date_time = empty
  test "issue_date_time = empty" do
    invalid_invoice = Map.put(@valid_invoice, :issue_date_time, "")

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice 2025_Q3_234234: Invalid date format or value, Delivery Date 2025-08-12 is not after Invoice Date "}
  end

  # Test issue_date_time after deliver_date
  test "issue_date_time after deliver_date" do
    invalid_invoice = Map.put(@valid_invoice, :issue_date_time, ~D[2025-08-15])

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice 2025_Q3_234234: Delivery Date 2025-08-12 is not after Invoice Date 2025-08-15"}
  end

  # Test issue_date_time = nil
  test "issue_date_time = nil" do
    invalid_invoice = Map.put(@valid_invoice, :issue_date_time, nil)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error, "Validation failed for invoice #{invalid_invoice.id}: No date provided"}
  end

  # Test issue_date_time wrong format
  test "issue_date_time wrong format" do
    invalid_invoice = Map.put(@valid_invoice, :issue_date_time, "12343243245")

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invalid date format or value, Delivery Date 2025-08-12 is not after Invoice Date 12343243245"}
  end

  # Test occurrence_date_time wrong format
  test "occurrence_date_time wrong format" do
    invalid_invoice = Map.put(@valid_invoice, :occurrence_date_time, "12343243245")

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error, "Validation failed for invoice #{invalid_invoice.id}: Date input error"}
  end

  # Test occurrence_date_time = nil Rechnungsdatum = Lieferdatum"
  test "occurrence_date_time Rechnungsdatum = Lieferdatum" do
    invalid_invoice =
      @valid_invoice
      |> Map.put(:occurrence_date_time, nil)
      |> Map.put(:note_date, "Rechnungsdatum = Lieferdatum")

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # Test occurrence_date_time = nil Rechnungsdatum = NIX
  test "occurrence_date_time Rechnungsdatum = NIX" do
    invalid_invoice =
      @valid_invoice
      |> Map.put(:occurrence_date_time, nil)
      |> Map.put(:note_date, "Rechnungsdatum = NIX")

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: No delivery date and hint 'Rechnungsdatum = Lieferdatum' is missing"}
  end

  # Test for street too long
  test "Street too long" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(
          @valid_invoice.seller_trade_party,
          :line_one,
          "TOOOOOOOOOOOOOOOOOOOOOOLONG12345645345"
        )
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: line_one exceeds maximum length of 35 characters."}
  end

  # ADRESS
  # Test for street missing
  test "Street missing" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(@valid_invoice.seller_trade_party, :line_one, nil)
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: line_one is required but is empty or nil."}
  end

  # Test for city_name
  test "City too long" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(
          @valid_invoice.seller_trade_party,
          :city_name,
          "TOOOOOOOOOOOOOOOOOOOOOOLONG12345645345"
        )
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: city_name exceeds maximum length of 20 characters."}
  end

  # Test for city_name
  test "City_name missing" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(@valid_invoice.seller_trade_party, :city_name, "")
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: city_name is required but is empty or nil."}
  end

  # Test for city_name = nil
  test "City_name nil" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(@valid_invoice.seller_trade_party, :city_name, nil)
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: city_name is required but is empty or nil."}
  end

  # Test for missing postal code
  test "Invalid postal code nil" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(@valid_invoice.seller_trade_party, :post_code_code, nil)
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: No postal code provided"}
  end

  # Test invalid postal code
  test "Invalid postal code" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(@valid_invoice.seller_trade_party, :post_code_code, "invalid")
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: German postal code is not valid"}
  end

  # Test invalid postal code
  test "Invalid postal code too long" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(@valid_invoice.seller_trade_party, :post_code_code, "123456787")
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: German postal code is not valid"}
  end

  # Test valid postal code
  test "Valid postal code starting with 0" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(@valid_invoice.seller_trade_party, :post_code_code, "01145")
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # Test for postal code outside of Germany
  test "Test for a Postal Code outside of Germany" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:post_code_code, "123456")
      |> Map.put(:country_id, "FR")

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # Test name too long
  test "Invalid name too long" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(
          @valid_invoice.seller_trade_party,
          :name,
          "123456789101112131415161718192021222345672"
        )
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: name exceeds maximum length of 40 characters."}
  end

  # Test name = nil
  test "Test name =nil" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :buyer_trade_party,
        Map.put(
          @valid_invoice.buyer_trade_party,
          :name,
          nil
        )
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error, "Validation failed for invoice #{invalid_invoice.id}: Missing field: name"}
  end

  # Test Valid trading_business_name and name missing
  test "Valid trading_business_name and name" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:trading_business_name, "trading_business_name")
      |> Map.put(:name, "costumer name")

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # TAX
  # Test Invalid VAT number, tax ok
  test "Invalid VAT number, tax ok" do
    invalid_invoice = put_in(@valid_invoice[:seller_trade_party][:vat_id], "INVALID")

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # Test Invalid Paymet method
  test "Invalid payment method" do
    invalid_invoice = Map.put(@valid_invoice, :payment_methode, "Bitcoin")

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Payment method must be one of Überweisung, Kreditkarte, PayPal"}
  end

  # Test invalid tax rate rate_applicable_percent
  test "Invalid tax rate" do
    invalid_invoice = Map.put(@valid_invoice, :rate_applicable_percent, 3)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Tax_rate must be 0, 7, or 19."}
  end

  # Test invalid IBAN
  test "Invalid IBAN" do
    invalid_invoice =
      Map.put(
        @valid_invoice,
        :seller_trade_party,
        Map.put(@valid_invoice.seller_trade_party, :iban_id, "INVALID_IBAN")
      )

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: IBAN validation failed: invalid_format"}
  end

  # -----------------------
  # Test for a valid German tax number (10 digits in the format xxx/xxx/xxxxx)
  test "Valid German tax number (10 digits)" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:tax_id, "123/456/78901")
      |> Map.put(:vat_id, nil)

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # Test german Valid German tax number (11 digits)
  test "Valid German tax number (11 digits)" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:tax_id, "123/456/12345")
      |> Map.put(:vat_id, nil)

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # Test for a valid German VAT ID ("DE" followed by 9 digits)
  test "Valid German VAT ID 9 digits" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:tax_id, nil)
      |> Map.put(:vat_id, "DE812526315")

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:ok, "Validation successful. PDF 2025_Q3_234234.pdf is created."}
  end

  # Test for an invalid German tax number (wrong format)
  test "InValid German VAT ID" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:tax_id, nil)
      |> Map.put(:vat_id, "1DE13456789")

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invalid tax number and invalid VAT number"}
  end

  # Test for Invalid German VAT ID too short
  test "Invalid German VAT ID too short" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:tax_id, nil)
      |> Map.put(:vat_id, "DE12345678")

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invalid tax number and invalid VAT number"}
  end

  # Test for Invalid German VAT ID (empty string)
  test "Invalid German VAT ID (empty string)" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:tax_id, nil)
      |> Map.put(:vat_id, "")

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invalid tax number and invalid VAT number"}
  end

  # Test for an invalid VAT ID (nil)
  test "Invalid German VAT ID and Tax-ID (nil)" do
    invalid_address =
      @valid_invoice.seller_trade_party
      |> Map.put(:tax_id, nil)
      |> Map.put(:vat_id, nil)

    invalid_invoice = Map.put(@valid_invoice, :seller_trade_party, invalid_address)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invalid tax number and invalid VAT number"}
  end

  # ITEMS
  # Test for Invalid item name too long
  test "Invalid item name too long" do
    invalid_invoice =
      update_in(@valid_invoice[:included_supply_chain_trade_line_item], fn items ->
        [%{Enum.at(items, 0) | name: String.duplicate("A", 51)}]
      end)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: name exceeds maximum length of 25 characters."}
  end

  # Test for Invalid item quantity is nil
  test "Invalid item quantity is nil" do
    invalid_invoice =
      update_in(@valid_invoice[:included_supply_chain_trade_line_item], fn items ->
        [%{Enum.at(items, 0) | billed_quantity: nil}]
      end)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Item has missing or invalid fields: quantity"}
  end

  # Test Invalid item quantity is not a number
  test "Invalid item quantity is not a number" do
    invalid_invoice =
      update_in(@valid_invoice[:included_supply_chain_trade_line_item], fn items ->
        [%{Enum.at(items, 0) | billed_quantity: "invalid"}]
      end)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Item has missing or invalid fields: quantity"}
  end

  # Test Invalid item quantity is negative anumber
  test "Invalid item quantity is a negative number" do
    invalid_invoice =
      update_in(@valid_invoice[:included_supply_chain_trade_line_item], fn items ->
        [%{Enum.at(items, 0) | billed_quantity: -2}]
      end)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Item has missing or invalid fields: quantity"}
  end

  # total net not correct
  test "Item level total net not correct" do
    invalid_invoice =
      update_in(@valid_invoice[:included_supply_chain_trade_line_item], fn items ->
        [%{Enum.at(items, 0) | line_total_amount: -184}]
      end)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice 2025_Q3_234234: Invalid total net: expected 1000.00, but got -184"}
  end

  # Test invalid tax rate (negative)
  test "Negative tax rate" do
    invalid_invoice = Map.put(@valid_invoice, :rate_applicable_percent, -19)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Tax_rate must be 0, 7, or 19."}
  end

  # Test for missing invoice items
  test "Missing invoice items" do
    invalid_invoice = Map.put(@valid_invoice, :included_supply_chain_trade_line_item, [])

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invoice must contain at least one item."}
  end

  # Test for invalid total_net (0 or negative)
  test "Invalid total_net" do
    invalid_invoice = Map.put(@valid_invoice, :line_total_amount, 0)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice 2025_Q3_234234: Tax_rate must be 0, 7, or 19., The calculated net price 2000.00 does not match the expected invoice net 0."}
  end

  test "Negative total_net" do
    invalid_invoice = Map.put(@valid_invoice, :line_total_amount, -100)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Tax_rate must be 0, 7, or 19., The calculated net price 2000.00 does not match the expected invoice net -100."}
  end

  # Test for invalid total_tax (negative)
  test "Negative total_tax" do
    invalid_invoice = Map.put(@valid_invoice, :tax_total_amount, -50)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Tax_rate must be 0, 7, or 19."}
  end

  # Test for invalid tax_rate (not 0, 7, or 19)
  test "Invalid tax_rate" do
    invalid_invoice = Map.put(@valid_invoice, :rate_applicable_percent, 5)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Tax_rate must be 0, 7, or 19."}
  end

  # Test for mismatched tax_rate calculation
  test "Mismatched tax_rate calculation" do
    invalid_invoice = Map.put(@valid_invoice, :tax_total_amount, 400)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Tax_rate does not match the calculated tax rate"}
  end

  # Test for mismatched grand_total_amount
  test "Mismatched grand_total_amount" do
    invalid_invoice = Map.put(@valid_invoice, :grand_total_amount, 2400)

    assert ExInvoice.validate_invoice(invalid_invoice) ==
             {:error,
              "Validation failed for invoice #{invalid_invoice.id}: Invoice total does not match: expected 2380.00, but got 2400"}
  end

  # -----------------------
end
