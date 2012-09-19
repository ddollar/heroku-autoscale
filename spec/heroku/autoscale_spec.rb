require "spec_helper"
require "heroku/autoscale"

describe Heroku::Autoscale do

  include Rack::Test::Methods

  def noop
    lambda {|*args| }
  end

  describe "option validation" do
    it "requires username" do
      lambda { Heroku::Autoscale.new(noop) }.should raise_error(/Must supply :username/)
    end

    it "requires password" do
      lambda { Heroku::Autoscale.new(noop) }.should raise_error(/Must supply :password/)
    end

    it "requires app_name" do
      lambda { Heroku::Autoscale.new(noop) }.should raise_error(/Must supply :app_name/)
    end
  end

  describe "with valid options" do
    let(:app) do
      Heroku::Autoscale.new noop,
        :defer => false,
        :username => "test_username",
        :password => "test_password",
        :app_name => "test_app_name",
        :min_dynos       => 1,
        :max_dynos       => 10,
        :queue_wait_low  => 10,
        :queue_wait_high => 100,
        :min_frequency   => 10
    end

    it "scales up" do
      heroku = mock(Heroku::Client)
      heroku.should_receive(:info).with("test_app_name").and_return({ :dynos => 1 })
      heroku.should_receive(:set_dynos).with("test_app_name", 2)

      app.stub(:heroku).and_return(heroku)
      app.call({ "HTTP_X_HEROKU_QUEUE_WAIT_TIME" => 101 })
    end

    it "scales down" do
      heroku = mock(Heroku::Client)
      heroku.should_receive(:info).with("test_app_name").and_return({ :dynos => 3 })
      heroku.should_receive(:set_dynos).with("test_app_name", 2)

      app.stub(:heroku).and_return(heroku)
      app.call({ "HTTP_X_HEROKU_QUEUE_WAIT_TIME" => 9 })
    end

    it "wont go below one dyno" do
      heroku = mock(Heroku::Client)
      heroku.should_receive(:info).with("test_app_name").and_return({ :dynos => 1 })
      heroku.should_not_receive(:set_dynos)

      app.stub(:heroku).and_return(heroku)
      app.call({ "HTTP_X_HEROKU_QUEUE_WAIT_TIME" => 9 })
    end

    it "respects max dynos" do
      heroku = mock(Heroku::Client)
      heroku.should_receive(:info).with("test_app_name").and_return({ :dynos => 10 })
      heroku.should_not_receive(:set_dynos)

      app.stub(:heroku).and_return(heroku)
      app.call({ "HTTP_X_HEROKU_QUEUE_WAIT_TIME" => 101 })
    end

    it "respects min dynos" do
      app.options[:min_dynos] = 2
      heroku = mock(Heroku::Client)
      heroku.should_receive(:info).with("test_app_name").and_return({ :dynos => 2 })
      heroku.should_not_receive(:set_dynos)

      app.stub(:heroku).and_return(heroku)
      app.call({ "HTTP_X_HEROKU_QUEUE_WAIT_TIME" => 9 })
    end

    it "doesnt flap" do
      heroku = mock(Heroku::Client)
      heroku.should_receive(:info).with("test_app_name").and_return({ :dynos => 5 })
      heroku.should_receive(:set_dynos).once

      app.stub(:heroku).and_return(heroku)
      app.call({ "HTTP_X_HEROKU_QUEUE_WAIT_TIME" => 9 })
      app.call({ "HTTP_X_HEROKU_QUEUE_WAIT_TIME" => 9 })
    end
  end

end
