require 'rubygems'
require 'highline/import'
require 'nokogiri'
require 'mechanize'
require 'open-uri'

# @author Lucas Silvestre (https://github.com/lsilvs/)
class JoinBaskets
	# Define some vars
  @url_login = "https://secure.tesco.ie/register/default.aspx?from=http%3a%2f%2fwww.tesco.ie%2fgroceries%2fbasket%2fDefault.aspx"
	@shelf = []

	agent = Mechanize.new

  agent.get(@url_login)
  form = agent.page.forms.first

  # Ask user for the credentials
  form.loginID = ask("Enter your Email address:  ") { |q| q.echo = true }
  form.password = ask("Enter your password:  ") { |q| q.echo = "*" }

  form.submit

  if agent.page.title == "Tesco.ie - Sorry, but we couldn't sign you in"
    p agent.page.title
  else
    p agent.page.title
    # Access the main basket (My Basket)
    agent.get("http://www.tesco.ie/groceries/basket/")
    form = agent.page.form_with(:id => "fBasket")
    form.field_with(:name => 'baskets').options.first.click
    form.click_button

    # Empty the main basket before join the others
    agent.get("http://www.tesco.ie/groceries/dialogue/?dialogueName=EmptyBasket")
    agent.submit(agent.page.forms.first, agent.page.forms.first.button_with(:name => 'emptyBasket'))

    # Iterate through each basket
    form.field_with(:name => 'baskets').options.each do |opt|
      opt.click
      form.click_button

      p opt.text

      # Iterate through each product on shelfs
      agent.page.parser.css("tbody.shelf tr").each do |row|
        if row.css("p.prodName a").any? and row.css("input.basketItemQuantity").any?
          product = { 
            "name" => row.css("p.prodName a").text, 
            "link" => row.css("p.prodName a")[0]["href"],
            "quantity" => row.css("input.basketItemQuantity")[0]["value"],
            "price" => row.css("p.price span").text,
          }
          @shelf.push(product)
          p product['quantity'] + " :: " + product['name'] + " :: " + product['price']
        end
      end
    end

    # Access the main basket (My Basket)
    agent.get("http://www.tesco.ie/groceries/basket/")
    form = agent.page.form_with(:id => "fBasket")
    form.field_with(:name => 'baskets').options.first.click
    form.click_button

    # Add each product to the main basket
    @shelf.each do |product|
       agent.get(product['link'])
       form = agent.page.form_with(:id => %r{fDetails})
       form.fields[2].value = product['quantity']
       agent.submit(form, form.buttons[0])
    end

  p "All your baskets were joined together into the 'My Basket'. Check it out on Tesco.ie ;)"
  p "Cheers for use me and spread the word!"

  end

end