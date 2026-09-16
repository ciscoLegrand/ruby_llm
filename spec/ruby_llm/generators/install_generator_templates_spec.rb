# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'generators/ruby_llm/install/install_generator'

RSpec.describe RubyLLM::Generators::InstallGenerator do
  def generate_migrations(reference_type)
    Dir.mktmpdir do |destination|
      generator = described_class.new([], {}, destination_root: destination)
      allow(generator).to receive_messages(
        postgresql?: true, mysql?: false, migration_version: '[8.1]', reference_type: reference_type
      )
      allow(generator).to receive(:say_status)
      generator.create_migration_files

      Dir.glob(File.join(destination, 'db/migrate/*.rb')).map { |file| File.read(file) }.join("\n")
    end
  end

  it 'gives every table a matching primary key type for UUID apps' do
    content = generate_migrations(:uuid)

    %i[ruby_llm_models ruby_llm_tool_calls ruby_llm_usages ruby_llm_batches chats messages].each do |table|
      expect(content).to include("create_table :#{table}, id: :uuid do |t|")
    end
  end

  it 'passes through other configured primary key types' do
    content = generate_migrations(:string)

    expect(content).to include('create_table :chats, id: :string do |t|')
    expect(content).to include('create_table :ruby_llm_models, id: :string do |t|')
  end

  it 'leaves the default bigint primary keys unchanged' do
    content = generate_migrations(:bigint)

    expect(content).to include('create_table :chats do |t|')
    expect(content).to include('create_table :ruby_llm_models do |t|')
    expect(content).not_to include('id: :')
  end
end
