require "spec_helper"
require "chef/chef_fs/file_system/repository/chef_repository_file_system_root_dir"
require "chef/chef_fs/file_system/repository/nodes_dir"

describe Chef::ChefFS::FileSystem::Repository::NodesDir do
  let(:tmp_path) { Dir.mktmpdir }
  let(:child_paths) { { "nodes" => [tmp_path] } }
  let(:root_dir) do
    Chef::ChefFS::FileSystem::Repository::ChefRepositoryFileSystemRootDir.new(child_paths)
  end
  let(:nodes_dir) { described_class.new("nodes", root_dir, tmp_path) }

  describe "#create_child" do
    let(:file) { double("Chef::Resource::File") }
    let(:context) { double("Chef::RunContext") }
    let(:owner) { "test-user" }
    let(:node_name) { "test-node" }
    let(:node_path) { File.join(nodes_dir.file_path, "#{node_name}.json") }
    let(:node_content) { '{"name": "test-node"}' }

    before do
      allow(Chef::Resource::File).to receive(:new) { file }
      allow(Chef::RunContext).to receive(:new) { context }
      allow(file).to receive(:mode)
      allow(file).to receive(:rights)
      allow(file).to receive(:inherits)
      allow(file).to receive(:run_action)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("USERNAME") { owner }
    end

    it "creates the file" do
      expect(Chef::Resource::File).to receive(:new).with(node_path, context)
      expect(file).to receive(:run_action).with(:create)
      nodes_dir.create_child(node_name, node_content)
    end

    describe "permissions" do
      describe "on unix", :unix_only do
        it "sets them correctly" do
          expect(file).to receive(:mode).with(0600)
          nodes_dir.create_child(node_name, node_content)
        end
      end

      describe "on windows", :windows_only do
        it "sets them correctly" do
          expect(file).to receive(:rights).with([:read, :write], owner)
          expect(file).to receive(:inherits).with(false)
          nodes_dir.create_child(node_name, node_content)
        end
      end
    end
  end
end
