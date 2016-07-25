require 'watir-webdriver'

class Orderer
  def self.run(user)
    new(user).run
  end

  def initialize(user)
    @driver = Watir::Browser.new :phantomjs
    @wait = Watir::Wait
    @user = user

    driver.window.resize_to(1200, 1200)
  end

  def run
    begin
      # remove watir cookies
      delete_cookies

      driver.goto "https://mealpass.com/login"

      wait.until { driver.text.include? "Log in to your MealPass account" }

      login

      wait.until { driver.text.include? "WHAT'S FOR LUNCH ?" }

      raise 'Kitchen closed' if kitchen_closed?

      rate_meal if rate_meal_required?

      raise 'Meal already reserved' if meal_reserved?

      enter_address

      select_meal

      log('Ordered :)')
      true

    rescue Exception => e
      log(e)

      false
    ensure
      puts 'closing driver'

      driver.close

      false
    end
  end

  private

  def login
    driver.text_field(:name, "email").when_present.set(user.mealpass_email)
    driver.text_field(:name, "password").set(user.mealpass_password)

    driver.button(:text, "Log in").click
  end

  def meal_reserved?
    driver.text.include? 'Your meal is reserved'
  end

  def kitchen_closed?
    driver.text.include? 'The kitchen is closed'
  end

  def rate_meal_required?
    driver.text.include? 'Rate your meal!'
  end

  def rate_meal
    # rate as a "4" (good)
    driver.spans(class_name: 'star')[3].click
    # rate as a medium size portion
    driver.spans(class_name: 'portion ng-scope')[1].click

    driver.button(:text, "SUBMIT").click
  end

  def enter_address
    driver
      .text_field { input(:placeholder => 'Search Location ...') }
      .set('22 West 19th Street, New York, NY, United States')

    driver.send_keys :enter
  end

  def select_meal
    wait.until { driver.spans(:css, '.meal').length && driver.spans(:css, '.meal').length > 0 }
    sleep 10
    num_choices = driver.spans(:css, '.meal').length
    pick_number = (0...num_choices).to_a.sample

    driver
      .spans(:css, '.meal')[pick_number]
      .div(:css, '.address').click

    driver
      .spans(:css, '.meal')[pick_number]
      .button(class_name: 'mp-pickup-button').click

    driver
      .spans(:css, '.meal')[pick_number]
      .ul(:class_name => 'pickupTimes-list')
      .lis.find { |li| li.text == '12:00pm-12:15pm' }
      .click

    driver
      .spans(:css, '.meal')[pick_number]
      .button(text: 'RESERVE NOW').click
  end

  def log(message)
    log_entry = "\n===========================\n#{Time.now}\n#{message}"

    File.open('log/log.log', 'a') { |file| file << log_entry }

    puts message
  end

  def delete_cookies
    driver.cookies.clear
  end

  attr_reader :driver, :wait, :user
end