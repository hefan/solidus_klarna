# frozen_string_literal: true

require 'spec_helper'

describe Spree::PaymentMethod::Klarna do
  let!(:klarna) { create(:klarna_payment_method) }

  describe "save preferences" do
    it "can save config key" do
      klarna.set_preference(:config_key, "the key")
      klarna.save!
      expect(klarna.get_preference(:config_key)).to eq("the key");
    end

    it "can save server url" do
      klarna.set_preference(:server_url, "the url")
      klarna.save!
      expect(klarna.get_preference(:server_url)).to eq("the url");
    end

    it "can save reference prefix" do
      klarna.set_preference(:reference_prefix, "prefix")
      klarna.save!
      expect(klarna.get_preference(:reference_prefix)).to eq("prefix");
    end

    it "can save reference suffix" do
      klarna.set_preference(:reference_suffix, "suffix")
      klarna.save!
      expect(klarna.get_preference(:reference_suffix)).to eq("suffix");
    end
  end
end
