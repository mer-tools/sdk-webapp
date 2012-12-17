ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative 'sdk_helper'

include Rack::Test::Methods

def app() SdkHelper end

ORIGINAL_PATH = ENV['PATH']

describe "Sdk Webapp" do
	
	describe "working with not-locked sdk-manage/zypper" do 

		before do 
			ENV['PATH'] = "./tests/mock-bin-ok/:" + ORIGINAL_PATH
		end

		it "asked about / should send main page with sdk version in it" do
			get '/'
			last_response.body.must_match /.*SDK_MOCK_VERSION.*/
		end

		it "asked about /targets/ should send page with list of targets, form with installed toolchains" do
			get '/targets/'
			response = last_response.body
			response.must_match /.*TARGET1.*/
			response.must_match /.*TARGET2.*/
			response.must_match /.*DEFAULT_TARGET.*/
			#TODO: should show default target as default
			response.wont_match /.*TOOLCHAIN1.*/
			response.must_match /.*TOOLCHAIN2.*/
			response.wont_match /.*TOOLCHAIN3.*/
		end


		it "asked about /toolchains/ should send page with list of toolchains" do
			get '/toolchains/'
			response = last_response.body
			response.must_match /.*TOOLCHAIN1.*/
			response.must_match /.*TOOLCHAIN2.*/
			response.must_match /.*TOOLCHAIN3.*/
			#TODO: should show installed toolchains as installed
		end


	end

	describe "with cache built, locked zypper" do 

		before do 
			ENV['PATH'] = "./tests/mock-bin-ok/:" + ORIGINAL_PATH
			get '/'
			get '/targets/'
			get '/toolchains/'
			ENV['PATH'] = "./tests/mock-bin-locked/:" + ORIGINAL_PATH
		end

		it "asked about / should send main page with sdk version in it" do
			get '/'
			last_response.body.must_match /.*SDK_MOCK_VERSION.*/
			last_response.body.wont_match /.*WRONG_TEXT.*/
		end

		it "asked about /targets/ should send page with list of targets, form with installed toolchains" do
			get '/targets/'
			response = last_response.body
			response.must_match /.*TARGET1.*/
			response.must_match /.*TARGET2.*/
			response.must_match /.*DEFAULT_TARGET.*/
			#TODO: should show default target as default
			response.wont_match /.*TOOLCHAIN1.*/
			response.must_match /.*TOOLCHAIN2.*/
			response.wont_match /.*TOOLCHAIN3.*/
			response.wont_match /.*WRONG_TEXT.*/
		end


		it "asked about /toolchains/ should send page with list of toolchains" do
			get '/toolchains/'
			response = last_response.body
			response.must_match /.*TOOLCHAIN1.*/
			response.must_match /.*TOOLCHAIN2.*/
			response.must_match /.*TOOLCHAIN3.*/
			response.wont_match /.*WRONG_TEXT.*/
			#TODO: should show installed toolchains as installed
		end


	end


	describe "without cache built, locked zypper" do 

		before do 
			$sdk_version = nil
			$targets_list = nil
			$target_default = nil
			$toolchain_list = nil
			ENV['PATH'] = "./tests/mock-bin-locked/:" + ORIGINAL_PATH
		end

		it "asked about / should send main page with sdk version in it" do
			get '/'
			last_response.body.wont_match /.*SDK_MOCK_VERSION.*/
			last_response.body.wont_match /.*WRONG_TEXT.*/
		end

		it "asked about /targets/ should send page with list of targets, form with installed toolchains" do
			get '/targets/'
			response = last_response.body
			response.wont_match /.*TARGET1.*/
			response.wont_match /.*TARGET2.*/
			response.wont_match /.*DEFAULT_TARGET.*/
			#TODO: should show default target as default
			response.wont_match /.*TOOLCHAIN1.*/
			response.wont_match /.*TOOLCHAIN2.*/
			response.wont_match /.*TOOLCHAIN3.*/
			response.wont_match /.*WRONG_TEXT.*/
		end


		it "asked about /toolchains/ should send page with list of toolchains" do
			get '/toolchains/'
			response = last_response.body
			response.wont_match /.*TOOLCHAIN1.*/
			response.wont_match /.*TOOLCHAIN2.*/
			response.wont_match /.*TOOLCHAIN3.*/
			response.wont_match /.*WRONG_TEXT.*/
			#TODO: should show installed toolchains as installed
		end


	end



end


