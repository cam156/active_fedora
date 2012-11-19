require 'spec_helper'
require "solrizer"

describe ActiveFedora::NokogiriDatastream do
  
  before(:all) do
    class HydrangeaArticle2 < ActiveFedora::Base
      # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
      has_metadata :name => "descMetadata", :type => Hydra::ModsArticleDatastream

      # A place to put extra metadata values
      has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
        m.field 'collection', :string
      end
    end

  end

  after(:all) do
    Object.send(:remove_const, :HydrangeaArticle2)
  end

  describe '.term_values' do
    before do
      @pid = "hydrangea:fixture_mods_article1"
      @test_solr_object = ActiveFedora::Base.load_instance_from_solr(@pid)
      @test_object = HydrangeaArticle2.find(@pid)
    end

    it "should return the same values whether getting from solr or Fedora" do
      @test_solr_object.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["Creator","Contributor","Funder","Host"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>0},:role,:text).should == ["Creator"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["Contributor"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Creator"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["Contributor"]
      @test_solr_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
      ar = @test_solr_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
      ar.length.should == 4
      ar.include?("Creator").should == true
      ar.include?("Contributor").should == true
      ar.include?("Funder").should == true
      ar.include?("Host").should == true

      @test_object.datastreams["descMetadata"].term_values(:name,:role,:text).should == ["Creator","Contributor","Funder","Host"]
      @test_object.datastreams["descMetadata"].term_values({:name=>0},:role,:text).should == ["Creator"]
      @test_object.datastreams["descMetadata"].term_values({:name=>1},:role,:text).should == ["Contributor"]
      @test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Creator"]
      @test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>0},:text).should == ["Contributor"]
      @test_object.datastreams["descMetadata"].term_values({:name=>1},{:role=>1},:text).should == []
      ar = @test_object.datastreams["descMetadata"].term_values(:name,{:role=>0},:text)
      ar.length.should == 4
      ar.include?("Creator").should == true
      ar.include?("Contributor").should == true
      ar.include?("Funder").should == true
      ar.include?("Host").should == true
    end
  end
  
  describe '.update_values' do
    before do
      @pid = "hydrangea:fixture_mods_article1"
      @test_object = HydrangeaArticle2.find(@pid)
    end

    it "should not be dirty after .update_values is saved" do
      @test_object.datastreams["descMetadata"].update_values([{:name=>0},{:role=>0},:text] =>"Funder")
      @test_object.datastreams["descMetadata"].dirty?.should be_true
      @test_object.save
      @test_object.datastreams["descMetadata"].dirty?.should be_false
      @test_object.datastreams["descMetadata"].term_values({:name=>0},{:role=>0},:text).should == ["Funder"]
    end    
  end


  describe ".to_solr" do
    before do
      object = HydrangeaArticle2.new
      object.descMetadata.journal.issue.publication_date = Date.parse('2012-11-02')
      object.save!
      @test_object = HydrangeaArticle2.find(object.pid)

    end
    it "should solrize terms with :type=>'date' to *_dt solr terms" do
      @test_object.to_solr['mods_journal_issue_publication_date_dt'].should == ['2012-11-02T00:00:00Z']
    end
  end

  describe "#generate_solr_symbol" do
    it "should use the default mapper from the Solrizer gem" do
      # This is a strange problem where AF will not use the default mapper in the Solrizer gem when it's running tests.
      # If you go into a irb session, it works though:
      #
      # $ irb -I lib
      # 1.9.3p286 :001 > require 'active-fedora'
      #  => true 
      # 1.9.3p286 :002 > Solrizer::FieldMapper::Default.new.mappings[:searchable].data_types[:date].converter.is_a?(Proc)
      #  => true 
      Solrizer::XML::TerminologyBasedSolrizer.default_field_mapper.mappings[:searchable].data_types[:date].converter.is_a?(Proc).should be_true
    end
  end

end
