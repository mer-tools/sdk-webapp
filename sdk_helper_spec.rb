ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative 'sdk_helper'

include Rack::Test::Methods

def app() SdkHelper end

ORIGINAL_PATH = ENV['PATH']

$server_list = [ "MOCK_SERVER" ]


describe "Sdk Webapp" do
	
	before do 
		class RestClient::Request
			def self.execute(*params)
				params[0][:url].must_equal 'MOCK_SERVER'
				'[{"name": "MOCK_TARGET_NAME", "url": "MOCK_TARGET_URL", "toolchain": "MOCK_TARGET_TOOLCHAIN"}]'
			end
		end
	end

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
			response.must_match /.*MOCK_TARGET_URL.*/
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
			response.must_match /.*MOCK_TARGET_URL.*/
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
			response.must_match /.*MOCK_TARGET_URL.*/
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

	describe "working with target server sending commented json" do 
		
		it "doesn't fail on hash comments" do
			class RestClient::Request
				def self.execute(*params)
					params[0][:url].must_equal 'MOCK_SERVER'
					"# dupa\n"+'[{"name": "MOCK_TARGET_NAME", "url": "MOCK_TARGET_URL", "toolchain": "MOCK_TARGET_TOOLCHAIN"}]'
				end
			end

			get '/targets/'
			response = last_response.body
			response.must_match /.*MOCK_TARGET_URL.*/
		end

		it "doesn't fail on slash-slash comments" do
			class RestClient::Request
				def self.execute(*params)
					params[0][:url].must_equal 'MOCK_SERVER'
					"# dupa\n"+'[{"name": "MOCK_TARGET_NAME", "url": "MOCK_TARGET_URL", "toolchain": "MOCK_TARGET_TOOLCHAIN"}]'
				end
			end

			get '/targets/'
			response = last_response.body
			response.must_match /.*MOCK_TARGET_URL.*/
		end

		
	end

	describe "working with crappy target server" do 

		before do 
			ENV['PATH'] = "./tests/mock-bin-ok/:" + ORIGINAL_PATH
		end

		describe "returning crap" do

			it "doesn't fail when asked about /targets/" do 
				class RestClient::Request
					def self.execute(*params)
						"crap"
					end
				end
				get "/targets/"
				response = last_response.body
				response.must_match /.*TARGET1.*/
				response.must_match /.*TARGET2.*/
				response.must_match /.*DEFAULT_TARGET.*/
				#TODO: should show default target as default
				response.wont_match /.*TOOLCHAIN1.*/
				response.must_match /.*TOOLCHAIN2.*/
				response.wont_match /.*TOOLCHAIN3.*/
				response.wont_match /.*MOCK_TARGET_URL.*/
				#TODO: ensure target dropdown is not generated
			end

		end

		describe "returning nothing" do

			it "doesn't fail when asked about /targets/" do 
				class RestClient::Request
					def self.execute(*params)
						nil
					end
				end
				get "/targets/"
				response = last_response.body
				response.must_match /.*TARGET1.*/
				response.must_match /.*TARGET2.*/
				response.must_match /.*DEFAULT_TARGET.*/
				#TODO: should show default target as default
				response.wont_match /.*TOOLCHAIN1.*/
				response.must_match /.*TOOLCHAIN2.*/
				response.wont_match /.*TOOLCHAIN3.*/
				response.wont_match /.*MOCK_TARGET_URL.*/
				#TODO: ensure target dropdown is not generated
			end

		end

	end

end


