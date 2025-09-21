defmodule ExInvoicePDF do
  @moduledoc """
  Module for generating PDF invoices based on HTML templates using ChromicPDF.

  This module allows the generation of PDF files for invoices by using HTML and CSS
  to define the structure and layout of the invoice. The module leverages [ChromicPDF](https://hexdocs.pm/chromic_pdf/)
  as the backend for PDF creation.

  ## Functions

    - `generate_pdf/1`: Creates a PDF file for a given invoice and saves it in the `invoices_output` directory.
    - `create_html_invoice/1`: Converts the invoice data into an HTML template used for PDF generation.
    - `create_item/1`: Helper function that creates HTML table rows for each invoice line item.

  ## Examples

      invoice = %{
        id: "2024_Q3_234234",
        issue_date_time: ~D[2024-08-10],
        occurrence_date_time: ~D[2024-08-12],
        buyer_trade_party: %{
          name: "Customer XYZ",
          line_one: "Example Street 1",
          post_code_code: "12345",
          city_name: "Sample City"
        },
        seller_trade_party: %{
          name: "Seller Inc.",
          line_one: "Seller Street 2",
          city_name: "Seller City",
          post_code_code: "54321",
          country_id: "DE",
          vat_id: "DE123456789",
          tax_id: "123/456/78910",
          legal_court: "District Court Seller City",
          legal_HRB: "123456",
          bank_name: "Seller Bank",
          iban_id: "DE12345678901234567890",
          bic_id: "BANKDEFF",
          account_name: "Seller Inc.",
          uri_id: "info@seller.com",
          tel_complete_number: "0123456789",
          fax_complete_number: "0987654321",
          contact_web: "https://seller.com"
        },
        invoice_items: [
          %{
            seller_assigned_id: "A1314",
            name: "Test Item",
            description: "Description of the item",
            billed_quantity: 2,
            charge_amount: 100,
            line_total_amount: 200,
            tax_total_amount: 38
          }
        ],
        line_total_amount: 200,
        invoice_tax: 38,
        rate_applicable_percent: 19,
        grand_total_amount: 238,
        type_code: "Bank Transfer",
        invoice_payment_skonto_rate: 2,
        invoice_payment_skonto_days: 14,
        included_note: "Please keep this invoice for at least 10 years."
      }

      ExInvoicePDF.generate_pdf(invoice)

  ## Dependencies

  - ChromicPDF: Used to generate PDF files based on HTML/CSS.
  - CSS and image files should be placed in the `assets/css` and `assets/images` directories, respectively, for proper reference in the HTML template.

  ## Notes

  - The generated PDF file is saved in the `invoices_output` directory. If this directory does not exist,
    it will be created automatically.
  - The PDF file is saved under the name `invoice_<invoice_id>.pdf`, where `<invoice_id>` is replaced with the invoice number.

  """

  # PDF Creation via ChromicPDF

  def generate_pdf(invoice) do
    # Create a HTML File for using ChromicPDF
    invoice_html = create_html_invoice(invoice)
    # Create an output folder in case it doesnt exist
    File.mkdir_p!("invoices_output")
    # Filename of HTML=invoice number
    filename = "invoice_#{invoice[:id]}.pdf"

    [
      size: :a4,
      content: invoice_html
    ]
    |> ChromicPDF.Template.source_and_options()
    |> ChromicPDF.print_to_pdfa(output: Path.join("invoices_output", filename))
  end

  defp create_html_invoice(invoice) do
    # CSS and IMG has to be in folder assests/image or assest/css
    css_path = Path.join([Path.expand("../../assets/css", __DIR__), "styles.css"])
    logo_path = Path.join([Path.expand("../../assets/images", __DIR__), "logo.webp"])

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Invoice #{invoice.id}</title>
    <link rel="stylesheet" href="file://#{css_path}">
    </head>
    <body>
    <div class="invoice-box">
       <div class="header">
          <div class="customer-details">
               <div>#{invoice.buyer_trade_party.name}</div>
               <div>#{invoice.buyer_trade_party.line_one}</div>
               <div>#{invoice.buyer_trade_party.post_code_code} #{invoice.buyer_trade_party.city_name}</div>
          </div>
           <div class="invoice-date">
               <img src="file://#{logo_path}" alt="Company Logo"><br>
               <div>Rechnungsdatum: #{invoice.issue_date_time}</div>
               <div>Lieferdatum: #{invoice.occurrence_date_time}</div>
               <strong>#{invoice.seller_trade_party.name}</strong><br>
               #{invoice.seller_trade_party.line_one}<br>
               #{invoice.seller_trade_party.post_code_code} #{invoice.seller_trade_party.city_name}<br>
               #{invoice.seller_trade_party.country_id}<br>
           </div>
       </div>

       <div class="invoice-title">
           Rechnung
       </div>

       <div class="invoice-details">
           <div>Rechnungsnummer: #{invoice.id}</div>
           <div>Auftrags-Nr.: #{invoice.seller_order_referenced_document || "N/A"}</div>
           <div>Kundenreferenz: #{invoice.buyer_reference}</div>
       </div>

       <table class="table">
           <thead>
               <tr>
                   <th>Pos.</th>
                   <th>Art-Nr.</th>
                   <th>Bezeichnung</th>
                   <th>Menge</th>
                   <th>Einheit</th>
                   <th>Preis/Einh. (€)</th>
                   <th>Gesamt (€)</th>
               </tr>
           </thead>
           <tbody>
               #{create_item(invoice.included_supply_chain_trade_line_item)}
             <tr>
               <td colspan="7">&nbsp;</td>
             </tr>
               <tr>
                   <td colspan="6" style="text-align: left;">Summe Netto:</td>
                   <td style="text-align: right;">#{Decimal.to_string(Decimal.round(Decimal.from_float(invoice.line_total_amount), 2), :normal)} €</td>
               </tr>
               <tr>
                   <td colspan="6" style="text-align: left;">MWST (#{invoice.rate_applicable_percent}%):</td>
                   <td style="text-align: right;">#{Decimal.to_string(Decimal.round(Decimal.from_float(invoice.tax_total_amount), 2), :normal)} €</td>
               </tr>
               <tr>
                   <td colspan="6" style="text-align: left;"><strong>Endsumme:</strong></td>
                   <td style="text-align: right;"><strong>#{Decimal.to_string(Decimal.round(Decimal.from_float(invoice.grand_total_amount), 2), :normal)} €</strong></td>
               </tr>

           </tbody>
       </table>
       <div class="notes">
           <div>Bitte überweisen SIe den Rechnungsbetrag innerhalb von 14 Tagen auf unser unten genanntes Konto. </div>
           <div>Rechnungsbetrag zahlbar per #{invoice.payment_methode} abzüglich #{invoice.invoice_payment_skonto_rate}% Skonto innerhalb von #{invoice.invoice_payment_skonto_days} Tagen ab Rechnungsdatum.</div>
           <div>Lieferbedingungen: #{invoice.delivery_type_code || "N/A"}</div>
           <div>Andere Hinweise: #{invoice.included_note}</div>
           <br>
           <div> Für weitere Fragen stehen wir Ihnen gerne zu Verfügung.</div>
           <br>
           <div>Mit freundlichen Grüßen</div>
       </div>
    </div>
    <footer class="footer">
       <div class="footer-column">
           <!-- Left Column: Company Address -->
           #{invoice.seller_trade_party.name}<br>
           #{invoice.seller_trade_party.line_one}<br>
           #{invoice.seller_trade_party.city_name}, #{invoice.seller_trade_party.post_code_code}<br>
           #{invoice.seller_trade_party.country_id}
           </div>
      <div class="footer-column">
           <!-- Left Column: Company Address -->
           Mail: #{invoice.seller_trade_party.uri_id}<br>
           Telefonnummer: #{invoice.seller_trade_party.tel_complete_number}<br>
           Fax: #{invoice.seller_trade_party.fax_complete_number}<br>
           Internet: #{invoice.seller_trade_party.contact_web}
           </div>

       <div class="footer-column">
           <!-- Center Column: Bank Account Details -->
           Bank: #{invoice.seller_trade_party.bank_name}<br>
           IBAN: #{invoice.seller_trade_party.iban_id}<br>
           BIC: #{invoice.seller_trade_party.bic_id}<br>
           Kto. Inh.: #{invoice.seller_trade_party.account_name}<br>
       </div>
       <div class="footer-column">
        <!-- Right Column: VAT-ID and Legal Info -->
         UST-ID: #{invoice.seller_trade_party.vat_id}<br>
         Steuernummer: #{invoice.seller_trade_party.tax_id} <br>
         Amtsgericht: #{invoice.seller_trade_party.legal_court} <br>
         Handelsregisternummer: #{invoice.seller_trade_party.legal_HRB}
       </div>

    </footer>

    </body>
    </html>

    """
  end

  # For every item position a new line has to be created
  defp create_item(items) do
    Enum.map_join(items, "", fn item ->
      """
      <tr>
          <td>#{item.seller_assigned_id}</td>
          <td>#{item.name}</td>
          <td>#{item.description}</td>
          <td>#{item.billed_quantity}</td>
          <td>#{item.line_id || "Stück"}</td>
          <td>#{Decimal.to_string(Decimal.round(Decimal.from_float(item.charge_amount), 4), :normal)}</td>
          <td>#{Decimal.to_string(Decimal.round(Decimal.from_float(item.line_total_amount), 2), :normal)}</td>
      </tr>
      """
    end)
  end
end
